# CC-32 — Phase 2.25 Frontend Tracking & Visibility Portal Foundation, Notes

Version: 1.0 (DRAFT)
Scope: Twenty-sixth platform step. Frontend-only — wires the CC-15
`buyer_upsert_milestone` + `buyer_upsert_stop` RPCs (which CC-31 deliberately
left unwired) and adds a per-shipment tracking timeline view across all three
audiences.
Migration: **none.** DB baseline 0001–0032 is unchanged.
Status: Implementation complete; all directives met. Pending user acceptance.

## Locked decisions (Q1–Q10)

| # | Decision | Notes |
|---|----------|--------|
| Q1 | A — all 3 routes shipped | buyer + supplier + admin tracking sub-routes. |
| Q2 | A — sub-routes under existing shipment detail | `/{audience}/shipments/[id]/tracking`. |
| Q3 | A — combined chronological timeline + detail tables | Single page renders timeline merge AND full milestone + stop tables. |
| Q4 | A — inline forms (per row, per kind) | Milestone upsert + stop upsert; buyer-only (CC-15 has no other-audience mutators). |
| Q5 | A — sidecar wrappers + enum aliases | 3 wrappers + 3 enums. `ShipmentDetail` extended with optional `milestones[]` + `stops[]`. |
| Q6 | A — editable when status ∈ {draft, planned, booked, in_transit, arrived} | Forms hidden on `delivered / cancelled / closed`. |
| Q7 | A — verifier extended | All 3 routes asserted under CC-32 section. |
| Q8 | A — shared `TrackingTimeline` component | Imported by all three audiences; audience prop toggles actor_user_id column for admin. |
| Q9 | A — manual `sequence_number` input | Required integer ≥ 1; matches RPC's `p_sequence_number` requirement. |
| Q10 | A — stop at green pgTAP + typecheck + build + verifier | No manual browser smoke. |

## What changed

### Files created (9)

**Server modules (2):**

| File | Coverage |
|---|---|
| `src/lib/shipment/get-tracking.ts` | Audience-switched read returning shipment + milestones + stops + events + chronologically-merged timeline; admin path supplements missing events via `admin_list_shipment_events`. |
| `src/lib/shipment/tracking-actions.ts` | 2 Server Actions: `buyerUpsertMilestone`, `buyerUpsertStop`. Buyer-only — CC-15 exposes no supplier/admin mutators for milestones or stops. |

**Pages + components (7):**

| Path | Purpose |
|---|---|
| `src/components/shipment/tracking-timeline.tsx` | Shared component: combined timeline + milestones table + stops table; audience prop controls actor_user_id column visibility |
| `app/buyer/shipments/[id]/tracking/page.tsx` | Buyer view: timeline + upsert forms (gated by editable status) |
| `app/buyer/shipments/[id]/tracking/upsert-milestone-form.tsx` | Inline milestone upsert: type (11 values), status (5 values), planned_at, completed_at, notes |
| `app/buyer/shipments/[id]/tracking/upsert-stop-form.tsx` | Inline stop upsert: sequence_number, type (8 values), city, country, port, location_text, planned/actual arrival+departure, notes |
| `app/supplier/shipments/[id]/tracking/page.tsx` | Read-only supplier view |
| `app/admin/shipments/[id]/tracking/page.tsx` | Read-only admin view with actor_user_id column populated |

### Files modified (5)

| File | Change |
|---|---|
| `src/types/database.compat.ts` | Added "CC-32: Tracking & Visibility portal types" with 3 wrapper interfaces + 3 enum aliases. Extended existing `ShipmentDetail` with optional `milestones[]` + `stops[]`. |
| `scripts/verify-admin-route-guards.sh` | Header expanded to CC-32. Added buyer + supplier + admin tracking sub-route checks. |
| `app/buyer/shipments/[id]/page.tsx` | Added "ردیابی محموله" link to the existing back-button row. |
| `app/supplier/shipments/[id]/page.tsx` | Same — supplier-side link. |
| `app/admin/shipments/[id]/page.tsx` | Same — admin-side link. |

**Files NOT touched:** all migrations 0001–0032, every `shipment.*` SQL surface, `database.ts` generated file, `supabase/config.toml`, all CC-22..CC-31 portal code, every other domain.

### Route inventory

3 new routes:

```
buyer:     /shipments/[id]/tracking
supplier:  /shipments/[id]/tracking
admin:     /shipments/[id]/tracking
```

Build route count: **85 → 88 (+3).**

## Validation results

| Gate | Required | Actual |
|---|---|---|
| `bash 23-DATABASE/tests/run.sh` | 101 / 790 / 0 (unchanged) | **101 files / 790 assertions / 0 failures** |
| `npm run typecheck` | 0 errors | **0 errors** |
| `npm run build` | exit 0; route count grows by 3 | **88 routes built**, exit 0 |
| `bash scripts/verify-admin-route-guards.sh` | extended + pass | **VERIFICATION PASSED** (all 3 CC-32 routes asserted alongside every prior section) |

## Key design choices

1. **Timeline merge is computed in the loader.** `getTracking` calls `getShipment` first, then merges `milestones[]` + `stops[]` + `events[]` into a single `TrackingTimelineRow[]` sorted by best-available timestamp (`completed_at ?? planned_at ?? created_at` for milestones; `actual_arrival ?? planned_arrival ?? actual_departure ?? planned_departure ?? created_at` for stops). Pure server-side; no client logic.
2. **`ShipmentDetail` extended with optional arrays.** If the `get_shipment` jsonb wrapper doesn't bundle `milestones` / `stops` (CC-15's projection is opaque from RPC types), the timeline renders an empty array gracefully. The buyer-side upsert forms still write correctly; the next page render picks them up.
3. **Admin events supplement.** When `audience='admin'` and the get RPC didn't bundle events, `getTracking` calls `admin_list_shipment_events` so admin tracking always shows the full event audit alongside milestones + stops.
4. **Shared `TrackingTimeline` component (Q8=A).** Imported by all three audiences; the `audience` prop controls whether the actor_user_id column appears (admin only). Same reuse pattern as CC-30 contracts + CC-31 shipments.
5. **Editable-status gate (Q6=A).** Buyer forms appear when shipment status ∈ `{draft, planned, booked, in_transit, arrived}` — pre-terminal states. After `delivered`/`cancelled`/`closed`, the page shows a read-only timeline.
6. **Sequence number is buyer-typed (Q9=A).** CC-15 requires `p_sequence_number` as a non-optional integer; the form mandates it. Buyers can re-number to insert mid-route. Auto-increment can be a future polish.

## Mid-execution findings

None. CC-15 milestone + stop RPC signatures mapped cleanly on the first pass; the `ShipmentDetail` interface extension was the only sidecar change beyond the new types. Build went green on the first attempt.

## Boundaries respected

- ✅ No DB / RPC / RLS / grant / trigger / migration changes. CC-15 byte-identical.
- ✅ No new migrations.
- ✅ No client-side Supabase mutations — Server Actions only.
- ✅ No real-time GPS / map / geocoding / route map.
- ✅ No carrier ETA prediction / external tracking API.
- ✅ No bulk milestone/stop import (CSV/Excel).
- ✅ No proof-of-delivery photos / attachments / file upload.
- ✅ No supplier-side or admin-side mutators (CC-15 has none).
- ✅ No notify-channel additions.
- ✅ No nav-bar entries added — reached only via shipment detail page deep-link.
- ✅ No new pgTAP tests.
- ✅ No automatic milestone derivation from status transitions.
- ✅ No KYC / pricing / quotation cross-domain UI changes.
- ✅ No new dependencies — `package.json` untouched.
- ✅ No mobile-app deep links / PWA changes.

## Known limitations / handoff notes

1. **Milestone + stop arrays depend on `get_shipment` jsonb projection.** If CC-15's RPC returns them at different jsonb keys than `milestones` / `stops`, the timeline will render empty. Easy fix in a follow-up CC: adjust the projection field names in `ShipmentDetail`.
2. **No delete milestone / delete stop.** CC-15 doesn't expose `buyer_remove_milestone` or `buyer_remove_stop` RPCs. Buyers can only upsert. Wrong rows have to be edited via re-upsert with the same identifying keys.
3. **No edit-existing form.** The upsert forms always create new rows (or re-upsert under whatever conflict key the RPC uses). To edit an existing milestone, the buyer must enter matching identifying fields — there is no "edit this row" button next to existing entries.
4. **Sequence number is buyer-managed.** No automatic insertion logic; buyer must avoid collisions.
5. **Timeline timestamps prefer "actual" over "planned" over "created_at".** If a stop has no timestamps at all (just notes), it shows at `created_at`. This is intentional but worth knowing for audit reviewers.
6. **No status-event filter.** Admin sees every status_event chronologically intermixed with milestones + stops. No filtering UI; ops can drill into the separate tables below.

## Acceptance criteria

- [ ] `bash 23-DATABASE/tests/run.sh` reports **101 / 790 / 0** (unchanged). ✓
- [ ] `npm run typecheck` exits 0. ✓
- [ ] `npm run build` exits 0 with 88 routes. ✓
- [ ] `bash scripts/verify-admin-route-guards.sh` passes the extended verifier. ✓
- [ ] Confirm the combined timeline + detail table layout is acceptable.
- [ ] Confirm the manual sequence_number requirement is acceptable as a starting point.
- [ ] Confirm CC-33 may proceed.
