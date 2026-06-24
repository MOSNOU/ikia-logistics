# CC-31 — Phase 2.24 Frontend Shipment Execution Portal Foundation, Notes

Version: 1.0 (DRAFT)
Scope: Twenty-fifth platform step. Frontend-only — wires CC-15 `shipment.*`
RPCs through Next.js Server Actions + server-rendered pages across buyer,
supplier, and admin portals.
Migration: **none.** DB baseline 0001–0032 is unchanged.
Status: Implementation complete; all directives met. Pending user acceptance.

## Locked decisions (Q1–Q10)

| # | Decision | Notes |
|---|----------|--------|
| Q1 | A — all 7 routes shipped | buyer × 3 + supplier × 2 + admin × 2. |
| Q2 | A — minimal create form | contract_id, transport_mode, dates, origin/destination city + country, incoterm, notes. |
| Q3 | A — inline upsert (per row) | doc-requirements + documents; no items (CC-15 doesn't have shipment items). |
| Q4 | Mapped to CC-15's actual surface | Two buttons: `admin_close_shipment` + `admin_force_cancel_shipment`. No arbitrary status selector exists (matches CC-28 RFQ narrow pattern). |
| Q5 | A — sidecar wrappers + enums | 5 wrappers + 4 enum aliases. |
| Q6 | Downgraded to read-only supplier pages | CC-15 exposes only `supplier_get_my_shipment` + `supplier_list_my_shipments` — no `supplier_*` action RPCs. (Intent of Q6=A executed as Q6=B equivalent.) |
| Q7 | A — verifier extended | All 7 routes asserted under CC-31 section. |
| Q8 | A — shared `ShipmentSummary` component | Imported by buyer / supplier / admin detail pages. |
| Q9 | A — hard-coded mode select | 7 enum values from `shipment.transport_mode`. |
| Q10 | A — stop at green pgTAP + typecheck + build + verifier | No manual browser smoke. |

## Mid-execution findings — 2 surface adjustments

1. **Supplier side is read-only.** CC-15 exposes no `supplier_*` mutation RPCs (no confirm-readiness, no mark-handed-over, no report-issue). Q6 default (auto-detect) fell back to read-only supplier pages; the buyer-driven lifecycle pattern from the draft holds.
2. **No shipment items entity.** Shipment has `doc_requirements`, `documents`, `milestones`, `stops` — not `items`. UI focuses on doc-requirement + document upsert (the natural minimum). Milestones + stops are documented as known limitations.
3. **Admin force surface is `close` + `force_cancel` (2 buttons).** No `admin_force_shipment_status` RPC; Q4 mapped to what's actually available — narrower than CC-27 settlement's selector, matches CC-28 RFQ.

## What changed

### Files created (18)

**Server modules (7):**

| File | Coverage |
|---|---|
| `src/lib/shipment/list-buyer-shipments.ts` | `shipment.buyer_list_shipments` |
| `src/lib/shipment/list-supplier-shipments.ts` | `shipment.supplier_list_my_shipments` |
| `src/lib/shipment/get-shipment.ts` | Audience-switched read (buyer / supplier / admin) |
| `src/lib/shipment/buyer-actions.ts` | 11 Server Actions: create / update / upsert-doc-req / upsert-document / mark-planned / mark-booked / mark-in-transit / mark-arrived / mark-delivered / cancel |
| `src/lib/admin/list-shipments.ts` | `shipment.admin_list_shipments` |
| `src/lib/admin/list-shipment-events.ts` | `shipment.admin_list_shipment_events` |
| `src/lib/admin/shipment-admin-actions.ts` | 2 admin Server Actions: close + force-cancel |

**Pages + components (11):**

| Path | Purpose |
|---|---|
| `app/buyer/shipments/page.tsx` | List + status/contract filters |
| `app/buyer/shipments/new/page.tsx` + `create-shipment-form.tsx` | Minimal create form with `?contract_id=` prefill |
| `app/buyer/shipments/[id]/page.tsx` | Detail + status actions + doc-requirement upsert + document upsert |
| `app/buyer/shipments/[id]/shipment-status-actions.tsx` | mark-planned/booked/in-transit/arrived/delivered/cancel (status-gated) |
| `app/buyer/shipments/[id]/upsert-doc-requirement-form.tsx` | doc-requirement upsert |
| `app/buyer/shipments/[id]/upsert-document-form.tsx` | document upsert |
| `app/supplier/shipments/page.tsx` | Read-only supplier list |
| `app/supplier/shipments/[id]/page.tsx` | Read-only detail (reuses `ShipmentSummary`) |
| `app/admin/shipments/page.tsx` | Cross-tenant queue |
| `app/admin/shipments/[id]/page.tsx` + `admin-force-actions.tsx` | Read-only detail + close/force-cancel panel |
| `src/components/shipment/shipment-summary.tsx` | Shared summary panel (header + doc_requirements + documents + events) reused across all three audiences |

### Files modified (2)

| File | Change |
|---|---|
| `src/types/database.compat.ts` | Added "CC-31: Shipment portal types" section with 5 wrapper interfaces + 4 enum aliases. |
| `scripts/verify-admin-route-guards.sh` | Header expanded to CC-31. Added admin + supplier + buyer shipment page checks. |

**Files NOT touched:** all migrations 0001–0032, every `shipment.*` SQL surface, `database.ts` generated file, `supabase/config.toml`, all CC-22..CC-30 portal code, every other domain.

### Route inventory

7 new routes:

```
buyer:     /shipments, /shipments/new, /shipments/[id]
supplier:  /shipments, /shipments/[id]
admin:     /shipments, /shipments/[id]
```

Build route count: **78 → 85 (+7).**

## Validation results

| Gate | Required | Actual |
|---|---|---|
| `bash 23-DATABASE/tests/run.sh` | 101 / 790 / 0 (unchanged) | **101 files / 790 assertions / 0 failures** |
| `npm run typecheck` | 0 errors | **0 errors** |
| `npm run build` | exit 0; route count grows by 7 | **85 routes built**, exit 0 |
| `bash scripts/verify-admin-route-guards.sh` | extended + pass | **VERIFICATION PASSED** (all sections green) |

## Key design choices

1. **Shared `ShipmentSummary` component (Q8=A).** Buyer + supplier + admin all import it; status-action panels live next to it audience-specifically. Same pattern as CC-30 contracts.
2. **Status-driven button visibility.** Each `mark_*` button appears only when the current status matches the legal predecessor: `draft → planned → booked → in_transit → arrived → delivered`. Cancel is available at any non-terminal status.
3. **Book action opens an inline form** for carrier name, tracking reference, and vehicle reference — the only transition that needs free-text inputs.
4. **Admin events merge.** Admin detail page calls `admin_list_shipment_events` and merges into `detail.events` if `admin_get_shipment` didn't bundle them — same pattern as CC-27 dispute admin detail.
5. **`?contract_id=` deep-link prefill.** `/buyer/shipments/new` accepts the URL param so a future "ایجاد محموله" CTA on `/buyer/contracts/[id]` can deep-link in with one click.

## Boundaries respected

- ✅ No DB / RPC / RLS / grant / trigger / migration changes. CC-15 byte-identical.
- ✅ No new migrations.
- ✅ No client-side Supabase mutations — Server Actions only.
- ✅ No real-time GPS tracking / map UI / tracking provider integration.
- ✅ No carrier marketplace / booking provider API. `carrier_reference` is free text.
- ✅ No insurance claim / customs filing UI.
- ✅ No file upload for documents — metadata-only with `external_reference` text.
- ✅ No automatic settlement creation downstream of delivery.
- ✅ No bulk operations.
- ✅ No nav-bar entries added.
- ✅ No KYC gating.
- ✅ No new dependencies — `package.json` untouched.
- ✅ No proof-of-delivery photo / signature capture.

## Known limitations / handoff notes

1. **No milestones UI.** CC-15 exposes `buyer_upsert_milestone` with 10 milestone types (booking_confirmed, cargo_ready, pickup_completed, customs_export_cleared, departed_origin, border_crossed, arrived_destination, customs_import_cleared, delivered, closed, other) — not wired to UI. A natural CC-32 follow-up.
2. **No stops UI.** `buyer_upsert_stop` with 8 stop types (pickup, loading, border, transshipment, customs, unloading, delivery, other) — also a future polish.
3. **Documents UI lacks status / requirement-link editing.** `buyer_upsert_document` accepts `document_status` and `requirement_id`; the CC-31 form omits both for the minimum-surface principle.
4. **Supplier is read-only.** Per CC-15 RPC surface. If a future migration adds supplier-confirm-readiness or similar, the UI can pick it up.
5. **Admin force surface is two buttons** (close + force-cancel) — narrower than CC-27 settlement but matching CC-28 RFQ. No arbitrary status selector exists in CC-15.
6. **`/buyer/shipments/new` requires raw `executed_contract_id` UUID.** A future polish CC can wire a contract picker.
7. **Update RPC `buyer_update_shipment` is not surfaced** beyond the book-time carrier fields. The header is read-only after creation in CC-31.

## Acceptance criteria

- [ ] `bash 23-DATABASE/tests/run.sh` reports **101 / 790 / 0** (unchanged). ✓
- [ ] `npm run typecheck` exits 0. ✓
- [ ] `npm run build` exits 0 with 85 routes. ✓
- [ ] `bash scripts/verify-admin-route-guards.sh` passes the extended verifier. ✓
- [ ] Confirm read-only supplier pages are acceptable (no supplier_* mutation RPCs exist in CC-15).
- [ ] Confirm admin force surface = close + force-cancel is acceptable.
- [ ] Confirm CC-32 may proceed.
