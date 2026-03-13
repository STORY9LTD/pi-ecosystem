# Planner Learnings
> Last updated: 2026-03-13. Curated by retrospective agent.

## Strengths

- (pending substantive planner sessions — this session was mostly direct implementation)

## Watch Out

- **Infrastructure planning requires env discovery** — Cloud sandbox (2026-03-13): When planning GitHub Actions workflows that use external services (Claude API, Anthropic), must investigate auth mechanism first. Pi uses OAuth (auth.json), not raw API keys. Planning "add ANTHROPIC_API_KEY to secrets" without scouting led to 3 failed runs.

## Patterns

- **Auth mechanism discovery first** — Before planning integration with third-party services, scout how auth works (API keys? OAuth? Tokens? File-based?). Don't assume standard patterns. Pi, NextAuth, Firebase — all have different auth models.
- **GitHub Actions secrets are env-specific** — When planning cloud runners, check if secrets need special handling (base64 encoding, JSON structure, token refresh). OAuth credentials aren't simple strings.
