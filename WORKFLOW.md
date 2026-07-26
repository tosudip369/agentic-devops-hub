# Agentic Engineering Workflow & Core Tool Stack

This document outlines the core tool stack and the roadmap for maintaining a god-level agentic engineering workflow.

## The Core Tool Stack

- **Environment & Navigation**: **WezTerm** (terminal emulator) used with **tmux** (session multiplexing) and **Neovim** (code editor) to keep the workflow entirely keyboard-driven.
- **Agent Harnesses**: **Claude Code** is the primary driver, but the workflow is agent-agnostic, supporting others like **Codeex CLI**, **PI**, and **OpenCode**.
- **Input & Planning**: **OpenSuperWhisper** for high-speed voice-to-text input, and **Lavish AXI** for creating interactive, project-aligned HTML artifacts to plan complex features visually.
- **Validation & Pipeline**: **no-mistakes** is critical; it automates adversarial code reviews, end-to-end testing, and documentation updates.
- **Parallelization**: **treehouse** manages ephemeral git worktrees to prevent context conflicts when running multiple agents.
- **Management**: **good-night-have-fun** for long-running, autonomous tasks and **firstmate** to orchestrate multiple agent sessions as a single cohesive unit.

## Workflow Roadmap

1. **Assembly (The Ship)**: Establish a terminal-centric workspace (WezTerm/tmux/Neovim) to minimize context switching and keep hands on the keyboard.
2. **Onboarding (Memory & Skills)**: Configure `AGENTS.md` (global/project-level) for consistent rules and use `npx skills` to provide agents with modular, token-efficient knowledge.
3. **Planning (The Blueprint)**: Instead of wall-of-text prompts, use **Lavish AXI** to generate interactive visual artifacts to refine requirements before writing code.
4. **Implementation & Validation (The Pipeline)**: Delegate execution to agents and pipe the output into `no-mistakes`. This automated pipeline ensures quality, tests against the original intent, and manages PR lifecycle so the captain (you) only steps in for high-level judgment.
5. **Scaling (The Captain's Mindset)**: As volume increases, utilize `treehouse` for parallel worktrees and `firstmate` to oversee multiple concurrent agents, shifting your focus from "writing code" to "product strategy".

