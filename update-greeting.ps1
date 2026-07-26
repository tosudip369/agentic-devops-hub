$ErrorActionPreference = "Stop"
$HubRoot = "C:\Users\Asus Tuf\agentic-devops-hub"
$BinDir = Join-Path $HubRoot "bin"

Write-Host "1. Making activate.ps1 polite and friendly..."
$activateCode = @"
# activate.ps1 - Environment Activator for Agentic DevOps Hub
`$HubRoot = `$PSScriptRoot
`$BinDir = Join-Path `$HubRoot "bin"

# Set an alias so you can just type 'agentic' anywhere
Set-Alias -Name agentic -Value (Join-Path `$BinDir "use-agentic-ai.ps1") -Scope Global
Set-Alias -Name hub -Value (Join-Path `$BinDir "use-agentic-ai.ps1") -Scope Global

# Add bin to PATH temporarily for this session
if (`$env:PATH -notmatch [regex]::Escape(`$BinDir)) {
    `$env:PATH = "`$BinDir;`$env:PATH"
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
Write-Host "agentic `"Could you please build me a python script?`"" -ForegroundColor Yellow
Write-Host ""
"@
Set-Content (Join-Path $HubRoot "activate.ps1") -Value $activateCode -Encoding UTF8

Write-Host "2. Instructing AI agents to be friendly..."
$cliPath = Join-Path $BinDir "use-agentic-ai.ps1"
$cliCode = Get-Content $cliPath -Raw

$oldRules = "Algo (Strict): 1.Question reqs(make less dumb). 2.Delete parts(>10% added back=good). 3.Simplify/Optimize(after step2). 4.Accelerate cycle. 5.Automate(last)."
$newRules = `$oldRules + "`nPERSONALITY: You must be extremely polite, friendly, helpful, and always address the user respectfully as `"Captain`"."
$cliCode = $cliCode.Replace($oldRules, $newRules)

# Make status greeting friendly
$cliCode = $cliCode.Replace("Write-Host `"  🧠 Agentic DevOps Hub v`$Version         |`" -ForegroundColor Cyan", "Write-Host `"  🧠 Agentic DevOps Hub v`$Version (At your service, Captain) |`" -ForegroundColor Cyan")

Set-Content $cliPath -Value $cliCode -Encoding UTF8
Write-Host "Done."
