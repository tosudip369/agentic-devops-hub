param([Parameter(Mandatory=$true)][string]$FilePath)
$ext = [System.IO.Path]::GetExtension($FilePath)
$errorMsg = ""
$failed = $false

switch ($ext) {
    ".ps1" {
        $err = $null
        [management.automation.psparser]::Tokenize((Get-Content $FilePath -Raw), [ref]$err)
        if ($err) { $failed = $true; $errorMsg = $err[0].Message }
    }
    ".py" {
        $result = python -m py_compile $FilePath 2>&1
        if ($LASTEXITCODE -ne 0) { $failed = $true; $errorMsg = "$result" }
    }
    ".json" {
        try { Get-Content $FilePath -Raw | ConvertFrom-Json | Out-Null } catch { $failed = $true; $errorMsg = $_.Exception.Message }
    }
}

if ($failed) {
    Write-Host "❌ Validation failed on $FilePath" -ForegroundColor Red
    Write-Host "   $errorMsg" -ForegroundColor DarkGray
    Write-Host "🔨 Auto-dispatching AI remediation..." -ForegroundColor Magenta

    $prompt = "[STRICT DIRECTIVE: EVENT-DRIVEN FIX] Fix the error in $FilePath: $errorMsg. Do not break existing functionality."
    if (Get-Command "agy.exe" -ErrorAction SilentlyContinue) {
        agy.exe --print $prompt --dangerously-skip-permissions
    } else {
        Write-Host "⚠️ No agent available for immediate remediation." -ForegroundColor Yellow
    }
}
