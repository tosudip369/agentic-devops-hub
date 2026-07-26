param(
    [string]$Action = "list", # 'list' or 'call'
    [string]$ServerName = "",
    [string]$ToolName = "",
    [string]$ArgsJson = "{}"
)

$configFile = Join-Path (Split-Path (Split-Path $MyInvocation.MyCommand.Path)) "mcp_servers.json"
if (-not (Test-Path $configFile)) { return "{}" }

$config = Get-Content $configFile -Raw | ConvertFrom-Json
if (-not $config.mcpServers) { return "{}" }

if ($Action -eq "list") {
    $allTools = @()
    foreach ($srv in $config.mcpServers.PSObject.Properties) {
        $srvName = $srv.Name
        $cmd = $srv.Value.command
        $argsArray = $srv.Value.args
        
        try {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $cmd
            $psi.Arguments = $argsArray -join " "
            $psi.RedirectStandardInput = $true
            $psi.RedirectStandardOutput = $true
            $psi.UseShellExecute = $false
            $psi.CreateNoWindow = $true
            $p = [System.Diagnostics.Process]::Start($psi)
            
            # 1. Initialize
            $initMsg = '{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {"name": "AgenticHub", "version": "1.0"}}}'
            $p.StandardInput.WriteLine($initMsg)
            $initResp = $p.StandardOutput.ReadLine()
            
            # 2. tools/list
            $listMsg = '{"jsonrpc": "2.0", "id": 2, "method": "tools/list"}'
            $p.StandardInput.WriteLine($listMsg)
            $listResp = $p.StandardOutput.ReadLine() | ConvertFrom-Json
            
            if ($listResp.result.tools) {
                foreach ($t in $listResp.result.tools) {
                    $t | Add-Member -MemberType NoteProperty -Name "mcp_server" -Value $srvName
                    $allTools += $t
                }
            }
            $p.Kill()
        } catch {
            Write-Host "Failed to connect to MCP Server: $srvName" -ForegroundColor Red
        }
    }
    return ($allTools | ConvertTo-Json -Depth 10)
}

if ($Action -eq "call" -and $ServerName -and $ToolName) {
    $srv = $config.mcpServers.$ServerName
    if (-not $srv) { return "Server not found" }
    
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $srv.command
        $psi.Arguments = $srv.args -join " "
        $psi.RedirectStandardInput = $true
        $psi.RedirectStandardOutput = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $p = [System.Diagnostics.Process]::Start($psi)
        
        $initMsg = '{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {"name": "AgenticHub", "version": "1.0"}}}'
        $p.StandardInput.WriteLine($initMsg)
        $initResp = $p.StandardOutput.ReadLine()
        
        $callMsg = @{
            jsonrpc = "2.0"
            id = 2
            method = "tools/call"
            params = @{
                name = $ToolName
                arguments = ($ArgsJson | ConvertFrom-Json)
            }
        } | ConvertTo-Json -Depth 10 -Compress
        
        $p.StandardInput.WriteLine($callMsg)
        $callResp = $p.StandardOutput.ReadLine() | ConvertFrom-Json
        
        $p.Kill()
        return ($callResp.result.content[0].text)
    } catch {
        return "Tool execution failed."
    }
}
