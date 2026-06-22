#!/usr/bin/env bash
# CC-06 / CC-07 — Route-guard verification.
#
# Proves at build time, without spinning up a browser, that:
#   ADMIN PORTAL:
#     1. src/app/admin/layout.tsx exists and calls
#        requireRole(ROLES.PLATFORM_ADMIN).
#     2. No nested layout.tsx under src/app/admin/ could bypass the gate.
#     3. Required CC-06 admin pages exist:
#          /admin/users, /admin/organizations, /admin/audit
#     4. Required CC-07 admin pages exist:
#          /admin/suppliers, /admin/suppliers/[supplierId]
#
#   SUPPLIER PORTAL:
#     5. src/app/supplier/layout.tsx exists and calls requireRole(...)
#        admitting SUPPLIER_ADMIN, ORGANIZATION_ADMIN, and PLATFORM_ADMIN.
#     6. No nested layout.tsx under src/app/supplier/ could bypass the gate.
#     7. Required CC-07 supplier portal pages exist:
#          /supplier/profile, /supplier/categories, /supplier/documents
#
# Exit code 0 = all checks passed. Non-zero = at least one check failed.

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ADMIN_DIR="$(cd "$HERE/../src/app/admin" && pwd)"
SUP_DIR="$(cd "$HERE/../src/app/supplier" && pwd)"
ADMIN_LAYOUT="$ADMIN_DIR/layout.tsx"
SUP_LAYOUT="$SUP_DIR/layout.tsx"

FAIL=0
ok()   { echo "OK:   $*"; }
fail() { echo "FAIL: $*"; FAIL=1; }

echo "=== CC-06/07 route-guard verification ==="
echo ""
echo "--- Admin portal ---"

if [[ -f "$ADMIN_LAYOUT" ]]; then
  ok "src/app/admin/layout.tsx exists"
else
  fail "src/app/admin/layout.tsx missing"
fi

if [[ -f "$ADMIN_LAYOUT" ]]; then
  if grep -E 'requireRole\(\s*ROLES\.PLATFORM_ADMIN' "$ADMIN_LAYOUT" >/dev/null; then
    ok "admin layout calls requireRole(ROLES.PLATFORM_ADMIN)"
  else
    fail "admin layout does not gate on ROLES.PLATFORM_ADMIN"
  fi
fi

nested_admin=$(find "$ADMIN_DIR" -mindepth 2 -name layout.tsx 2>/dev/null)
if [[ -z "$nested_admin" ]]; then
  ok "no nested layout.tsx under src/app/admin/"
else
  fail "nested layout.tsx detected under src/app/admin/:"
  echo "$nested_admin" | sed 's/^/      /'
fi

for path in users organizations audit; do
  if [[ -f "$ADMIN_DIR/$path/page.tsx" ]]; then
    ok "/admin/$path/page.tsx exists"
  else
    fail "/admin/$path/page.tsx missing"
  fi
done

# CC-07 admin supplier pages
for path in suppliers "suppliers/[supplierId]"; do
  if [[ -f "$ADMIN_DIR/$path/page.tsx" ]]; then
    ok "/admin/$path/page.tsx exists"
  else
    fail "/admin/$path/page.tsx missing"
  fi
done

echo ""
echo "--- Supplier portal ---"

if [[ -f "$SUP_LAYOUT" ]]; then
  ok "src/app/supplier/layout.tsx exists"
else
  fail "src/app/supplier/layout.tsx missing"
fi

if [[ -f "$SUP_LAYOUT" ]]; then
  if grep -E 'requireRole\(\s*\[' "$SUP_LAYOUT" >/dev/null \
     && grep -E 'ROLES\.SUPPLIER_ADMIN'      "$SUP_LAYOUT" >/dev/null \
     && grep -E 'ROLES\.ORGANIZATION_ADMIN'  "$SUP_LAYOUT" >/dev/null \
     && grep -E 'ROLES\.PLATFORM_ADMIN'      "$SUP_LAYOUT" >/dev/null; then
    ok "supplier layout calls requireRole([SUPPLIER_ADMIN, ORGANIZATION_ADMIN, PLATFORM_ADMIN])"
  else
    fail "supplier layout does not gate on the expected role set"
  fi
fi

nested_sup=$(find "$SUP_DIR" -mindepth 2 -name layout.tsx 2>/dev/null)
if [[ -z "$nested_sup" ]]; then
  ok "no nested layout.tsx under src/app/supplier/"
else
  fail "nested layout.tsx detected under src/app/supplier/:"
  echo "$nested_sup" | sed 's/^/      /'
fi

for path in profile categories documents; do
  if [[ -f "$SUP_DIR/$path/page.tsx" ]]; then
    ok "/supplier/$path/page.tsx exists"
  else
    fail "/supplier/$path/page.tsx missing"
  fi
done

echo ""
if [[ "$FAIL" -ne 0 ]]; then
  echo "VERIFICATION FAILED"
  exit 1
fi
echo "VERIFICATION PASSED"
