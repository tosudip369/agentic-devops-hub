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
