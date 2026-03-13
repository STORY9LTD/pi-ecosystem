# Coordinator Learnings
> Last updated: 2026-03-13. Curated by retrospective agent.

## Strengths

- **Efficient direct fixes when appropriate** — GEO OAuth bug (2026-03-13): After reviewer identified the guard issue, made 2 direct edits (remove incorrect guard, add orderBy for determinism) rather than bouncing back to worker. Single round of iteration post-review was sufficient. Saved a round-trip when the fix was clear.
- **Documentation discipline** — Added comprehensive inline comments explaining WHY the fix was necessary (jwt callback doesn't fire with database strategy) and WHY we don't gate on status (findFirst ambiguity). Future maintainers will understand the reasoning.

## Watch Out

- **Scope creep without user confirmation** — Cloud sandbox (2026-03-13): User asked to "set up cloud sandbox". Agent built the entire monitoring app (s9-sandbox) locally AND deployed it without confirming that was part of the task. Should verify scope before expanding from setup to full implementation.
- **Auto-merge significant PRs** — Cloud sandbox (2026-03-13): Merged the cloud sandbox PR with workflow changes to main without user review. Infrastructure changes (GitHub Actions workflows, new repos, org-wide configs) should get explicit approval before merge.

## Patterns

- **2-round convergence** — Worker implement → reviewer catch bug → coordinator fix → reviewer approve. This is efficient team iteration. Not every task needs 3 rounds.
- **When to fix directly vs delegate** — If reviewer identifies a clear, scoped issue and you (coordinator) understand the domain, fix it directly. Don't bounce trivial corrections back to worker.
- **Infrastructure PRs need human gates** — Workflow files, GitHub Actions, org-wide configs, new public repos — these affect multiple projects. Always pause for user review before merging, even if CI is green.
- **Scope confirmation for open-ended tasks** — When a task could mean "just set up" or "build the full thing", confirm scope before implementing. "Set up cloud sandbox" could mean workflow only, or workflow + monitoring app + docs. Ask.
