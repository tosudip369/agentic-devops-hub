# ==============================================================================
# The Universal 'use-agentic-ai' Wrapper for Windows PowerShell
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

$StrictRules = "[STRICT DIRECTIVE: use-agentic-ai] You are operating under the Agentic DevOps Hub architecture. You must: 1) Enforce ClearCode. 2) Use ephemeral branches. 3) Cross-reference neural memory. 4) Write code that passes strict CI/CD. Now, execute the following request:"

$FullPrompt = "$StrictRules $UserPrompt"

Write-Host "🧠 [use-agentic-ai] Injecting God-Level architecture into local agent..." -ForegroundColor Cyan

if (Get-Command "agy.exe" -ErrorAction SilentlyContinue) {
    Write-Host "🚀 Detected Antigravity CLI (agy)" -ForegroundColor Green
    agy.exe "$FullPrompt"
} elseif (Get-Command "openclaw" -ErrorAction SilentlyContinue) {
    Write-Host "🚀 Detected OpenClaw" -ForegroundColor Green
    openclaw --prompt "$FullPrompt"
} elseif (Get-Command "hermes" -ErrorAction SilentlyContinue) {
    Write-Host "🚀 Detected Hermes" -ForegroundColor Green
    hermes chat "$FullPrompt"
} elseif (Get-Command "ollama" -ErrorAction SilentlyContinue) {
    Write-Host "🚀 Detected Ollama" -ForegroundColor Green
    ollama run qwen2.5-coder "$FullPrompt"
} elseif (Get-Command "claude" -ErrorAction SilentlyContinue) {
    Write-Host "🚀 Detected Claude Code" -ForegroundColor Green
    claude -p "$FullPrompt"
} else {
    Write-Host "⚠️ No supported agentic CLI found in PATH." -ForegroundColor Yellow
    Write-Host "Fallback - Copy/Paste this into your IDE/Chat:"
    Write-Host $FullPrompt
}
