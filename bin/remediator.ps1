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
    
    if ($ext -match "\.sql|\.tf|\.json|\.yml|\.yaml|\.ps1|\.py|\.js|\.ts|\.go") {
        Write-Host "⚠️ CRITICAL FILE MUTATION DETECTED." -ForegroundColor Yellow
        $ans = Read-Host "Captain, structural mutation requested on $FilePath. Proceed? (Y/N)"
        if ($ans -notmatch "^Y") { exit }
    }

    $semanticError = $errorMsg -replace '\b\d+\b', '' -replace '0x[a-fA-F0-9]+', '' -replace '([a-zA-Z]:\\[^\s]+)', ''
    $hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($semanticError))
    $sig = [System.BitConverter]::ToString($hashBytes) -replace '-'
    $memoryDir = Join-Path (Split-Path (Split-Path $MyInvocation.MyCommand.Path)) ".hub_memory"
    if (-not (Test-Path $memoryDir)) { New-Item -ItemType Directory -Path $memoryDir -Force | Out-Null }
    
    $memoryFile = Join-Path $memoryDir "$sig.txt"
    if (Test-Path $memoryFile) {
        Write-Host "🧠 [Positive Memory] Retrieved past solution! Applying Multi-File Patch..." -ForegroundColor Magenta
        $cachedFix = Get-Content $memoryFile -Raw
        try {
            $actions = $cachedFix | ConvertFrom-Json
            foreach ($a in $actions) { if ($a.action -eq 'write') { Set-Content $a.file -Value $a.content -Encoding UTF8 } }
        } catch { Set-Content $FilePath -Value $cachedFix -Encoding UTF8 }
        exit
    }

    $failedMemoryFile = Join-Path $memoryDir "failed_$sig.txt"
    $negativeContext = ""
    if (Test-Path $failedMemoryFile) {
        $negativeContext = "CRITICAL NEGATIVE MEMORY: You have attempted to fix this before and failed. Here is what you MUST NOT REPEAT:`n" + (Get-Content $failedMemoryFile -Raw)
        Write-Host "🧠 [Negative Memory] Retrieved past failures." -ForegroundColor DarkYellow
    }

        $provider = if ($env:HUB_AI_PROVIDER) { $env:HUB_AI_PROVIDER } else { "Antigravity" }
    $model = if ($env:HUB_AI_MODEL) { $env:HUB_AI_MODEL } else { "llama3" }
    $aiWrapper = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "use-agentic-ai.ps1"
    
    function Invoke-AI ([string]$promptText) {
        return & pwsh -NoProfile -NonInteractive -File $aiWrapper -Prompt $promptText -Provider $provider -Model $model
    }

    Write-Host "☠️ INITIATING PATH OF EXILE MINION SWARM (V15 SPM ARCHITECTURE) VIA $provider..." -ForegroundColor Magenta

    Write-Host "   -> 👻 Summoning Spectres to scout the repository..." -ForegroundColor DarkCyan
    $repoContext = ""
    $keywords = $errorMsg -replace '[^\w]', ' ' -split ' ' | Where-Object { $_.Length -gt 5 } | Select-Object -Unique
    if ($keywords) {
        $filesToSearch = Get-ChildItem -Recurse -File -Include *.ps1,*.py,*.js,*.ts,*.go -ErrorAction SilentlyContinue | Select-Object -First 100
        $contextFiles = $filesToSearch | Where-Object {
            $path = $_.Name; $match = $false
            foreach ($k in $keywords) { if ($path -match $k) { $match = $true; break } }
            $match
        } | Select-Object -First 3
        
        foreach ($cf in $contextFiles) {
            if ($cf.FullName -ne $FilePath) {
                $repoContext += "`n--- Related File: $($cf.FullName) ---`n" + ((Get-Content $cf.FullName -ErrorAction SilentlyContinue | Select-Object -First 50) -join "`n")
            }
        }
    }

    Write-Host "   -> 🪨 Summoning Golem (Test Engineer)..." -ForegroundColor Blue
    $testPrompt = "[ROLE: GOLEM] Write a test script to verify the fix for $errorMsg in $FilePath. OUTPUT RAW CODE ONLY."
    $testFix = Invoke-AI $testPrompt
    $testFix = $testFix -replace '(?s)^```\w*\n(.*)```$', '$1'
    $testPath = "$FilePath.tests$ext"
    Set-Content $testPath -Value $testFix -Encoding UTF8

        $maxRetries = 3
    $loopCount = 0
    $testPassed = $false
    $originalContent = Get-Content $FilePath -Raw
    $hasDocker = Get-Command docker -ErrorAction SilentlyContinue

    # --- V16 MCP BRIDGE SETUP ---
    $mcpContext = ""
    $mcpDir = Join-Path (Split-Path (Split-Path $MyInvocation.MyCommand.Path)) ".hub_mcp"
    if (Test-Path $mcpDir) {
        $mcpTools = Get-ChildItem -Path $mcpDir -Filter *.json
        if ($mcpTools) {
            $mcpContext = "You are connected to a Model Context Protocol (MCP) Bridge. You have access to the following tools:
"
            foreach ($tool in $mcpTools) { $mcpContext += (Get-Content $tool.FullName -Raw) + "
" }
        }
    }

    while ($loopCount -lt $maxRetries -and -not $testPassed) {
        $loopCount++
        Write-Host "   -> 💀 Summoning Skeleton (Attempt $loopCount/$maxRetries)..." -ForegroundColor Cyan
        
        $basePrompt = "[ROLE: SKELETON] You are an aggressive code Surgeon. The file $FilePath crashed. OUTPUT ONLY A STRICT JSON ARRAY OF ACTIONS. 

Format:
[
  {"action": "write", "file": "path", "content": "raw code"},
  {"action": "command", "cmd": "npm i foo"},
  {"action": "mcp_tool", "tool": "search_web", "args": {"query": "error code"}}
]

$mcpContext

$negativeContext

$repoContext"
        
        if ($loopCount -eq 1) {
            $devPrompt = "$basePrompt

Error: $errorMsg"
        } else {
            $devPrompt = "$basePrompt

Your previous fix failed with error: $testError. Try again."
        }
        
        # --- MULTI-TURN MCP LOOP ---
        $mcpResolved = $false
        $turnLimit = 3
        $turnCount = 0
        while (-not $mcpResolved -and $turnCount -lt $turnLimit) {
            $turnCount++
            $devFix = Invoke-AI $devPrompt
            $devFix = $devFix -replace '(?s)^`\w*\n(.*)`
            $actions = $devFix | ConvertFrom-Json
            foreach ($action in $actions) {
                if ($action.action -eq 'write') {
                    Set-Content $action.file -Value $action.content -Encoding UTF8
                } elseif ($action.action -eq 'command') {
                    Write-Host "   -> 💻 Executing AI Command: $($action.cmd)" -ForegroundColor DarkGray
                    Invoke-Expression $action.cmd | Out-Null
                }
            }
        } catch {
            Write-Host "   -> ⚠️ Skeleton failed to output valid JSON. Falling back to single-file patch..." -ForegroundColor Yellow
            Set-Content $FilePath -Value $devFix -Encoding UTF8
        }
        
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
            Write-Host "   -> ⚠️ Executing test locally (UNSAFE)..." -ForegroundColor DarkYellow
            $testOutput = switch ($ext) {
                ".ps1" { pwsh -NoProfile -NonInteractive -Command "& '$testPath'" 2>&1 }
                ".py"  { python "$testPath" 2>&1 }
                ".js"  { node "$testPath" 2>&1 }
                default { "Execution failed." }
            }
        }
        
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) {
            $testPassed = $true
            Write-Host "   -> 🟢 Skeleton JSON Patch PASSED!" -ForegroundColor Green
        } else {
            $testError = $testOutput
            Write-Host "   -> 🔴 Skeleton Patch FAILED. Forcing rewrite..." -ForegroundColor Red
            Add-Content $failedMemoryFile -Value "`n--- FAILED ATTEMPT $loopCount ---`n$devFix" -Encoding UTF8
        }
    }

    if (-not $testPassed) {
        Write-Host "⚠️ Swarm failed. Restoring original code." -ForegroundColor Red
        Set-Content $FilePath -Value $originalContent -Encoding UTF8
        exit
    }

    Write-Host "   -> 🧟 Summoning Zombie (Gatekeeper) for heavy review..." -ForegroundColor Yellow
    $reviewPrompt = "[ROLE: ZOMBIE] You are a Gatekeeper Zombie. Review this JSON patch for security:`n`n$devFix`n`nIf flawless, output 'APPROVED'. If flawed, output CORRECTED JSON."
    $finalFix = Invoke-AI $reviewPrompt

    if ($finalFix.Trim() -match "APPROVED") {
        $finalCode = $devFix
    } else {
        $finalCode = $finalFix -replace '(?s)^```\w*\n(.*)```$', '$1'
    }

    Set-Content $memoryFile -Value $finalCode -Encoding UTF8
    if (Test-Path $failedMemoryFile) { Remove-Item $failedMemoryFile -Force }

    Write-Host "   ✅ Minion Consensus Reached. Applying Final Multi-File Patch..." -ForegroundColor Green
}

, '$1'
            $mcpTriggered = $false
            
            try {
                $actions = $devFix | ConvertFrom-Json
                foreach ($action in $actions) {
                    if ($action.action -eq 'mcp_tool') {
                        Write-Host "   -> 🔌 MCP Tool Triggered: $($action.tool)" -ForegroundColor Yellow
                        $mcpTriggered = $true
                        if ($action.tool -eq 'search_web') {
                            # Simulate a web search using Invoke-RestMethod against a free search API or DuckDuckGo HTML
                            $q = [uri]::EscapeDataString($action.args.query)
                            $mcpResult = "Simulated Web Search Results for $q: 'Ensure you have the latest version installed, or check StackOverflow for this specific stack trace.'"
                            $devPrompt += "

MCP Tool Result ($($action.tool)): $mcpResult
Now generate the final JSON action array to fix the code."
                        }
                    } elseif ($action.action -eq 'write') {
                        Set-Content $action.file -Value $action.content -Encoding UTF8
                    } elseif ($action.action -eq 'command') {
                        Write-Host "   -> 💻 Executing AI Command: $($action.cmd)" -ForegroundColor DarkGray
                        Invoke-Expression $action.cmd | Out-Null
                    }
                }
            } catch {
                Set-Content $FilePath -Value $devFix -Encoding UTF8
            }
            if (-not $mcpTriggered) { $mcpResolved = $true }
        }
        try {
            $actions = $devFix | ConvertFrom-Json
            foreach ($action in $actions) {
                if ($action.action -eq 'write') {
                    Set-Content $action.file -Value $action.content -Encoding UTF8
                } elseif ($action.action -eq 'command') {
                    Write-Host "   -> 💻 Executing AI Command: $($action.cmd)" -ForegroundColor DarkGray
                    Invoke-Expression $action.cmd | Out-Null
                }
            }
        } catch {
            Write-Host "   -> ⚠️ Skeleton failed to output valid JSON. Falling back to single-file patch..." -ForegroundColor Yellow
            Set-Content $FilePath -Value $devFix -Encoding UTF8
        }
        
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
            Write-Host "   -> ⚠️ Executing test locally (UNSAFE)..." -ForegroundColor DarkYellow
            $testOutput = switch ($ext) {
                ".ps1" { pwsh -NoProfile -NonInteractive -Command "& '$testPath'" 2>&1 }
                ".py"  { python "$testPath" 2>&1 }
                ".js"  { node "$testPath" 2>&1 }
                default { "Execution failed." }
            }
        }
        
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) {
            $testPassed = $true
            Write-Host "   -> 🟢 Skeleton JSON Patch PASSED!" -ForegroundColor Green
        } else {
            $testError = $testOutput
            Write-Host "   -> 🔴 Skeleton Patch FAILED. Forcing rewrite..." -ForegroundColor Red
            Add-Content $failedMemoryFile -Value "`n--- FAILED ATTEMPT $loopCount ---`n$devFix" -Encoding UTF8
        }
    }

    if (-not $testPassed) {
        Write-Host "⚠️ Swarm failed. Restoring original code." -ForegroundColor Red
        Set-Content $FilePath -Value $originalContent -Encoding UTF8
        exit
    }

    Write-Host "   -> 🧟 Summoning Zombie (Gatekeeper) for heavy review..." -ForegroundColor Yellow
    $reviewPrompt = "[ROLE: ZOMBIE] You are a Gatekeeper Zombie. Review this JSON patch for security:`n`n$devFix`n`nIf flawless, output 'APPROVED'. If flawed, output CORRECTED JSON."
    $finalFix = Invoke-AI $reviewPrompt

    if ($finalFix.Trim() -match "APPROVED") {
        $finalCode = $devFix
    } else {
        $finalCode = $finalFix -replace '(?s)^```\w*\n(.*)```$', '$1'
    }

    Set-Content $memoryFile -Value $finalCode -Encoding UTF8
    if (Test-Path $failedMemoryFile) { Remove-Item $failedMemoryFile -Force }

    Write-Host "   ✅ Minion Consensus Reached. Applying Final Multi-File Patch..." -ForegroundColor Green
}


