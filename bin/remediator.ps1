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
    $semanticError = $errorMsg -replace '\b\d+\b', '' -replace '0x[a-fA-F0-9]+', '' -replace '([a-zA-Z]:\\[^\s]+)', ''
    $hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($semanticError))
    $sig = [System.BitConverter]::ToString($hashBytes) -replace '-'
    $memoryDir = Join-Path (Split-Path (Split-Path $MyInvocation.MyCommand.Path)) ".hub_memory"
    if (-not (Test-Path $memoryDir)) { New-Item -ItemType Directory -Path $memoryDir -Force | Out-Null }
    
    $memoryFile = Join-Path $memoryDir "$sig.txt"
    if (Test-Path $memoryFile) {
        Write-Host "🧠 [Positive Memory] Retrieved past solution! O(1) instant fix applied." -ForegroundColor Magenta
        Set-Content $FilePath -Value (Get-Content $memoryFile -Raw) -Encoding UTF8
        exit
    }

    # === 3. NEGATIVE MEMORY (POST-MORTEMS) ===
    $failedMemoryFile = Join-Path $memoryDir "failed_$sig.txt"
    $negativeContext = ""
    if (Test-Path $failedMemoryFile) {
        $negativeContext = "CRITICAL NEGATIVE MEMORY: You have attempted to fix this before and failed. Here is the post-mortem of previous failed code blocks you MUST NOT REPEAT:`n" + (Get-Content $failedMemoryFile -Raw)
        Write-Host "🧠 [Negative Memory] Retrieved past failures. Enforcing new AI pathways..." -ForegroundColor DarkYellow
    }

    Write-Host "☠️ INITIATING PATH OF EXILE MINION SWARM (V13 APEX ENGINE)..." -ForegroundColor Magenta

    # === 4. SPECTRES (MULTI-FILE RAG CONTEXT) ===
    Write-Host "   -> 👻 Summoning Spectres to scout the repository..." -ForegroundColor DarkCyan
    $repoContext = ""
    $keywords = $errorMsg -replace '[^\w]', ' ' -split ' ' | Where-Object { $_.Length -gt 5 } | Select-Object -Unique
    if ($keywords) {
        $filesToSearch = Get-ChildItem -Recurse -File -Include *.ps1,*.py,*.js,*.ts,*.go -ErrorAction SilentlyContinue | Select-Object -First 100
        $contextFiles = $filesToSearch | Where-Object {
            $path = $_.Name; $match = $false
            foreach ($k in $keywords) { if ($path -match $k) { $match = $true; break } }
            $match
        } | Select-Object -First 2
        
        foreach ($cf in $contextFiles) {
            if ($cf.FullName -ne $FilePath) {
                $repoContext += "`n--- Related File Context: $($cf.Name) ---`n" + ((Get-Content $cf.FullName -ErrorAction SilentlyContinue | Select-Object -First 50) -join "`n")
            }
        }
    }

    # === 5. SUMMON GOLEM (TDD ENGINEER) ===
    Write-Host "   -> 🪨 Summoning Golem (Test Engineer) for structural buffs..." -ForegroundColor Blue
    $testPrompt = "[ROLE: GOLEM] You are a TDD Golem. Write a test script to verify the fix for $errorMsg in $FilePath. OUTPUT RAW CODE ONLY."
    $testFix = agy.exe --print $testPrompt --dangerously-skip-permissions
    $testFix = $testFix -replace '(?s)^```\w*\n(.*)```$', '$1'
    $testPath = "$FilePath.tests$ext"
    Set-Content $testPath -Value $testFix -Encoding UTF8
    Write-Host "   -> 🪨 Golem has fortified the build with a test suite at $testPath" -ForegroundColor Blue

    # === 6. THE EXECUTION LOOP (SKELETON AUTONOMY) ===
    $maxRetries = 3
    $loopCount = 0
    $testPassed = $false
    $devFix = ""
    $testError = ""
    $originalContent = Get-Content $FilePath -Raw
    $hasDocker = Get-Command docker -ErrorAction SilentlyContinue

    while ($loopCount -lt $maxRetries -and -not $testPassed) {
        $loopCount++
        Write-Host "   -> 💀 Summoning Skeleton (Attempt $loopCount/$maxRetries)..." -ForegroundColor Cyan
        
        $basePrompt = "[ROLE: SKELETON] You are an aggressive code Surgeon. The file $FilePath crashed. Fix it. OUTPUT ONLY RAW CODE. You operate under the 5-Step Algorithm.`n`n$negativeContext`n`n$repoContext"
        if ($loopCount -eq 1) {
            $devPrompt = "$basePrompt`n`nError: $errorMsg"
        } else {
            $devPrompt = "$basePrompt`n`nYour previous fix failed the test with error: $testError. Rewrite the exact replacement code."
        }
        
        $devFix = agy.exe --print $devPrompt --dangerously-skip-permissions
        $devFix = $devFix -replace '(?s)^```\w*\n(.*)```$', '$1'
        
        Set-Content $FilePath -Value $devFix -Encoding UTF8
        
        # === 7. THE DOCKER MATRIX (SANDBOXING) ===
        if ($hasDocker) {
            Write-Host "   -> 🐳 Executing test inside Ephemeral Docker Sandbox..." -ForegroundColor Magenta
            $dockerImg = switch ($ext) {
                ".ps1" { "mcr.microsoft.com/powershell:lts" }
                ".py"  { "python:3.11-alpine" }
                ".js"  { "node:20-alpine" }
                ".ts"  { "node:20-alpine" }
                ".go"  { "golang:1.21-alpine" }
                default { "" }
            }
            if ($dockerImg) {
                $testOutput = docker run --rm -v "$($FilePath):/app/target$ext" -v "$($testPath):/app/test$ext" -w /app $dockerImg sh -c "cat /app/test$ext" 2>&1
            } else {
                $testOutput = "Unsupported Docker Sandbox language."
                $LASTEXITCODE = 1
            }
        } else {
            Write-Host "   -> ⚠️ Docker not found. Executing locally (UNSAFE)..." -ForegroundColor DarkYellow
            $testOutput = switch ($ext) {
                ".ps1" { pwsh -NoProfile -NonInteractive -Command "& '$testPath'" 2>&1 }
                ".py"  { python "$testPath" 2>&1 }
                ".js"  { node "$testPath" 2>&1 }
                default { "Execution failed." }
            }
        }
        
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) {
            $testPassed = $true
            Write-Host "   -> 🟢 Skeleton Code PASSED the Golem's Test!" -ForegroundColor Green
        } else {
            $testError = $testOutput
            Write-Host "   -> 🔴 Skeleton Code FAILED the Golem's Test. Forcing rewrite..." -ForegroundColor Red
            Add-Content $failedMemoryFile -Value "`n--- FAILED ATTEMPT $loopCount ---`n$devFix" -Encoding UTF8
        }
    }

    if (-not $testPassed) {
        Write-Host "⚠️ Swarm failed after $maxRetries attempts. Restoring original code." -ForegroundColor Red
        Set-Content $FilePath -Value $originalContent -Encoding UTF8
        exit
    }

    # === 8. SUMMON ZOMBIE (GATEKEEPER) ===
    Write-Host "   -> 🧟 Summoning Zombie (Gatekeeper) for heavy defensive review..." -ForegroundColor Yellow
    $reviewPrompt = "[ROLE: ZOMBIE] You are a Gatekeeper Zombie. Review this test-verified fix for $FilePath:`n`n$devFix`n`nAnalyze for security under the 5-Step Algorithm. If flawless, output 'APPROVED'. If flawed, output CORRECTED RAW CODE."
    $finalFix = agy.exe --print $reviewPrompt --dangerously-skip-permissions

    if ($finalFix.Trim() -match "APPROVED") {
        $finalCode = $devFix
    } else {
        $finalCode = $finalFix -replace '(?s)^```\w*\n(.*)```$', '$1'
    }

    # === 9. UPDATE NEURAL MEMORY LEDGER ===
    Set-Content $memoryFile -Value $finalCode -Encoding UTF8
    if (Test-Path $failedMemoryFile) { Remove-Item $failedMemoryFile -Force }

    Write-Host "   ✅ Minion Consensus Reached & Neural Memory Updated. Applying..." -ForegroundColor Green
    Set-Content $FilePath -Value $finalCode -Encoding UTF8
}
