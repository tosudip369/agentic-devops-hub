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
    Write-Host "❌ Error detected in $FilePath" -ForegroundColor Red
    Write-Host "🐝 INITIATING AGENT SWARM ORCHESTRATION..." -ForegroundColor Magenta

    # AGENT 1: The Surgeon (Developer)
    Write-Host "   -> 🤖 Dispatching Surgeon Agent for primary fix..." -ForegroundColor Cyan
    $devPrompt = "[ROLE: SURGEON] The file $FilePath crashed with: $errorMsg. Write the exact replacement code to fix this. OUTPUT ONLY RAW CODE. No markdown fences. No explanations. Follow the 5-Step Algorithm."
    $devFix = agy.exe --print $devPrompt --dangerously-skip-permissions

    # AGENT 2: The Gatekeeper (Reviewer/Security)
    Write-Host "   -> 🛡️ Dispatching Gatekeeper Agent for adversarial review..." -ForegroundColor Yellow
    $reviewPrompt = "[ROLE: GATEKEEPER] Review this proposed fix for $FilePath:

$devFix

Analyze for O(1) performance, security leaks, and clearcode metrics. If it is flawless, output the exact word 'APPROVED'. If it is flawed, output the CORRECTED RAW CODE only."
    $finalFix = agy.exe --print $reviewPrompt --dangerously-skip-permissions

    if ($finalFix.Trim() -eq "APPROVED") {
        Write-Host "   ✅ Consensus Reached: Gatekeeper approved Surgeon's fix." -ForegroundColor Green
        Set-Content $FilePath -Value $devFix -Encoding UTF8
    } else {
        Write-Host "   ⚠️ Consensus Reached: Gatekeeper intervened and applied structural optimizations." -ForegroundColor Green
        Set-Content $FilePath -Value $finalFix -Encoding UTF8
    }
    Write-Host "🚀 Swarm Remediation Complete." -ForegroundColor Green
}
