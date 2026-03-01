param(
    [ValidateRange(1, 60)]
    [int]$RefreshSeconds = 2,
    [string]$ProjectRoot = "",
    [string]$WindowTitle = "BMS Dashboard"
)

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

Set-Location $ProjectRoot
$Host.UI.RawUI.WindowTitle = $WindowTitle

function Get-LatestLogFile {
    param([string]$Pattern)
    Get-ChildItem $Pattern -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

$sqlOnline = @"
SET NOCOUNT ON;
SELECT COUNT(*) AS OnlineAccounts FROM UserConnection.dbo.Connections;
SELECT CON.AccountID, A.AccountName, CON.ChannelID, CON.IPStr
FROM UserConnection.dbo.Connections CON
LEFT JOIN GlobalAccount.dbo.Account A ON A.AccountID = CON.AccountID
ORDER BY CON.AccountID;
"@

Write-Host "[$WindowTitle] started (no flicker mode)."
Write-Host "Refresh: ${RefreshSeconds}s"
Write-Host

while ($true) {
    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "=================================================="
    Write-Host "[$WindowTitle] $now"
    Write-Host

    $composeLines = @(docker compose ps 2>&1)
    Write-Host "== Docker compose ps =="
    Write-Host ($composeLines -join [Environment]::NewLine)
    Write-Host

    $loginLog = Get-LatestLogFile ".\temp\MSLog\Login_*.log"
    $centerLog = Get-LatestLogFile ".\temp\MSLog\CenterOrion_*.log"

    $loginConnected = $false
    $centerLoginConnected = $false
    $centerShopConnected = $false
    $allServicesInPing = $false
    $serverPingLine = ""

    if ($loginLog) {
        $loginTail = Get-Content $loginLog.FullName -Tail 200 -ErrorAction SilentlyContinue
        $loginConnected = $loginTail -match "Center socket connected successfully"
    }
    if ($centerLog) {
        $centerTail = Get-Content $centerLog.FullName -Tail 400 -ErrorAction SilentlyContinue
        $centerLoginConnected = $centerTail -match "Local server connected successfully Login"
        $centerShopConnected = $centerTail -match "Local server connected successfully Shop0Orion"
        $serverPingLine = ($centerTail | Where-Object { $_ -match "ServerPing:" } | Select-Object -Last 1)

        if ($serverPingLine) {
            $required = @("Login", "Game0Orion", "Game1Orion", "Game2Orion", "Game3Orion", "Game4Orion", "Shop0Orion")
            $allServicesInPing = $true
            foreach ($name in $required) {
                if ($serverPingLine -notmatch [regex]::Escape($name)) {
                    $allServicesInPing = $false
                    break
                }
            }
        }
    }

    Write-Host "== Login/Center readiness =="
    Write-Host ("Login -> Center connected: " + ($(if ($loginConnected) { "YES" } else { "NO" })))
    Write-Host ("Center sees Login:        " + ($(if ($centerLoginConnected) { "YES" } else { "NO" })))
    Write-Host ("Center sees Shop:         " + ($(if ($centerShopConnected) { "YES" } else { "NO" })))
    Write-Host ("ServerPing complete:      " + ($(if ($allServicesInPing) { "YES" } else { "NO" })))
    if ($serverPingLine) {
        Write-Host $serverPingLine
    }
    Write-Host

    Write-Host "== Online players =="
    docker exec bmsdb /opt/mssql-tools/bin/sqlcmd `
        -S localhost -U sa -P "Dong0#1sG00d" `
        -W -Q $sqlOnline 2>&1
    Write-Host

    Write-Host "== Debug tail (bms_server, 20 lines) =="
    docker logs --tail 20 bms_server 2>&1

    Start-Sleep -Seconds $RefreshSeconds
}
