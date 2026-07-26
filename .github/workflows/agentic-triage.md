---
name: "Agentic Issue Triage & Self-Healing"
on:
  issues:
    types: [opened, edited]
  workflow_dispatch:
safe_outputs:
  - issue_comment
  - add_label
---

# Agentic DevOps Triage Workflow

This is a `gh-aw` (GitHub Agentic Workflows) natural language pipeline. When compiled using `gh aw compile`, it generates a locked, secure GitHub Actions YAML file.

## Goal
Act as a first-responder for any new issues opened in the repository. Provide autonomous triage, labeling, and integration with our local `firstmate` execution fleet.

## Steps

1. **Understand the Issue**: Read the issue title and body.
2. **Determine Severity & Type**:
   - If the issue contains stack traces or errors, label it as `bug` and `needs-reproduction`.
   - If it mentions infrastructure, cloud, or deployments, label it `devops`.
   - Otherwise, label it `enhancement`.
3. **Formulate a Plan**:
   - Write a comment on the issue acknowledging receipt.
   - If it's a bug, suggest a high-level root cause hypothesis.
4. **Trigger Local Fleet (Optional/Conceptual)**:
   - Comment with a `/firstmate scout` command. This signals our local `all-seeing` watcher to pick up the issue, spawn a `treehouse` worktree, and assign an agent to attempt a fix overnight via `gnhf`.

## Constraints
- Do not close the issue.
- Keep the tone helpful, nautical, and robotic.


