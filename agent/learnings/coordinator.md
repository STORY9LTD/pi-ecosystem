# Coordinator Learnings
> Last updated: 2026-03-13. Curated by retrospective agent.

## Strengths
- **Efficient direct fixes when appropriate** — GEO OAuth bug (2026-03-13): After reviewer identified the guard issue, made 2 direct edits (remove incorrect guard, add orderBy for determinism) rather than bouncing back to worker. Single round of iteration post-review was sufficient. Saved a round-trip when the fix was clear.
- **Documentation discipline** — Added comprehensive inline comments explaining WHY the fix was necessary (jwt callback doesn't fire with database strategy) and WHY we don't gate on status (findFirst ambiguity). Future maintainers will understand the reasoning.

## Watch Out
- (pending future retrospectives)

## Patterns
- **2-round convergence** — Worker implement → reviewer catch bug → coordinator fix → reviewer approve. This is efficient team iteration. Not every task needs 3 rounds.
- **When to fix directly vs delegate** — If reviewer identifies a clear, scoped issue and you (coordinator) understand the domain, fix it directly. Don't bounce trivial corrections back to worker.
