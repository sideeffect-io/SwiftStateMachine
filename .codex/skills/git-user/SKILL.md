---
name: git-user
description: Step-by-step guidance for maintaining the Git workflow with rebases, feature branches, and fast-forward merges.
---

# Git Workflow Guide

## When to use
Trigger this skill when creating or merging branches, writing commit instructions, or defining CI checks.

## Steps
0. Use the Git CLI
1. Branch from `main`: `feature/<topic>`
2. Rebase often: `git fetch && git rebase origin/main`
3. Resolve conflicts locally
4. Merge with fast-forward: `git merge --ff-only`

## Branch naming

- `feature/<topic>` for a brand new feature
- `fix/<topic>` for a bug fix
- `chores/<topic>` for projet cleaning, doc generation, global house work

## Commit style
- Imperative verbs (“add…”, “fix…”)
- Small atomic changes

## Why
- Clean linear history
- Effective `git bisect` and blame

## Common pitfalls
- Don’t merge with merge commits
- Rebase before review