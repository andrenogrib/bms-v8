param(
    [ValidateRange(1, 60)]
    [int]$RefreshSeconds = 2,
    [string]$ProjectRoot = "",
    [string]$WindowTitle = "BMS Players"
)

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

Set-Location $ProjectRoot
$Host.UI.RawUI.WindowTitle = $WindowTitle

$sqlOnline = @"
SET NOCOUNT ON;
SELECT COUNT(*) AS OnlineAccounts FROM UserConnection.dbo.Connections;
SELECT CON.AccountID, A.AccountName, CON.ChannelID, CON.IPStr
FROM UserConnection.dbo.Connections CON
LEFT JOIN GlobalAccount.dbo.Account A ON A.AccountID = CON.AccountID
ORDER BY CON.AccountID;
"@

$sqlChars = @"
SET NOCOUNT ON;
SELECT C.AccountID, C.CharacterName, C.WorldID
FROM GameWorld.dbo.Character C
WHERE C.AccountID IN (SELECT AccountID FROM UserConnection.dbo.Connections)
ORDER BY C.AccountID, C.CharacterID;
"@

Write-Host "[$WindowTitle] started (no flicker mode)."
Write-Host "Refresh: ${RefreshSeconds}s"
Write-Host

$lastSnapshot = ""
$heartbeatCounter = 0

while ($true) {
    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $onlineOut = docker exec bmsdb /opt/mssql-tools/bin/sqlcmd `
        -S localhost -U sa -P "Dong0#1sG00d" `
        -W -Q $sqlOnline 2>&1

    $charsOut = docker exec bmsdb /opt/mssql-tools/bin/sqlcmd `
        -S localhost -U sa -P "Dong0#1sG00d" `
        -W -Q $sqlChars 2>&1

    $snapshot = @(
        ($onlineOut -join [Environment]::NewLine)
        ""
        ($charsOut -join [Environment]::NewLine)
    ) -join [Environment]::NewLine

    if ($snapshot -ne $lastSnapshot) {
        Write-Host "[$now] players snapshot changed"
        Write-Host "--------------------------------------------------"
        Write-Host "Online accounts:"
        Write-Host ($onlineOut -join [Environment]::NewLine)
        Write-Host
        Write-Host "Characters from connected accounts:"
        Write-Host ($charsOut -join [Environment]::NewLine)
        Write-Host
        $lastSnapshot = $snapshot
        $heartbeatCounter = 0
    } else {
        $heartbeatCounter++
        if ($heartbeatCounter -ge [Math]::Max([int](30 / $RefreshSeconds), 1)) {
            Write-Host "[$now] players snapshot unchanged"
            $heartbeatCounter = 0
        }
    }

    Start-Sleep -Seconds $RefreshSeconds
}
