# Scout Learnings
> Last updated: 2026-03-13. Curated by retrospective agent.

## Strengths

- **Precise file selection for auth debugging** — GEO OAuth bug (2026-03-13): Read exactly the right 7 files (auth.ts, middleware.ts, login/page.tsx, dashboard pages, config) to diagnose a redirect loop. No noise, no missing context.
- **Root cause identification** — Correctly identified that `jwt` callback doesn't fire with `session.strategy: 'database'` in NextAuth — this is a subtle framework behaviour that many miss.

## Watch Out

- **Auth file discovery** — Cloud sandbox (2026-03-13): When investigating auth failures in frameworks, check for non-standard auth files (pi uses ~/.pi/agent/auth.json, not just ANTHROPIC_API_KEY env var). Framework auth can be file-based, not env-based.

## Patterns

- **Auth debugging checklist** — When debugging auth flows, always read: auth config, middleware, protected route pages, .env (if accessible), and next.config for basePath/redirects. For framework tools (pi, Next.js, etc.), also check for auth.json or similar credential files.
- **Framework credential locations** — Different frameworks store credentials differently: .env vars, auth.json files, OS keychains. When scouting auth issues, look beyond environment variables.
