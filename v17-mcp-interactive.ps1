$ErrorActionPreference = "Stop"
$HubRoot = "C:\Users\Asus Tuf\agentic-devops-hub"
$BinDir = Join-Path $HubRoot "bin"

Write-Host "1. Creating mcp_servers.json..."
$mcpConfig = @"
{
  "mcpServers": {
    "sqlite": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sqlite", "--db-path", "hub.db"]
    }
  }
}
"@
Set-Content (Join-Path $HubRoot "mcp_servers.json") -Value $mcpConfig -Encoding UTF8


Write-Host "2. Creating bin/mcp-router.ps1 (The True JSON-RPC Bridge)..."
$mcpRouter = @"
param(
    [string]`$Action = "list", # 'list' or 'call'
    [string]`$ServerName = "",
    [string]`$ToolName = "",
    [string]`$ArgsJson = "{}"
)

`$configFile = Join-Path (Split-Path (Split-Path `$MyInvocation.MyCommand.Path)) "mcp_servers.json"
if (-not (Test-Path `$configFile)) { return "{}" }

`$config = Get-Content `$configFile -Raw | ConvertFrom-Json
if (-not `$config.mcpServers) { return "{}" }

if (`$Action -eq "list") {
    `$allTools = @()
    foreach (`$srv in `$config.mcpServers.PSObject.Properties) {
        `$srvName = `$srv.Name
        `$cmd = `$srv.Value.command
        `$argsArray = `$srv.Value.args
        
        try {
            `$psi = New-Object System.Diagnostics.ProcessStartInfo
            `$psi.FileName = `$cmd
            `$psi.Arguments = `$argsArray -join " "
            `$psi.RedirectStandardInput = `$true
            `$psi.RedirectStandardOutput = `$true
            `$psi.UseShellExecute = `$false
            `$psi.CreateNoWindow = `$true
            `$p = [System.Diagnostics.Process]::Start(`$psi)
            
            # 1. Initialize
            `$initMsg = '{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {"name": "AgenticHub", "version": "1.0"}}}'
            `$p.StandardInput.WriteLine(`$initMsg)
            `$initResp = `$p.StandardOutput.ReadLine()
            
            # 2. tools/list
            `$listMsg = '{"jsonrpc": "2.0", "id": 2, "method": "tools/list"}'
            `$p.StandardInput.WriteLine(`$listMsg)
            `$listResp = `$p.StandardOutput.ReadLine() | ConvertFrom-Json
            
            if (`$listResp.result.tools) {
                foreach (`$t in `$listResp.result.tools) {
                    `$t | Add-Member -MemberType NoteProperty -Name "mcp_server" -Value `$srvName
                    `$allTools += `$t
                }
            }
            `$p.Kill()
        } catch {
            Write-Host "Failed to connect to MCP Server: `$srvName" -ForegroundColor Red
        }
    }
    return (`$allTools | ConvertTo-Json -Depth 10)
}

if (`$Action -eq "call" -and `$ServerName -and `$ToolName) {
    `$srv = `$config.mcpServers.`$ServerName
    if (-not `$srv) { return "Server not found" }
    
    try {
        `$psi = New-Object System.Diagnostics.ProcessStartInfo
        `$psi.FileName = `$srv.command
        `$psi.Arguments = `$srv.args -join " "
        `$psi.RedirectStandardInput = `$true
        `$psi.RedirectStandardOutput = `$true
        `$psi.UseShellExecute = `$false
        `$psi.CreateNoWindow = `$true
        `$p = [System.Diagnostics.Process]::Start(`$psi)
        
        `$initMsg = '{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {"name": "AgenticHub", "version": "1.0"}}}'
        `$p.StandardInput.WriteLine(`$initMsg)
        `$initResp = `$p.StandardOutput.ReadLine()
        
        `$callMsg = @{
            jsonrpc = "2.0"
            id = 2
            method = "tools/call"
            params = @{
                name = `$ToolName
                arguments = (`$ArgsJson | ConvertFrom-Json)
            }
        } | ConvertTo-Json -Depth 10 -Compress
        
        `$p.StandardInput.WriteLine(`$callMsg)
        `$callResp = `$p.StandardOutput.ReadLine() | ConvertFrom-Json
        
        `$p.Kill()
        return (`$callResp.result.content[0].text)
    } catch {
        return "Tool execution failed."
    }
}
"@
Set-Content (Join-Path $BinDir "mcp-router.ps1") -Value $mcpRouter -Encoding UTF8


Write-Host "3. Updating use-agentic-ai.ps1 to act as an Interactive CLI (Like Claude Code)..."
$aiCliPath = Join-Path $BinDir "use-agentic-ai.ps1"
$aiCliCode = Get-Content $aiCliPath -Raw

# We will wrap the existing CLI in an interactive loop if no prompt is provided.
$interactiveWrapper = @"
param(
    [string]`$Prompt = "",
    [string]`$Provider = "Antigravity",
    [string]`$Model = "llama3",
    [string]`$ApiKey = `$env:HUB_API_KEY,
    [string]`$CustomEndpoint = `$env:HUB_CUSTOM_ENDPOINT
)

`$mcpRouterPath = Join-Path (Split-Path `$MyInvocation.MyCommand.Path) "mcp-router.ps1"

function Call-Provider(`$text) {
    # ... [Existing routing logic will go here] ...
"@

$aiCliCode = $aiCliCode -replace 'param\([\s\S]*?CustomEndpoint\r?\n\)', $interactiveWrapper
$aiCliCode = $aiCliCode -replace 'if \(\$Provider -eq "Antigravity"\)', 'if ($Provider -eq "Antigravity")'
$aiCliCode = $aiCliCode -replace 'exit 1', 'throw "API Error"'
$aiCliCode = $aiCliCode -replace 'return \$response\.choices\[0\]\.message\.content', 'return $response.choices[0].message.content'

$interactiveTail = @"
}

if (`$Prompt) {
    return Call-Provider `$Prompt
}

# --- V17 INTERACTIVE CLI (Claude Code Style) ---
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "🤖 Agentic DevOps Hub Interactive CLI v17" -ForegroundColor Cyan
Write-Host "Type 'exit' to quit. Provider: `$Provider" -ForegroundColor DarkGray
Write-Host "==========================================" -ForegroundColor Cyan

`$history = ""
`$mcpTools = & pwsh -NoProfile -NonInteractive -File `$mcpRouterPath -Action list
`$sysPrompt = "You are an elite CLI agent. You have access to these MCP tools:`n`$mcpTools`nTo use a tool, output exactly: {`"mcp_call`": `"true`", `"server`": `"name`", `"tool`": `"name`", `"args`": {}}."

while (`$true) {
    `$input = Read-Host "`n❯ "
    if (`$input -eq "exit") { break }
    
    `$fullPrompt = "`$sysPrompt`n`nChat History:`n`$history`nUser: `$input"
    Write-Host "Thinking..." -ForegroundColor DarkGray
    
    try {
        `$response = Call-Provider `$fullPrompt
        
        # Check if the AI wants to use an MCP tool
        if (`$response -match '\{"mcp_call":\s*"true"') {
            try {
                `$action = `$response | ConvertFrom-Json
                Write-Host "🛠️ Executing MCP Tool [Server: `$(`$action.server), Tool: `$(`$action.tool)]..." -ForegroundColor Yellow
                `$toolArgs = `$action.args | ConvertTo-Json -Compress
                `$mcpRes = & pwsh -NoProfile -NonInteractive -File `$mcpRouterPath -Action call -ServerName `$action.server -ToolName `$action.tool -ArgsJson `$toolArgs
                
                Write-Host "Result retrieved. Analyzing..." -ForegroundColor DarkGray
                `$followUp = "`$fullPrompt`nAI attempted tool `$(`$action.tool). Result: `$mcpRes`nNow respond to the user."
                `$response = Call-Provider `$followUp
            } catch {
                Write-Host "MCP execution failed." -ForegroundColor Red
            }
        }
        
        Write-Host "`n`$response" -ForegroundColor Green
        `$history += "`nUser: `$input`nAI: `$response"
    } catch {
        Write-Host "Error communicating with AI Provider." -ForegroundColor Red
    }
}
"@
$aiCliCode = $aiCliCode + "`n" + $interactiveTail
Set-Content $aiCliPath -Value $aiCliCode -Encoding UTF8


Write-Host "4. Updating remediator.ps1 to use true MCP Router..."
$remPath = Join-Path $BinDir "remediator.ps1"
$remCode = Get-Content $remPath -Raw
$remCode = $remCode -replace '`$mcpDir = Join-Path.*?if \(Test-Path \$mcpDir\) \{[\s\S]*?\}', "`$mcpTools = & pwsh -NoProfile -NonInteractive -File (Join-Path (Split-Path `$MyInvocation.MyCommand.Path) 'mcp-router.ps1') -Action list`n    if (`$mcpTools -ne '{}') { `$mcpContext = `"You are connected to TRUE JSON-RPC MCP Servers. Tools:`n`$mcpTools`" }"
$remCode = $remCode -replace 'if \(\$action\.action -eq ''mcp_tool''\) \{[\s\S]*?\} elseif', "if (`$action.action -eq 'mcp_tool') {`n                        Write-Host `"   -> 🔌 True MCP Tool Triggered: `$(`$action.server) / `$(`$action.tool)`" -ForegroundColor Yellow`n                        `$mcpTriggered = `$true`n                        `$toolArgs = `$action.args | ConvertTo-Json -Compress`n                        `$mcpResult = & pwsh -NoProfile -NonInteractive -File (Join-Path (Split-Path `$MyInvocation.MyCommand.Path) 'mcp-router.ps1') -Action call -ServerName `$action.server -ToolName `$action.tool -ArgsJson `$toolArgs`n                        `$devPrompt += `"`n`nMCP Tool Result: `$mcpResult`nGenerate final JSON.`"`n                    } elseif"
Set-Content $remPath -Value $remCode -Encoding UTF8


Write-Host "5. Committing and Pushing..."
git add .
git commit -m "feat: release v17.0.0 True JSON-RPC MCP Client (Claude Code style Interactive CLI)"
git push origin main
Write-Host "✅ V17 MCP Client & Interactive CLI updated."
