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
Write-Host "  Welcome aboard, Captain! 🫡" -ForegroundColor Green
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "  The Agentic DevOps Hub is activated and at your service."
Write-Host "  Please feel free to just type: " -NoNewline
Write-Host "agentic " -ForegroundColor Cyan -NoNewline
Write-Host "or " -NoNewline
Write-Host "hub" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Example: " -NoNewline
Write-Host "agentic "Could you please build me a python script?"" -ForegroundColor Yellow
Write-Host ""
