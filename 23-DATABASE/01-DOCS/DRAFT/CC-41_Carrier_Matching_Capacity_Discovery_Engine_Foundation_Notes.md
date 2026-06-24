# CC-41 — Carrier Matching & Capacity Discovery Engine Foundation

## Mission
Add the first advisory linkage between shipments and the marketplace
(carrier_profiles + capacity_listings). Compute-on-demand only. No booking,
no assignment, no shipment mutation, no reservation, no pricing.

## Locked decisions (Q1–Q10 = A, plus clarifications)
- **Q1=A** RPC-only matching; no persistence.
- **Q2=A** Scores computed on demand.
- **Q3=A** Buyer + admin frontend (3 routes total).
- **Q4=A** Supplier visibility = none.
- **Q5=A** Fixed weights table is authoritative; total possible = 100.
  - transport_mode = 35
  - origin = 20 (country 15 + city refinement 5)
  - destination = 20 (country 15 + city refinement 5)
  - availability_window = 15 (full in-window or both windows null; 7 if
    pickup_date is null but listing window exists; 0 if outside)
  - profile_completeness = 5 (1 point per filled field, capped at 5)
  - directory_visibility = 5 (binary on is_public=true)
- **Q6=A** No audit table.
- **Q7=A** Summary metrics only.
- **Q8=A** Only `status='active'` listings considered (also filters
  `valid_until > now()`).
- **Q9=A** Carriers ranked by best matching active capacity; carriers with
  no active match fall back to profile + visibility, capped at 10.
- **Q10=A** Stop after validation report.

Clarifications applied verbatim:
- Country match is required for the main origin/destination score; city
  match is a +5 refinement within the same bucket.
- "total_match_requests" is the derived eligible-shipment count (last 100
  shipments in planned/booked/in_transit) because there is no audit table.
- Mode mismatch zeroes the **mode component only**, not the whole row.
  Other components still contribute under the soft-weights model. A listing
  is filtered out only when its total score is 0.

## Boundaries respected
- No new tables or enums. No changes to supplier or shipment schemas/RPCs.
- Migrations 0001–0033 untouched. Migration 0034 appends only marketplace
  RPCs.
- Notify and audit channels untouched (no new templates, no new triggers).
- `supabase/config.toml` unchanged (marketplace schema was already exposed
  in CC-39).
- No new package dependencies.
- No booking / dispatch / assignment / capacity reservation / carrier
  acceptance / pricing / quotation / payment / GPS / ETA / AI / ML /
  route-optimization logic introduced.

## Files created (10)

### Migration
- `23-DATABASE/migrations/0034_marketplace_matching.sql` — 6 functions
  (1 visibility helper + 2 scoring helpers + 3 audience RPCs) and 3 grants.

### pgTAP tests
- `tests/109_matching_rpc_shape.sql` — 8 assertions
- `tests/110_matching_visibility.sql` — 5 assertions
- `tests/111_matching_scoring.sql` — 7 assertions
- `tests/112_matching_admin_summary.sql` — 4 assertions

Total added: **+4 files / +24 assertions** (108/842 → 112/866).

### Frontend
- `src/lib/marketplace/find-matching.ts` — orchestrator over the two find_*
  RPCs plus the admin summary loader. Translates RPC error codes (42501 /
  P0002) into Persian copy.
- `src/components/marketplace/matching-results.tsx` —
  `MatchingCapacityTable` and `MatchingCarriersTable`. No action buttons,
  no booking/reserve/assign affordances. Score breakdown surfaced as pills.
- `src/app/buyer/shipments/[id]/matching/page.tsx` — buyer-side detail.
- `src/app/admin/matching/page.tsx` — admin KPI dashboard with eligible
  shipment list.
- `src/app/admin/matching/[shipmentId]/page.tsx` — admin per-shipment view.

### Sidecar types (`src/types/database.compat.ts` — CC-41 block)
- `MatchingScoreBreakdown`, `CapacityMatchRow`, `CarrierMatchRow`,
  `MatchingSummary`.

### Notes
- `23-DATABASE/01-DOCS/DRAFT/CC-41_Carrier_Matching_Capacity_Discovery_Engine_Foundation_Notes.md`

## Files modified (3)
- `src/types/database.ts` — regenerated via `supabase gen types typescript
  --local` so the supabase client recognises the 3 new RPC names. CC-21
  sidecar barrel re-appended after regeneration.
- `src/types/database.compat.ts` — CC-41 block appended.
- `scripts/verify-admin-route-guards.sh` — header bumped and three CC-41
  route checks added (one under each portal section). 3 new route checks.

## Mid-execution findings

1. **`#variable_conflict use_column` was required.** The matching RPCs
   declare RETURNS TABLE OUT parameters with the same names
   (`carrier_organization_id`, `score`, `score_breakdown`) as the inner
   CTE columns. Without `#variable_conflict use_column`, PostgreSQL flagged
   `carrier_organization_id is ambiguous` at the RETURN QUERY step.
2. **Supplier shell trigger collision.** `supplier.fn_create_supplier_shell`
   auto-creates a `supplier.suppliers` row on `organization.organizations`
   insert when `type='supplier'`. Tests originally tried to insert a second
   shell with hand-rolled UUIDs and hit `suppliers_organization_id_key`.
   Resolved by removing explicit supplier inserts and pulling supplier_id
   via `select id from supplier.suppliers where organization_id = ...`.
3. **Test contract chain required full FK stubbing.** Shipments require an
   `executed_contract` which requires `preparation_id`, `decision_id`,
   `request_id`, and `offer_id`. Each test now inserts the full stub chain
   (rfq → offer → decision → preparation → executed_contract → shipment)
   before exercising the matching engine.
4. **Soft-weights model surprise.** The original test expected
   transport-mode mismatch to exclude the listing. Under the locked
   weights-table model, mode mismatch zeros only the 35-point mode
   component; other components (origin + destination + availability +
   profile + visibility = up to 65) still contribute. Test 111 assertion 2
   and test 112 assertion 3 were rewritten to reflect this; the soft-weight
   behaviour itself was kept, matching the brief's authoritative weights
   table.
5. **`unmatched_shipments` definition.** With any active+public listing
   present, the soft-weights scorer almost always returns score > 0, so
   "unmatched" effectively means "no scored row". Test 112 isolates this
   by leaving the marketplace empty for the test transaction, exercising
   the genuine no-match path.
6. **Within-transaction `now()` ordering ties** noted in CC-39 do not
   affect CC-41 because the matching RPCs sort by score (numeric) and
   id (uuid) as tiebreaker.

## Validation results

| Gate | Target | Result |
|---|---|---|
| `bash 23-DATABASE/tests/run.sh` | 112 / ~875 / 0 | **112 / 866 / 0** ✓ |
| `npm run typecheck` | 0 errors | **0 errors** ✓ |
| `npm run build` | exit 0 | **exit 0** ✓ |
| `bash scripts/verify-admin-route-guards.sh` | VERIFICATION PASSED | **VERIFICATION PASSED** ✓ |

Route count: **118 → 121** (+3 routes — exactly the three specified in the
brief).

## Confirmation
No changes to supplier or shipment schemas/RPCs. Migrations 0001–0033
untouched. No booking, dispatch, assignment, reservation, shipment
mutation, pricing, GPS, AI/ML, or route-optimization logic added. No new
dependencies. No nav entries.
