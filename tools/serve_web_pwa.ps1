param(
    [int]$Port = 8060,
    [string]$PythonPath = "C:\Users\klehv\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$webRoot = Join-Path $projectRoot "web"
$entryPoint = Join-Path $webRoot "index.html"

if (-not (Test-Path -LiteralPath $PythonPath)) {
    throw "Python executable not found: $PythonPath"
}

if (-not (Test-Path -LiteralPath $entryPoint)) {
    throw "Web build not found. Run tools\export_web_pwa.ps1 first."
}

Write-Output "Serving Nyanris at http://127.0.0.1:$Port/index.html"
Write-Output "Press Ctrl+C to stop the server."
& $PythonPath -m http.server $Port --bind 127.0.0.1 --directory $webRoot
