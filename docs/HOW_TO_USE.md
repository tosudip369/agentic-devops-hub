# How to Use the Agentic DevOps Hub

This guide tells you exactly what commands to type to start using the Hub right now, whether you want full background autonomy or manual control via the Antigravity CLI.

## 1. The Autonomous "Hands-Free" Mode
If you want the Hub to watch your code and fix bugs automatically while you sleep or work, you start the **Observer**.

**In your terminal, run:**
```bash
# From inside the agentic-devops-hub directory
bash bin/observer.sh --start
```
*What happens:* It runs continuously in the background. If it detects a syntax error or a failing test in your watched projects, it automatically spawns `remediate.sh` in an isolated branch to fix it.

## 2. Manual Trigger via Antigravity CLI (`agy`)
If you don't want the background watchdog, but you just encountered an error in your project and want to invoke the Hub's "Neural Remediator" instantly, use the Antigravity CLI.

**To trigger a surgical fix via the Hub's remediation script:**
```bash
# From inside the agentic-devops-hub directory
bash bin/remediate.sh "/path/to/your/broken/project/file.py"
```
*What happens:* It branches your code, runs the `agy` agent to fix it using strict ClearCode rules, and prepares a Pull Request.

**To use Antigravity directly in your project folder:**
If you just want the agent to fix your current directory using standard Antigravity commands, simply navigate to your broken project and type:
```bash
agy "Fix the syntax errors and failing tests in this directory. Review the logs, apply the fix, and do not break O(1) complexity."
```

## 3. How to Connect a New Project
To tell the Hub to watch a brand new project (a new app, software, or script):
1. Open `bin/observer.sh`.
2. Add your new project's absolute path to the monitoring list (e.g., `/Users/you/workspace/my-new-app`).
3. Ensure your new project has tests and a linter.
4. Restart `bash bin/observer.sh --start`.

You are now running a God-Level orchestration hub!

## 4. The Magic Keyword: `use-agentic-ai`
To strictly enforce this entire architecture across any project without manually setting up the scripts every time, use the universal keyword **`use-agentic-ai`** in your prompts or IDEs.

Whenever you type:
> *"use-agentic-ai to build this feature"* or *"use-agentic-ai to fix this bug"*

Your AI tools (like Antigravity CLI, VS Code, or Claude Code) are instructed to **strictly** adhere to the Agentic DevOps Hub blueprint:
1. They must use the Neural Error Memory to avoid past mistakes.
2. They must enforce "ClearCode" rules (O(1) lookups, zero deep nesting, one-thing functions).
3. They must branch their work ephemerally (like `treehouse`).
4. They must prepare the code for the strict `no-mistakes` validation pipeline.

**How to use it today:** 
Just add `use-agentic-ai` at the beginning or end of your prompt in the Antigravity CLI or IDE. The system knows exactly what architectural standards to apply.
