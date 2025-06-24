# this is the mcp code deploy script to the existing Azure Function App
# Canonical MCP Code Deployment Script (PowerShell)
# Deploys Python Azure Functions code to an existing Azure Function App using Azure Functions Core Tools
# Uses a JSON config file for all deployment parameters.

$ConfigPath = Join-Path $PSScriptRoot 'mcpcodedeploy.config.json'

if (Test-Path $ConfigPath) {
    $config = Get-Content $ConfigPath | ConvertFrom-Json
    Write-Host "[MCP DEPLOY] Loaded config: $ConfigPath"
} else {
    Write-Error "[MCP DEPLOY] Config file not found. Please create mcpcodedeploy.config.json."
    exit 1
}

$FunctionAppName = $config.function_app_name
$ResourceGroup   = $config.resource_group
$Location        = $config.location
$SubscriptionId  = $config.subscription_id
$PythonVersion   = $config.python_version

Write-Host "[MCP DEPLOY] Deployment parameters:" -ForegroundColor Cyan
Write-Host "  Function App Name : $FunctionAppName"
Write-Host "  Resource Group    : $ResourceGroup"
Write-Host "  Location          : $Location"
Write-Host "  Subscription ID   : $SubscriptionId"
Write-Host "  Python Version    : $PythonVersion"
Write-Host "  Config path       : $ConfigPath"
Write-Host "  Working Directory : $(Get-Location)"
Write-Host ""

$confirmation = Read-Host "Proceed with deployment? (y/n)"
if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
    Write-Host "[MCP DEPLOY] Deployment cancelled by user."
    exit 0
}

# Check for Azure Functions Core Tools
if (-not (Get-Command "func" -ErrorAction SilentlyContinue)) {
    Write-Error "Azure Functions Core Tools ('func') is not installed or not in PATH. Please install it first."
    exit 1
}

# Optional: Login to Azure if not already logged in
if (-not (az account show 2>$null)) {
    Write-Host "[MCP DEPLOY] Logging in to Azure..."
    az login | Out-Null
}

# Show current Azure subscription
$sub = az account show --query "name" -o tsv
Write-Host "[MCP DEPLOY] Using Azure subscription: $sub"

# List all function folders (subfolders with function.json)
$FunctionFolders = Get-ChildItem -Path "$PSScriptRoot\.." -Directory | Where-Object {
    Test-Path (Join-Path $_.FullName 'function.json')
}

if ($FunctionFolders.Count -eq 0) {
    Write-Warning "[MCP DEPLOY] No function folders (with function.json) found in workspace root."
} else {
    Write-Host "[MCP DEPLOY] The following function folders will be deployed:" -ForegroundColor Yellow
    foreach ($folder in $FunctionFolders) {
        Write-Host "  - $($folder.Name)"
    }
    Write-Host ""
    $funcConfirm = Read-Host "Proceed with deployment of these functions? (y/n)"
    if ($funcConfirm -ne 'y' -and $funcConfirm -ne 'Y') {
        Write-Host "[MCP DEPLOY] Deployment cancelled by user."
        exit 0
    }
}

# Publish the function app
Write-Host "[MCP DEPLOY] Running: func azure functionapp publish $FunctionAppName --python"
func azure functionapp publish $FunctionAppName --python

if ($LASTEXITCODE -eq 0) {
    Write-Host "[MCP DEPLOY] Deployment succeeded."
} else {
    Write-Error "[MCP DEPLOY] Deployment failed."
    exit 1
}
