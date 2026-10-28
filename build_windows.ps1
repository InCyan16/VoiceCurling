$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ToolsDir = Join-Path $ProjectRoot ".tools"
$GodotZip = Join-Path $ToolsDir "Godot_v4.6.3-stable_win64.exe.zip"
$TemplatesZip = Join-Path $ToolsDir "Godot_v4.6.3-stable_export_templates.tpz"
$GodotExe = Join-Path $ToolsDir "Godot_v4.6.3-stable_win64.exe"
$ExportName = "VoiceCurling.exe"
$ExportPath = Join-Path $ProjectRoot $ExportName

New-Item -ItemType Directory -Force -Path $ToolsDir | Out-Null

$GodotUrl = "https://github.com/godotengine/godot/releases/download/4.6.3-stable/Godot_v4.6.3-stable_win64.exe.zip"
$TemplatesUrl = "https://github.com/godotengine/godot/releases/download/4.6.3-stable/Godot_v4.6.3-stable_export_templates.tpz"

if (-not (Test-Path $GodotExe)) {
    Write-Host "Downloading Godot editor..."
    Invoke-WebRequest -Uri $GodotUrl -OutFile $GodotZip
    Expand-Archive -Path $GodotZip -DestinationPath $ToolsDir -Force
}

if (-not (Test-Path $TemplatesZip)) {
    Write-Host "Downloading export templates..."
    Invoke-WebRequest -Uri $TemplatesUrl -OutFile $TemplatesZip
}

$TemplateVersionDir = Join-Path $env:APPDATA "Godot\export_templates\4.6.3.stable"
if (-not (Test-Path (Join-Path $TemplateVersionDir "windows_release_x86_64.exe"))) {
    Write-Host "Installing export templates..."
    $TempExtract = Join-Path $env:TEMP "godot_templates_extract_463"
    $ZipCopy = Join-Path $env:TEMP "godot_templates_463.zip"
    if (Test-Path $TempExtract) { Remove-Item -Recurse -Force $TempExtract }
    New-Item -ItemType Directory -Force -Path $TempExtract | Out-Null
    Copy-Item $TemplatesZip $ZipCopy -Force
    Expand-Archive -Path $ZipCopy -DestinationPath $TempExtract -Force
    $SourceDir = Join-Path $TempExtract "templates"
    if (-not (Test-Path $SourceDir)) { $SourceDir = $TempExtract }
    New-Item -ItemType Directory -Force -Path $TemplateVersionDir | Out-Null
    Copy-Item -Path (Join-Path $SourceDir "*") -Destination $TemplateVersionDir -Recurse -Force
}

Write-Host "Exporting Windows Desktop build..."
& $GodotExe --headless --path $ProjectRoot --export-release "Windows Desktop" $ExportPath
if ($LASTEXITCODE -ne 0) {
    throw "Godot export failed with exit code $LASTEXITCODE"
}

Write-Host "Export complete: $ExportPath"
