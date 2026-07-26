# file-handler.ps1 - Core File Management System for Agentic DevOps Hub
# Provides safe reading, writing, and backup of project files for autonomous agents

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("read", "write", "backup", "list")]
    [string]$Action,

    [Parameter(Mandatory=$true)]
    [string]$FilePath,

    [string]$Content = ""
)

# Function to safely ensure directory exists
function Ensure-Directory {
    param([string]$Path)
    $dir = Split-Path $Path -Parent
    if (-not [string]::IsNullOrEmpty($dir) -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
}

switch ($Action) {
    "read" {
        if (Test-Path $FilePath) {
            Get-Content $FilePath -Raw
        } else {
            Write-Error "File not found: $FilePath"
            exit 1
        }
    }
    
    "write" {
        Ensure-Directory $FilePath
        Set-Content -Path $FilePath -Value $Content -Encoding UTF8
        Write-Host "✅ Successfully wrote to $FilePath" -ForegroundColor Green
    }
    
    "backup" {
        if (Test-Path $FilePath) {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $backupPath = "$FilePath.$timestamp.bak"
            Copy-Item $FilePath $backupPath -Force
            Write-Host "✅ Backup created at $backupPath" -ForegroundColor Cyan
        } else {
            Write-Host "⚠️ File does not exist, nothing to backup: $FilePath" -ForegroundColor Yellow
        }
    }
    
    "list" {
        if (Test-Path $FilePath) {
            Get-ChildItem -Path $FilePath -Recurse | Select-Object FullName, Length | Format-Table -AutoSize
        } else {
            Write-Error "Directory not found: $FilePath"
            exit 1
        }
    }
}
