# Canonical MCP Code Deployment Script (PowerShell)
# Deploys a selected MCP Server (Python Azure Functions codebase) to a single Azure Function App (the current deployment slot)
# Uses a JSON config file for all deployment parameters, located in the root of each MCP Server app folder.
#
# In this model, you have:
#   - One Azure Function App (the deployment target, or "slot")
#   - Multiple MCP Server codebases (under apps/), each with its own endpoints and config
#   - Only one MCP Server can be deployed to the Function App at a time
#   - To "switch" which MCP Server is live, deploy a different app folder to the Function App
#
# If you want true side-by-side isolation, provision multiple Function Apps in Terraform and deploy each MCP Server to its own.

param(
    [string]$AppName = $null,
    [string]$ConfigPath = $null
)

# Step 1: Select MCP Server app from mapping file
if (-not $AppName) {
    $MappingPath = Join-Path (Join-Path $PSScriptRoot '..') 'apps/deployment.map.json'
    if (Test-Path $MappingPath) {
        $mapping = Get-Content $MappingPath | ConvertFrom-Json
        $availableApps = $mapping.PSObject.Properties.Name
        Write-Host "Available MCP Server apps for deployment:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $availableApps.Count; $i++) {
            Write-Host ("  [{0}] {1}" -f ($i+1), $availableApps[$i])
        }
        $choice = Read-Host "Enter the number of the MCP Server app to deploy"
        if ($choice -match '^[0-9]+$' -and $choice -ge 1 -and $choice -le $availableApps.Count) {
            $AppName = $availableApps[$choice - 1]
        } else {
            Write-Error "[MCP DEPLOY] Invalid selection. Exiting."
            exit 1
        }
    } else {
        Write-Error "[MCP DEPLOY] Mapping file 'apps/deployment.map.json' not found. Please create it from the sample."
        exit 1
    }
}

# Always look for the app under the 'apps' folder
$AppRoot = Join-Path (Join-Path $PSScriptRoot '..') "apps/$AppName"
if (-not (Test-Path $AppRoot)) {
    Write-Error "[MCP DEPLOY] MCP Server app '$AppName' not found at $AppRoot."
    exit 1
}

# Use mapping file ONLY for Function App name; always load per-app config for other parameters
$MappingPath = Join-Path (Join-Path $PSScriptRoot '..') 'apps/deployment.map.json'
if (Test-Path $MappingPath) {
    $mapping = Get-Content $MappingPath | ConvertFrom-Json
    if ($mapping.PSObject.Properties.Name -contains $AppName) {
        $FunctionAppName = $mapping.$AppName
        Write-Host "[MCP DEPLOY] Using Function App from mapping: $FunctionAppName"
    } else {
        Write-Error "[MCP DEPLOY] No mapping found for '$AppName' in deployment.map.json."
        exit 1
    }
} else {
    Write-Error "[MCP DEPLOY] Mapping file 'apps/deployment.map.json' not found. Please create it from the sample."
    exit 1
}

# Always load the per-app config for all other parameters
if (-not $ConfigPath) {
    $ConfigPath = Get-ChildItem -Path $AppRoot -Filter 'mcpcodedeploy.config*.json' | Where-Object { $_.Name -notlike '*.example' } | Select-Object -First 1 | ForEach-Object { $_.FullName }
}
if (-not $ConfigPath -or -not (Test-Path $ConfigPath)) {
    Write-Error "[MCP DEPLOY] Config file not found in $AppRoot. Please copy a sample and fill it out."
    exit 1
}

$config = Get-Content $ConfigPath | ConvertFrom-Json
$ResourceGroup   = $config.resource_group
$Location        = $config.location
$SubscriptionId  = $config.subscription_id
$PythonVersion   = $config.python_version

# Step 2: Dynamically list Function Apps only in the known resource group
Write-Host "Querying Azure for available Function Apps (slots) in resource group '$ResourceGroup'..."
$functionApps = az functionapp list --resource-group $ResourceGroup --query "[].{name:name, rg:resourceGroup}" -o json | ConvertFrom-Json
if (-not $functionApps -or $functionApps.Count -eq 0) {
    Write-Error "[MCP DEPLOY] No Function Apps found in resource group '$ResourceGroup'."
    exit 1
}
Write-Host "Available Function App slots in resource group '$ResourceGroup':" -ForegroundColor Cyan
for ($i = 0; $i -lt $functionApps.Count; $i++) {
    Write-Host ("  [{0}] {1}" -f ($i+1), $functionApps[$i].name)
}
$slotChoice = Read-Host "Enter the number of the Function App slot to deploy to"
if ($slotChoice -match '^[0-9]+$' -and $slotChoice -ge 1 -and $slotChoice -le $functionApps.Count) {
    $FunctionAppName = $functionApps[$slotChoice - 1].name
    Write-Host "[MCP DEPLOY] Selected Function App: $FunctionAppName (Resource Group: $ResourceGroup)"
} else {
    Write-Error "[MCP DEPLOY] Invalid Function App selection. Exiting."
    exit 1
}

# Check for Azure Functions Core Tools
if (-not (Get-Command "func" -ErrorAction SilentlyContinue)) {
    Write-Error "Azure Functions Core Tools ('func') is not installed or not in PATH. Please install it first."
    exit 1
}

# Optional: Login to Azure if not already logged in
try {
    az account show | Out-Null
} catch {
    Write-Host "[MCP DEPLOY] Logging in to Azure..."
    az login | Out-Null
}

# Show current Azure subscription
$sub = az account show --query "name" -o tsv
Write-Host "[MCP DEPLOY] Using Azure subscription: $sub"

# List all function folders (subfolders with function.json)
$FunctionFolders = Get-ChildItem -Path (Join-Path $AppRoot 'functions') -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'function.json') }

if ($FunctionFolders.Count -eq 0) {
    Write-Warning "[MCP DEPLOY] No function folders (with function.json) found in $AppRoot/functions."
} else {
    Write-Host "[MCP DEPLOY] The following function endpoints will be deployed:" -ForegroundColor Yellow
    foreach ($folder in $FunctionFolders) {
        Write-Host "  - $($folder.Name)"
    }
    Write-Host ""
}

# Query and report Function App status and Python version from Azure
$faInfo = az functionapp show --name $FunctionAppName --resource-group $ResourceGroup --query "{state:state, enabled:enabled, pythonVersion:siteConfig.pythonVersion, defaultHostName:defaultHostName}" -o json | ConvertFrom-Json
if ($faInfo) {
    Write-Host "  [Azure Function App Status]"
    Write-Host "    State         : $($faInfo.state)"
    Write-Host "    Enabled       : $($faInfo.enabled)"
    Write-Host "    Python Ver    : $($faInfo.pythonVersion)"
    Write-Host "    Hostname      : $($faInfo.defaultHostName)"
} else {
    Write-Host "  [Azure Function App Status] Could not retrieve status from Azure."
}

# Print a rich summary of all deployment details before confirmation
Write-Host "[MCP DEPLOY] Deployment summary:" -ForegroundColor Cyan
Write-Host "  MCP Server App     : $AppName"
Write-Host "  Config path        : $ConfigPath"
Write-Host "  Function App Name  : $FunctionAppName (deployment slot)"
Write-Host "  Resource Group     : $ResourceGroup"
Write-Host "  Location           : $Location"
Write-Host "  Subscription ID    : $SubscriptionId"
Write-Host "  Python Version     : $PythonVersion"
Write-Host "  Working Directory  : $AppRoot"
Write-Host "  Function Endpoints :"
foreach ($folder in $FunctionFolders) {
    Write-Host "    - $($folder.Name)"
}
Write-Host ""
$confirmation = Read-Host "Proceed with deployment of this MCP Server to the selected Function App slot? (y/n)"
if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
    Write-Host "[MCP DEPLOY] Deployment cancelled by user."
    exit 0
}

# Publish the function app from the app root
Write-Host "[MCP DEPLOY] Running: func azure functionapp publish $FunctionAppName --python"
Push-Location $AppRoot
func azure functionapp publish $FunctionAppName --python
Pop-Location

if ($LASTEXITCODE -eq 0) {
    Write-Host "[MCP DEPLOY] Deployment succeeded."
} else {
    Write-Error "[MCP DEPLOY] Deployment failed."
    exit 1
}
