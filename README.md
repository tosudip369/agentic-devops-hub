# 👁️ All-Seeing Agentic DevOps Hub

Welcome to your unified control plane. This hub synthesizes the principles of **GitHub Agentic Workflows (`gh-aw`)**, **Autonomous DevOps (`agenticsorg/devops`)**, and **Agentic Gen-AI** into a single, all-seeing ecosystem that orchestrates your existing tools (`firstmate`, `gnhf`, `treehouse`, `no-mistakes`).

## 🏗️ Architecture: The All-Seeing Setup

This setup transforms your workspace into a self-healing, autonomous software factory.

```mermaid
graph TD
    subgraph "Cloud / GitHub (gh-aw)"
        GH_AW[gh-aw Markdown Workflows]
        GH_AW --> |Triage & Review| Issues
        GH_AW --> |Security/Lint| PRs
    end

    subgraph "All-Seeing Hub (Control Plane)"
        Observer[DevOps Observer / Self-Healing Loop]
        Agentics[Agentics DevOps Patterns]
        Observer --> |Monitors Health| Infrastructure
    end

    subgraph "Local Execution Fleet"
        FirstMate[firstmate (Crew Orchestrator)]
        GNHF[gnhf (Overnight Loop)]
        Treehouse[treehouse (Worktree Pool)]
        NoMistakes[no-mistakes (Quality Gate)]
    end

    GH_AW -.-> |Dispatches Tasks| FirstMate
    Observer -.-> |Triggers Remediation| FirstMate
    FirstMate --> |Spawns Crew| Treehouse
    FirstMate --> |Overnight Fixes| GNHF
    Treehouse --> |Commits| NoMistakes
    NoMistakes --> |Clean PRs| GH_AW
```

## 🚀 Key Components

1. **Natural Language Workflows (`.github/workflows/agentic-triage.md`)**
   - Writing CI/CD automation in plain English (via `gh-aw`). 
   - These compile to secure, deterministic Actions.

2. **Self-Healing DevOps Loop (`bin/observer.sh`)**
   - An always-on watcher that monitors system health.
   - When something breaks, it doesn't page you; it pages `firstmate` to dispatch a crewmate to fix it.

3. **Fleet Orchestration (`firstmate` + `treehouse`)**
   - Multi-agent concurrency. Work gets done in parallel isolated worktrees.

## 🛠️ Getting Started

### 1. Install `gh-aw`
To enable natural language workflows on your GitHub repos:
```bash
gh extension install github/gh-aw
# Compile your markdown workflows to locked YAML
gh aw compile
```

### 2. Start the All-Seeing Observer
Run the local DevOps self-healing loop:
```bash
./bin/observer.sh --start
```

### 3. Dispatch a Crew
Talk to your first mate to initiate an infrastructure audit or feature build:
```bash
firstmate "Audit all projects for security vulnerabilities and raise PRs via no-mistakes"
```
