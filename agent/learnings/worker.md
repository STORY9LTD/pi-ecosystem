# Worker Learnings
> Last updated: 2026-03-13. Curated by retrospective agent.

## Strengths

- **NextAuth session strategy awareness** — GEO OAuth bug (2026-03-13): Correctly diagnosed that `jwt` callback doesn't fire when using `session.strategy: 'database'` (PrismaAdapter). Moved logic to `signIn` callback which fires regardless of strategy. This is a framework subtlety that's easy to miss.
- **Structural fixes over workarounds** — Moved the activation logic to the right lifecycle callback rather than patching symptoms.
- **Incremental debugging approach** — Cloud sandbox session (2026-03-13): When API auth failed 3 times, added debug logging (key length, prefix) to diagnose that `ANTHROPIC_API_KEY` was OAuth token, not raw API key. Methodical logging beats guessing.

## Watch Out

- **Guard conditions on findFirst results** — GEO OAuth bug (2026-03-13): Added `if (brandMember.status === 'pending')` guard, but `findFirst` might return an `active` record even when user has OTHER `pending` records for different brands. Always consider multi-record scenarios when using findFirst — don't assume the returned record represents all states. Reviewer caught this before it shipped.
- **OAuth vs API key assumptions** — Cloud sandbox (2026-03-13): Assumed `ANTHROPIC_API_KEY` was a standard API key (sk-ant-...). Pi actually uses OAuth tokens from auth.json (access token + refresh token). When auth fails, inspect the credential format — don't assume standard patterns. Took 3 failed runs to diagnose.
- **Private repo access in GitHub Actions** — Cloud sandbox (2026-03-13): Created pi-ecosystem as private repo, but `GITHUB_TOKEN` can't access other private repos. Had to make it public. For shared configs, public repos or PATs are needed.
- **Direct main pushes trigger deployments** — Cloud sandbox (2026-03-13): Pushed workflow files directly to main on multiple repos (s9-survey, whosin), triggering unwanted Vercel deploys. Should use branches/PRs for workflow changes.

## Patterns

- **NextAuth callback lifecycle** — `signIn` fires for all session strategies. `jwt` fires ONLY with JWT strategy, NOT with database strategy. If logic must run on sign-in regardless of strategy, use `signIn` callback.
- **Prisma findFirst + updateMany pattern** — When using `findFirst` for a membership check, don't gate subsequent `updateMany` on the found record's status — the query might have returned a different record than the one updateMany will affect.
- **Framework auth is opaque** — Modern frameworks (pi, NextAuth, etc.) often use OAuth/token systems, not simple API keys. When debugging auth: (1) locate the auth file (auth.json, .env), (2) inspect the credential format (length, structure), (3) check framework docs for auth mechanism. Don't assume.
- **GitHub Actions timeout defaults** — 30 min is too short for agent blueprints (Next.js builds, multi-step workflows). Cloud sandbox run was killed mid-execution. Use 60 min for agent workloads. Always try to save partial work.
- **GitHub Actions private repo cloning** — `GITHUB_TOKEN` in Actions can only access the repo it's running in. To clone other org repos: (a) make them public, or (b) use a PAT. For agent ecosystem configs, public repo is simpler.
- **Branch discipline for automation** — When adding workflows/configs to multiple repos, use feature branches + PRs. Direct main pushes can trigger CI/CD deploys you don't want.
