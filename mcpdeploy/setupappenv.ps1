# this script will query the apps/ folder for the mcp app mapping file and offer a choice to create a venv for the selected app

# setupappenv.ps1
# Interactive script to create a Python virtual environment for a selected MCP app

# Step 1: Read mapping file and offer app choice
$MappingPath = Join-Path (Join-Path $PSScriptRoot '..') 'apps/deployment.map.json'
if (-not (Test-Path $MappingPath)) {
    Write-Error "Mapping file 'apps/deployment.map.json' not found."
    exit 1
}
$mapping = Get-Content $MappingPath | ConvertFrom-Json
$availableApps = $mapping.PSObject.Properties.Name
Write-Host "Available MCP Server apps:" -ForegroundColor Cyan
for ($i = 0; $i -lt $availableApps.Count; $i++) {
    Write-Host ("  [{0}] {1}" -f ($i+1), $availableApps[$i])
}
$choice = Read-Host "Enter the number of the MCP Server app to set up the environment for"
if ($choice -match '^[0-9]+$' -and $choice -ge 1 -and $choice -le $availableApps.Count) {
    $AppName = $availableApps[$choice - 1]
} else {
    Write-Error "Invalid selection. Exiting."
    exit 1
}
$AppRoot = Join-Path (Join-Path $PSScriptRoot '..') "apps/$AppName"

# Step 2: Get python version from app config (required)
$ConfigPath = Get-ChildItem -Path $AppRoot -Filter 'mcpcodedeploy.config*.json' | Where-Object { $_.Name -notlike '*.example' } | Select-Object -First 1 | ForEach-Object { $_.FullName }
if (-not $ConfigPath -or -not (Test-Path $ConfigPath)) {
    Write-Error "No deployment config file found in $AppRoot."
    exit 1
}
$config = Get-Content $ConfigPath | ConvertFrom-Json
if (-not $config.python_version) {
    Write-Error "No python_version specified in $ConfigPath. Please add it to your config file."
    exit 1
}
$PythonVersion = $config.python_version

# Step 3: Detect installed Python executables
$pythonDirs = @('C:\Program Files\Python*', "C:\Users\$env:USERNAME\AppData\Local\Programs\Python*")
$pythonExes = @()
foreach ($dirGlob in $pythonDirs) {
    $dirs = Get-ChildItem $dirGlob -Directory -ErrorAction SilentlyContinue
    foreach ($d in $dirs) {
        $exe = Join-Path $d.FullName 'python.exe'
        if (Test-Path $exe) {
            $ver = & $exe --version 2>&1
            $pythonExes += [PSCustomObject]@{Path=$exe; Version=$ver}
        }
    }
}
if ($pythonExes.Count -eq 0) {
    Write-Error "No Python executables found in common install locations. Please install the required version."
    exit 1
}
Write-Host "Available Python executables on this system:" -ForegroundColor Cyan
for ($i = 0; $i -lt $pythonExes.Count; $i++) {
    Write-Host ("  [{0}] {1} ({2})" -f ($i+1), $pythonExes[$i].Version, $pythonExes[$i].Path)
}
# Try to match the config version
$defaultIdx = ($pythonExes | ForEach-Object { if ($_.Version -match $PythonVersion) { $pythonExes.IndexOf($_) } }) | Select-Object -First 1
if ($null -eq $defaultIdx -or $defaultIdx -lt 0) { $defaultIdx = 0 }
$pyChoice = Read-Host "Enter the number of the Python executable to use (default: $($defaultIdx+1))"
if ([string]::IsNullOrWhiteSpace($pyChoice)) { $pyChoice = $defaultIdx+1 }
if ($pyChoice -match '^[0-9]+$' -and $pyChoice -ge 1 -and $pyChoice -le $pythonExes.Count) {
    $pyExe = $pythonExes[$pyChoice-1].Path
} else {
    Write-Error "Invalid Python selection. Exiting."
    exit 1
}

# Step 4: Create venv
$venvPath = Join-Path $AppRoot ".venv"
Write-Host "Creating virtual environment in $venvPath using $pyExe..."
& $pyExe -m venv $venvPath
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to create virtual environment. Check that $pyExe exists and is the correct version."
    exit 1
}

# Step 5: Install requirements
$reqPath = Join-Path $AppRoot "requirements.txt"
if (Test-Path $reqPath) {
    Write-Host "Installing dependencies from requirements.txt..."
    & "$venvPath\Scripts\pip.exe" install -r $reqPath
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Virtual environment and dependencies are ready for $AppName."
        Write-Host "To activate:"
        Write-Host "  .\apps\$AppName\.venv\Scripts\Activate.ps1"
    } else {
        Write-Error "Failed to install dependencies."
    }
} else {
    Write-Warning "No requirements.txt found in $AppRoot. Venv created, but no dependencies installed."
}
