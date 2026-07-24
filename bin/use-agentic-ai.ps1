# ==============================================================================
# The S-Tier 'use-agentic-ai' Wrapper for Windows PowerShell
# Upgraded with Dynamic Context & Git State Injection
# ==============================================================================

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$PromptArgs
)

$UserPrompt = $PromptArgs -join " "

if ([string]::IsNullOrWhiteSpace($UserPrompt)) {
    Write-Host "Usage: .\bin\use-agentic-ai.ps1 `"your prompt here`""
    exit 1
}

# 1. BASE GUARDRAILS
$BaseRules = "[STRICT DIRECTIVE: use-agentic-ai] You are operating under the Agentic DevOps Hub architecture. You must: 1) Enforce ClearCode. 2) Use ephemeral branches. 3) Cross-reference neural memory. 4) Write code that passes strict CI/CD."

# 2. DYNAMIC RULES (Read from SPEC.md or .agentrules if they exist)
$DynamicRules = ""
if (Test-Path "SPEC.md") {
    $DynamicRules += "`n`n[PROJECT SPECIFICATION]`n" + (Get-Content "SPEC.md" -Raw)
} elseif (Test-Path ".agentrules") {
    $DynamicRules += "`n`n[PROJECT SPECIFICATION]`n" + (Get-Content ".agentrules" -Raw)
}

# 3. GIT CONTEXT INJECTION (Instantly tell the AI what files are modified)
$GitContext = ""
if (Get-Command "git" -ErrorAction SilentlyContinue) {
    if (Test-Path ".git") {
        $GitStatus = git status --short
        if (-not [string]::IsNullOrWhiteSpace($GitStatus)) {
            $GitContext = "`n`n[CURRENT GIT STATUS]`nThe following files are currently modified or untracked:`n$GitStatus`nEnsure you address these files if relevant."
        }
    }
}

# COMBINE ALL CONTEXT
$FullPrompt = "$BaseRules $DynamicRules $GitContext `n`n[USER REQUEST]`n$UserPrompt"

Write-Host "🧠 [use-agentic-ai] Injecting God-Level S-Tier Architecture..." -ForegroundColor Cyan
if ($DynamicRules) { Write-Host "   -> 📄 Injected Dynamic Project Rules" -ForegroundColor DarkGray }
if ($GitContext) { Write-Host "   -> 🌿 Injected Git Status Context" -ForegroundColor DarkGray }

# ROUTE TO AVAILABLE AGENT CLI
if (Get-Command "agy.exe" -ErrorAction SilentlyContinue) {
    Write-Host "🚀 Routing to Antigravity CLI (agy)" -ForegroundColor Green
    agy.exe "$FullPrompt"
} elseif (Get-Command "openclaw" -ErrorAction SilentlyContinue) {
    Write-Host "🚀 Routing to OpenClaw" -ForegroundColor Green
    openclaw --prompt "$FullPrompt"
} elseif (Get-Command "hermes" -ErrorAction SilentlyContinue) {
    Write-Host "🚀 Routing to Hermes" -ForegroundColor Green
    hermes chat "$FullPrompt"
} elseif (Get-Command "ollama" -ErrorAction SilentlyContinue) {
    Write-Host "🚀 Routing to Ollama (qwen2.5-coder)" -ForegroundColor Green
    ollama run qwen2.5-coder "$FullPrompt"
} elseif (Get-Command "claude" -ErrorAction SilentlyContinue) {
    Write-Host "🚀 Routing to Claude Code" -ForegroundColor Green
    claude -p "$FullPrompt"
} else {
    Write-Host "⚠️ No supported agentic CLI found in PATH." -ForegroundColor Yellow
    Write-Host "Fallback - Copy/Paste this exact payload into your IDE/Chat:"
    Write-Host "--------------------------------------------------------"
    Write-Host $FullPrompt
    Write-Host "--------------------------------------------------------"
}
