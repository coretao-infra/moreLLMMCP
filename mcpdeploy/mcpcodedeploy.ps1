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

if (-not $AppName) {
    $AppName = Read-Host "Enter the MCP Server app name to deploy (e.g., mcp_server_helloworld)"
}

$AppRoot = Join-Path (Join-Path $PSScriptRoot '..') $AppName
if (-not (Test-Path $AppRoot)) {
    Write-Error "[MCP DEPLOY] MCP Server app '$AppName' not found at $AppRoot."
    exit 1
}

# Find config file in app root
if (-not $ConfigPath) {
    $ConfigPath = Get-ChildItem -Path $AppRoot -Filter 'mcpcodedeploy.config*.json' | Where-Object { $_.Name -notlike '*.example' } | Select-Object -First 1 | ForEach-Object { $_.FullName }
}
if (-not $ConfigPath -or -not (Test-Path $ConfigPath)) {
    Write-Error "[MCP DEPLOY] Config file not found in $AppRoot. Please copy a sample and fill it out."
    exit 1
}

$config = Get-Content $ConfigPath | ConvertFrom-Json
Write-Host "[MCP DEPLOY] Loaded config: $ConfigPath"

$FunctionAppName = $config.function_app_name
$ResourceGroup   = $config.resource_group
$Location        = $config.location
$SubscriptionId  = $config.subscription_id
$PythonVersion   = $config.python_version

Write-Host "[MCP DEPLOY] Deployment parameters:" -ForegroundColor Cyan
Write-Host "  MCP Server App     : $AppName"
Write-Host "  Function App Name  : $FunctionAppName (deployment slot)"
Write-Host "  Resource Group     : $ResourceGroup"
Write-Host "  Location           : $Location"
Write-Host "  Subscription ID    : $SubscriptionId"
Write-Host "  Python Version     : $PythonVersion"
Write-Host "  Config path        : $ConfigPath"
Write-Host "  Working Directory  : $AppRoot"
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
$FunctionFolders = Get-ChildItem -Path (Join-Path $AppRoot 'functions') -Directory | Where-Object {
    Test-Path (Join-Path $_.FullName 'function.json')
}

if ($FunctionFolders.Count -eq 0) {
    Write-Warning "[MCP DEPLOY] No function folders (with function.json) found in $AppRoot/functions."
} else {
    Write-Host "[MCP DEPLOY] The following function endpoints will be deployed:" -ForegroundColor Yellow
    foreach ($folder in $FunctionFolders) {
        Write-Host "  - $($folder.Name)"
    }
    Write-Host ""
    $funcConfirm = Read-Host "Proceed with deployment of these endpoints? (y/n)"
    if ($funcConfirm -ne 'y' -and $funcConfirm -ne 'Y') {
        Write-Host "[MCP DEPLOY] Deployment cancelled by user."
        exit 0
    }
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
