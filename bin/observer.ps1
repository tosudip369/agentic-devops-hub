param(
    [string]$WatchPath = ".",
    [switch]$Start
)

if (-not $Start) {
    Write-Host "Use -Start to begin observing"
    exit 0
}

$WatchPath = Resolve-Path $WatchPath
Write-Host "🚀 Starting Event-Driven Observer (v4.0.0) on $WatchPath..." -ForegroundColor Green

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $WatchPath
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite

$action = {
    $path = $Event.SourceEventArgs.FullPath
    $name = $Event.SourceEventArgs.Name
    $changeType = $Event.SourceEventArgs.ChangeType
    
    if ($path -match "\.git" -or $path -match "\.log") { return }

    if ($path -match "\.ps1$" -or $path -match "\.py$" -or $path -match "\.sh$" -or $path -match "\.json$") {
        Write-Host "⚡ [$changeType] Detected change in $name" -ForegroundColor Cyan
        $RemediatorScript = Join-Path $PSScriptRoot "remediator.ps1"
        & $RemediatorScript -FilePath $path
    }
}

Register-ObjectEvent $watcher "Changed" -Action $action | Out-Null

Write-Host "👀 Listening for events. Press Ctrl+C to exit." -ForegroundColor DarkGray
while ($true) { Start-Sleep -Seconds 1 }
