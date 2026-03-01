param(
    [string]$ProjectRoot = "",
    [string]$WindowTitle = "BMS Debug"
)

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

Set-Location $ProjectRoot
$Host.UI.RawUI.WindowTitle = $WindowTitle

Write-Host "[$WindowTitle] Streaming docker logs from bms_server..."
Write-Host "Press Ctrl+C to stop this window."
Write-Host

while ($true) {
    docker logs -f --since 5m bms_server
    Write-Host
    Write-Host "[watch-debug] Log stream ended, retrying in 2 seconds..."
    Start-Sleep -Seconds 2
}
