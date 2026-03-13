# Scout Learnings
> Last updated: 2026-03-13. Curated by retrospective agent.

## Strengths
- **Precise file selection for auth debugging** — GEO OAuth bug (2026-03-13): Read exactly the right 7 files (auth.ts, middleware.ts, login/page.tsx, dashboard pages, config) to diagnose a redirect loop. No noise, no missing context.
- **Root cause identification** — Correctly identified that `jwt` callback doesn't fire with `session.strategy: 'database'` in NextAuth — this is a subtle framework behaviour that many miss.

## Watch Out
- (pending future retrospectives)

## Patterns
- **Auth debugging checklist** — When debugging auth flows, always read: auth config, middleware, protected route pages, .env (if accessible), and next.config for basePath/redirects.
