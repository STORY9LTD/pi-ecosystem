# Cross-Agent Patterns
> Last updated: 2026-03-13. Curated by retrospective agent.

## Handoff Issues
- **Framework-specific knowledge gaps** — GEO OAuth bug (2026-03-13): Worker correctly diagnosed NextAuth session strategy issue, but missed a guard logic edge case. This suggests we need both framework knowledge AND multi-record thinking. Scout provided good context, but worker still needed reviewer to catch the subtlety.

## Team Dynamics
- **Efficient 2-round iterations** — GEO OAuth bug (2026-03-13): Worker → reviewer FAIL → coordinator direct fix → reviewer PASS. Total 2 rounds. When reviewer identifies a clear, scoped issue and coordinator understands the fix, direct intervention saves round-trips. Not every task needs the full 3 rounds.
- **Reviewer as safety net, not bottleneck** — Reviewer caught a real correctness bug (multi-brand pending invitation edge case) that would have caused silent failures in production. This validates the review step — even on "simple" auth fixes.

## System-Level
- **NextAuth session strategy gotcha** — When using `PrismaAdapter` (database sessions), the `jwt` callback does NOT fire. Logic that must run on every sign-in needs to be in the `signIn` callback. This is a common Next.js auth footgun — worth documenting as a known pattern.
- **Multi-tenancy guard patterns** — When code uses `findFirst` followed by conditional logic based on the found record's state, there's risk of multi-record edge cases (e.g., user has both active Brand A and pending Brand B). Always ask: "Does this guard account for multiple records in different states?"
