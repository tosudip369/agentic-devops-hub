# How to Use the Agentic DevOps Hub v3.0

This guide tells you exactly what commands to type to start using the Hub right now. With v3.0, everything revolves around the Universal Builder script.

## The Magic Wrapper: `use-agentic-ai.ps1`

You no longer need to call individual bash scripts. Use the PowerShell wrapper from anywhere in your workspace.

### 1. Auto-Remediation Mode (The True Autonomy)
If you just pulled code that is broken, or want to clean up an entire repository instantly:

```powershell
.\bin\use-agentic-ai.ps1 -Mode auto
```
**What happens:** 
1. It scans your current directory for Bash, Python, or JSON errors.
2. For each error, it queries the **Neural Memory Engine**.
3. It spawns the best available local agent (`agy`, `claude`, `codex`, `ollama`) to fix the file in an isolated branch.
4. It locally validates the fix and commits it automatically.
5. It exits gracefully when all errors are resolved.

### 2. Manual Build / Fix Modes
To command the AI while enforcing the **God-Level Rules** (Elon Musk's 5-Step Algorithm, ClearCode, Ephemeral Branches, and Subagent Delegation):

```powershell
# Build a new feature
.\bin\use-agentic-ai.ps1 "Build me a new REST API for the user authentication flow."

# Surgically fix a specific bug without refactoring unrelated code
.\bin\use-agentic-ai.ps1 -Mode fix "Fix the auth token expiry bug in middleware.ts"
```
**What happens:** The script dynamically injects your Git status, your GitHub Remote URL, and any `SPEC.md` rules into the prompt before passing it to the AI, giving it total context.

### 3. The Continuous Watchdog Mode
If you want the Hub to guard your projects in the background while you sleep or work:

```powershell
.\bin\use-agentic-ai.ps1 -Mode observe
```
**What happens:** It runs continuously. It checks every directory listed in `projects.conf`. If it detects an error, it spawns a remediation agent automatically in the background.

### 4. Status Dashboard
To check the health of your Agentic Hub:

```powershell
.\bin\use-agentic-ai.ps1 -Mode status
```
**What happens:** Displays your active Git branch, detected AI agents, the number of successful fixes stored in Neural Memory, and the number of projects currently monitored.

## Connecting New Projects
To tell the continuous Watchdog to monitor a brand new project:
1. Open `projects.conf`.
2. Add your new project's absolute path on a new line (e.g., `C:\Users\you\workspace\my-new-app`).
3. Run `.\bin\use-agentic-ai.ps1 -Mode observe`.

## The Elon Musk 5-Step Algorithm (Under the Hood)
Whenever you run this tool, the AI is literally forced to obey this sequence before writing code:
1. Question requirements.
2. Delete unnecessary parts.
3. Simplify and optimize.
4. Accelerate cycle time.
5. Automate.

You are now running a God-Level orchestration hub!
