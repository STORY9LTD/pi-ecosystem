---
name: security-audit
description: |
  Run a comprehensive security audit on a Story9 webapp or any Next.js project. Checks for:
  auth vulnerabilities, exposed secrets, API route protection, input validation, CORS issues,
  dependency vulnerabilities, Vercel config, Airtable injection, and OWASP Top 10 coverage.
  Use when shipping to production, after major changes, or on a schedule.
---

# Security Audit

Comprehensive security review for Story9 webapps and Next.js projects.

## When to Run

- Before first production deploy
- After adding authentication or API routes
- After adding new dependencies
- Monthly scheduled audit
- After any security incident

## Audit Procedure

Run all sections in order. For each finding, classify as:
- 🔴 **CRITICAL** — Must fix before deploy. Active vulnerability.
- 🟠 **HIGH** — Fix within 24 hours. Likely exploitable.
- 🟡 **MEDIUM** — Fix this sprint. Defence-in-depth.
- 🔵 **LOW** — Track and fix when convenient.

---

### 1. Secrets & Environment Variables

```bash
# Check for hardcoded secrets in code
grep -rn "NEXTAUTH_SECRET\|API_KEY\|SECRET\|PASSWORD\|TOKEN" --include="*.ts" --include="*.tsx" --include="*.js" . \
  | grep -v node_modules | grep -v ".env" | grep -v "process.env"

# Check .env files aren't committed
git ls-files | grep -i "\.env" | grep -v ".example"

# Check .gitignore has env files
grep "\.env" .gitignore

# Check for exposed keys in package.json
grep -i "key\|secret\|token\|password" package.json
```

**What to look for:**
- Hardcoded API keys, secrets, or tokens in source code
- `.env` files tracked by git
- Missing `.gitignore` entries for sensitive files
- Secrets in client-side code (`NEXT_PUBLIC_` vars that shouldn't be public)

---

### 2. Authentication & Authorization

```bash
# Find all API routes
find app/api -name "route.ts" -o -name "route.js" | sort

# Check each route has auth
for route in $(find app/api -name "route.ts"); do
  if ! grep -q "getServerSession\|auth()" "$route"; then
    echo "⚠️  NO AUTH: $route"
  fi
done

# Check admin routes have admin checks
for route in $(find app/api/admin -name "route.ts" 2>/dev/null); do
  if ! grep -q "isAdmin\|isAdminAsync" "$route"; then
    echo "⚠️  NO ADMIN CHECK: $route"
  fi
done

# Check for auth bypass patterns
grep -rn "TODO\|FIXME\|HACK\|skip auth\|bypass" --include="*.ts" app/api/
```

**What to look for:**
- API routes without `getServerSession()` check
- Admin routes without `isAdmin()` / `isAdminAsync()` check
- Auth checks after business logic (should be FIRST)
- Missing `signIn` callback domain restriction in production
- Dev auth enabled on production (`ENABLE_DEV_AUTH` on prod Vercel env)

---

### 3. Input Validation & Injection

```bash
# Check for raw user input in Airtable queries (injection risk)
grep -rn "filterByFormula" --include="*.ts" lib/ | grep -v "escapeAirtable"

# Check for unsanitised input in SQL/queries
grep -rn "request.json()" --include="*.ts" app/api/ | head -20

# Check for XSS vectors (dangerouslySetInnerHTML)
grep -rn "dangerouslySetInnerHTML\|innerHTML" --include="*.tsx" --include="*.ts" .
```

**What to look for:**
- Airtable `filterByFormula` without `escapeAirtable()` — injection risk
- Missing input validation after `request.json()`
- `dangerouslySetInnerHTML` usage (XSS vector)
- User input directly in HTML without escaping
- Missing type validation on API inputs

---

### 4. Dependencies

```bash
# Check for known vulnerabilities
npm audit 2>&1

# Check for outdated packages
npm outdated 2>&1 | head -20

# Check for suspicious packages
npm ls --depth=0 2>&1
```

**What to look for:**
- Critical/high severity vulnerabilities
- Outdated `next`, `next-auth`, `react` versions
- Unnecessary dependencies (attack surface)
- Packages with known supply-chain issues

---

### 5. API Security

```bash
# Check for rate limiting
grep -rn "rate\|limit\|throttle" --include="*.ts" middleware.ts app/api/ 2>/dev/null

# Check for CORS configuration
grep -rn "Access-Control\|cors\|CORS" --include="*.ts" . | grep -v node_modules

# Check response headers
grep -rn "NextResponse.json" --include="*.ts" app/api/ | head -10
```

**What to look for:**
- No rate limiting on mutation endpoints (POST, DELETE)
- Overly permissive CORS
- Missing security headers (CSP, X-Frame-Options)
- Error responses leaking internal details (stack traces, file paths)
- DELETE endpoints without confirmation patterns

---

### 6. Vercel & Deployment

```bash
# Check Vercel env var scoping
vercel env ls --scope story9 2>&1 | head -30

# Verify dev auth NOT on production
vercel env ls production --scope story9 2>&1 | grep -i "DEV_AUTH\|ENABLE_DEV"

# Check for preview-only vars on production
vercel env ls production --scope story9 2>&1 | grep -i "NEXT_PUBLIC_ENABLE"
```

**What to look for:**
- `ENABLE_DEV_AUTH=true` on production (CRITICAL)
- `NEXT_PUBLIC_ENABLE_DEV_AUTH=true` on production (CRITICAL)
- Secrets with trailing newlines (verification: `vercel env pull`)
- Missing `NEXTAUTH_SECRET` (auth won't work)

---

### 7. Data Protection

```bash
# Check what's logged
grep -rn "console.log\|console.error" --include="*.ts" app/api/ | grep -i "email\|password\|token\|secret\|key"

# Check for PII in client components
grep -rn "email\|phone\|address" --include="*.tsx" components/ | grep -v "type\|interface\|import"
```

**What to look for:**
- PII logged to console (visible in Vercel logs)
- User data in client-side state without need
- Missing data minimisation (fetching more than needed)

---

### 8. File & Path Security

```bash
# Check for directory traversal vectors
grep -rn "\.\./" --include="*.ts" app/api/

# Check file upload handlers
grep -rn "formData\|multipart\|upload" --include="*.ts" app/api/
```

---

## Report Template

After running all checks, produce this report:

```
# Security Audit Report

**Project:** {project-name}
**Date:** {date}
**Auditor:** pi security-audit skill
**Version:** {from lib/version.ts}

## Summary

| Severity | Count |
|----------|-------|
| 🔴 Critical | X |
| 🟠 High | X |
| 🟡 Medium | X |
| 🔵 Low | X |

## Findings

### 🔴 CRITICAL

1. **[Title]**
   - File: `path/to/file.ts:line`
   - Issue: Description
   - Fix: Specific remediation steps
   - OWASP: A01:2021 Broken Access Control

### 🟠 HIGH
...

### 🟡 MEDIUM
...

### 🔵 LOW
...

## Passed Checks
- ✅ Auth on all API routes
- ✅ No hardcoded secrets
- ✅ Dependencies up to date
...

## Recommendations
1. Priority fixes
2. Process improvements
3. Monitoring to add
```
