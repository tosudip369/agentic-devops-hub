# 📖 How To Use Guide (v16.0.0)

Welcome to the Agentic DevOps Hub manual. This framework transforms your local machine into an autonomous, self-healing software factory.

## 1. Installation & Setup
1. Clone the repository to your machine.
2. Run .\activate.ps1 to globally register the gentic alias in your terminal.
3. Configure your AI Provider by setting an environment variable in your profile (e.g., $PROFILE):
   `powershell
   # Choose your provider (Ollama, OpenAI, Groq, OpenRouter, HuggingFace, Custom, Antigravity)
   $env:HUB_AI_PROVIDER="Ollama" 
   
   # Required if not using Ollama or Antigravity
   $env:HUB_API_KEY="your-api-key"
   `

## 2. Using The Hub
Navigate to *any* project on your computer (it doesn't have to be inside the Hub folder) and use the CLI:

### 🛠️ Manual Interventions
- **Generate Code**: gentic "Build a Node.js express server with JWT auth"
- **Targeted Surgery**: gentic -Mode fix "Fix the database race condition"

### 🤖 Autonomous Modes
- **Watchdog Mode**: gentic -Mode observe
  - *What it does*: Runs silently in the background. If you save a file that causes a syntax error or a test failure, the Hub instantly detects it and patches it.
- **Auto-Sweep**: gentic -Mode auto
  - *What it does*: Scans the entire project for structural flaws, memory leaks, or missing tests, and dispatches Swarm agents to rewrite the flawed files.

## 3. Extending the Brain (Model Context Protocol)
You can teach the Swarm new skills by adding .json files to the .hub_mcp/ directory.
For example, if you add a database_query.json tool schema, the AI will dynamically use that tool in a multi-turn conversation before it applies file patches.
