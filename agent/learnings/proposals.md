# Proposals
> Retrospective agent recommendations. User reviews and approves.

---

## Proposal 1: Update coordinator.md — Add scope confirmation rule
**Date:** 2026-03-13
**Evidence:** Cloud sandbox session — user said "set up cloud sandbox", agent built full monitoring app + deployed without confirming that was in scope
**Change:** Add to coordinator.md "Rules" section
**Old:** (no rule about scope confirmation)
**New:** "When task wording is ambiguous ('set up X', 'add Y'), confirm scope before expanding beyond the minimal interpretation. Ask: 'By [task], do you mean just [minimal] or also [expanded]?'"
**Rationale:** Prevents autonomous agents from over-delivering and potentially deploying unwanted changes. User should control scope expansion.
**Status:** ✅ applied (2026-03-13)

---

## Proposal 2: Update coordinator.md — Add infrastructure merge gate
**Date:** 2026-03-13
**Evidence:** Cloud sandbox session — merged PR with GitHub Actions workflows across multiple repos without user review, triggering unwanted Vercel deployments
**Change:** Add to coordinator.md "Running a Team" section, step 7 (Report)
**Old:** "7. **Report** with: what was done, files changed, rounds used, quality verdict, rollback command"
**New:** "7. **Report** with: what was done, files changed, rounds used, quality verdict, rollback command. **For infrastructure changes** (workflows, configs, public repos, org secrets), include: **'⚠️ Needs approval before merge — infrastructure changes affect multiple projects'**"
**Rationale:** Infrastructure changes have blast radius beyond a single feature. Human review gate is appropriate.
**Status:** ✅ applied (2026-03-13)

---

## Proposal 3: Update worker.md — Add framework auth investigation pattern
**Date:** 2026-03-13
**Evidence:** Cloud sandbox session — assumed ANTHROPIC_API_KEY was standard API key, but pi uses OAuth tokens in auth.json. Took 3 failed runs to diagnose.
**Change:** Add new section to worker.md after "Output format" section
**Old:** (no auth guidance)
**New:**
```
## Framework Auth Patterns

When implementing integration with third-party APIs or frameworks:
1. **Don't assume standard API keys** — many frameworks use OAuth, tokens, or file-based auth
2. **Locate credentials first** — check .env, auth.json, ~/.config, OS keychain
3. **Inspect format** — log credential length/prefix in debug mode to verify structure
4. **Check framework docs** — pi uses auth.json, NextAuth uses adapters, Firebase uses service accounts

Examples:
- Pi: OAuth tokens in ~/.pi/agent/auth.json (not ANTHROPIC_API_KEY)
- NextAuth: session strategy affects which callbacks fire
- GitHub Actions: GITHUB_TOKEN is scoped to current repo only
```
**Rationale:** Framework auth is a recurring pain point. This gives workers a checklist before assuming patterns.
**Status:** ✅ applied (2026-03-13)

---

## Proposal 4: Update scout.md — Add auth mechanism discovery to checklist
**Date:** 2026-03-13
**Evidence:** Cloud sandbox session — scout didn't investigate how pi auth works before planner designed the workflow
**Change:** Update scout.md "Strategy" section
**Old:**
```
Strategy:
1. grep/find to locate relevant code
2. Read key sections (not entire files)
3. Identify types, interfaces, key functions
4. Note dependencies between files
```
**New:**
```
Strategy:
1. grep/find to locate relevant code
2. Read key sections (not entire files)
3. Identify types, interfaces, key functions
4. Note dependencies between files
5. **For integrations/infra**: Discover auth mechanism (API keys? OAuth? File-based? Env vars?)
```
**Rationale:** Auth mechanism discovery should be part of infrastructure reconnaissance. Would have prevented 3 failed workflow runs.
**Status:** ✅ applied (2026-03-13)

---

## Proposal 5: Update blueprints/s9-implement.yaml — Increase timeout default
**Date:** 2026-03-13
**Evidence:** Cloud sandbox session — 30-min timeout killed a working run mid-execution (Next.js dev server was up)
**Change:** Add timeout metadata to blueprint header
**Old:** (no timeout specified)
**New:**
```yaml
name: s9-implement
description: "Story9 implementation blueprint. Adds branch workflow, version bump, S9 standards to team-implement pattern."
timeout: 60  # minutes — agent blueprints need generous timeouts for Next.js builds + multi-step workflows
args:
  - name: task
```
**Rationale:** 30 min isn't enough for scout → plan → implement → build → review cycles on Next.js projects. 60 min is safer and still reasonable.
**Status:** ✅ applied (2026-03-13)

---

## Proposal 6: Create pi-auth.md knowledge document
**Date:** 2026-03-13
**Evidence:** Cloud sandbox session — pi OAuth system is non-obvious, caused 3 failed runs
**Change:** Create new file ~/.pi/agent/learnings/pi-auth.md
**Content:**
```markdown
# Pi Authentication System

Pi uses **OAuth tokens** (Claude subscription), not raw API keys.

## Local Development
- Auth stored in: `~/.pi/agent/auth.json`
- Format: `{ "access_token": "...", "refresh_token": "...", ... }`
- The `ANTHROPIC_API_KEY` in .env is actually the access token (not a sk-ant-... key)

## GitHub Actions / Cloud Runners
- Cannot use ANTHROPIC_API_KEY env var alone
- Must store entire auth.json as base64-encoded secret:
  ```bash
  base64 -i ~/.pi/agent/auth.json | pbcopy
  # Store as PI_AUTH_JSON secret in GitHub
  ```
- In workflow, decode and write to ~/.pi/agent/auth.json before running pi

## Debugging Auth Issues
1. Check if auth.json exists and is valid JSON
2. Log credential length/prefix (don't log full token!)
3. Test with pi CLI locally first before trying in cloud
4. OAuth tokens expire — refresh tokens handle renewal

## Common Mistakes
- ❌ Assuming ANTHROPIC_API_KEY is a raw API key (sk-ant-...)
- ❌ Only passing access token without refresh token
- ❌ Not base64-encoding the JSON for GitHub secrets
- ❌ Trying to clone pi-ecosystem as private repo (GITHUB_TOKEN can't access)
```
**Rationale:** This knowledge is framework-specific and not obvious. Document once, reference in agent learnings.
**Status:** ✅ applied (2026-03-13)

---

## Proposal 7: Reviewer.md — Add deployment trigger check
**Date:** 2026-03-13
**Evidence:** Cloud sandbox session — workflow files pushed to main triggered unwanted Vercel deploys
**Change:** Add to reviewer.md "Strategy" section
**Old:**
```
Strategy:
1. Run `git diff` to see recent changes (if applicable)
2. Read the modified files
3. Check for bugs, security issues, code smells
```
**New:**
```
Strategy:
1. Run `git diff` to see recent changes (if applicable)
2. Read the modified files
3. Check for bugs, security issues, code smells
4. **For workflow/config files**: Check if pushing to main will trigger deploys (Vercel, Netlify, Actions)
```
**Rationale:** Infrastructure files have side effects. Reviewer should flag when changes need PR process.
**Status:** ✅ applied (2026-03-13)

---

## System Recommendation: Damage Control Refinement

**Issue:** Cloud sandbox session had several false positives — safe commands blocked:
- `curl` for API testing (blocked as "curl | sh" risk)
- `git show <commit>` (incorrectly matched forbidden patterns)
- Monitoring loops with `watch`

**Recommendation:** Refine damage control rules to be less conservative for read-only operations:
1. Allow `curl` when NOT piped to sh/bash/eval
2. Allow `git show`, `git log`, `git diff` (pure read operations)
3. Allow `watch` for monitoring (read-only loop)
4. Keep blocks on: `rm -rf`, `dd`, `curl | sh`, `:(){:|:&};:`, secret paths

This is a system-level change (not agent .md), so implementation is outside retrospective scope, but worth documenting as a known friction point.

---

## Summary of Proposals

- **3 agent definition changes** (coordinator, worker, scout)
- **1 blueprint change** (s9-implement timeout)
- **1 new knowledge document** (pi-auth.md)
- **1 reviewer enhancement** (deployment trigger awareness)
- **1 system recommendation** (damage control refinement)

All proposals are **pending user review** — do not apply without approval.
