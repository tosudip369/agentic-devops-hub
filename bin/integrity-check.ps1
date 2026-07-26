Write-Host "🔍 Initiating System Integrity Sweep..." -ForegroundColor Cyan
$memoryDir = Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) "..\.hub_memory"
if (-not (Test-Path $memoryDir)) {
    Write-Host "✅ Memory Ledger is clean (Empty)." -ForegroundColor Green
    exit
}

$files = Get-ChildItem $memoryDir -Filter "*.txt"
$corrupted = 0
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    if ([string]::IsNullOrWhiteSpace($content) -or $content -match "`") {
        Write-Host "⚠️ Corruption detected in Memory Node: $($file.Name). Purging..." -ForegroundColor Yellow
        Remove-Item $file.FullName -Force
        $corrupted++
    }
}

if ($corrupted -eq 0) {
    Write-Host "✅ Neural Memory Ledger Integrity: 100% Verified." -ForegroundColor Green
} else {
    Write-Host "🔧 Integrity Sweep Complete. Purged $corrupted corrupted Neural Nodes." -ForegroundColor Magenta
}
