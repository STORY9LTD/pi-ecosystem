---
name: context7
description: |
  Look up latest library documentation and coding best practices via Context7 (Upstash).
  Use when you need current API docs, migration guides, or version-specific code examples
  for any library (Next.js, React, Tailwind, NextAuth, SWR, Airtable, etc.).
  Pulls docs directly from source repositories — always up to date.
---

# Context7 — Latest Docs Lookup

Query up-to-date library documentation. Never rely on training data when you can check the source.

## When to Use

- Before implementing with a library you're unsure about
- When a user asks about latest API changes or best practices
- When you see deprecation warnings or breaking changes
- Before starting any Story9 project — check latest Next.js, NextAuth, SWR docs
- When debugging library-specific issues

## How to Use

### Step 1: Resolve the library

Find the Context7-compatible library ID:

```bash
cd "$(dirname "$0")" && bash scripts/lookup.sh resolve "next.js"
```

Common libraries and their likely IDs:
- `next.js` — Next.js framework
- `react` — React
- `tailwindcss` — Tailwind CSS
- `next-auth` — NextAuth.js
- `swr` — SWR data fetching
- `airtable` — Airtable API
- `typescript` — TypeScript
- `vercel` — Vercel platform
- `playwright` — Playwright testing

### Step 2: Query for a specific topic

```bash
cd "$(dirname "$0")" && bash scripts/lookup.sh query "<library-id>" "app router server components"
```

### Step 3: Read and apply

Read the returned documentation and apply it to the current task. If the docs show patterns different from what's in the Story9 playbook, note the discrepancy — the playbook may need updating.

## Quick Search (resolve + query in one step)

```bash
cd "$(dirname "$0")" && bash scripts/lookup.sh search "next.js app router middleware"
```

## Integration with Story9

When building Story9 projects, check Context7 for:

| Library | Check for |
|---------|-----------|
| Next.js | App Router changes, new APIs, middleware patterns |
| NextAuth | v5 migration, new providers, session handling |
| SWR | New hooks, caching strategies |
| Tailwind | v4 changes, new utilities |
| React | New hooks, server components patterns |

If Context7 shows a newer pattern than the Story9 playbook, flag it:

```
Note: Context7 shows NextAuth v5 uses `auth()` instead of `getServerSession()`.
The Story9 playbook still uses v4 patterns. Consider updating.
```

## Fallback

If the Context7 MCP server isn't responding, fall back to:
1. Check the library's GitHub repo directly
2. Use the version pinned in the project's `package.json`
3. Follow existing Story9 playbook patterns (known working)
