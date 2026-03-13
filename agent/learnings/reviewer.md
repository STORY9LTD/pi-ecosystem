# Reviewer Learnings
> Last updated: 2026-03-13. Curated by retrospective agent.

## Strengths
- **Multi-record edge case detection** — GEO OAuth bug (2026-03-13): Caught that worker's `if (brandMember.status === 'pending')` guard was checking the wrong record. When a user has BOTH an active Brand A membership AND a pending Brand B invitation, `findFirst` might return the active one, preventing the pending one from being activated. This is a subtle correctness bug, not a nit. Prevented a multi-brand failure mode from shipping.
- **Clear failure explanations** — Explained the edge case scenario with concrete example (Brand A active, Brand B pending).

## Watch Out
- (pending future retrospectives)

## Patterns
- **Multi-tenancy guards are risky** — When reviewing code that uses `findFirst` followed by conditional logic, always ask: "What if there are multiple records for this user/entity in different states?" The first match might not represent the full picture.
