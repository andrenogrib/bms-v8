param(
    [ValidateRange(1, 60)]
    [int]$RefreshSeconds = 2,
    [string]$ProjectRoot = "",
    [string]$WindowTitle = "BMS Login+Center"
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

function Write-NewLogLines {
    param(
        [hashtable]$State,
        [string]$Pattern,
        [string]$Prefix,
        [string]$Now
    )

    $latest = Get-LatestLogFile $Pattern
    if (-not $latest) {
        if (-not $State.NotFoundPrinted) {
            Write-Host "[$Now] [$Prefix] log not found yet"
            $State.NotFoundPrinted = $true
        }
        return
    }

    if ($State.Path -ne $latest.FullName) {
        $State.Path = $latest.FullName
        $State.NotFoundPrinted = $false
        $all = @(Get-Content $State.Path -ErrorAction SilentlyContinue)
        $State.LastLine = $all.Count
        Write-Host "[$Now] [$Prefix] attached to $($latest.Name) at EOF ($($State.LastLine) lines)"
        return
    }

    $lines = @(Get-Content $State.Path -ErrorAction SilentlyContinue)
    $total = $lines.Count
    if ($total -le $State.LastLine) {
        return
    }

    $newLines = $lines | Select-Object -Skip $State.LastLine
    foreach ($line in $newLines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        Write-Host "[$Prefix] $line"
    }
    $State.LastLine = $total
}

Write-Host "[$WindowTitle] started (stream mode, no flicker)."
Write-Host "Refresh: ${RefreshSeconds}s"
Write-Host

$loginState = @{
    Path = ""
    LastLine = 0
    NotFoundPrinted = $false
}
$centerState = @{
    Path = ""
    LastLine = 0
    NotFoundPrinted = $false
}

$lastReadyState = ""
$heartbeatCounter = 0

while ($true) {
    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-NewLogLines -State $loginState -Pattern ".\temp\MSLog\Login_*.log" -Prefix "LOGIN" -Now $now
    Write-NewLogLines -State $centerState -Pattern ".\temp\MSLog\CenterOrion_*.log" -Prefix "CENTER" -Now $now

    $loginConnected = $false
    $centerLoginConnected = $false
    $centerShopConnected = $false
    $serverPingLine = ""
    $allServicesInPing = $false

    if ($loginState.Path) {
        $loginTail = Get-Content $loginState.Path -Tail 200 -ErrorAction SilentlyContinue
        $loginConnected = $loginTail -match "Center socket connected successfully"
    }

    if ($centerState.Path) {
        $centerTail = Get-Content $centerState.Path -Tail 400 -ErrorAction SilentlyContinue
        $centerLoginConnected = $centerTail -match "Local server connected successfully Login"
        $centerShopConnected = $centerTail -match "Local server connected successfully Shop0Orion"
        $serverPingLine = ($centerTail | Where-Object { $_ -match "ServerPing:" } | Select-Object -Last 1)

        if ($serverPingLine) {
            $required = @(
                "Login",
                "Game0Orion",
                "Game1Orion",
                "Game2Orion",
                "Game3Orion",
                "Game4Orion",
                "Shop0Orion"
            )
            $allServicesInPing = $true
            foreach ($name in $required) {
                if ($serverPingLine -notmatch [regex]::Escape($name)) {
                    $allServicesInPing = $false
                    break
                }
            }
        }
    }

    $ready = $loginConnected -and $centerLoginConnected -and $centerShopConnected -and $allServicesInPing
    $stateLine = "Login->Center=$(if ($loginConnected) { 'YES' } else { 'NO' }) | Center(Login)=$(if ($centerLoginConnected) { 'YES' } else { 'NO' }) | Center(Shop)=$(if ($centerShopConnected) { 'YES' } else { 'NO' }) | ServerPingFull=$(if ($allServicesInPing) { 'YES' } else { 'NO' }) | READY=$(if ($ready) { 'YES' } else { 'NO' })"

    if ($stateLine -ne $lastReadyState) {
        Write-Host "[$now] [STATUS] $stateLine"
        if ($serverPingLine) {
            Write-Host "[$now] [STATUS] Last ServerPing: $serverPingLine"
        }
        Write-Host
        $lastReadyState = $stateLine
        $heartbeatCounter = 0
    } else {
        $heartbeatCounter++
        if ($heartbeatCounter -ge [Math]::Max([int](30 / $RefreshSeconds), 1)) {
            Write-Host "[$now] [STATUS] unchanged"
            $heartbeatCounter = 0
        }
    }

    Start-Sleep -Seconds $RefreshSeconds
}
