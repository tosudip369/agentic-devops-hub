# file-handler.ps1 - HFT-Speed Core File Management System
# Uses native .NET for zero-latency I/O bypassing PowerShell's pipeline overhead
param (
    [Parameter(Mandatory=$true)][ValidateSet("read", "write", "backup", "list")][string]$Action,
    [Parameter(Mandatory=$true)][string]$FilePath,
    [string]$Content = ""
)
switch ($Action) {
    "read" {
        if ([System.IO.File]::Exists($FilePath)) {
            [System.IO.File]::ReadAllText($FilePath)
        } else { Write-Error "Not found: $FilePath"; exit 1 }
    }
    "write" {
        $dir = [System.IO.Path]::GetDirectoryName($FilePath)
        if ($dir -and -not [System.IO.Directory]::Exists($dir)) { [System.IO.Directory]::CreateDirectory($dir) | Out-Null }
        [System.IO.File]::WriteAllText($FilePath, $Content, [System.Text.Encoding]::UTF8)
        Write-Host "⚡ HFT-Write: $FilePath" -ForegroundColor Green
    }
    "backup" {
        if ([System.IO.File]::Exists($FilePath)) {
            $backupPath = "$FilePath.20260726_074516.bak"
            [System.IO.File]::Copy($FilePath, $backupPath, $true)
            Write-Host "⚡ HFT-Backup: $backupPath" -ForegroundColor Cyan
        }
    }
    "list" {
        [System.IO.Directory]::EnumerateFiles($FilePath, "*.*", [System.IO.SearchOption]::AllDirectories)
    }
}
