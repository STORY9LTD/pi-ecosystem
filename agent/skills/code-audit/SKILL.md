---
name: code-audit
description: |
  Run a comprehensive code quality audit on a Story9 webapp or any Next.js/TypeScript project.
  Checks: Story9 playbook compliance, TypeScript strictness, component patterns, API patterns,
  performance, accessibility, test coverage, dead code, bundle size, and coding best practices.
  Use before major releases, during code reviews, or on a schedule.
---

# Code Audit

Full code quality review against Story9 standards and industry best practices.

## When to Run

- Before major version bumps
- After a sprint of feature work
- When onboarding a new project
- Monthly quality check
- Before handing a project to another developer

## Audit Procedure

Run all sections. Score each as:
- ✅ **Pass** — Meets standards
- ⚠️ **Warning** — Works but could be better
- ❌ **Fail** — Doesn't meet standards, needs fixing

---

### 1. Story9 Playbook Compliance

```bash
# Check project structure
echo "=== Structure Check ==="
for dir in app components lib types public/icons docs; do
  [ -d "$dir" ] && echo "✅ $dir/" || echo "❌ Missing: $dir/"
done

# Check mandatory files
for file in lib/version.ts lib/auth.ts lib/swr.ts CLAUDE.md app/manifest.ts app/providers.tsx; do
  [ -f "$file" ] && echo "✅ $file" || echo "❌ Missing: $file"
done

# Check version file
if [ -f "lib/version.ts" ]; then
  echo "Version: $(grep APP_VERSION lib/version.ts)"
else
  echo "❌ NO VERSION FILE"
fi

# Check Tailwind has S9 colours
grep -q "s9-navy\|#162945" tailwind.config.ts 2>/dev/null && echo "✅ S9 brand colours" || echo "❌ Missing S9 colours in Tailwind"

# Check sidebar exists
find components -name "Sidebar*" 2>/dev/null | head -1 | grep -q . && echo "✅ Sidebar component" || echo "⚠️  No Sidebar component found"

# Check PWA manifest
[ -f "app/manifest.ts" ] && echo "✅ PWA manifest" || echo "❌ No PWA manifest"
[ -d "public/icons" ] && echo "✅ PWA icons" || echo "❌ No PWA icons"
```

---

### 2. TypeScript Quality

```bash
# Strict mode check
grep -q '"strict": true' tsconfig.json 2>/dev/null && echo "✅ Strict mode" || echo "❌ Strict mode not enabled"

# Type check
npx tsc --noEmit 2>&1

# Count 'any' usage
echo "=== 'any' usage ==="
grep -rn ": any\|as any\|<any>" --include="*.ts" --include="*.tsx" . | grep -v node_modules | wc -l
grep -rn ": any\|as any\|<any>" --include="*.ts" --include="*.tsx" . | grep -v node_modules | head -10

# Check for missing return types on API routes
grep -rn "export async function" --include="*.ts" app/api/ | grep -v "Promise\|Response"

# Check for proper interfaces (not inline types)
echo "=== Interfaces in types/ ==="
grep -c "interface\|type " types/*.ts 2>/dev/null || echo "⚠️  No type files"
```

**Standards:**
- Zero `tsc` errors
- Minimal `any` usage (< 5 in entire codebase)
- Shared types in `types/` directory
- Proper interface definitions for all API data

---

### 3. Component Quality

```bash
# Check file naming
echo "=== Component naming ==="
find components -name "*.tsx" | while read f; do
  base=$(basename "$f" .tsx)
  if [[ ! "$base" =~ ^[A-Z] ]]; then
    echo "❌ Not PascalCase: $f"
  fi
done

# Check for prop interfaces
echo "=== Props interfaces ==="
for f in $(find components -name "*.tsx"); do
  if grep -q "export.*function\|export default" "$f"; then
    if ! grep -q "interface.*Props\|type.*Props" "$f"; then
      echo "⚠️  No Props interface: $f"
    fi
  fi
done

# Check for accessibility
echo "=== Accessibility ==="
grep -rn "onClick" --include="*.tsx" components/ | grep -v "button\|Button\|a \|Link\|role=" | head -5
grep -rn "<img" --include="*.tsx" . | grep -v "alt=" | grep -v node_modules | head -5

# Check for hardcoded strings (should use constants)
grep -rn "className=\".*#[0-9a-fA-F]" --include="*.tsx" components/ | head -5
```

**Standards:**
- PascalCase component files
- Props interfaces for all components
- `alt` on all images
- `onClick` only on interactive elements
- No hardcoded colours (use Tailwind S9 classes)

---

### 4. API Route Quality

```bash
# Check all routes follow the pattern
echo "=== API Route Audit ==="
for route in $(find app/api -name "route.ts" | sort); do
  echo "--- $route ---"

  # Auth check first?
  FIRST_CHECK=$(grep -n "getServerSession\|NextResponse.json" "$route" | head -1)
  echo "  First check: $FIRST_CHECK"

  # Has error handling?
  grep -q "try.*catch\|catch.*error" "$route" && echo "  ✅ Error handling" || echo "  ❌ No error handling"

  # Has input validation?
  grep -q "if (!.*)" "$route" && echo "  ✅ Input validation" || echo "  ⚠️  Weak input validation"

  # Correct status codes?
  grep -o "status: [0-9]*" "$route" | sort -u | tr '\n' ' '
  echo ""
done
```

---

### 5. Performance

```bash
# Check bundle size
npm run build 2>&1 | grep -A 50 "Route\|Size" | head -30

# Check for large dependencies
du -sh node_modules/*/ 2>/dev/null | sort -rh | head -10

# Check for unnecessary client components
grep -rn "\"use client\"" --include="*.tsx" app/ | wc -l
echo "client components in app/"

# Check image optimisation
find public -name "*.png" -o -name "*.jpg" | while read f; do
  SIZE=$(du -k "$f" | cut -f1)
  [ "$SIZE" -gt 200 ] && echo "⚠️  Large image ($SIZE KB): $f"
done

# Check for N+1 query patterns
grep -rn "\.all()" --include="*.ts" lib/ | head -5
```

---

### 6. Dead Code & Cleanup

```bash
# Unused exports
echo "=== Potentially unused exports ==="
for f in $(find lib components -name "*.ts" -o -name "*.tsx" | grep -v node_modules); do
  exports=$(grep "^export " "$f" | grep -o "function [a-zA-Z]*\|const [a-zA-Z]*\|interface [a-zA-Z]*" | awk '{print $2}')
  for exp in $exports; do
    count=$(grep -rn "$exp" --include="*.ts" --include="*.tsx" . | grep -v node_modules | grep -v "$f" | wc -l | tr -d ' ')
    [ "$count" -eq 0 ] && echo "  ⚠️  Possibly unused: $exp in $f"
  done
done 2>/dev/null | head -20

# Console.log left in
echo "=== Console.log ==="
grep -rn "console.log" --include="*.ts" --include="*.tsx" . | grep -v node_modules | grep -v "console.error" | wc -l

# TODO/FIXME/HACK
echo "=== TODOs ==="
grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.ts" --include="*.tsx" . | grep -v node_modules | wc -l
grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.ts" --include="*.tsx" . | grep -v node_modules
```

---

### 7. Test Coverage

```bash
# Check test files exist
echo "=== Test files ==="
find . -name "*.test.ts" -o -name "*.test.tsx" -o -name "*.spec.ts" | grep -v node_modules | wc -l

# Check testing docs
[ -f "docs/TESTING.md" ] && echo "✅ TESTING.md exists" || echo "❌ No TESTING.md"

# Run tests if available
npm test 2>&1 | tail -10
```

---

### 8. Best Practices (use Context7)

Before finishing the audit, check latest best practices:

```
/skill:context7 search "next.js security best practices"
/skill:context7 search "react server components patterns"
```

Compare current implementation against latest recommendations.

---

## Report Template

```
# Code Audit Report

**Project:** {project-name}
**Date:** {date}
**Version:** {from lib/version.ts}

## Score Card

| Area | Score | Notes |
|------|-------|-------|
| Playbook Compliance | ✅/⚠️/❌ | |
| TypeScript Quality | ✅/⚠️/❌ | X 'any' usages |
| Component Quality | ✅/⚠️/❌ | |
| API Routes | ✅/⚠️/❌ | X/Y routes have auth |
| Performance | ✅/⚠️/❌ | Bundle: X KB |
| Dead Code | ✅/⚠️/❌ | X console.logs, Y TODOs |
| Test Coverage | ✅/⚠️/❌ | X test files |
| Accessibility | ✅/⚠️/❌ | |

**Overall: X/8 passing**

## Findings

### Must Fix (❌)
1. Issue — file:line — remediation

### Should Fix (⚠️)
1. Issue — file:line — remediation

## Recommendations
1. Priority improvements
2. Playbook updates needed
3. Dependencies to update
```
