param(
    [Parameter(Mandatory=$true)][string]$Prompt,
    [string]$Provider = "Antigravity",
    [string]$Model = "llama3",
    [string]$ApiKey = $env:HUB_API_KEY
)

if ($Provider -eq "Antigravity") {
    return agy.exe --print $Prompt --dangerously-skip-permissions
} elseif ($Provider -eq "Ollama") {
    try {
        $body = @{ model = $Model; prompt = $Prompt; stream = $false } | ConvertTo-Json
        $response = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body $body -ContentType "application/json"
        return $response.response
    } catch {
        Write-Error "Ollama connection failed. Ensure Ollama is running locally on port 11434."
        exit 1
    }
} elseif ($Provider -eq "OpenAI" -or $Provider -eq "Groq") {
    $url = if ($Provider -eq "OpenAI") { "https://api.openai.com/v1/chat/completions" } else { "https://api.groq.com/openai/v1/chat/completions" }
    $headers = @{ "Authorization" = "Bearer $ApiKey"; "Content-Type" = "application/json" }
    $body = @{ model = $Model; messages = @(@{role="user"; content=$Prompt}) } | ConvertTo-Json -Depth 10
    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
        return $response.choices[0].message.content
    } catch {
        Write-Error "$Provider API connection failed. Verify your HUB_API_KEY."
        exit 1
    }
} else {
    Write-Error "Unsupported Provider: $Provider. Use Antigravity, Ollama, OpenAI, or Groq."
    exit 1
}
