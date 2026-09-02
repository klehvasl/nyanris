param(
    [string]$GodotPath = "C:\Users\klehv\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$outputDirectory = Join-Path $projectRoot "web-six"
$outputFile = Join-Path $outputDirectory "index.html"

if (-not (Test-Path -LiteralPath $GodotPath)) {
    throw "Godot executable not found: $GodotPath"
}

New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

& $GodotPath --headless --path $projectRoot --export-release "Web PWA" $outputFile
if ($LASTEXITCODE -ne 0) {
    throw "Godot Web PWA export failed with exit code $LASTEXITCODE."
}

Write-Output "Nyanris Six PWA exported to: $outputDirectory"
