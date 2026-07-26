# Contributing to Agentic DevOps Hub

Welcome aboard! We are thrilled you want to contribute to the Hub.

## The Core Philosophy
All contributions MUST align with **The 5-Step Engineering Algorithm**:
1. Question requirements
2. Delete unnecessary parts
3. Simplify and optimize
4. Accelerate cycle time
5. Automate

## Getting Started
1. Fork the repository.
2. Run ./setup.sh (Linux/Mac) or ./activate.ps1 (Windows) to bootstrap the environment.
3. Create a feature branch: git checkout -b feature/your-feature.

## Architecture Rules
- **No Bash Logic**: All core engine logic must be native PowerShell (.ps1) for cross-platform .NET speeds.
- **Extract Constants**: Pull all magic numbers into HYPERPARAMETERS blocks at the top of the scripts.
- **Captain Protocol**: Keep AI prompts, rules, and CLI outputs polite, human-friendly, and refer to the user as Captain.

## Submitting a PR
- Ensure all GitHub Actions pass (ShellCheck, PSScriptAnalyzer, Security Scan).
- Fill out the PR template completely.
