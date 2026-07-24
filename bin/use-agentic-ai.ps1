# ==============================================================================
# use-agentic-ai v3.0 — The Autonomous Cutting-Edge Builder
# ==============================================================================
# Modes: build | fix | auto | observe | status
# Auto-detects agents: agy, claude, codex, openclaw, hermes, ollama
# Features: Auto-scan, memory injection, git context, subagent delegation
# ==============================================================================

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$PromptArgs,

    [Alias("m")]
    [string]$Mode = "build",

    [Alias("p")]
    [string]$Project = "."
)

$UserPrompt = $PromptArgs -join " "
$HubRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$MemoryEngine = Join-Path (Join-Path $HubRoot "bin") "memory-engine.sh"
$ObserverScript = Join-Path (Join-Path $HubRoot "bin") "observer.sh"
$RemediateScript = Join-Path (Join-Path $HubRoot "bin") "remediate.sh"

# ── HELP ──────────────────────────────────────────────────────────────────────
if ([string]::IsNullOrWhiteSpace($UserPrompt) -and $Mode -eq "build") {
    Write-Host ""
    Write-Host "  use-agentic-ai v3.0 — The Autonomous Builder" -ForegroundColor Cyan
    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  USAGE:" -ForegroundColor Yellow
    Write-Host '    .\bin\use-agentic-ai.ps1 "Build me a REST API"'
    Write-Host '    .\bin\use-agentic-ai.ps1 -Mode fix "Fix the login bug"'
    Write-Host '    .\bin\use-agentic-ai.ps1 -Mode auto'                       -ForegroundColor White
    Write-Host '    .\bin\use-agentic-ai.ps1 -Mode observe'
    Write-Host '    .\bin\use-agentic-ai.ps1 -Mode status'
    Write-Host ""
    Write-Host "  MODES:" -ForegroundColor Yellow
    Write-Host "    build    — (default) Dispatch the agent to build/create" -ForegroundColor White
    Write-Host "    fix      — Surgical error repair with memory context" -ForegroundColor White
    Write-Host "    auto     — Auto-scan current dir, find errors, fix them" -ForegroundColor Green
    Write-Host "    observe  — Start the background observer watchdog" -ForegroundColor White
    Write-Host "    status   — Show system health and memory stats" -ForegroundColor White
    Write-Host ""
    exit 0
}

# ── MODE: STATUS ──────────────────────────────────────────────────────────────
if ($Mode -eq "status") {
    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "  │  🧠 Agentic DevOps Hub v3.0         │" -ForegroundColor Cyan
    Write-Host "  └─────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""

    $branch = git -C $HubRoot rev-parse --abbrev-ref HEAD 2>$null
    $commits = git -C $HubRoot rev-list --count HEAD 2>$null
    Write-Host "  Git Branch : $branch" -ForegroundColor White
    Write-Host "  Commits    : $commits" -ForegroundColor White

    $agents = @("agy.exe", "claude", "codex", "openclaw", "hermes", "ollama", "gemini")
    foreach ($agent in $agents) {
        if (Get-Command $agent -ErrorAction SilentlyContinue) {
            Write-Host "  Agent      : $agent ✅" -ForegroundColor Green
        }
    }

    $ledger = "$env:USERPROFILE\.agentic\memory\error_ledger.jsonl"
    if (Test-Path $ledger) {
        $count = (Get-Content $ledger | Measure-Object -Line).Lines
        Write-Host "  Memory     : $count recorded fixes" -ForegroundColor Magenta
    } else {
        Write-Host "  Memory     : Empty (no fixes yet)" -ForegroundColor DarkGray
    }

    $conf = Join-Path $HubRoot "projects.conf"
    if (Test-Path $conf) {
        $projects = (Get-Content $conf | Where-Object { $_ -and $_ -notmatch '^\s*#' } | Measure-Object -Line).Lines
        Write-Host "  Projects   : $projects registered" -ForegroundColor White
    }
    Write-Host ""
    exit 0
}

# ── MODE: OBSERVE ─────────────────────────────────────────────────────────────
if ($Mode -eq "observe") {
    Write-Host "🚀 Starting Observer v2.0 in background..." -ForegroundColor Green
    if (Get-Command "bash" -ErrorAction SilentlyContinue) {
        bash $ObserverScript --start
    } else {
        Write-Host "⚠️ bash not found. Use WSL or Git Bash." -ForegroundColor Yellow
    }
    exit 0
}

# ── MODE: AUTO (The Magic — scans, detects, fixes automatically) ──────────────
if ($Mode -eq "auto") {
    Write-Host ""
    Write-Host "  🤖 AUTO MODE — Scanning current directory for errors..." -ForegroundColor Cyan
    Write-Host ""

    $targetDir = Resolve-Path $Project
    $errors = @()

    # Scan .sh files
    $shFiles = Get-ChildItem -Path $targetDir -Filter "*.sh" -Recurse -ErrorAction SilentlyContinue
    foreach ($f in $shFiles) {
        if (Get-Command "bash" -ErrorAction SilentlyContinue) {
            $result = bash -n $f.FullName 2>&1
            if ($LASTEXITCODE -ne 0) {
                $errors += @{ File = $f.FullName; Error = "$result"; Lang = "bash" }
            }
        }
    }

    # Scan .py files
    $pyFiles = Get-ChildItem -Path $targetDir -Filter "*.py" -Recurse -ErrorAction SilentlyContinue
    foreach ($f in $pyFiles) {
        if (Get-Command "python3" -ErrorAction SilentlyContinue) {
            $result = python3 -m py_compile $f.FullName 2>&1
            if ($LASTEXITCODE -ne 0) {
                $errors += @{ File = $f.FullName; Error = "$result"; Lang = "python" }
            }
        } elseif (Get-Command "python" -ErrorAction SilentlyContinue) {
            $result = python -m py_compile $f.FullName 2>&1
            if ($LASTEXITCODE -ne 0) {
                $errors += @{ File = $f.FullName; Error = "$result"; Lang = "python" }
            }
        }
    }

    # Scan .json files
    $jsonFiles = Get-ChildItem -Path $targetDir -Filter "*.json" -MaxDepth 2 -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne "package-lock.json" }
    foreach ($f in $jsonFiles) {
        try {
            Get-Content $f.FullName -Raw | ConvertFrom-Json | Out-Null
        } catch {
            $errors += @{ File = $f.FullName; Error = $_.Exception.Message; Lang = "json" }
        }
    }

    if ($errors.Count -eq 0) {
        Write-Host "  ✅ No errors found. All files are healthy!" -ForegroundColor Green
        Write-Host ""
        exit 0
    }

    Write-Host "  ⚠️ Found $($errors.Count) error(s):" -ForegroundColor Yellow
    Write-Host ""

    foreach ($err in $errors) {
        Write-Host "  ❌ [$($err.Lang)] $($err.File)" -ForegroundColor Red
        Write-Host "     $($err.Error)" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "  🔨 Auto-dispatching remediation for each error..." -ForegroundColor Cyan
    Write-Host ""

    foreach ($err in $errors) {
        Write-Host "  🤖 Fixing: $($err.File)" -ForegroundColor Magenta

        if (Get-Command "bash" -ErrorAction SilentlyContinue) {
            bash $RemediateScript $err.File $err.Error
        } else {
            # Fallback: dispatch directly to AI agent
            $fixPrompt = "[STRICT DIRECTIVE: use-agentic-ai AUTO-FIX] Fix this error in $($err.File): $($err.Error). Enforce ClearCode. Do not break existing functionality."

            # Route to best available agent
            if (Get-Command "agy.exe" -ErrorAction SilentlyContinue) {
                agy.exe --print "$fixPrompt" --dangerously-skip-permissions
            } elseif (Get-Command "claude" -ErrorAction SilentlyContinue) {
                echo "$fixPrompt" | claude -p
            } else {
                Write-Host "  ⚠️ No agent found. Manual fix required." -ForegroundColor Yellow
            }
        }
    }

    Write-Host ""
    Write-Host "  ✅ Auto-remediation complete!" -ForegroundColor Green
    Write-Host ""
    exit 0
}

# ── MODES: BUILD / FIX ───────────────────────────────────────────────────────

# 1. TOKEN-OPTIMIZED RULES + 5-STEP ALGORITHM
$BaseRules = @"
[DIR:v3.0] Arch:AgenticDevOpsHub
Code: O(1)/O(N) pref. Max 2-lvl nest. Single-resp fns. Self-doc vars.
Flow: Ephemeral branches only. Write tests. Pass strict CI/CD.
Subagents: Auto-spawn subagents (security-auditor, code-reviewer) for complex/parallel tasks.
Algo (Strict): 1.Question reqs(make less dumb). 2.Delete parts(>10% added back=good). 3.Simplify/Optimize(after step2). 4.Accelerate cycle. 5.Automate(last).
"@

if ($Mode -eq "fix") {
    $BaseRules += "`nMODE: SURGICAL FIX — Focus only on the specific error. Minimal changes. Do not refactor unrelated code."
}

# 2. DYNAMIC RULES (from SPEC.md or .agentrules)
$DynamicRules = ""
if (Test-Path "SPEC.md") {
    $DynamicRules = "`n`n[PROJECT SPECIFICATION]`n" + (Get-Content "SPEC.md" -Raw)
} elseif (Test-Path ".agentrules") {
    $DynamicRules = "`n`n[PROJECT SPECIFICATION]`n" + (Get-Content ".agentrules" -Raw)
}

# 3. GIT CONTEXT INJECTION
$GitContext = ""
if (Get-Command "git" -ErrorAction SilentlyContinue) {
    if (Test-Path ".git") {
        $RemoteUrl = (git remote get-url origin 2>$null)
        if (-not [string]::IsNullOrWhiteSpace($RemoteUrl)) {
            $GitContext += "`n`n[GITHUB REPOSITORY]`nRepo: $RemoteUrl"
        }
        
        # MASSIVE IMPROVEMENT 1: The Project File Map
        # Instantly gives the AI the architectural layout of the project without it having to guess.
        $ProjectMap = (git ls-files | Select-Object -First 40) -join "`n"
        if (-not [string]::IsNullOrWhiteSpace($ProjectMap)) {
            $GitContext += "`n`n[PROJECT ARCHITECTURE MAP]`n$ProjectMap"
        }

        # MASSIVE IMPROVEMENT 2: Git Diff (What you just did)
        $GitStatus = git status --short
        if (-not [string]::IsNullOrWhiteSpace($GitStatus)) {
            $GitDiff = (git diff | Select-Object -First 50) -join "`n"
            $GitContext += "`n`n[MODIFIED FILES]`n$GitStatus`n`n[RECENT CODE CHANGES]`n$GitDiff"
        }
    }
}

# COMBINE
$FullPrompt = "$BaseRules $DynamicRules $GitContext`n`n[USER REQUEST]`n$UserPrompt"

Write-Host ""
Write-Host "  🧠 [use-agentic-ai v3.0] Dispatching..." -ForegroundColor Cyan
if ($DynamicRules) { Write-Host "   → 📄 Project rules injected" -ForegroundColor DarkGray }
if ($GitContext) { Write-Host "   → 🌿 Git context injected" -ForegroundColor DarkGray }
Write-Host ""

# ROUTE TO BEST AVAILABLE AGENT
$agentPriority = @(
    @{ Name = "agy.exe";   Label = "Antigravity CLI" },
    @{ Name = "claude";    Label = "Claude Code" },
    @{ Name = "codex";     Label = "Codex CLI" },
    @{ Name = "openclaw";  Label = "OpenClaw" },
    @{ Name = "hermes";    Label = "Hermes" },
    @{ Name = "ollama";    Label = "Ollama" }
)

$dispatched = $false
foreach ($agent in $agentPriority) {
    if (Get-Command $agent.Name -ErrorAction SilentlyContinue) {
        Write-Host "  🚀 Agent: $($agent.Label)" -ForegroundColor Green
        switch ($agent.Name) {
            "agy.exe"   { agy.exe "$FullPrompt" }
            "claude"    { claude -p "$FullPrompt" }
            "codex"     { codex "$FullPrompt" }
            "openclaw"  { openclaw --prompt "$FullPrompt" }
            "hermes"    { hermes chat "$FullPrompt" }
            "ollama"    { ollama run qwen2.5-coder "$FullPrompt" }
        }
        $dispatched = $true
        break
    }
}

if (-not $dispatched) {
    Write-Host "  ⚠️ No agent CLI found." -ForegroundColor Yellow
    Write-Host "  To unlock full autonomy, install one of these free/popular agents:" -ForegroundColor White
    Write-Host "    - Antigravity: Built-in to this IDE / Google ecosystem" -ForegroundColor DarkGray
    Write-Host "    - Claude Code: npm install -g @anthropic-ai/claude-code" -ForegroundColor DarkGray
    Write-Host "    - Ollama (Local/Free): https://ollama.com/download" -ForegroundColor DarkGray
    Write-Host "    - OpenClaw / Hermes: See their respective GitHub repos" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  🧠 FALLBACK MODE:" -ForegroundColor Cyan
    Write-Host "  Go and paste the prompt below into any AI you have (ChatGPT, Claude, Gemini, IDE)." -ForegroundColor White
    Write-Host "  The AI will instantly understand the God-Level architecture, teach you all about it, and show you exactly how to use it!" -ForegroundColor White
    Write-Host ""
    Write-Host "  --- COPY BELOW THIS LINE ---" -ForegroundColor DarkGray
    Write-Host $FullPrompt
    Write-Host "  ----------------------------" -ForegroundColor DarkGray
}
