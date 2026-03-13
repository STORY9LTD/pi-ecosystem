---
name: blueprint-engine
description: |
  Stripe-inspired blueprint engine for pi. Defines workflows that interleave deterministic code steps
  (bash commands, linters, tests, git operations) with agent reasoning steps (implement, review, fix).
  Agents + code beats agents alone. Use when orchestrating multi-step tasks that mix automation with intelligence.
  Usage: /skill:blueprint-engine run <blueprint-name> [args] or /skill:blueprint-engine list
---

# Blueprint Engine

Orchestrate workflows that combine deterministic code steps with agent reasoning steps.
Inspired by Stripe's Minions blueprint system: **agents + code > agents alone > code alone.**

## Concepts

A **blueprint** is a YAML file defining a sequence of steps. Each step is either:

- **`code`** — Runs a bash command deterministically. No LLM involved. Fast, predictable, cheap.
- **`agent`** — Delegates to an agent (subagent or main session) for reasoning. Creative, adaptive, expensive.
- **`gate`** — A conditional check. If it fails, the blueprint stops or retries.

Steps can reference outputs from previous steps using `{step.name}` placeholders.

## Blueprint File Format

Blueprints live in `~/.pi/agent/blueprints/` or `.pi/blueprints/` (project-level).

```yaml
name: implement-and-deploy
description: Full cycle - implement, lint, test, review, commit, deploy
args:
  - name: task
    description: What to implement
    required: true
  - name: branch
    description: Git branch name
    default: feature/auto

steps:
  # Deterministic: create branch
  - name: create-branch
    type: code
    command: git checkout -b {args.branch}
    allow_fail: true

  # Agent: implement the task
  - name: implement
    type: agent
    agent: worker
    task: |
      Implement the following task:
      {args.task}

      Follow all project conventions. Do NOT commit.

  # Deterministic: lint
  - name: lint
    type: code
    command: npm run lint 2>&1
    on_fail: fix-lint

  # Agent: fix lint errors (only runs if lint failed)
  - name: fix-lint
    type: agent
    agent: worker
    task: |
      Fix these lint errors. Do NOT change functionality:
      {step.lint.output}
    skip_unless: step.lint.failed

  # Deterministic: type check
  - name: typecheck
    type: code
    command: npx tsc --noEmit 2>&1

  # Deterministic: test
  - name: test
    type: code
    command: npm test 2>&1
    on_fail: fix-tests
    max_retries: 2

  # Agent: fix test failures
  - name: fix-tests
    type: agent
    agent: worker
    task: |
      Fix these test failures without changing test expectations:
      {step.test.output}
    skip_unless: step.test.failed

  # Agent: code review
  - name: review
    type: agent
    agent: reviewer
    task: |
      Review all uncommitted changes. Context: {args.task}
      {step.implement.output}

  # Gate: check review passed
  - name: review-gate
    type: gate
    condition: "!step.review.output.includes('Critical')"
    on_fail: fix-review

  # Agent: fix critical review findings
  - name: fix-review
    type: agent
    agent: worker
    task: |
      Fix ONLY the Critical findings from this code review:
      {step.review.output}
    skip_unless: step.review-gate.failed

  # Deterministic: commit and push
  - name: commit
    type: code
    command: |
      git add -A
      git commit -m "feat: {args.task}"
      git push origin {args.branch}

  # Deterministic: create PR
  - name: create-pr
    type: code
    command: |
      gh pr create --title "feat: {args.task}" --body "Automated by blueprint engine" --head {args.branch}
```

## How to Use

### Step 1: Check for existing blueprints

```bash
ls ~/.pi/agent/blueprints/ 2>/dev/null
ls .pi/blueprints/ 2>/dev/null
```

If none exist, create the directories:

```bash
mkdir -p ~/.pi/agent/blueprints
```

### Step 2: Run a blueprint

To run a blueprint, read the YAML file, then execute each step in order:

**For `code` steps:**
- Run the command directly with `bash`
- Capture stdout/stderr as `step.<name>.output`
- Track `step.<name>.failed` (true if exit code != 0)
- If `on_fail` is set, jump to that step on failure
- If `max_retries` is set, retry the step that many times before failing
- If `allow_fail` is true, continue even on failure

**For `agent` steps:**
- If `skip_unless` condition is false, skip the step
- Use the `subagent` tool if an `agent` field is specified
- Otherwise, execute the task directly in the main session
- Capture the agent's output as `step.<name>.output`

**For `gate` steps:**
- Evaluate the condition against the step context
- If false, mark as failed and trigger `on_fail` if set
- If no `on_fail`, stop the blueprint

### Step 3: Report

After all steps complete (or the blueprint stops), produce a report:

```
Blueprint: {name}
Status: {completed | stopped at step X | failed}

Steps:
| # | Name | Type | Status | Duration |
|---|------|------|--------|----------|
| 1 | create-branch | code | ✓ | 0.5s |
| 2 | implement | agent | ✓ | 45s |
| 3 | lint | code | ✗→fix | 2s |
| 4 | fix-lint | agent | ✓ | 12s |
| ... | ... | ... | ... | ... |

Output: {final step output or error}
```

## Built-in Blueprint Templates

### Quick Implement (no deploy)

Create `~/.pi/agent/blueprints/quick-implement.yaml`:

```yaml
name: quick-implement
description: Implement a task with lint and type checking
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
    command: npm run lint 2>&1 || true

  - name: typecheck
    type: code
    command: npx tsc --noEmit 2>&1

  - name: fix-errors
    type: agent
    agent: worker
    task: "Fix any errors from lint and typecheck:\nLint: {step.lint.output}\nTypecheck: {step.typecheck.output}"
    skip_unless: step.lint.failed || step.typecheck.failed
```

### Review Only

Create `~/.pi/agent/blueprints/review.yaml`:

```yaml
name: review
description: Review uncommitted changes
args:
  - name: context
    description: What the changes are about
    default: ""

steps:
  - name: diff
    type: code
    command: git diff --stat && echo "---" && git diff

  - name: review
    type: agent
    agent: reviewer
    task: "Review these changes. Context: {args.context}\n\n{step.diff.output}"
```

## Creating Custom Blueprints

1. Create a YAML file in `~/.pi/agent/blueprints/` or `.pi/blueprints/`
2. Define your steps mixing `code` and `agent` types
3. Use `{args.X}` for input parameters and `{step.name.output}` for step outputs
4. Add `gate` steps for validation checkpoints
5. Use `on_fail` to create recovery paths

**Key principle:** Use `code` for everything deterministic (git, lint, test, build, deploy). Use `agent` for everything that needs reasoning (implement, review, fix, plan). This is what makes blueprints more powerful than pure agent workflows.
