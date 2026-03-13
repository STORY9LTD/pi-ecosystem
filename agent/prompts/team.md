---
description: Form an agent team for a task — coordinator runs iterative worker+reviewer loops with safety guardrails
---
Use the subagent tool to run the "coordinator" agent on this task:

Form a team and execute this task with iterative quality loops:

$@

SAFETY REQUIREMENTS (non-negotiable):
1. Create a git checkpoint BEFORE any worker runs (git stash push -m "pre-team-<timestamp>")
2. Count rounds explicitly: ROUND_COUNT: N of 3. Maximum 3 rounds. STOP after 3.
3. Run lint + typecheck after each worker round to verify no regressions
4. If the reviewer flags the SAME issues two rounds in a row → STOP (oscillation)
5. If a worker or reviewer errors out → STOP and report (fail fast)
6. Create a workspace log at ~/.pi/agent/runs/team-<timestamp>/workspace.md
7. Report: what was done, files changed, rounds taken, reviewer verdict, rollback command, safety check results

The coordinator should orchestrate autonomously — do NOT ask me for input during the run.
