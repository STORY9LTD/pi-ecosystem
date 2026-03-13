# Cross-Agent Patterns
> Last updated: 2026-03-13. Curated by retrospective agent.

## Handoff Issues

- **Framework-specific knowledge gaps** — GEO OAuth bug (2026-03-13): Worker correctly diagnosed NextAuth session strategy issue, but missed a guard logic edge case. This suggests we need both framework knowledge AND multi-record thinking. Scout provided good context, but worker still needed reviewer to catch the subtlety.
- **Auth mechanism assumptions** — Cloud sandbox (2026-03-13): Neither scout nor planner investigated pi's auth mechanism before planning the workflow. Assumed standard API key pattern. Pi uses OAuth (auth.json). Led to 3 failed workflow runs. When planning integrations, scout should discover auth mechanism first.

## Team Dynamics

- **Efficient 2-round iterations** — GEO OAuth bug (2026-03-13): Worker → reviewer FAIL → coordinator direct fix → reviewer PASS. Total 2 rounds. When reviewer identifies a clear, scoped issue and coordinator understands the fix, direct intervention saves round-trips. Not every task needs the full 3 rounds.
- **Reviewer as safety net, not bottleneck** — Reviewer caught a real correctness bug (multi-brand pending invitation edge case) that would have caused silent failures in production. This validates the review step — even on "simple" auth fixes.
- **Scope creep without gates** — Cloud sandbox (2026-03-13): User asked to "set up cloud sandbox", agent built the full monitoring app + deployed without confirming scope. Teams should verify task boundaries before expanding from setup to full implementation.

## System-Level

- **NextAuth session strategy gotcha** — When using `PrismaAdapter` (database sessions), the `jwt` callback does NOT fire. Logic that must run on every sign-in needs to be in the `signIn` callback. This is a common Next.js auth footgun — worth documenting as a known pattern.
- **Multi-tenancy guard patterns** — When code uses `findFirst` followed by conditional logic based on the found record's state, there's risk of multi-record edge cases (e.g., user has both active Brand A and pending Brand B). Always ask: "Does this guard account for multiple records in different states?"
- **Pi OAuth auth pattern** — Pi uses OAuth tokens (Claude subscription) stored in ~/.pi/agent/auth.json, not raw ANTHROPIC_API_KEY. The "API key" in .env is actually an access token. For GitHub Actions, base64-encode auth.json and store as secret. This is framework-specific knowledge that should be documented.
- **GitHub Actions private repo limits** — `GITHUB_TOKEN` can only access the repo the workflow runs in. To clone other org repos: make them public, or use a PAT. For agent ecosystem configs (agents, blueprints, learnings), public repos avoid auth complexity.
- **Timeout generosity for agent blueprints** — 30 min is insufficient for multi-step agent workflows (scout → plan → implement → review). Next.js builds alone can take 5+ min. Cloud sandbox run was killed mid-execution. Use 60 min for safety. Always save partial work if possible.
- **Branch discipline for infrastructure** — Workflow files, Vercel configs, org-wide settings — these should go through PR process even if you trust the code. Direct main pushes can trigger unwanted deploys across multiple projects. Learned from s9-survey, whosin unwanted Vercel deploys.
- **Incremental debugging > guessing** — Cloud sandbox auth failed 3 times before adding debug logging (key length, prefix). The logs revealed OAuth token structure. When mysterious failures occur, add observability before trying more fixes.

## Infrastructure Work Patterns

- **Cloud runner auth discovery** — Before building GitHub Actions that integrate external APIs: (1) Identify auth mechanism (keys? OAuth? tokens?), (2) Test credential format (length, structure), (3) Check if secrets need encoding (base64, JSON). Pi auth took 3 iterations because we assumed API key pattern.
- **Public config repos for Actions** — When multiple repos need shared configs (agent definitions, blueprints, learnings), public repos are simpler than PATs. GitHub Actions `GITHUB_TOKEN` is scoped to current repo only.
- **Infrastructure changes need human gates** — New workflows, public repos, org-wide secrets — these affect multiple projects. Coordinator should prompt for user approval before: (a) creating public repos, (b) merging infrastructure PRs, (c) pushing workflows to main.
