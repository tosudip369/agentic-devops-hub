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
    ".js" {
        $result = node --check $FilePath 2>&1
        if ($LASTEXITCODE -ne 0) { $failed = $true; $errorMsg = "$result" }
    }
    ".ts" {
        $result = npx tsc --noEmit $FilePath 2>&1
        if ($LASTEXITCODE -ne 0) { $failed = $true; $errorMsg = "$result" }
    }
    ".go" {
        $result = go build -o $null $FilePath 2>&1
        if ($LASTEXITCODE -ne 0) { $failed = $true; $errorMsg = "$result" }
    }
    ".json" {
        try { Get-Content $FilePath -Raw | ConvertFrom-Json | Out-Null } catch { $failed = $true; $errorMsg = $_.Exception.Message }
    }
}

if ($failed) {
    Write-Host "❌ Error detected in $FilePath" -ForegroundColor Red
    
    # === 1. ASYNCHRONOUS HUMAN-IN-THE-LOOP (HITL) CONTROL ===
    if ($ext -match "\.sql|\.tf|\.json|\.yml|\.yaml|\.ps1|\.py|\.js|\.ts|\.go") {
        Write-Host "⚠️ CRITICAL FILE MUTATION DETECTED." -ForegroundColor Yellow
        $ans = Read-Host "Captain, structural mutation requested on $FilePath. Proceed? (Y/N)"
        if ($ans -notmatch "^Y") { 
            Write-Host "Abort. Operation cancelled by Captain." -ForegroundColor Red
            exit 
        }
    }

    # === 2. NEURAL PATTERN MEMORY (FUZZY SEMANTIC HASHING) ===
    # Strip line numbers, file paths, and hex addresses to create a stable semantic signature
    $semanticError = $errorMsg -replace '\b\d+\b', '' -replace '0x[a-fA-F0-9]+', '' -replace '([a-zA-Z]:\\[^\s]+)', ''
    $hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($semanticError))
    $sig = [System.BitConverter]::ToString($hashBytes) -replace '-'
    $memoryDir = Join-Path (Split-Path (Split-Path $MyInvocation.MyCommand.Path)) ".hub_memory"
    if (-not (Test-Path $memoryDir)) { New-Item -ItemType Directory -Path $memoryDir -Force | Out-Null }
    
    $memoryFile = Join-Path $memoryDir "$sig.txt"
    if (Test-Path $memoryFile) {
        Write-Host "🧠 [Memory Ledger] Retrieved past solution! O(1) instant fix applied." -ForegroundColor Magenta
        Set-Content $FilePath -Value (Get-Content $memoryFile -Raw) -Encoding UTF8
        exit
    }

    Write-Host "☠️ INITIATING PATH OF EXILE MINION SWARM (V12 UNIVERSAL EXECUTION LOOP)..." -ForegroundColor Magenta

    # === 3. SUMMON GOLEM (TDD ENGINEER) ===
    Write-Host "   -> 🪨 Summoning Golem (Test Engineer) for structural buffs..." -ForegroundColor Blue
    $testPrompt = "[ROLE: GOLEM] You are a TDD Golem. Write a PowerShell test to verify the fix for $errorMsg in $FilePath. OUTPUT RAW CODE ONLY. You operate under the 5-Step Algorithm."
    $testFix = agy.exe --print $testPrompt --dangerously-skip-permissions
    $testFix = $testFix -replace '(?s)^```\w*\n(.*)```$', '$1'
    $testPath = "$FilePath.tests.ps1"
    Set-Content $testPath -Value $testFix -Encoding UTF8
    Write-Host "   -> 🪨 Golem has fortified the build with a test suite at $testPath" -ForegroundColor Blue

    # === 4. THE EXECUTION LOOP (SKELETON AUTONOMY) ===
    $maxRetries = 3
    $loopCount = 0
    $testPassed = $false
    $devFix = ""
    $testError = ""
    $originalContent = Get-Content $FilePath -Raw

    while ($loopCount -lt $maxRetries -and -not $testPassed) {
        $loopCount++
        Write-Host "   -> 💀 Summoning Skeleton (Attempt $loopCount/$maxRetries)..." -ForegroundColor Cyan
        
        if ($loopCount -eq 1) {
            $devPrompt = "[ROLE: SKELETON] You are an aggressive code Surgeon. The file $FilePath crashed with: $errorMsg. Write the exact replacement code to fix this. OUTPUT ONLY RAW CODE. You operate under the 5-Step Algorithm."
        } else {
            $devPrompt = "[ROLE: SKELETON] You are an aggressive code Surgeon. The file $FilePath crashed. Your previous fix failed the Golem's test with error: $testError. Rewrite the exact replacement code to pass the test. OUTPUT ONLY RAW CODE."
        }
        
        $devFix = agy.exe --print $devPrompt --dangerously-skip-permissions
        $devFix = $devFix -replace '(?s)^```\w*\n(.*)```$', '$1'
        
        # Inject fix temporarily to run tests
        Set-Content $FilePath -Value $devFix -Encoding UTF8
        
        Write-Host "   -> ⚙️ Executing Golem's Test against Skeleton's code..." -ForegroundColor Magenta
        $testOutput = pwsh -NoProfile -NonInteractive -Command "& '$testPath'" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $testPassed = $true
            Write-Host "   -> 🟢 Skeleton Code PASSED the Golem's Test!" -ForegroundColor Green
        } else {
            $testError = $testOutput
            Write-Host "   -> 🔴 Skeleton Code FAILED the Golem's Test. Forcing rewrite..." -ForegroundColor Red
        }
    }

    if (-not $testPassed) {
        Write-Host "⚠️ Swarm failed to resolve the issue after $maxRetries autonomous attempts. Restoring original code." -ForegroundColor Red
        Set-Content $FilePath -Value $originalContent -Encoding UTF8
        exit
    }

    # === 5. SUMMON ZOMBIE (GATEKEEPER) ===
    Write-Host "   -> 🧟 Summoning Zombie (Gatekeeper) for heavy defensive review..." -ForegroundColor Yellow
    $reviewPrompt = "[ROLE: ZOMBIE] You are a defensive Gatekeeper Zombie. Review this test-verified fix for $FilePath:`n`n$devFix`n`nAnalyze for O(1) performance and security under the 5-Step Algorithm. If flawless, output 'APPROVED'. If flawed, output CORRECTED RAW CODE."
    $finalFix = agy.exe --print $reviewPrompt --dangerously-skip-permissions

    if ($finalFix.Trim() -match "APPROVED") {
        $finalCode = $devFix
    } else {
        $finalCode = $finalFix -replace '(?s)^```\w*\n(.*)```$', '$1'
    }

    # === 6. UPDATE NEURAL MEMORY LEDGER ===
    # Save the abstract semantic fix
    Set-Content $memoryFile -Value $finalCode -Encoding UTF8

    Write-Host "   ✅ Minion Consensus Reached & Neural Memory Updated. Applying..." -ForegroundColor Green
    Set-Content $FilePath -Value $finalCode -Encoding UTF8
}
