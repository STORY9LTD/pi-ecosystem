---
name: outloop-runner
description: |
  Run autonomous out-loop agents in the background — Stripe minion style. Fire-and-forget tasks
  that run in parallel without human supervision. Use when you want to launch background agents,
  run multiple tasks simultaneously, or execute blueprints autonomously.
---

# Out-Loop Runner

Launch autonomous background agents. Inspired by Stripe's Minions — prompt and walk away.

## In-Loop vs Out-Loop

- **In-loop:** You're at the terminal, going back and forth. Good for building the agent system. (This session right now)
- **Out-loop:** Agent runs autonomously in background. Good for parallelised task execution. (This skill)

## Quick Start

### Single background task

```bash
~/.pi/agent/scripts/outloop.sh "Add input validation to all API endpoints" --cwd ~/projects/myapp &
```

### Multiple tasks in parallel

```bash
~/.pi/agent/scripts/outloop.sh "Fix login bug" --cwd ~/projects/app &
~/.pi/agent/scripts/outloop.sh "Add dark mode" --cwd ~/projects/app &
~/.pi/agent/scripts/outloop.sh "Write auth tests" --cwd ~/projects/app &
wait
```

### Batch file

Create a `tasks.txt`:
```
Fix the login page validation bug
Add dark mode to settings page
Write tests for the auth module
Refactor the API error handling
```

Run all in parallel:
```bash
~/.pi/agent/scripts/parallel.sh tasks.txt --cwd ~/projects/myapp --max 4
```

### With blueprints

```bash
~/.pi/agent/scripts/outloop.sh "add search feature" --blueprint scout-plan-implement-review --cwd ~/projects/myapp &
```

### With specific agent

```bash
~/.pi/agent/scripts/outloop.sh "find all authentication code" --agent scout --cwd ~/projects/myapp
```

## Options

| Flag | Description |
|------|-------------|
| `--cwd <path>` | Working directory for the agent |
| `--agent <name>` | Use a specific agent (scout, planner, worker, reviewer) |
| `--blueprint <name>` | Run a blueprint (from ~/.pi/agent/blueprints/) |
| `--model <model>` | Override model (e.g., `anthropic/claude-sonnet-4-5`) |
| `--log <file>` | Custom log file path |
| `--max <N>` | Max concurrency for parallel.sh (default: 4) |

## Logs

All runs are logged to `~/.pi/agent/runs/` with timestamps. Check logs:

```bash
ls -lt ~/.pi/agent/runs/ | head -10   # Recent runs
cat ~/.pi/agent/runs/<latest>.log      # Full output
```

## Architecture

```
You (in-loop)
  │
  ├── This session: build the system, review results
  │
  └── Out-loop agents (background):
        ├── Task 1 → pi -p --no-session "task" → log
        ├── Task 2 → pi -p --no-session "task" → log
        ├── Task 3 → pi -p --no-session "task" → log
        └── Task N → pi -p --no-session "task" → log
```

Each out-loop agent runs in its own `pi` process with isolated context. No file conflicts between parallel agents if they work on different files.
