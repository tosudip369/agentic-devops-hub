# ☠️ Path of Exile (PoE) Minion Swarm Architecture

This file defines the operational behaviors for the autonomous agents (Minions) within the gentic-devops-hub. 

We have evolved past standard agent orchestration into the **Path of Exile Necromancer** paradigm, combined with our **5-Step Engineering Ascendancy**.

## 👑 The Ascendancy (Core Passive Tree)
Every Minion summoned by the Hub automatically inherits the global passive buffs of **The 5-Step Engineering Algorithm**:
1. Question requirements
2. Delete unnecessary parts
3. Simplify and optimize
4. Accelerate cycle time
5. Automate

## 🔮 The Necromancer (The Orchestrator)
- **Role:** in/remediator.ps1
- **Function:** The Necromancer is the central command script. It does not write code. Instead, when an error is detected, it summons a specialized horde of Minions in the background to execute the repairs, coordinating their consensus.

## 💀 The Skeletons (The Surgeons / Developers)
- **Role:** High-DPS, aggressive problem solvers.
- **Function:** The Skeletons are summoned instantly when an error occurs. They are fed the exact stack trace and told to write a highly optimized O(1) patch. They output raw, aggressive code fixes and immediately despawn.

## 🧟 The Zombies (The Gatekeepers / Reviewers)
- **Role:** Heavy, defensive, resilient blockers.
- **Function:** No code written by a Skeleton can touch the disk without passing the Zombies. The Zombies take the proposed fix and subject it to a brutal adversarial review for security flaws and performance leaks. If it fails, they block it and rewrite it.

## 🪨 The Golems (Test Engineers)
- **Role:** System fortification and buffs.
- **Function:** Summoned in parallel with the Skeletons. The Golems write automated Test-Driven Development (TDD) .tests.ps1 suites. They ensure that once a bug is fixed, the system's overall armor (test coverage) permanently increases.

## 👻 The Spectres (Codebase Researchers)
- **Role:** Intelligence gathering (Subagents).
- **Function:** When the Necromancer encounters massive multi-file architectures, it summons Spectres (via invoke_subagent) to scout the entire repository, read documentation, and report back the context before the Skeletons strike.

## 💎 Support Gems (Hyperparameters)
The entire Minion horde is modified by globally tuned "Support Gems" (Hyperparameters) located at the top of the scripts, dictating their speed, token economics, and API limits.
