param(
    [Parameter(Mandatory=$true)][string]$Prompt,
    [string]$Provider = "Antigravity",
    [string]$Model = "llama3",
    [string]$ApiKey = $env:HUB_API_KEY,
    [string]$CustomEndpoint = $env:HUB_CUSTOM_ENDPOINT
)

if ($Provider -eq "Antigravity") {
    return agy.exe --print $Prompt --dangerously-skip-permissions
} elseif ($Provider -eq "Ollama") {
    $url = if ($CustomEndpoint) { $CustomEndpoint } else { "http://localhost:11434/api/generate" }
    try {
        $body = @{ model = $Model; prompt = $Prompt; stream = $false } | ConvertTo-Json
        $response = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json"
        return $response.response
    } catch {
        Write-Error "Ollama connection failed. Ensure Ollama is running or CustomEndpoint is correct."
        throw "API Error"
    }
} elseif ($Provider -match "^(OpenAI|Groq|OpenRouter|HuggingFace|Custom)$") {
    $url = switch ($Provider) {
        "OpenAI" { "https://api.openai.com/v1/chat/completions" }
        "Groq" { "https://api.groq.com/openai/v1/chat/completions" }
        "OpenRouter" { "https://openrouter.ai/api/v1/chat/completions" }
        "HuggingFace" { "https://api-inference.huggingface.co/models/$Model/v1/chat/completions" }
        "Custom" { $CustomEndpoint }
    }
    
    if (-not $url) { Write-Error "HUB_CUSTOM_ENDPOINT must be provided for Custom provider."; throw "API Error" }

    $headers = @{ "Authorization" = "Bearer $ApiKey"; "Content-Type" = "application/json" }
    
    # OpenRouter requires specific metadata headers for routing
    if ($Provider -eq "OpenRouter") {
        $headers["HTTP-Referer"] = "https://github.com/tosudip369/agentic-devops-hub"
        $headers["X-Title"] = "Agentic DevOps Hub"
    }

    $body = @{ model = $Model; messages = @(@{role="user"; content=$Prompt}) } | ConvertTo-Json -Depth 10
    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
        if ($response.choices) {
            return $response.choices[0].message.content
        } else {
            return $response | ConvertTo-Json
        }
    } catch {
        Write-Error "$Provider API connection failed. Verify your HUB_API_KEY and endpoint."
        throw "API Error"
    }
} else {
    Write-Error "Unsupported Provider: $Provider."
    throw "API Error"
}


}

if ($Prompt) {
    return Call-Provider $Prompt
}

# --- V17 INTERACTIVE CLI (Claude Code Style) ---
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "🤖 Agentic DevOps Hub Interactive CLI v17" -ForegroundColor Cyan
Write-Host "Type 'exit' to quit. Provider: $Provider" -ForegroundColor DarkGray
Write-Host "==========================================" -ForegroundColor Cyan

$history = ""
$mcpTools = & pwsh -NoProfile -NonInteractive -File $mcpRouterPath -Action list
$sysPrompt = "You are an elite CLI agent. You have access to these MCP tools:
$mcpTools
To use a tool, output exactly: {"mcp_call": "true", "server": "name", "tool": "name", "args": {}}."

while ($true) {
    $input = Read-Host "
❯ "
    if ($input -eq "exit") { break }
    
    $fullPrompt = "$sysPrompt

Chat History:
$history
User: $input"
    Write-Host "Thinking..." -ForegroundColor DarkGray
    
    try {
        $response = Call-Provider $fullPrompt
        
        # Check if the AI wants to use an MCP tool
        if ($response -match '\{"mcp_call":\s*"true"') {
            try {
                $action = $response | ConvertFrom-Json
                Write-Host "🛠️ Executing MCP Tool [Server: $($action.server), Tool: $($action.tool)]..." -ForegroundColor Yellow
                $toolArgs = $action.args | ConvertTo-Json -Compress
                $mcpRes = & pwsh -NoProfile -NonInteractive -File $mcpRouterPath -Action call -ServerName $action.server -ToolName $action.tool -ArgsJson $toolArgs
                
                Write-Host "Result retrieved. Analyzing..." -ForegroundColor DarkGray
                $followUp = "$fullPrompt
AI attempted tool $($action.tool). Result: $mcpRes
Now respond to the user."
                $response = Call-Provider $followUp
            } catch {
                Write-Host "MCP execution failed." -ForegroundColor Red
            }
        }
        
        Write-Host "
$response" -ForegroundColor Green
        $history += "
User: $input
AI: $response"
    } catch {
        Write-Host "Error communicating with AI Provider." -ForegroundColor Red
    }
}
