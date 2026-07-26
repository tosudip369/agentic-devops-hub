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
        exit 1
    }
} elseif ($Provider -match "^(OpenAI|Groq|OpenRouter|HuggingFace|Custom)$") {
    $url = switch ($Provider) {
        "OpenAI" { "https://api.openai.com/v1/chat/completions" }
        "Groq" { "https://api.groq.com/openai/v1/chat/completions" }
        "OpenRouter" { "https://openrouter.ai/api/v1/chat/completions" }
        "HuggingFace" { "https://api-inference.huggingface.co/models/$Model/v1/chat/completions" }
        "Custom" { $CustomEndpoint }
    }
    
    if (-not $url) { Write-Error "HUB_CUSTOM_ENDPOINT must be provided for Custom provider."; exit 1 }

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
        exit 1
    }
} else {
    Write-Error "Unsupported Provider: $Provider."
    exit 1
}
