# PowerShell script to deploy Azure infrastructure using Terraform
# Supports stepwise execution: init, plan, apply, destroy, import
# Usage: .\deploy.ps1 [init|plan|apply|destroy|import]

param(
    [Parameter(Position=0, Mandatory=$false)]
    [string]$Step = ""
)

$ErrorActionPreference = 'Stop'

# --- CANONICAL VALID STEPS ---
$validSteps = @('init', 'plan', 'apply', 'destroy', 'import')

function Get-LogFileName {
    param(
        [string]$step,
        [string]$time
    )
    $canonicalStep = if ($validSteps -contains $step) { $step } else { 'other' }
    return "terraform-deploy-$canonicalStep-$time.log"
}

# --- RUNTIME VALIDATION ---
if ($Step -and -not ($validSteps -contains $Step)) {
    Write-Error "Invalid step: $Step. Valid steps are: $($validSteps -join ', ')"
    exit 1
}

# --- CONFIGURATION ---
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$stepName = if ($validSteps -contains $Step) { $Step } else { 'other' }
$terraformExe = Join-Path $PSScriptRoot 'bin/terraform.exe'
$templateDir = Join-Path $PSScriptRoot 'templates'
$deploymentsDir = Join-Path $PSScriptRoot 'deployments'
$logsDir = Join-Path $PSScriptRoot 'logs'
$logFile = Join-Path $logsDir (Get-LogFileName $stepName $timestamp)
$planFile = Join-Path $deploymentsDir 'plan.tfplan'

# Ensure required directories exist
foreach ($dir in @($deploymentsDir, $logsDir)) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
}

Write-Host "\n=== TERRAFORM DEPLOYMENT SCRIPT STARTED ==="
Write-Host "Terraform executable: $terraformExe"
Write-Host "Template directory: $templateDir"
Write-Host "Deployments directory: $deploymentsDir"
Write-Host "Logs directory: $logsDir"
Write-Host "Log file: $logFile"
Write-Host "===============================\n"

# Step 1: Check for terraform.exe
if (-not (Test-Path $terraformExe)) {
    Write-Error "terraform.exe not found at $terraformExe. Please ensure it is present."
    exit 1
}

# Set Terraform logging environment variables
$env:TF_LOG = "INFO"  # Change to "DEBUG" for more detail
$env:TF_LOG_PATH = $logFile

switch ($Step) {
    "init" {
        # Step 2: Initialize Terraform in templates directory with state in deployments
        Write-Host "Initializing Terraform..."
        & $terraformExe "-chdir=$templateDir" init -backend-config="path=$deploymentsDir/terraform.tfstate" -reconfigure
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Terraform init failed. See $logFile for details."
            exit 1
        }
        Write-Host "Terraform init complete."
    }
    "plan" {
        # Step 3: Plan Terraform deployment
        Write-Host "Planning Terraform deployment..."
        & $terraformExe "-chdir=$templateDir" plan "-out=$planFile"
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Terraform plan failed. See $logFile for details."
            exit 1
        }
        Write-Host "Terraform plan complete. Plan file: $planFile"
    }
    "apply" {
        # Step 4: Apply Terraform deployment
        Write-Host "Applying Terraform deployment..."
        & $terraformExe "-chdir=$templateDir" apply $planFile
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Terraform apply failed. See $logFile for details."
            exit 1
        }
        Write-Host "Terraform apply complete."
    }
    "destroy" {
        # Step 5: Destroy Terraform-managed infrastructure
        Write-Host "Destroying Terraform-managed infrastructure..."
        & $terraformExe "-chdir=$templateDir" destroy
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Terraform destroy failed. See $logFile for details."
            exit 1
        }
        Write-Host "Terraform destroy complete."
    }
    "import" {
        # Step 6: Import existing resources based on the latest canonical apply log file
        Write-Host "Searching for latest canonical apply log for importable resources..."
        $applyLogs = Get-ChildItem -Path $logsDir -Filter (Get-LogFileName 'apply' '*') | Sort-Object LastWriteTime -Descending
        $lastApplyLog = $applyLogs | Select-Object -First 1
        if (-not $lastApplyLog) {
            Write-Error "No canonical apply log files found in $logsDir."
            exit 1
        }
        $logContent = Get-Content $lastApplyLog.FullName -Raw
        $importMatches = [regex]::Matches($logContent, 'A resource with the ID "([^"]+)" already exists - to be managed via Terraform this resource needs to be imported into the State. Please see the resource documentation for "([^"]+)" for more information.')
        if ($importMatches.Count -eq 0) {
            Write-Host "No importable resources found in the last canonical apply log."
            exit 0
        }
        foreach ($match in $importMatches) {
            $resourceId = $match.Groups[1].Value
            $resourceType = $match.Groups[2].Value
            # Map resource type to Terraform address (only supporting resource_group for now)
            switch ($resourceType) {
                "azurerm_resource_group" {
                    $tfAddress = "azurerm_resource_group.main"
                }
                default {
                    Write-Host "Resource type $resourceType not supported for auto-import. Skipping."
                    continue
                }
            }
            Write-Host "Importing $tfAddress from $resourceId..."
            & $terraformExe "-chdir=$templateDir" import $tfAddress $resourceId
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Terraform import failed for $tfAddress. See $logFile for details."
                exit 1
            }
        }
        Write-Host "Import(s) complete."
    }
    default {
        Write-Host "Usage: .\deploy.ps1 [init|plan|apply|destroy]"
        Write-Host "Example: .\deploy.ps1 plan"
    }
}

Write-Host "\n=== TERRAFORM SCRIPT FINISHED ===\n"