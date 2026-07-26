# activate.ps1 - Environment Activator for Agentic DevOps Hub
$HubRoot = $PSScriptRoot
$BinDir = Join-Path $HubRoot "bin"

# Set an alias so you can just type 'agentic' anywhere
Set-Alias -Name agentic -Value (Join-Path $BinDir "use-agentic-ai.ps1") -Scope Global
Set-Alias -Name hub -Value (Join-Path $BinDir "use-agentic-ai.ps1") -Scope Global

# Add bin to PATH temporarily for this session
if ($env:PATH -notmatch [regex]::Escape($BinDir)) {
    $env:PATH = "$BinDir;$env:PATH"
}

Write-Host ""
Write-Host "  ✅ Agentic DevOps Hub Activated!" -ForegroundColor Green
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "  You no longer need to type .\bin\use-agentic-ai.ps1"
Write-Host "  Instead, just type: " -NoNewline
Write-Host "agentic " -ForegroundColor Cyan -NoNewline
Write-Host "or " -NoNewline
Write-Host "hub" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Example: " -NoNewline
Write-Host "agentic `"build me a python script`"" -ForegroundColor Yellow
Write-Host ""
