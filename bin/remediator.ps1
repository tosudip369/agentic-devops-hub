param([Parameter(Mandatory=$true)][string]$FilePath)
$ext = [System.IO.Path]::GetExtension($FilePath)
$errorMsg = ""
$failed = $false

switch ($ext) {
    ".ps1" {
        $err = $null
        [System.Management.Automation.PSParser]::Tokenize((Get-Content $FilePath -Raw), [ref]$err)
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
    
    # === 1. ASYNCHRONOUS HUMAN-IN-THE-LOOP (HITL) CONTROL ===
    if ($ext -match "\.sql|\.tf|\.json|\.yml|\.yaml|\.ps1|\.py") {
        Write-Host "⚠️ CRITICAL FILE MUTATION DETECTED." -ForegroundColor Yellow
        $ans = Read-Host "Captain, structural mutation requested on $FilePath. Proceed? (Y/N)"
        if ($ans -notmatch "^Y") { 
            Write-Host "Abort. Operation cancelled by Captain." -ForegroundColor Red
            exit 
        }
    }

    # === 2. LONG-TERM VECTOR MEMORY (TRUE O(1) FILE LEDGER) ===
    # Using SHA256 instead of GetHashCode() for stable cross-process memory retrieval
    $hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($errorMsg))
    $sig = [System.BitConverter]::ToString($hashBytes) -replace '-'
    $memoryDir = Join-Path (Split-Path (Split-Path $MyInvocation.MyCommand.Path)) ".hub_memory"
    if (-not (Test-Path $memoryDir)) { New-Item -ItemType Directory -Path $memoryDir -Force | Out-Null }
    
    $memoryFile = Join-Path $memoryDir "$sig.txt"
    if (Test-Path $memoryFile) {
        Write-Host "🧠 [Memory Ledger] Retrieved past solution! O(1) instant fix applied." -ForegroundColor Magenta
        Set-Content $FilePath -Value (Get-Content $memoryFile -Raw) -Encoding UTF8
        exit
    }

    Write-Host "🐝 INITIATING V8 AGENT SWARM ORCHESTRATION..." -ForegroundColor Magenta

    # === 3. TEST-DRIVEN DEVELOPMENT (TDD) ENGINEER ===
    Write-Host "   -> 🧪 Dispatching Test Engineer..." -ForegroundColor Blue
    $testPrompt = "[ROLE: TESTER] Write a PowerShell test to verify the fix for $errorMsg in $FilePath. OUTPUT RAW CODE ONLY."
    $testFix = agy.exe --print $testPrompt --dangerously-skip-permissions
    $testFix = $testFix -replace '`\w*\r?\n', '' -replace '`', ''
    $testPath = "$FilePath.tests.ps1"
    Set-Content $testPath -Value $testFix -Encoding UTF8
    Write-Host "   -> 🧪 Test suite auto-generated at $testPath" -ForegroundColor Blue

    # === 4. THE SURGEON (DEVELOPER) ===
    Write-Host "   -> 🤖 Dispatching Surgeon Agent..." -ForegroundColor Cyan
    $devPrompt = "[ROLE: SURGEON] The file $FilePath crashed with: $errorMsg. Write the exact replacement code to fix this. OUTPUT ONLY RAW CODE."
    $devFix = agy.exe --print $devPrompt --dangerously-skip-permissions

    # === 5. THE GATEKEEPER (ADVERSARIAL REVIEW) ===
    Write-Host "   -> 🛡️ Dispatching Gatekeeper Agent..." -ForegroundColor Yellow
    $reviewPrompt = "[ROLE: GATEKEEPER] Review this proposed fix for $FilePath:

$devFix

Analyze for O(1) performance and security. If flawless, output 'APPROVED'. If flawed, output CORRECTED RAW CODE."
    $finalFix = agy.exe --print $reviewPrompt --dangerously-skip-permissions

    if ($finalFix.Trim() -match "APPROVED") {
        $finalCode = $devFix
    } else {
        $finalCode = $finalFix
    }

    # Strip markdown wrappers injected by LLM
    $finalCode = $finalCode -replace '`\w*\r?\n', '' -replace '`', ''

    # === 6. UPDATE NEURAL MEMORY LEDGER ===
    Set-Content $memoryFile -Value $finalCode -Encoding UTF8

    Write-Host "   ✅ Consensus Reached & Memory Updated. Applying..." -ForegroundColor Green
    Set-Content $FilePath -Value $finalCode -Encoding UTF8
}
