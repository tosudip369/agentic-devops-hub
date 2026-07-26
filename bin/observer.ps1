param([string]$WatchPath = ".", [switch]$Start)
if (-not $Start) { exit 0 }

$WatchPath = Resolve-Path $WatchPath
Write-Host "🏎️ Starting HFT-Speed Observer (v5.0.0) on $WatchPath" -ForegroundColor Green

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $WatchPath
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite

# Thread-safe dictionary for debouncing rapid saves
$global:LastEventTime = [System.Collections.Concurrent.ConcurrentDictionary[string, DateTime]]::new()

$action = {
    $path = $Event.SourceEventArgs.FullPath
    if ($path -match "\.git|error_ledger|\.log") { return }
    if ($path -match "\.(ps1|py|sh|json)$") {
        $now = [DateTime]::UtcNow
        $lastTime = $global:LastEventTime.GetOrAdd($path, [DateTime]::MinValue)
        if (($now - $lastTime).TotalMilliseconds -lt 500) { return } # Debounce 500ms
        $global:LastEventTime[$path] = $now

        Write-Host "⚡ File Trigger: $path" -ForegroundColor Cyan
        
        # Dispatch to background Runspace (HFT style, non-blocking)
        $ps = [PowerShell]::Create().AddScript({
            param($p, $script)
            & $script -FilePath $p
        }).AddArgument($path).AddArgument((Join-Path $PSScriptRoot "remediator.ps1"))
        $ps.BeginInvoke() | Out-Null
    }
}
Register-ObjectEvent $watcher "Changed" -Action $action | Out-Null

while ($true) { Start-Sleep -Milliseconds 100 }
