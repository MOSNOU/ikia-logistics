# CC-16 — Phase 2.9 Invoice / Payment Readiness Foundation, Schema Notes

Version: 1.0 (DRAFT)
Scope: Tenth business domain step — buyer-driven billing and payment record-keeping built atop CC-13 executed contracts and CC-14 shipments. Invoice header, derived/free-form invoice items, payment-method registry, payment records (with buyer/supplier-recorded receipts), immutable invoice status events, and immutable payment status events. Supplier read-visibility plus supplier payment receipt logging.
Migration: `23-DATABASE/migrations/0027_invoice_payment_foundation.sql` (single, append-only).
Status: Implementation complete; tests 057–061 pass (43 assertions). Pending user acceptance.

## Mission

CC-16 introduces a `finance` schema so a buyer organization can raise invoices for an executed contract (and/or a shipment), record payments made against those invoices (or have a supplier confirm receipt), and walk the invoice/payment through a controlled lifecycle. This is **record-keeping only** — no payment gateway integration, no pricing engine, no settlement, no escrow, no insurance, no advanced accounting, no live GPS. Auto-promotion of invoice status is driven entirely by recorded payment rows; there is no scheduled job in this CC.

## Relationship to existing foundations

| Foundation | How CC-16 uses it |
|------------|-------------------|
| identity | `is_platform_admin()`, `has_role(...)`, `current_organization_id()`, `current_user_id()` |
| organization | `organizations`, `memberships` for buyer/supplier RLS predicates |
| supplier | `supplier.fn_portal_supplier_id()` for supplier-side visibility / receipt logging |
| commodity | (none directly — items are descriptive text + numeric; product reference is carried via the optional contract/shipment item back-pointer) |
| rfq / offer / evaluation | (none directly — invoices reference the *executed* contract, not the upstream chain) |
| contract | `contract.executed_contracts(id)` is the primary target; `contract.executed_contract_items(id)` back-pointer on invoice items |
| shipment | `shipment.shipments(id)` is an alternative target; `shipment.shipment_items(id)` back-pointer on invoice items |
| audit | `audit.audit_event` written by `finance.fn_audit` and via the generic audit trigger on every table |

## Locked decisions

| # | Decision | Source |
|---|----------|--------|
| 1 | Single append-only migration `0027_invoice_payment_foundation.sql`. | CC-16 prompt |
| 2 | New `finance` schema (the prompt offered `finance` or `billing`; `finance` chosen as the more general parent). | CC-16 prompt #2 |
| 3 | RPC namespaces: `finance.buyer_*`, `finance.supplier_*`, `finance.admin_*`. | CC-16 prompt #12 |
| 4 | All mutations via SECURITY DEFINER RPCs. No direct INSERT/UPDATE/DELETE grants. | CC-16 prompt #11 |
| 5 | `search_path = ''` on every SECURITY DEFINER function. | CC-16 prompt #11 |
| 6 | Buyer RPCs derive organization from `identity.current_organization_id()` — no `p_buyer_organization_id` parameter. | CC-16 prompt #11 |
| 7 | Supplier RPCs derive supplier_id from `supplier.fn_portal_supplier_id()` — no `p_supplier_id` parameter. | CC-16 prompt #11 |
| 8 | Invoice creation requires at least one of `executed_contract_id` / `shipment_id` (CHECK constraint + RPC validation). | CC-16 prompt #4 |
| 9 | If both are supplied, the shipment must belong to the supplied contract. | CC-16 design |
| 10 | Invoice items: total auto-computed as `quantity * unit_price * (1 + tax_rate)`. Override via metadata if needed. | CC-16 design |
| 11 | Auto-promotion: when a payment is recorded with `status='completed'`, recompute totals and promote `issued/sent/due/partial/overdue` → `paid` (if fully covered) or `partial` (if some). Refund of a `completed` payment can **demote** a `paid` invoice back to `partial` (or `sent` if `paid_amount` drops to zero). | CC-16 prompt + lifecycle reasoning |
| 12 | `draft` is the only editable state for header / items. Payment recording is allowed on `issued/sent/due/partial/overdue`. | CC-16 prompt #11, #17 |
| 13 | Invoice and payment status events are immutable: no UPDATE/DELETE policies, no UPDATE/DELETE grants. | CC-16 prompt #10 |
| 14 | No payment gateway, no pricing engine, no settlement / escrow / insurance / accounting / GPS. | CC-16 prompt goal + #16 |

## Schema overview

### Enums (3)

- `finance.invoice_status` — `draft, issued, sent, due, paid, partial, overdue, cancelled, voided`
- `finance.payment_status` — `pending, processing, completed, failed, refunded, cancelled`
- `finance.payment_method_type` — `bank_transfer, credit_card, paypal, wire, check, other`

### Tables (6)

| Table | Purpose |
|-------|---------|
| `finance.invoices` | Invoice header per executed contract and/or shipment. Carries totals, currency, lifecycle timestamps, taxes_and_fees jsonb, payment_terms_text. |
| `finance.invoice_items` | Line items. Optional back-pointer to `executed_contract_item_id` or `shipment_item_id`. `total = quantity * unit_price * (1 + tax_rate)`. |
| `finance.payment_methods` | Per-organization payment-method registry (method_type + display_name + currency). |
| `finance.payments` | Payment records against invoices. `recorded_by_party` distinguishes buyer-side vs. supplier-side receipt log. |
| `finance.invoice_status_events` | **Immutable** invoice status transition trail. No UPDATE/DELETE policies. |
| `finance.payment_status_events` | **Immutable** payment status transition trail. No UPDATE/DELETE policies. |

## Invoice lifecycle

```
        buyer_create_draft_invoice(executed_contract_id?, shipment_id?, ...)
                              │ (requires at least one target)
                              ▼
                           draft
                              │ buyer_update_invoice / buyer_upsert_invoice_item /
                              │ buyer_remove_invoice_item
                              │
                       buyer_issue_invoice
                              │
                              ▼
                           issued
                              │
                       buyer_send_invoice
                              │
                              ▼
                            sent
                              │
                  ┌───────────┼───────────────────┐
                  │           │                   │
       buyer_mark_overdue   buyer_record_payment(completed)
                  │                       │
                  ▼                       ▼
               overdue           (auto via fn_promote_invoice_after_payment)
                  │                       │
                  └───────────────────────┤
                                          │
                              ┌───────────┼───────────┐
                              │           │           │
                            partial      paid       (no change if 0 paid)
                              │           │
                              │           │ buyer_refund_payment
                              ▼           ▼
                            paid       partial / sent  (auto-demotion)
                              │
                  buyer_cancel_invoice (non-terminal) → cancelled (terminal)
                  admin_void_invoice / admin_force_invoice_status → voided / target
```

- `draft → issued → sent` is the explicit promotion chain. `due` is reserved for due-date sweeper (not implemented).
- `partial` and `paid` are reached via payment recording.
- `cancelled` and `voided` are terminal.
- `admin_force_invoice_status` is the override hatch for ops.

## Payment lifecycle

```
       buyer_record_payment(invoice_id, paid_amount, status=completed)
       supplier_record_payment_receipt(invoice_id, paid_amount)
                              │
                              ▼
                          completed
                              │ buyer_refund_payment
                              ▼
                          refunded
```

- For CC-16, the simplest flow is "payment created in `completed`" because there's no gateway. The `pending` / `processing` / `failed` / `cancelled` states are reserved for future gateway integration.
- `recorded_by_party` records whether the buyer logged a payment or the supplier confirmed a receipt; both create rows with `status='completed'` and trigger invoice auto-promotion.
- Refund is the only state change implemented: `completed → refunded` via `buyer_refund_payment`. `fn_promote_invoice_after_payment` runs after the refund and may demote the parent invoice.

## Security model

### RLS

All 6 tables have RLS enabled with the standard predicate:

- **Buyer-side** — members of the invoice's `organization_id`.
- **Supplier-side** — members of the invoice's `supplier_id → supplier.suppliers.organization_id` (NOT for `payment_methods`, which is buyer-private).
- **Platform admin** — always.

Backstop `*_admin_modify` policies allow only `platform_admin`. RPCs bypass via SECURITY DEFINER. Events have no INSERT/UPDATE/DELETE policies — append-only via RPC.

### Grants

```
anon          → finance.invoices, finance.invoice_items                                          SELECT (RLS returns 0)

authenticated → all 6 finance.* tables                                                            SELECT
```

`payment_methods`, `payments`, `invoice_status_events`, `payment_status_events` are intentionally NOT exposed to `anon`. **No INSERT/UPDATE/DELETE direct grants on any finance table.**

### Helper functions (internal, SECURITY DEFINER, `search_path=''`)

| Function | Purpose |
|----------|---------|
| `finance.fn_audit(action, invoice_id, payload)` | Writes domain audit event; exception-swallowed. |
| `finance.fn_next_invoice_code(tenant)` | Generates `INV-YYYY-XXXXXXXX` codes. |
| `finance.fn_record_invoice_event(...)` | Inserts immutable invoice events row. |
| `finance.fn_record_payment_event(...)` | Inserts immutable payment events row. |
| `finance.fn_assert_buyer_for_invoice(invoice_id)` | Raises `42501` if caller's org doesn't own the invoice; returns the current status. |
| `finance.fn_assert_invoice_editable(invoice_id)` | Raises `P0001` if status ≠ `draft`. |
| `finance.fn_assert_invoice_payable(invoice_id)` | Raises `P0001` if status not in `(issued, sent, due, partial, overdue)`. |
| `finance.fn_recompute_invoice_totals(invoice_id)` | Recomputes subtotal, tax, total, paid_amount from items + completed payments. |
| `finance.fn_promote_invoice_after_payment(invoice_id)` | Auto-promote (or demote on refund) based on recomputed totals + current status. |

## RPC inventory (24)

### Buyer RPCs (14)

| Function | Vol | Purpose |
|----------|-----|---------|
| `buyer_create_draft_invoice(contract_id?, shipment_id?, currency?, ...)` returns uuid | volatile | Creates draft invoice. Either contract or shipment (or both) required. Derives supplier from the target. |
| `buyer_update_invoice(invoice_id, ...)` | volatile | Partial header update; draft only. |
| `buyer_upsert_invoice_item(invoice_id, description, qty, unit_price, tax_rate, ...)` returns uuid | volatile | Insert or update item; auto-computes total; recomputes invoice totals. |
| `buyer_remove_invoice_item(item_id)` | volatile | Soft-delete; recomputes invoice totals. |
| `buyer_issue_invoice(invoice_id)` | volatile | draft → issued. Sets invoice_date if null. |
| `buyer_send_invoice(invoice_id)` | volatile | issued → sent. |
| `buyer_mark_overdue(invoice_id)` | volatile | sent/due/partial → overdue. |
| `buyer_cancel_invoice(invoice_id, reason?)` | volatile | Any non-paid/non-cancelled/non-voided → cancelled. |
| `buyer_record_payment(invoice_id, paid_amount, payment_method_id?, status=completed, ...)` returns uuid | volatile | Creates payment row; auto-promotes invoice. |
| `buyer_refund_payment(payment_id, reason?)` | volatile | completed → refunded; auto-demotes invoice if necessary. |
| `buyer_list_invoices(status?, limit, offset)` | stable | List own org invoices. |
| `buyer_get_invoice(invoice_id)` returns jsonb | stable | Detail with items + payments. |
| `buyer_upsert_payment_method(method_type, display_name, currency?, ...)` returns uuid | volatile | Manage payment methods for own org. |
| `buyer_list_payment_methods(method_type?, active_only)` | stable | List own org payment methods. |

### Supplier RPCs (4)

| Function | Vol | Purpose |
|----------|-----|---------|
| `supplier_list_my_invoices(status?, limit, offset)` | stable | List invoices on caller's supplier. |
| `supplier_get_my_invoice(invoice_id)` returns jsonb | stable | Detail (no payment_methods detail). |
| `supplier_record_payment_receipt(invoice_id, paid_amount, ...)` returns uuid | volatile | Supplier confirms a receipt; creates payment with `recorded_by_party='supplier'`, auto-promotes invoice. |
| `supplier_list_my_payments(invoice_id?, status?, limit, offset)` | stable | List payments on supplier's invoices. |

### Admin RPCs (6)

| Function | Vol | Purpose |
|----------|-----|---------|
| `admin_list_invoices(organization_id?, supplier_id?, status?, limit, offset)` | stable | Cross-org admin list. |
| `admin_get_invoice(invoice_id)` returns jsonb | stable | Detail with counts. |
| `admin_force_invoice_status(invoice_id, to, reason?)` | volatile | Override to any status. Writes event. |
| `admin_list_invoice_events(invoice_id)` | stable | Invoice event trail. |
| `admin_list_payment_events(invoice_id?, payment_id?)` | stable | Payment event trail. |
| `admin_void_invoice(invoice_id, reason?)` | volatile | Force to voided. |

**24 RPCs total.** All `SECURITY DEFINER`, all `search_path=""`, single owner `postgres`. Volatility split: 10 stable / 14 volatile.

## Validation Summary

### Migration apply

```
Applying migration 20260622090027_invoice_payment_foundation.sql...
Finished supabase db reset on branch main.
```

All 27 migrations apply cleanly. One mid-implementation fix was required: `fn_promote_invoice_after_payment` originally only promoted from "payable" states; tests revealed that a refund couldn't demote a `paid` invoice back to `partial`. Added a `paid → partial / sent` demotion branch when `paid_amount` drops below `total_amount`.

### Verification queries (snapshot)

- 6 `finance.*` tables, all `relrowsecurity = t`, `relforcerowsecurity = f`
- 0 INSERT/UPDATE/DELETE direct grants on `finance.*`
- 24 RPCs across buyer/supplier/admin namespaces (14 buyer + 4 supplier + 6 admin)
- All RPCs `owner=postgres`, `security_definer=t`, `search_path=""`
- 10 stable + 14 volatile (split matches read/write intent)
- 0 buyer RPCs accept `p_buyer_organization_id`; 0 supplier RPCs accept `p_supplier_id`
- Single distinct owner across all finance RPCs
- 0 forbidden side-effect schemas (`pricing/settlement/escrow/insurance_claim/gps/accounting`)

### pgTAP suite

```
================================================================
Files: 61 passed, 0 failed
Assertions: 407 passed, 0 failed
================================================================
```

| File | Assertions | Coverage |
|------|------------|----------|
| 001–056 | 364 | CC-05 through CC-15 (incl. acceptance) |
| **057 finance RLS, grants, RPC metadata, safety, forbidden schemas** | **13** | **CC-16** |
| **058 buyer invoice lifecycle** (create → item → issue → send → record full payment → auto-paid → events) | **11** | **CC-16** |
| **059 scope + transitions** (cross-buyer block, draft cannot send, draft cannot accept payment, paid_amount<=0 rejected, missing target rejected, cancel-paid rejected) | **7** | **CC-16** |
| **060 payment lifecycle** (partial → paid via 2 payments, refund demotes paid → partial, refund of non-completed rejected) | **5** | **CC-16** |
| **061 supplier visibility + immutability** (supplier list/get, supplier receipt with party=supplier, unrelated supplier 0/42501, direct UPDATE/DELETE events blocked) | **7** | **CC-16** |
| **CC-16 new** | **43** | |
| **Suite total** | **407** | **across 61 files** |

### Frontend

CC-16 added no frontend code. The frontend remains at its CC-07 surface (22 routes). `supabase/config.toml` does not yet expose the `finance` schema (nor `app_storage` / `contract` / `evaluation` / `offer` / `shipment`) to PostgREST — must be added before any UI calls these RPCs.

## Known limitations / handoff notes for CC-17

1. **No payment gateway integration.** Payment recording is metadata-only. `pending` / `processing` / `failed` / `cancelled` payment states are reserved for future gateway integration. CC-17 may introduce a `payment_gateway` adapter layer with Shaparak / Stripe / etc.
2. **No scheduled overdue detection.** `buyer_mark_overdue` and `admin_force_invoice_status` are manual paths. A cron-style sweeper that walks `due_date < today AND status IN (sent, partial)` is a future addition.
3. **No tax engine / VAT calculation.** `tax_rate` is per-line, `tax_amount` is the sum, `taxes_and_fees` is freeform jsonb. Localised tax computation (Iranian VAT etc.) is a future concern.
4. **No multi-currency conversion.** `invoice.currency` is a single field per invoice; cross-currency payments aren't reconciled. FX is out of scope.
5. **No credit notes / debit notes.** Refund of a payment is modeled; credit-note documents are not.
6. **No invoice numbering customization per org.** Codes follow `INV-YYYY-XXXXXXXX`. Custom number formats per buyer org are a future addition.
7. **No partial-refund support.** `buyer_refund_payment` refunds the full payment row. A partial-refund flow (refund X% of a completed payment) would require either a new `refunds` table or amount adjustments — future addition.
8. **No payment method validation against gateway.** The `payment_methods` registry is descriptive metadata only.
9. **No invoice PDF rendering or sending.** `buyer_send_invoice` flips status but does not produce or transmit a document. Use the CC-15 `app_storage` layer to attach a generated PDF to the invoice (entity_type='invoice').
10. **No advanced accounting (GL, AP/AR, COGS, deferred revenue).** Same exclusion boundary as CC-15. Test 057/13 verifies that no `pricing/settlement/escrow/insurance_claim/gps` schemas exist (the `accounting` schema is also absent).
11. **No `Database` type entry for `finance`** in the frontend types file. Will be added when buyer / supplier billing UI lands.
12. **Cross-domain integrity is RPC-enforced.** `invoices.executed_contract_id → executed_contracts.id` is the load-bearing link; `supplier_id` is copied from the target at create time. Direct INSERTs by `service_role` bypassing RPCs could violate the invariants; mitigated by no-direct-write-grants on `authenticated`.
13. **Payment_methods are per-organization (buyer-private).** Supplier-defined payment methods (e.g. "Wire transfer to bank X") aren't modeled in this CC.
14. **No FK between invoice and shipment items.** Item back-pointers are optional FKs with `on delete set null`, so deleting a shipment/contract item won't cascade-delete invoice items.
