---
name: story9-standards
description: |
  Story9 company webapp standards. MUST be loaded for any Story9 project work — in-loop or out-loop.
  Covers: Next.js 14 App Router, Tailwind with S9 brand colours, Airtable backend, NextAuth + Google OAuth,
  SWR state management, Vercel deployment, collapsible sidebar, PWA, versioning, branch workflow.
  Source of truth: github.com/STORY9LTD/playbook
---

# Story9 Webapp Standards

> Source: [STORY9LTD/playbook](https://github.com/STORY9LTD/playbook)
> These standards apply to ALL Story9 webapps. No exceptions.

## Company Info

| Item | Value |
|------|-------|
| **GitHub Org** | STORY9LTD |
| **Vercel Team** | story9 (team_2kEmik28gmugmUPRGAJizDmz) |
| **Domain** | story9.agency |
| **Route53 Zone** | Z07988563ET2ARNRXQ3LZ |

## Tech Stack (Every Project)

- **Framework:** Next.js 14 App Router
- **Language:** TypeScript (strict)
- **Styling:** Tailwind CSS with S9 brand colours
- **Auth:** NextAuth.js + Google OAuth (@story9.agency restricted)
- **Database:** Airtable (table IDs, not names)
- **State:** SWR with optimistic updates
- **Hosting:** Vercel (story9 team)
- **PWA:** Mandatory for all apps

## Project Structure

```
project-root/
├── app/                    # Next.js App Router
│   ├── api/               # API routes (route.ts)
│   │   ├── auth/[...nextauth]/
│   │   └── {feature}/route.ts
│   ├── login/page.tsx
│   ├── admin/page.tsx
│   ├── layout.tsx         # Root layout (providers, fonts, meta)
│   ├── page.tsx
│   ├── providers.tsx      # SessionProvider wrapper
│   ├── globals.css
│   └── manifest.ts        # PWA manifest
├── components/
│   ├── ui/                # Generic (Button, Toast, Card)
│   ├── features/          # Domain-specific
│   └── layout/            # Sidebar.tsx
├── lib/
│   ├── airtable.ts        # CRUD with table IDs
│   ├── auth.ts            # NextAuth config + isAdmin
│   ├── version.ts         # MANDATORY: APP_VERSION
│   ├── swr.ts             # Fetcher + refresh interval
│   └── themes.ts          # Theme system
├── types/
│   ├── next-auth.d.ts
│   └── index.ts
├── public/icons/          # PWA icons (192, 512, apple-touch)
├── CLAUDE.md              # AI instructions
├── PROGRESS.md            # Work log
└── docs/SPEC.md           # Product spec
```

## File Naming

| Type | Convention | Example |
|------|------------|---------|
| Components | PascalCase | `BookingCard.tsx` |
| Utilities | camelCase | `airtable.ts` |
| API routes | lowercase + `route.ts` | `app/api/bookings/route.ts` |
| Types | PascalCase | `Booking`, `Settings` |
| Constants | SCREAMING_SNAKE | `TOTAL_DESKS` |

## Brand Colours (Tailwind)

```typescript
colors: {
  s9: {
    navy: "#162945",      // Backgrounds, primary surfaces
    midBlue: "#394A79",   // Lighter surfaces, inputs
    teal: "#56A491",      // Positive actions (book, confirm)
    purple: "#4B365F",    // Accents, hovers
    coral: "#DA5A73",     // Negative actions (cancel, delete)
    orange: "#E78E73",    // Warm accents
    tan: "#EDB084",       // Soft accents
    yellow: "#F1D28B",    // Highlights
    neon: "#90FC4D",      // Attention — use sparingly
  },
}
```

### Colour Rules
- Page background: `bg-s9-navy`
- Card background: `bg-s9-midBlue`
- Positive button: `bg-s9-teal hover:bg-s9-teal/90 text-white`
- Negative button: `bg-s9-coral hover:bg-s9-coral/90 text-white`
- Success toast: `bg-s9-teal/95 text-white`
- Warning toast: `bg-s9-coral/95 text-white`
- Theme colour: `#162945`

## Sidebar Navigation (ALL apps)

Collapsible left sidebar, not a top navbar.
- Expanded: `w-56`, Collapsed: `w-16`
- Background: `bg-white border-r border-gray-200`
- Active item: `bg-s9-navy text-white font-semibold`
- Collapse toggle: circle button at `top-5 -right-3`
- Mobile: hamburger menu (sidebar hidden `hidden lg:flex`)
- File: `components/layout/Sidebar.tsx`
- Version in footer: `v{APP_VERSION}` at `text-[11px] text-s9-navy-mid/50`

## API Route Pattern

```typescript
export async function POST(request: Request) {
  // 1. Auth check (always first)
  const session = await getServerSession(authOptions);
  if (!session?.user?.email)
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  // 2. Parse + validate input
  const { field } = await request.json();
  if (!field)
    return NextResponse.json({ error: "field required" }, { status: 400 });

  // 3. Business logic
  try {
    const result = await doThing(session.user.email, field);
    return NextResponse.json(result, { status: 201 });
  } catch (error) {
    console.error("Failed:", error);
    return NextResponse.json({ error: "Failed" }, { status: 500 });
  }
}
```

Error format: `{ error: "Human-readable message" }`

## Auth

- Google OAuth restricted to `@story9.agency` in production
- Dev auth on local + staging (via `ENABLE_DEV_AUTH` + `DEV_AUTH_SECRET`)
- Admin check: `isAdmin(email)` sync, `isAdminAsync(email)` async
- `ADMIN_EMAILS` env var (comma-separated)

## SWR Pattern

```typescript
const fetcher = (url: string) => fetch(url).then(r => r.json());
const REFRESH_INTERVAL = 7000;

// Optimistic updates
await mutate(async (current) => {
  const res = await fetch("/api/thing", { method: "POST", ... });
  const data = await res.json();
  return [...(current || []), data];
}, { optimisticData: [...items, optimistic], rollbackOnError: true, revalidate: false });
```

## Versioning (MANDATORY)

`lib/version.ts`: `export const APP_VERSION = '1.0.0'`
- Bump on EVERY push to staging/production
- New projects start at `0.1.0`, go to `1.0.0` on first production release
- Include in commit: `feat: add search (v1.5.0)`
- Display in sidebar footer

## Branch Workflow

```
feature/* → staging → main
    ↓          ↓        ↓
 Preview   Staging  Production
```

## Vercel Env Vars

- Use `printf '%s' 'value' | vercel env add VAR production --scope story9`
- NEVER use `echo` (adds trailing newline)
- Always verify after setting: `vercel env pull /tmp/verify.txt --scope story9 -y`
- `NEXTAUTH_URL` differs between prod/preview — everything else usually same

## Commit Style

Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`
Always include version: `feat: add feature (v1.5.0)`

## PWA Icons

- Navy background (#162945), white app initials, bold sans-serif
- Sizes: 192x192, 512x512, apple-touch 180x180, favicon 32x32
- manifest.ts: `background_color: "#162945"`, `theme_color: "#162945"`

## Toast Pattern

- Auto-dismiss: success 3s, error 5s
- Fixed top, centered, max-width 404px, rounded-xl
- Close button (X) on right

## For Full Details

Read the playbook directly:
```bash
# Clone for reference
gh repo clone STORY9LTD/playbook /tmp/s9-playbook -- --depth 1
```

Or read individual standards:
- `standards/webapp/COLORS.md` — Full colour palette
- `standards/webapp/UI-PATTERNS.md` — Toasts, cards, nav, responsive
- `standards/webapp/API-PATTERNS.md` — Routes, Airtable, rate limiting
- `standards/webapp/AUTH.md` — NextAuth, dev auth, admin
- `standards/webapp/COMPONENTS.md` — React patterns
- `standards/webapp/STATE-MANAGEMENT.md` — SWR, optimistic updates
- `standards/webapp/DEPLOYMENT.md` — Vercel, env vars
- `standards/webapp/VERSIONING.md` — Version bumping rules
- `deployment/BRANCH-WORKFLOW.md` — Git flow
