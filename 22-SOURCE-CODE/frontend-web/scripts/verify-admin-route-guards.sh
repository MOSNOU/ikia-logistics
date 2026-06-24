#!/usr/bin/env bash
# CC-06 / CC-07 / CC-24 / CC-25 / CC-26 / CC-27 / CC-28 / CC-29 / CC-30 / CC-31 / CC-32 / CC-33 / CC-34 / CC-36 / CC-37 / CC-38 / CC-41 / CC-42 / CC-43 / CC-44 / CC-46 / CC-47 / CC-48 / CC-50 — Route-guard verification.
#
# CC-47 adds no new routes — it self-hosts Leaflet assets, wires navigation
# links into existing guarded layouts, and polishes empty/stale states.
# The CC-46 tracking-map routes remain covered below.
#
# CC-48 adds the carrier telemetry reporting console at
# /carrier/tracking/[shipmentId]/report — write surface for carriers only,
# inheriting the existing /carrier guarded layout. Verified below alongside
# the CC-46 carrier tracking-map route. No buyer or admin telemetry-write
# routes are introduced (admin remains read-only for telemetry).
#
# CC-49 adds no new routes — it polishes /carrier/tracking/[shipmentId]/report
# with a live-capture panel and mobile-first section layout. No verification
# changes required.
#
# CC-50 adds the carrier driver console:
#   /carrier/driver/trips
#   /carrier/driver/trips/[shipmentId]
# Both inherit the existing /carrier guarded layout. No nested layout.tsx
# is allowed under /carrier/driver. No buyer or admin driver routes are
# introduced.
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
#     4b. CC-24 admin pricing pages exist:
#          /admin/pricing, /admin/pricing/currency-rates/new
#
#   SUPPLIER PORTAL:
#     5. src/app/supplier/layout.tsx exists and calls requireRole(...)
#        admitting SUPPLIER_ADMIN, ORGANIZATION_ADMIN, and PLATFORM_ADMIN.
#     6. No nested layout.tsx under src/app/supplier/ could bypass the gate.
#     7. Required CC-07 supplier portal pages exist:
#          /supplier/profile, /supplier/categories, /supplier/documents
#     7b. CC-24 supplier pricing pages exist:
#          /supplier/price-lists, /supplier/price-lists/new,
#          /supplier/price-lists/[listId], /supplier/quotations,
#          /supplier/quotations/new, /supplier/quotations/[quotationId]
#
#   BUYER PORTAL (CC-24):
#     8. src/app/buyer/layout.tsx exists and calls requireRole(...)
#        admitting BUYER_ADMIN, ORGANIZATION_ADMIN, and PLATFORM_ADMIN.
#     9. No nested layout.tsx under src/app/buyer/ could bypass the gate.
#    10. CC-24 buyer pages exist:
#          /buyer/quotations, /buyer/quotations/[quotationId]
#
# Exit code 0 = all checks passed. Non-zero = at least one check failed.

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ADMIN_DIR="$(cd "$HERE/../src/app/admin" && pwd)"
SUP_DIR="$(cd "$HERE/../src/app/supplier" && pwd)"
BUYER_DIR="$(cd "$HERE/../src/app/buyer" && pwd)"
ADMIN_LAYOUT="$ADMIN_DIR/layout.tsx"
SUP_LAYOUT="$SUP_DIR/layout.tsx"
BUYER_LAYOUT="$BUYER_DIR/layout.tsx"

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

# CC-24 admin pricing pages
for path in pricing "pricing/currency-rates/new"; do
  if [[ -f "$ADMIN_DIR/$path/page.tsx" ]]; then
    ok "/admin/$path/page.tsx exists"
  else
    fail "/admin/$path/page.tsx missing"
  fi
done

# CC-25 admin KYC pages
for path in kyc "kyc/[subjectType]/[verificationId]"; do
  if [[ -f "$ADMIN_DIR/$path/page.tsx" ]]; then
    ok "/admin/$path/page.tsx exists"
  else
    fail "/admin/$path/page.tsx missing"
  fi
done

# CC-26 admin notifications page
for path in notifications; do
  if [[ -f "$ADMIN_DIR/$path/page.tsx" ]]; then
    ok "/admin/$path/page.tsx exists"
  else
    fail "/admin/$path/page.tsx missing"
  fi
done

# CC-27 admin settlement + dispute pages
for path in settlements "settlements/[id]" disputes "disputes/[id]"; do
  if [[ -f "$ADMIN_DIR/$path/page.tsx" ]]; then
    ok "/admin/$path/page.tsx exists"
  else
    fail "/admin/$path/page.tsx missing"
  fi
done

# CC-28 admin RFQ + offer pages
for path in rfqs "rfqs/[id]" offers "offers/[id]"; do
  if [[ -f "$ADMIN_DIR/$path/page.tsx" ]]; then
    ok "/admin/$path/page.tsx exists"
  else
    fail "/admin/$path/page.tsx missing"
  fi
done

# CC-29 admin evaluation pages
for path in evaluations "evaluations/[id]"; do
  if [[ -f "$ADMIN_DIR/$path/page.tsx" ]]; then
    ok "/admin/$path/page.tsx exists"
  else
    fail "/admin/$path/page.tsx missing"
  fi
done

# CC-30 admin contract pages
for path in contracts "contracts/[id]"; do
  if [[ -f "$ADMIN_DIR/$path/page.tsx" ]]; then
    ok "/admin/$path/page.tsx exists"
  else
    fail "/admin/$path/page.tsx missing"
  fi
done

# CC-31 admin shipment pages
for path in shipments "shipments/[id]"; do
  if [[ -f "$ADMIN_DIR/$path/page.tsx" ]]; then
    ok "/admin/$path/page.tsx exists"
  else
    fail "/admin/$path/page.tsx missing"
  fi
done

# CC-32 admin shipment tracking sub-route
for path in "shipments/[id]/tracking"; do
  if [[ -f "$ADMIN_DIR/$path/page.tsx" ]]; then
    ok "/admin/$path/page.tsx exists"
  else
    fail "/admin/$path/page.tsx missing"
  fi
done

# CC-33 admin trade-document pages
for path in documents "documents/[id]"; do
  if [[ -f "$ADMIN_DIR/$path/page.tsx" ]]; then
    ok "/admin/$path/page.tsx exists"
  else
    fail "/admin/$path/page.tsx missing"
  fi
done

# CC-36 admin finance control-center pages
for path in finance "finance/settlements" "finance/settlements/[id]" "finance/exceptions"; do
  if [[ -f "$ADMIN_DIR/$path/page.tsx" ]]; then
    ok "/admin/$path/page.tsx exists"
  else
    fail "/admin/$path/page.tsx missing"
  fi
done

# CC-37 admin executive dashboard
for path in executive; do
  if [[ -f "$ADMIN_DIR/$path/page.tsx" ]]; then
    ok "/admin/$path/page.tsx exists"
  else
    fail "/admin/$path/page.tsx missing"
  fi
done

# CC-38 admin marketplace pages
for path in marketplace "marketplace/activity"; do
  if [[ -f "$ADMIN_DIR/$path/page.tsx" ]]; then
    ok "/admin/$path/page.tsx exists"
  else
    fail "/admin/$path/page.tsx missing"
  fi
done

# CC-41 admin matching pages
for path in matching "matching/[shipmentId]"; do
  if [[ -f "$ADMIN_DIR/$path/page.tsx" ]]; then
    ok "/admin/$path/page.tsx exists"
  else
    fail "/admin/$path/page.tsx missing"
  fi
done

# CC-42 admin booking pages
for path in bookings "bookings/[id]"; do
  if [[ -f "$ADMIN_DIR/$path/page.tsx" ]]; then
    ok "/admin/$path/page.tsx exists"
  else
    fail "/admin/$path/page.tsx missing"
  fi
done

# CC-43 admin dispatch pages
for path in dispatches "dispatches/[id]"; do
  if [[ -f "$ADMIN_DIR/$path/page.tsx" ]]; then
    ok "/admin/$path/page.tsx exists"
  else
    fail "/admin/$path/page.tsx missing"
  fi
done

# CC-44 admin control tower pages
for path in control-tower "control-tower/activity" "control-tower/exceptions"; do
  if [[ -f "$ADMIN_DIR/$path/page.tsx" ]]; then
    ok "/admin/$path/page.tsx exists"
  else
    fail "/admin/$path/page.tsx missing"
  fi
done

# CC-46 admin tracking map pages
for path in "tracking/[shipmentId]/map" "tracking/live"; do
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

# CC-24 supplier pricing pages
for path in \
  price-lists \
  "price-lists/new" \
  "price-lists/[listId]" \
  quotations \
  "quotations/new" \
  "quotations/[quotationId]"; do
  if [[ -f "$SUP_DIR/$path/page.tsx" ]]; then
    ok "/supplier/$path/page.tsx exists"
  else
    fail "/supplier/$path/page.tsx missing"
  fi
done

# CC-25 supplier KYB page
for path in kyb; do
  if [[ -f "$SUP_DIR/$path/page.tsx" ]]; then
    ok "/supplier/$path/page.tsx exists"
  else
    fail "/supplier/$path/page.tsx missing"
  fi
done

# CC-27 supplier settlement + dispute pages
for path in settlements "settlements/[id]" disputes "disputes/[id]"; do
  if [[ -f "$SUP_DIR/$path/page.tsx" ]]; then
    ok "/supplier/$path/page.tsx exists"
  else
    fail "/supplier/$path/page.tsx missing"
  fi
done

# CC-28 supplier RFQ + offer pages
for path in rfqs "rfqs/[id]" offers "offers/[id]"; do
  if [[ -f "$SUP_DIR/$path/page.tsx" ]]; then
    ok "/supplier/$path/page.tsx exists"
  else
    fail "/supplier/$path/page.tsx missing"
  fi
done

# CC-30 supplier contract pages
for path in contracts "contracts/[id]"; do
  if [[ -f "$SUP_DIR/$path/page.tsx" ]]; then
    ok "/supplier/$path/page.tsx exists"
  else
    fail "/supplier/$path/page.tsx missing"
  fi
done

# CC-31 supplier shipment pages
for path in shipments "shipments/[id]"; do
  if [[ -f "$SUP_DIR/$path/page.tsx" ]]; then
    ok "/supplier/$path/page.tsx exists"
  else
    fail "/supplier/$path/page.tsx missing"
  fi
done

# CC-32 supplier shipment tracking sub-route
for path in "shipments/[id]/tracking"; do
  if [[ -f "$SUP_DIR/$path/page.tsx" ]]; then
    ok "/supplier/$path/page.tsx exists"
  else
    fail "/supplier/$path/page.tsx missing"
  fi
done

# CC-33 supplier trade-documents page (summary view)
for path in trade-documents; do
  if [[ -f "$SUP_DIR/$path/page.tsx" ]]; then
    ok "/supplier/$path/page.tsx exists"
  else
    fail "/supplier/$path/page.tsx missing"
  fi
done

# CC-36 supplier finance pages
for path in finance "finance/settlements" "finance/settlements/[id]"; do
  if [[ -f "$SUP_DIR/$path/page.tsx" ]]; then
    ok "/supplier/$path/page.tsx exists"
  else
    fail "/supplier/$path/page.tsx missing"
  fi
done

# CC-37 supplier executive dashboard
for path in executive; do
  if [[ -f "$SUP_DIR/$path/page.tsx" ]]; then
    ok "/supplier/$path/page.tsx exists"
  else
    fail "/supplier/$path/page.tsx missing"
  fi
done

# CC-38 supplier marketplace pages
for path in marketplace "marketplace/capacity" "marketplace/publish"; do
  if [[ -f "$SUP_DIR/$path/page.tsx" ]]; then
    ok "/supplier/$path/page.tsx exists"
  else
    fail "/supplier/$path/page.tsx missing"
  fi
done

echo ""
echo "--- Buyer portal ---"

if [[ -f "$BUYER_LAYOUT" ]]; then
  ok "src/app/buyer/layout.tsx exists"
else
  fail "src/app/buyer/layout.tsx missing"
fi

if [[ -f "$BUYER_LAYOUT" ]]; then
  if grep -E 'requireRole\(\s*\[' "$BUYER_LAYOUT" >/dev/null \
     && grep -E 'ROLES\.BUYER_ADMIN'         "$BUYER_LAYOUT" >/dev/null \
     && grep -E 'ROLES\.ORGANIZATION_ADMIN'  "$BUYER_LAYOUT" >/dev/null \
     && grep -E 'ROLES\.PLATFORM_ADMIN'      "$BUYER_LAYOUT" >/dev/null; then
    ok "buyer layout calls requireRole([BUYER_ADMIN, ORGANIZATION_ADMIN, PLATFORM_ADMIN])"
  else
    fail "buyer layout does not gate on the expected role set"
  fi
fi

nested_buyer=$(find "$BUYER_DIR" -mindepth 2 -name layout.tsx 2>/dev/null)
if [[ -z "$nested_buyer" ]]; then
  ok "no nested layout.tsx under src/app/buyer/"
else
  fail "nested layout.tsx detected under src/app/buyer/:"
  echo "$nested_buyer" | sed 's/^/      /'
fi

# CC-24 buyer quotation pages
for path in quotations "quotations/[quotationId]"; do
  if [[ -f "$BUYER_DIR/$path/page.tsx" ]]; then
    ok "/buyer/$path/page.tsx exists"
  else
    fail "/buyer/$path/page.tsx missing"
  fi
done

# CC-27 buyer settlement + dispute pages
for path in settlements "settlements/[id]" disputes "disputes/[id]"; do
  if [[ -f "$BUYER_DIR/$path/page.tsx" ]]; then
    ok "/buyer/$path/page.tsx exists"
  else
    fail "/buyer/$path/page.tsx missing"
  fi
done

# CC-28 buyer RFQ pages (RFQ list + new + detail)
for path in rfqs "rfqs/new" "rfqs/[id]"; do
  if [[ -f "$BUYER_DIR/$path/page.tsx" ]]; then
    ok "/buyer/$path/page.tsx exists"
  else
    fail "/buyer/$path/page.tsx missing"
  fi
done

# CC-29 buyer evaluation pages
for path in evaluations "evaluations/[id]" "rfqs/[id]/evaluate"; do
  if [[ -f "$BUYER_DIR/$path/page.tsx" ]]; then
    ok "/buyer/$path/page.tsx exists"
  else
    fail "/buyer/$path/page.tsx missing"
  fi
done

# CC-30 buyer contract pages
for path in contracts "contracts/new" "contracts/[id]"; do
  if [[ -f "$BUYER_DIR/$path/page.tsx" ]]; then
    ok "/buyer/$path/page.tsx exists"
  else
    fail "/buyer/$path/page.tsx missing"
  fi
done

# CC-31 buyer shipment pages
for path in shipments "shipments/new" "shipments/[id]"; do
  if [[ -f "$BUYER_DIR/$path/page.tsx" ]]; then
    ok "/buyer/$path/page.tsx exists"
  else
    fail "/buyer/$path/page.tsx missing"
  fi
done

# CC-32 buyer shipment tracking sub-route
for path in "shipments/[id]/tracking"; do
  if [[ -f "$BUYER_DIR/$path/page.tsx" ]]; then
    ok "/buyer/$path/page.tsx exists"
  else
    fail "/buyer/$path/page.tsx missing"
  fi
done

# CC-33 buyer trade-document pages
for path in documents "documents/[id]"; do
  if [[ -f "$BUYER_DIR/$path/page.tsx" ]]; then
    ok "/buyer/$path/page.tsx exists"
  else
    fail "/buyer/$path/page.tsx missing"
  fi
done

# CC-34 buyer trade-document lifecycle pages (requirements + doc create/edit + files)
for path in \
  "shipments/[id]/requirements" \
  "shipments/[id]/requirements/[reqId]/edit" \
  "documents/new" \
  "documents/[id]/edit" \
  "documents/[id]/files"; do
  if [[ -f "$BUYER_DIR/$path/page.tsx" ]]; then
    ok "/buyer/$path/page.tsx exists"
  else
    fail "/buyer/$path/page.tsx missing"
  fi
done

# CC-36 buyer finance pages
for path in finance "finance/settlements" "finance/settlements/[id]"; do
  if [[ -f "$BUYER_DIR/$path/page.tsx" ]]; then
    ok "/buyer/$path/page.tsx exists"
  else
    fail "/buyer/$path/page.tsx missing"
  fi
done

# CC-37 buyer executive dashboard
for path in executive; do
  if [[ -f "$BUYER_DIR/$path/page.tsx" ]]; then
    ok "/buyer/$path/page.tsx exists"
  else
    fail "/buyer/$path/page.tsx missing"
  fi
done

# CC-38 buyer marketplace pages
for path in marketplace "marketplace/carriers" "marketplace/capacity"; do
  if [[ -f "$BUYER_DIR/$path/page.tsx" ]]; then
    ok "/buyer/$path/page.tsx exists"
  else
    fail "/buyer/$path/page.tsx missing"
  fi
done

# CC-41 buyer shipment matching page
for path in "shipments/[id]/matching"; do
  if [[ -f "$BUYER_DIR/$path/page.tsx" ]]; then
    ok "/buyer/$path/page.tsx exists"
  else
    fail "/buyer/$path/page.tsx missing"
  fi
done

# CC-42 buyer booking pages
for path in bookings "bookings/[id]"; do
  if [[ -f "$BUYER_DIR/$path/page.tsx" ]]; then
    ok "/buyer/$path/page.tsx exists"
  else
    fail "/buyer/$path/page.tsx missing"
  fi
done

# CC-43 buyer dispatch pages
for path in dispatches "dispatches/[id]"; do
  if [[ -f "$BUYER_DIR/$path/page.tsx" ]]; then
    ok "/buyer/$path/page.tsx exists"
  else
    fail "/buyer/$path/page.tsx missing"
  fi
done

# CC-44 buyer control tower
for path in control-tower; do
  if [[ -f "$BUYER_DIR/$path/page.tsx" ]]; then
    ok "/buyer/$path/page.tsx exists"
  else
    fail "/buyer/$path/page.tsx missing"
  fi
done

# CC-46 buyer tracking map page
for path in "tracking/[shipmentId]/map"; do
  if [[ -f "$BUYER_DIR/$path/page.tsx" ]]; then
    ok "/buyer/$path/page.tsx exists"
  else
    fail "/buyer/$path/page.tsx missing"
  fi
done

echo ""
echo "--- Carrier portal ---"

CARRIER_DIR="$(cd "$HERE/../src/app/carrier" && pwd)"
CARRIER_LAYOUT="$CARRIER_DIR/layout.tsx"

if [[ -f "$CARRIER_LAYOUT" ]]; then
  ok "src/app/carrier/layout.tsx exists"
  if grep -E 'requireRole\(\s*\[' "$CARRIER_LAYOUT" >/dev/null \
     && grep -E 'ROLES\.CARRIER_ADMIN'       "$CARRIER_LAYOUT" >/dev/null \
     && grep -E 'ROLES\.ORGANIZATION_ADMIN'  "$CARRIER_LAYOUT" >/dev/null \
     && grep -E 'ROLES\.PLATFORM_ADMIN'      "$CARRIER_LAYOUT" >/dev/null; then
    ok "carrier layout calls requireRole([CARRIER_ADMIN, ORGANIZATION_ADMIN, PLATFORM_ADMIN])"
  else
    fail "carrier layout does not gate on the expected role set"
  fi
else
  fail "src/app/carrier/layout.tsx missing"
fi

nested_carrier=$(find "$CARRIER_DIR" -mindepth 2 -name layout.tsx 2>/dev/null)
if [[ -z "$nested_carrier" ]]; then
  ok "no nested layout.tsx under src/app/carrier/"
else
  fail "nested layout.tsx detected under src/app/carrier/:"
  echo "$nested_carrier" | sed 's/^/      /'
fi

# CC-42 carrier booking pages
for path in bookings "bookings/[id]"; do
  if [[ -f "$CARRIER_DIR/$path/page.tsx" ]]; then
    ok "/carrier/$path/page.tsx exists"
  else
    fail "/carrier/$path/page.tsx missing"
  fi
done

# CC-43 carrier dispatch pages
for path in dispatches "dispatches/[id]"; do
  if [[ -f "$CARRIER_DIR/$path/page.tsx" ]]; then
    ok "/carrier/$path/page.tsx exists"
  else
    fail "/carrier/$path/page.tsx missing"
  fi
done

# CC-44 carrier control tower
for path in control-tower; do
  if [[ -f "$CARRIER_DIR/$path/page.tsx" ]]; then
    ok "/carrier/$path/page.tsx exists"
  else
    fail "/carrier/$path/page.tsx missing"
  fi
done

# CC-46 carrier tracking map page
for path in "tracking/[shipmentId]/map"; do
  if [[ -f "$CARRIER_DIR/$path/page.tsx" ]]; then
    ok "/carrier/$path/page.tsx exists"
  else
    fail "/carrier/$path/page.tsx missing"
  fi
done

# CC-48 carrier telemetry reporting console (write surface).
# Lives under the carrier guarded layout — no separate layout.tsx beneath.
for path in "tracking/[shipmentId]/report"; do
  if [[ -f "$CARRIER_DIR/$path/page.tsx" ]]; then
    ok "/carrier/$path/page.tsx exists"
  else
    fail "/carrier/$path/page.tsx missing"
  fi
  if [[ -f "$CARRIER_DIR/$path/layout.tsx" ]]; then
    fail "/carrier/$path/layout.tsx exists — must not introduce a nested layout (CC-48 boundary)"
  else
    ok "/carrier/$path has no nested layout.tsx (CC-48 boundary preserved)"
  fi
done

# CC-50 driver console (mobile-first trip list + per-trip detail).
# Both routes inherit the existing /carrier guarded layout — no nested
# layout.tsx is permitted beneath /carrier/driver.
for path in "driver/trips" "driver/trips/[shipmentId]"; do
  if [[ -f "$CARRIER_DIR/$path/page.tsx" ]]; then
    ok "/carrier/$path/page.tsx exists"
  else
    fail "/carrier/$path/page.tsx missing"
  fi
done
if [[ -f "$CARRIER_DIR/driver/layout.tsx" ]]; then
  fail "/carrier/driver/layout.tsx exists — CC-50 must not introduce a nested layout"
else
  ok "/carrier/driver has no nested layout.tsx (CC-50 boundary preserved)"
fi
if [[ -f "$CARRIER_DIR/driver/trips/layout.tsx" ]]; then
  fail "/carrier/driver/trips/layout.tsx exists — CC-50 must not introduce a nested layout"
else
  ok "/carrier/driver/trips has no nested layout.tsx (CC-50 boundary preserved)"
fi

echo ""
echo "--- Inbox portal (CC-26) ---"

# CC-26 /inbox routes use per-page getProfile() guards (no inbox/layout.tsx).
INBOX_DIR="$(cd "$HERE/../src/app/inbox" && pwd)"
for path in "" "[notificationId]" "preferences"; do
  fullpath="$INBOX_DIR${path:+/$path}/page.tsx"
  label="/inbox${path:+/$path}/page.tsx"
  if [[ -f "$fullpath" ]]; then
    ok "$label exists"
    if grep -E 'getProfile' "$fullpath" >/dev/null \
       && grep -E 'redirect\("/login"\)' "$fullpath" >/dev/null; then
      ok "$label calls getProfile() and redirects to /login when unauthenticated"
    else
      fail "$label does not perform the expected auth check"
    fi
  else
    fail "$label missing"
  fi
done

echo ""
echo "--- Personal KYC portal (CC-25) ---"

# CC-25 /profile/kyc: the /profile route family relies on per-page getProfile()
# guards (no /profile/layout.tsx). We verify the page exists and that it does
# the per-page redirect on missing profile.
PROFILE_KYC_DIR="$(cd "$HERE/../src/app/profile" && pwd)"
if [[ -f "$PROFILE_KYC_DIR/kyc/page.tsx" ]]; then
  ok "/profile/kyc/page.tsx exists"
else
  fail "/profile/kyc/page.tsx missing"
fi

if [[ -f "$PROFILE_KYC_DIR/kyc/page.tsx" ]]; then
  if grep -E 'getProfile' "$PROFILE_KYC_DIR/kyc/page.tsx" >/dev/null \
     && grep -E 'redirect\("/login"\)' "$PROFILE_KYC_DIR/kyc/page.tsx" >/dev/null; then
    ok "/profile/kyc/page.tsx calls getProfile() and redirects to /login when unauthenticated"
  else
    fail "/profile/kyc/page.tsx does not perform the expected auth check"
  fi
fi

echo ""
if [[ "$FAIL" -ne 0 ]]; then
  echo "VERIFICATION FAILED"
  exit 1
fi
echo "VERIFICATION PASSED"
