# CC-14 — Phase 2.7 Shipment / Logistics Execution Foundation, Schema Notes

Version: 1.0 (DRAFT)
Scope: Eighth business domain — buyer-driven shipment / logistics execution built atop CC-13 executed contracts. Shipment header, derived shipment items, route stops, operational milestones, document requirements, document metadata (no file storage), and immutable shipment lifecycle / event trail. Supplier read-visibility.
Migration: `23-DATABASE/migrations/0025_shipment_logistics_execution_foundation.sql` (single, append-only).
Status: Implementation complete; tests 048–052 pass (41 assertions). Pending user acceptance.

## Mission

CC-14 introduces the **shipment / logistics execution** surface. Once a contract reaches `executed` in CC-13, an authorized buyer user can build a structured shipment plan: a shipment header carrying transport mode + origin/destination + carrier info, line items derived from the executed contract items, route stops with strict sequence numbering, operational milestones, per-shipment document requirements, document metadata records (no file storage), and an immutable status / event trail. Strictly scoped to **shipment planning and tracking metadata** — no pricing engine, no settlement, no escrow, no payment, no invoice, no accounting, no insurance claim workflow, no live GPS tracking.

## Relationship to existing foundations

| Foundation | How CC-14 uses it |
|------------|-------------------|
| identity | `is_platform_admin()`, `has_role(...)`, `current_organization_id()`, `current_user_id()` |
| organization | `organizations`, `memberships` for buyer/supplier/carrier RLS predicates |
| supplier | `supplier.fn_portal_supplier_id()` for supplier-side visibility; `supplier.suppliers(id)` FK |
| commodity | `commodity.products(id)` referenced via `shipment_items.product_id` |
| rfq | `rfq.requests(id)` parent reference (carried from contract) |
| offer | `offer.supplier_offers(id)` reference (carried from contract) |
| evaluation | — (no direct reference; chain runs through the executed contract) |
| contract | `contract.executed_contracts(id)` with `status='executed'` is the **only** valid trigger for shipment creation. Items copied from `executed_contract_items` |
| audit | `audit.audit_event` written by `shipment.fn_audit` and via the generic audit trigger on every shipment table |

## Locked decisions

| # | Decision | Source |
|---|----------|--------|
| 1 | Single append-only migration `0025_shipment_logistics_execution_foundation.sql`. | CC-14 prompt |
| 2 | New `shipment` schema. | CC-14 prompt #2 |
| 3 | RPC namespaces: `shipment.buyer_*`, `shipment.supplier_*`, `shipment.admin_*`. | CC-14 prompt #13 |
| 4 | All mutations via SECURITY DEFINER RPCs. No direct INSERT/UPDATE/DELETE grants. | CC-14 prompt #12 |
| 5 | `search_path = ''` on every SECURITY DEFINER function. | CC-14 prompt #12 |
| 6 | Buyer RPCs derive organization from `identity.current_organization_id()` — no `p_buyer_organization_id` parameter. | CC-14 prompt #14 |
| 7 | Supplier RPCs derive supplier_id from `supplier.fn_portal_supplier_id()` — no `p_supplier_id` parameter. | CC-14 prompt #15 |
| 8 | Shipment creation requires `contract.executed_contracts.status='executed'`. | CC-14 prompt #17 |
| 9 | Shipment items are **copied** from `executed_contract_items` at create time (back-pointer `executed_contract_item_id`). | CC-14 prompt #7, #18 |
| 10 | Stops must have unique `sequence_number` per shipment (partial unique index). | CC-14 prompt #18 |
| 11 | Document metadata referencing a `requirement_id` must reference a requirement from the **same** shipment (RPC-asserted). | CC-14 prompt #18 |
| 12 | Documents are metadata-only: external_reference + status, no file storage in CC-14. | CC-14 prompt #10 |
| 13 | Status lifecycle: `draft → planned → booked → in_transit → arrived → delivered → closed`. Cancel from any non-terminal state. `closed` is admin-only and reachable from `delivered` or `arrived`. | CC-14 prompt #5 |
| 14 | `delivered`, `closed`, `cancelled` lock the shipment from `buyer_update_shipment`. Operational updates (milestones, documents) remain available in non-terminal states. | CC-14 prompt #17 |
| 15 | Shipment events are immutable: no UPDATE/DELETE policies, no UPDATE/DELETE grants. | CC-14 prompt #11 |
| 16 | No pricing / payment / settlement / escrow / invoice / accounting / insurance claim / GPS tracking is created. | CC-14 prompt #17, #23 |

## Schema overview

### Enums (8)

- `shipment.shipment_status` — `draft, planned, booked, in_transit, arrived, delivered, cancelled, closed`
- `shipment.transport_mode` — `road, rail, sea, air, multimodal, pipeline, other`
- `shipment.stop_type` — `pickup, loading, border, transshipment, customs, unloading, delivery, other`
- `shipment.milestone_type` — `booking_confirmed, cargo_ready, pickup_completed, customs_export_cleared, departed_origin, border_crossed, arrived_destination, customs_import_cleared, delivered, closed, other`
- `shipment.milestone_status` — `pending, in_progress, completed, skipped, blocked`
- `shipment.document_kind` — `bill_of_lading, cmr, rail_waybill, airway_bill, packing_list, certificate_of_origin, inspection_certificate, customs_declaration, delivery_order, proof_of_delivery, other`
- `shipment.requirement_level` — `required, recommended, optional`
- `shipment.document_status` — `pending, available, expired, rejected, archived`

### Tables (7)

| Table | Purpose |
|-------|---------|
| `shipment.shipments` | Master shipment record per executed contract. Carries transport mode, incoterm, origin/destination, planned/actual pickup/delivery dates, carrier info, tracking reference, full lifecycle timestamps. |
| `shipment.shipment_items` | Line items copied from `contract.executed_contract_items` (back-pointer `executed_contract_item_id`). |
| `shipment.shipment_stops` | Route stops. Unique `sequence_number` per shipment. |
| `shipment.shipment_milestones` | Operational milestones per shipment, one active per `(shipment, milestone_type)`. |
| `shipment.shipment_document_requirements` | Per-shipment required/recommended/optional documents. Buyer-private. |
| `shipment.shipment_documents` | Document metadata records (no file storage). May reference an in-shipment requirement. |
| `shipment.shipment_events` | **Immutable** lifecycle / operational event trail. No UPDATE/DELETE policies. |

## Shipment lifecycle

```
                buyer_create_shipment  (contract must be executed)
                              │  ↳ copy items from executed_contract_items,
                              │    write event(null→draft)
                              ▼
                            draft
                              │ buyer_update_shipment / buyer_upsert_stop /
                              │ buyer_upsert_milestone / buyer_upsert_doc_requirement /
                              │ buyer_upsert_document
                              │
                       buyer_mark_planned
                              │
                              ▼
                           planned  ← editable (structural + operational)
                              │
                       buyer_mark_booked (sets carrier info)
                              │
                              ▼
                           booked  ← operational updates only
                              │
                       buyer_mark_in_transit (sets actual_pickup_date)
                              │
                              ▼
                         in_transit
                              │
                       buyer_mark_arrived
                              │
                              ▼
                           arrived
                              │
                       buyer_mark_delivered (sets actual_delivery_date)
                              │
                              ▼
                         delivered ── admin_close_shipment ──► closed (terminal)
                              │
                  any non-terminal: buyer_cancel_shipment
                              ▼
                          cancelled (terminal)
```

- `draft` and `planned` are fully editable.
- `booked`, `in_transit`, `arrived` permit operational updates (milestones, documents) but block `buyer_update_shipment` (header updates) and structural updates (stops, doc requirements). `fn_assert_shipment_editable(strict=true)` raises P0001; `strict=false` allows non-terminal updates.
- `delivered`, `closed`, `cancelled` are terminal and locked from all buyer mutations except admin operations.
- Every status transition writes one `shipment_events` row and one `audit.audit_event` row.

## Security model

### RLS

All 7 tables have RLS enabled. The audience predicate is one of:

- **Buyer-side** — members of the buyer organization (`shipments.organization_id`).
- **Supplier-side** — members of the supplier organization (resolved via `shipments.supplier_id → supplier.suppliers.organization_id`).
- **Platform admin** — always.

`shipment_document_requirements` is **buyer-private** — suppliers cannot read it. All other tables (shipments, items, stops, milestones, documents, events) are visible to buyer + supplier + admin.

Backstop `*_admin_modify` policies on the mutable tables (`shipments`, `shipment_items`, `shipment_stops`, `shipment_milestones`, `shipment_document_requirements`, `shipment_documents`) allow only `platform_admin`. RPCs bypass via SECURITY DEFINER. Events have no INSERT/UPDATE/DELETE policies — append-only via RPC.

### Grants

```
anon          → shipment.shipments, shipment.shipment_items            SELECT (RLS returns 0)

authenticated → all 7 shipment.* tables                                 SELECT
```

`shipment_stops`, `shipment_milestones`, `shipment_document_requirements`, `shipment_documents`, `shipment_events` are intentionally NOT exposed to `anon`. **No INSERT/UPDATE/DELETE direct grants on any shipment table.**

### Helper functions (internal, SECURITY DEFINER, `search_path=''`)

| Function | Purpose |
|----------|---------|
| `shipment.fn_audit(action, shipment_id, payload)` | Writes domain audit event; exception-swallowed. |
| `shipment.fn_record_shipment_event(...)` | Inserts immutable events row. |
| `shipment.fn_next_shipment_code(tenant)` | Generates `SHP-YYYY-XXXXXXXX` codes (tenant-unique via partial unique index). |
| `shipment.fn_assert_buyer_for_contract(contract)` | Verifies role + caller's org matches contract buyer + contract is `executed`. Returns cross-domain identifiers. |
| `shipment.fn_assert_shipment_owned(shipment)` | Raises `42501` if caller's org doesn't own the shipment. |
| `shipment.fn_assert_shipment_editable(shipment, strict)` | `strict=true` → only draft/planned; `strict=false` → any non-terminal. Returns current status. |

## RPC inventory (21)

### Buyer RPCs (14)

| Function | Vol | Purpose |
|----------|-----|---------|
| `buyer_create_shipment(contract_id, transport_mode?, ...)` returns uuid | volatile | Creates draft shipment from executed contract. Copies items. Writes initial event. |
| `buyer_update_shipment(shipment_id, ...)` | volatile | Partial header update; draft/planned only. |
| `buyer_upsert_stop(shipment_id, sequence_number, stop_type, ...)` returns uuid | volatile | Upsert by `(shipment_id, sequence_number)`; draft/planned only. |
| `buyer_upsert_milestone(shipment_id, milestone_type, status, ...)` returns uuid | volatile | Upsert by `(shipment_id, milestone_type)`; non-terminal. |
| `buyer_upsert_doc_requirement(shipment_id, document_kind, ...)` returns uuid | volatile | Upsert by `(shipment_id, document_kind)`; draft/planned only. |
| `buyer_upsert_document(shipment_id, document_kind, ..., requirement_id?, shipment_item_id?)` returns uuid | volatile | Insert (or update with `p_document_id`); non-terminal. Requirement / item must belong to the same shipment. |
| `buyer_mark_planned(shipment_id)` | volatile | draft → planned. Writes event. |
| `buyer_mark_booked(shipment_id, carrier_org?, carrier_name?, vehicle?, tracking?)` | volatile | planned → booked. Sets carrier info. |
| `buyer_mark_in_transit(shipment_id)` | volatile | booked → in_transit. Sets actual_pickup_date. |
| `buyer_mark_arrived(shipment_id)` | volatile | in_transit → arrived. |
| `buyer_mark_delivered(shipment_id)` | volatile | arrived → delivered. Sets actual_delivery_date. |
| `buyer_cancel_shipment(shipment_id, reason?)` | volatile | Any non-terminal → cancelled. |
| `buyer_list_shipments(executed_contract_id?, status?, limit, offset)` | stable | List own org shipments. |
| `buyer_get_shipment(shipment_id)` returns jsonb | stable | Detail with items / stops / milestones / requirements / documents. |

### Supplier RPCs (2 — read-only)

| Function | Vol | Purpose |
|----------|-----|---------|
| `supplier_list_my_shipments(status?, limit, offset)` | stable | List shipments on caller's own contracts. |
| `supplier_get_my_shipment(shipment_id)` returns jsonb | stable | Detail (no requirements — buyer-private). |

### Admin RPCs (5)

| Function | Vol | Purpose |
|----------|-----|---------|
| `admin_list_shipments(...)` | stable | Cross-org admin list. |
| `admin_get_shipment(shipment_id)` returns jsonb | stable | Detail with counts. |
| `admin_list_shipment_events(shipment_id)` | stable | Event trail. |
| `admin_force_cancel_shipment(shipment_id, reason?)` | volatile | Cancel from any non-terminal state. |
| `admin_close_shipment(shipment_id, reason?)` | volatile | delivered/arrived → closed. |

**21 RPCs total.** All `SECURITY DEFINER`, all `search_path=""`, single owner `postgres`.

## Validation Summary

### Migration apply

```
Applying migration 20260622090025_shipment_logistics_execution_foundation.sql...
Finished supabase db reset on branch main.
```

All 25 migrations apply cleanly. No mid-implementation fixes were required.

### Verification queries (snapshot)

- 7 `shipment.*` tables, all `relrowsecurity = t`, `relforcerowsecurity = f`
- 0 INSERT/UPDATE/DELETE direct grants on `shipment.*`
- 21 RPCs across buyer/supplier/admin namespaces (14 buyer + 2 supplier + 5 admin)
- All RPCs `owner=postgres`, `security_definer=t`, `search_path=""`
- 7 stable + 14 volatile (split matches read/write intent)
- 0 `buyer_*` RPCs accept `p_buyer_organization_id`
- 0 `supplier_*` RPCs accept `p_supplier_id`
- Single distinct owner across all shipment RPCs
- 0 forbidden side-effect schemas exist (`pricing/payment/settlement/escrow/invoice/accounting/insurance_claim/gps`)

### pgTAP suite

```
================================================================
Files: 52 passed, 0 failed
Assertions: 333 passed, 0 failed
================================================================
```

| File | Assertions | Coverage |
|------|------------|----------|
| 001–047 | 292 | CC-05 through CC-13 (incl. acceptance) |
| **048 shipment RLS, grants, RPC metadata** | **13** | **CC-14** |
| **049 buyer shipment lifecycle** (create → items derived → update → stop idempotent → milestone → doc req → document → planned→booked→in_transit→arrived→delivered → locked → events ≥5) | **13** | **CC-14** |
| **050 scope + integrity** (cross-buyer block, non-executed contract block, cross-shipment requirement reference block, no forbidden schemas) | **4** | **CC-14** |
| **051 transitions + events immutability** (6 events on full chain, immutable UPDATE/DELETE blocked, cancelled lock, cancel-from-delivered rejected) | **6** | **CC-14** |
| **052 supplier visibility** (own visible, get detail, foreign 0/42501, requirements buyer-private) | **5** | **CC-14** |
| **CC-14 new** | **41** | |
| **Suite total** | **333** | **across 52 files** |

Note: tests `040` and `045` were also updated (documentation-only change to their schema exclusion lists) — the `shipment` schema legitimately lands in CC-14, so it was removed from those tests' "no forbidden schemas" assertions. No migration was modified.

### Frontend

CC-14 added no frontend code. The frontend remains at its CC-07 surface (22 routes). `supabase/config.toml` does not yet expose the `shipment` (or `contract` / `evaluation` / `offer`) schema to PostgREST — must be added before any UI calls these RPCs.

## Known limitations / handoff notes for CC-15

1. **`supabase/config.toml`** does not expose `shipment` (nor `contract` / `evaluation` / `offer`) to PostgREST. Future CC must add these to `[api].schemas` before frontend can call these RPCs.
2. **No file storage for documents.** `shipment_documents` is metadata-only (external_reference + status). Storage bucket integration is a future concern.
3. **No live GPS tracking.** `tracking_reference` is a free-text field for external system identifiers (carrier tracking number etc.). No real-time location ingestion / streaming.
4. **No pricing, payment, invoice, settlement, escrow, accounting, insurance claim.** Same boundary as CC-13 plus explicit CC-14 exclusions. Test 050/4 verifies that no `pricing|payment|settlement|escrow|invoice|accounting|insurance_claim|gps` schemas exist.
5. **No automatic milestone progression.** Buyer manually upserts milestones; status transitions on the shipment header are separate from milestone state.
6. **No automatic event correlation between shipment + contract.** Marking a shipment `delivered` does not change `executed_contract.status`. Contract closure post-delivery is a future concern.
7. **No partial-shipment optimization.** `buyer_create_shipment` copies ALL active executed contract items into the shipment. Quantity splitting across multiple shipments is left to the buyer to adjust post-create. Reconciliation against contract items is not modeled.
8. **Documents are buyer-administered.** Suppliers can read documents (and items / stops / milestones) but cannot upload or update. Document requirements are buyer-private (suppliers don't see what's required).
9. **No multi-leg / sub-shipment hierarchy.** Each shipment is flat; transshipment is recorded as a stop, not as a nested shipment.
10. **No carrier portal.** `carrier_organization_id` is a buyer-side annotation; carrier orgs have no special RLS access in CC-14.
11. **No `Database` type entry for shipment tables** in the frontend types file. Will be added when buyer / supplier shipment UI lands.
12. **Cross-domain integrity is RPC-enforced.** `shipment.executed_contract_id → executed_contracts.id` is the load-bearing link; `request_id / offer_id / supplier_id` are copied at create time. Direct INSERTs by `service_role` bypassing RPCs could violate the invariants; mitigated by no-direct-write-grants on `authenticated`.
13. **Document referencing an item across shipments is impossible at the RPC layer** but FK does not enforce it (only RPC assertion). Direct service_role inserts could violate — mitigated by no-direct-write-grants.
