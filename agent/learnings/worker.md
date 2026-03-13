# Worker Learnings
> Last updated: 2026-03-13. Curated by retrospective agent.

## Strengths
- **NextAuth session strategy awareness** — GEO OAuth bug (2026-03-13): Correctly diagnosed that `jwt` callback doesn't fire when using `session.strategy: 'database'` (PrismaAdapter). Moved logic to `signIn` callback which fires regardless of strategy. This is a framework subtlety that's easy to miss.
- **Structural fixes over workarounds** — Moved the activation logic to the right lifecycle callback rather than patching symptoms.

## Watch Out
- **Guard conditions on findFirst results** — GEO OAuth bug (2026-03-13): Added `if (brandMember.status === 'pending')` guard, but `findFirst` might return an `active` record even when user has OTHER `pending` records for different brands. Always consider multi-record scenarios when using findFirst — don't assume the returned record represents all states. Reviewer caught this before it shipped.

## Patterns
- **NextAuth callback lifecycle** — `signIn` fires for all session strategies. `jwt` fires ONLY with JWT strategy, NOT with database strategy. If logic must run on sign-in regardless of strategy, use `signIn` callback.
- **Prisma findFirst + updateMany pattern** — When using `findFirst` for a membership check, don't gate subsequent `updateMany` on the found record's status — the query might have returned a different record than the one updateMany will affect.
