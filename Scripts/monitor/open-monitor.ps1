param(
    [switch]$StartServer,
    [switch]$SingleWindow,
    [ValidateRange(1, 60)]
    [int]$RefreshSeconds = 2
)

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $repoRoot

if ($StartServer) {
    Write-Host "[open-monitor] Starting containers..."
    docker compose up -d
}

$windows = @(
    @{ Title = "BMS Health"; Script = "watch-health.ps1" },
    @{ Title = "BMS Login+Center"; Script = "watch-login-center.ps1" },
    @{ Title = "BMS Players"; Script = "watch-players.ps1" },
    @{ Title = "BMS Debug"; Script = "watch-debug.ps1" }
)

if ($SingleWindow) {
    & (Join-Path $PSScriptRoot "watch-dashboard.ps1") `
        -ProjectRoot $repoRoot `
        -RefreshSeconds $RefreshSeconds `
        -WindowTitle "BMS Dashboard"
    exit $LASTEXITCODE
}

foreach ($window in $windows) {
    $scriptPath = (Join-Path $PSScriptRoot $window.Script).Replace("'", "''")
    $safeRoot = $repoRoot.Replace("'", "''")
    $safeTitle = $window.Title.Replace("'", "''")
    $cmd = "Set-Location '$safeRoot'; & '$scriptPath' -ProjectRoot '$safeRoot' -WindowTitle '$safeTitle'"
    if ($window.Script -ne "watch-debug.ps1") {
        $cmd += " -RefreshSeconds $RefreshSeconds"
    }

    Start-Process powershell `
        -ArgumentList @("-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $cmd) `
        | Out-Null
    Start-Sleep -Milliseconds 300
}

Write-Host "[open-monitor] Opened 4 monitor windows."
Write-Host "[open-monitor] Repo root: $repoRoot"
