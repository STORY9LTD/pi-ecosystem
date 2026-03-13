---
name: blueprint-engine
description: |
  Define and run workflows that interleave deterministic code steps (bash commands, linters,
  tests, git operations) with agent reasoning steps (implement, review, fix). The core idea:
  use code for everything predictable, use agents for everything that needs judgement. This
  combination beats either approach alone. Usage: /skill:blueprint-engine run <blueprint-name>
---

# Blueprint Engine

Orchestrate workflows that combine deterministic code steps with agent reasoning steps.

## Why Blueprints?

Pure agent workflows are creative but unpredictable — they might skip the lint step, forget
to run tests, or commit before checking types. Pure code workflows are predictable but rigid —
they can't handle "implement this feature" or "review this code."

Blueprints give you both: **code for the predictable parts, agents for the creative parts.**
Linting is always the same command. Implementing a feature always requires judgement. A
blueprint knows the difference and uses the right tool for each step.

## How It Works

You (the orchestrating agent) read a YAML blueprint file and execute each step in order.
This is not a separate runtime — **you are the engine.** You read the YAML, run the bash
commands, spawn the agents, track the outputs, and handle failures.

## Blueprint Format

Blueprints live in `~/.pi/agent/blueprints/` or `.pi/blueprints/` (project-level).

Each step is one of three types:

| Type | What it does | When to use |
|------|-------------|-------------|
| `code` | Runs a bash command. Fast, predictable, cheap. | Git, lint, test, build, deploy |
| `agent` | Delegates to a subagent for reasoning. Creative, adaptive. | Implement, review, fix, plan |
| `gate` | Checks a condition. Stops or redirects on failure. | Quality checkpoints |

### YAML Structure

```yaml
name: implement-and-review
description: Implement a task with quality checks
args:
  - name: task
    description: What to implement
    required: true

steps:
  - name: implement
    type: agent
    agent: worker
    task: "Implement: {args.task}"

  - name: lint
    type: code
    command: npm run lint 2>&1
    on_fail: fix-lint        # Jump to this step on failure

  - name: fix-lint
    type: agent
    agent: worker
    task: "Fix these lint errors:\n{step.lint.output}"
    skip_unless: step.lint.failed  # Only runs if lint failed

  - name: typecheck
    type: code
    command: npx tsc --noEmit 2>&1

  - name: review
    type: agent
    agent: reviewer
    task: "Review changes. Context: {args.task}"

  - name: review-gate
    type: gate
    condition: "!step.review.output.includes('Critical')"
    on_fail: fix-review
```

### Reference Syntax

- `{args.X}` — Input parameters from the user
- `{step.name.output}` — Stdout/output from a previous step
- `{step.name.failed}` — Boolean: did the step fail?

## Executing a Blueprint

### For `code` steps:
1. Run the command with bash
2. Capture stdout/stderr as `step.<name>.output`
3. Track `step.<name>.failed` (true if exit code ≠ 0)
4. On failure: jump to `on_fail` step if set, retry if `max_retries` set, stop if neither
5. If `allow_fail: true`, continue regardless

### For `agent` steps:
1. Check `skip_unless` — if the condition is false, skip
2. Spawn the named agent via the subagent tool
3. Capture the agent's response as `step.<name>.output`

### For `gate` steps:
1. Evaluate the condition against known step outputs
2. If false → mark failed, trigger `on_fail` if set, otherwise stop the blueprint

### Error Handling

Blueprints should fail fast and fail clearly:

| Situation | Behaviour |
|-----------|----------|
| Code step fails, no `on_fail` | Stop blueprint, report which step failed and the output |
| Code step fails, has `on_fail` | Jump to the recovery step |
| Code step fails after `max_retries` | Stop blueprint |
| Agent step returns empty/error | Stop blueprint — don't retry agent steps silently |
| Gate fails, no `on_fail` | Stop blueprint |
| Step references nonexistent step output | Stop blueprint with a clear error message |

## Report

After completion (or failure), produce a report that covers **what** was done AND **why**.
The reader hasn't seen the agent outputs — your report is the only record of the run.

```
Blueprint: {name}
Status: {completed | stopped at step X | failed}

Steps:
| # | Name | Type | Status | Duration |
|---|------|------|--------|----------|
| 1 | implement | agent | ✓ | 45s |
| 2 | lint | code | ✗→fix | 2s |
| 3 | fix-lint | agent | ✓ | 12s |
| ... | ... | ... | ... | ... |
```

### Agent Reasoning (IMPORTANT)

Include a condensed version of what each agent found/decided. This is the "why" —
without it the report is just a list of files with no context. Keep each to 3-5 lines max.

```
### Scout Findings
{Condensed summary of what the scout found — the key files, the root cause, relevant patterns}

### Planner's Approach
{Why this approach was chosen — the key decisions and trade-offs in the plan}

### Review Verdict
{Reviewer's assessment — what's good, any concerns, approval status}
```

### Changes Delivered
```
Files changed, what each does, key improvements, testing notes.
```

This matters because sandbox runs are fire-and-forget — the user comes back hours later
and needs to understand not just WHAT was built but WHY those decisions were made.

## Finding Blueprints

```bash
ls ~/.pi/agent/blueprints/ 2>/dev/null
ls .pi/blueprints/ 2>/dev/null
```

If the user asks for a blueprint that doesn't exist, you can create one —
save it to `~/.pi/agent/blueprints/<name>.yaml` and then execute it.
