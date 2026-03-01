param(
    [ValidateRange(1, 60)]
    [int]$RefreshSeconds = 2,
    [string]$ProjectRoot = "",
    [string]$WindowTitle = "BMS Health"
)

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

Set-Location $ProjectRoot
$Host.UI.RawUI.WindowTitle = $WindowTitle

Write-Host "[$WindowTitle] started (no flicker mode)."
Write-Host "Refresh: ${RefreshSeconds}s"
Write-Host

$lastDbHealthy = $null
$lastServerUp = $null
$lastReady = $null
$heartbeatCounter = 0

while ($true) {
    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $composeLines = @(docker compose ps 2>&1)
    $composeText = ($composeLines -join [Environment]::NewLine)

    $dbLine = $composeLines | Where-Object { $_ -match "^\s*bmsdb\s" } | Select-Object -First 1
    $serverLine = $composeLines | Where-Object { $_ -match "^\s*bms_server\s" } | Select-Object -First 1

    $dbHealthy = $false
    $serverUp = $false

    if ($dbLine) { $dbHealthy = $dbLine -match "healthy" }
    if ($serverLine) { $serverUp = $serverLine -match "\bUp\b" }

    $ready = $dbHealthy -and $serverUp
    $changed = ($dbHealthy -ne $lastDbHealthy) -or ($serverUp -ne $lastServerUp) -or ($ready -ne $lastReady)

    if ($changed) {
        Write-Host "[$now] Compose status changed"
        Write-Host "--------------------------------------------------"
        Write-Host $composeText
        Write-Host
        Write-Host ("bmsdb healthy:  " + ($(if ($dbHealthy) { "YES" } else { "NO" })))
        Write-Host ("bms_server up:  " + ($(if ($serverUp) { "YES" } else { "NO" })))
        Write-Host ("overall ready:  " + ($(if ($ready) { "YES" } else { "NO" })))
        Write-Host
        $heartbeatCounter = 0
    } else {
        $heartbeatCounter++
        if ($heartbeatCounter -ge [Math]::Max([int](30 / $RefreshSeconds), 1)) {
            Write-Host "[$now] no change (bmsdb healthy=$(if($dbHealthy){'YES'}else{'NO'}), bms_server up=$(if($serverUp){'YES'}else{'NO'}))"
            $heartbeatCounter = 0
        }
    }

    $lastDbHealthy = $dbHealthy
    $lastServerUp = $serverUp
    $lastReady = $ready

    Start-Sleep -Seconds $RefreshSeconds
}
