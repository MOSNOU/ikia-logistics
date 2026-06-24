# CC-17 — Phase 2.10 Settlement / Escrow Foundation, Schema Notes

Version: 1.0 (DRAFT)
Scope: Eleventh business domain step — buyer-driven settlement ledger backed by logical escrow accounts. Settlements anchored to executed contracts and/or shipments, with line items, immutable escrow ledger entries, escrow lifecycle scaffolding, and dispute status scaffolding. Supplier reconciliation + dispute opening.
Migration: `23-DATABASE/migrations/0028_settlement_escrow_foundation.sql` (single, append-only).
Status: Implementation complete; tests 062–066 pass (42 assertions). Pending user acceptance.

## Mission

CC-17 introduces the `settlement` schema: a logical-money layer over CC-13 executed contracts and CC-14 shipments. Buyers open an escrow account per (organization, supplier, currency), then walk individual settlements through a draft → ready → holding → released → reconciled lifecycle. The escrow account holds **logical** balances derived from an immutable ledger of credit / hold / release / debit / reverse / adjustment entries. Suppliers can confirm reconciliation and open dispute status flags. **No actual money moves.** No banking API, no PSP, no payment gateway, no escrow license workflow, no advanced accounting, no insurance, no tax engine, no arbitration workflow.

## Locked decisions (Q1–Q10)

| # | Decision | Source |
|---|----------|--------|
| Q1 | Pure DB CC. No `supabase/config.toml` PostgREST exposure changes. | CC-17 prompt |
| Q2 | No UI in CC-17. DB-only foundation. | CC-17 prompt |
| Q3 | Settlement anchor — at least one of `executed_contract_id` / `shipment_id` (CHECK + RPC). | CC-17 prompt |
| Q4 | One active escrow per `(organization_id, supplier_id, currency)` (partial unique index). | CC-17 prompt |
| Q5 | `settlement.escrow_entries` is the immutable ledger; balances are recomputed from it. | CC-17 prompt |
| Q6 | `dispute_status` lives on `settlement.settlements`. No separate disputes table. | CC-17 prompt |
| Q7 | Settlement currency forced to match escrow account currency. | CC-17 prompt |
| Q8 | `supplier_confirm_reconciliation` covers full `released_amount` only. | CC-17 prompt |
| Q9 | `platform_fee_amount` on settlement and items. No policies table. | CC-17 prompt |
| Q10 | Tests 062–066, target ~42 assertions. | CC-17 prompt |

## Relationship to existing foundations

| Foundation | How CC-17 uses it |
|------------|-------------------|
| identity | `is_platform_admin()`, `has_role(...)`, `current_organization_id()`, `current_user_id()` |
| organization | `organizations`, `memberships` for buyer/supplier RLS predicates |
| supplier | `supplier.fn_portal_supplier_id()` for supplier-side visibility |
| contract | `contract.executed_contracts(id)` — primary settlement anchor |
| shipment | `shipment.shipments(id)` — alternative settlement anchor |
| finance | `finance.invoices(id)`, `finance.payments(id)` — optional back-pointers on settlement items |
| audit | `audit.audit_event` written by `settlement.fn_audit` and via the generic audit trigger |

## Schema overview

### Enums (4)

- `settlement.settlement_status` — `draft, ready, holding, released, reconciled, disputed, cancelled, voided`
- `settlement.escrow_status` — `open, active, frozen, closed, voided`
- `settlement.escrow_entry_type` — `credit, debit, hold, release, reverse, adjustment`
- `settlement.dispute_status` — `none, opened, under_review, resolved_buyer, resolved_supplier, withdrawn`

### Tables (6)

| Table | Purpose |
|-------|---------|
| `settlement.escrow_accounts` | Logical escrow per `(organization, supplier, currency)`. Carries recomputed balances. |
| `settlement.escrow_entries` | **Immutable** append-only ledger. Source of truth for balances. No UPDATE/DELETE policies. |
| `settlement.escrow_status_events` | **Immutable** escrow account lifecycle trail. No UPDATE/DELETE policies. |
| `settlement.settlements` | Settlement record per executed contract and/or shipment. |
| `settlement.settlement_items` | Line items with `amount`, `fees_amount`, `platform_fee_amount`, `net_amount`. |
| `settlement.settlement_events` | **Immutable** settlement lifecycle trail. No UPDATE/DELETE policies. |

## Lifecycles

### Settlement

```
       buyer_create_draft_settlement (anchor = contract and/or shipment)
                              │
                              ▼
                           draft
                              │ buyer_update / upsert_item / remove_item
                              │
                  buyer_mark_settlement_ready (requires planned_amount > 0)
                              │
                              ▼
                           ready
                              │ buyer_hold_settlement (writes credit + hold)
                              ▼
                          holding
                              │ buyer_release_settlement (writes release + debit)
                              ▼
                         released
                              │ supplier_confirm_reconciliation
                              ▼
                       reconciled (terminal)

  buyer_cancel_settlement: draft/ready/holding → cancelled
                            (holding cancel writes a `reverse` ledger entry)
  supplier_open_dispute: dispute_status='opened'; if status was holding/released,
                          settlement.status flips to 'disputed'
  admin_force_settlement_status: override hatch
```

### Escrow account

```
       buyer_open_escrow_account
                              │
                              ▼
                           open
                              │ first credit auto-promotes
                              ▼
                          active
                              │ admin_freeze_escrow_account ⇄ admin_unfreeze_escrow_account
                              ▼
                          frozen
                              │
                      admin_close_escrow_account (requires zero held + zero available)
                              ▼
                          closed (terminal)
```

## Security model

### RLS

All 6 tables have RLS enabled with the standard predicate:

- **Buyer-side** — members of the settlement's / escrow's `organization_id`
- **Supplier-side** — members of the settlement's / escrow's `supplier_id → supplier.suppliers.organization_id`
- **Platform admin** — always

Backstop `*_admin_modify` policies on the 3 mutable tables (`escrow_accounts`, `settlements`, `settlement_items`) allow only `platform_admin`. RPCs bypass via SECURITY DEFINER. Events and ledger entries have **no** INSERT/UPDATE/DELETE policies.

### Grants

```
anon          → settlement.settlements, settlement.settlement_items                SELECT (RLS returns 0)
authenticated → all 6 settlement.* tables                                          SELECT
```

`escrow_accounts`, `escrow_entries`, `escrow_status_events`, `settlement_events` intentionally NOT exposed to `anon`. **No INSERT/UPDATE/DELETE direct grants on any settlement table.**

### Internal helpers (SECURITY DEFINER, `search_path=''`)

| Helper | Purpose |
|--------|---------|
| `fn_audit(action, resource_id, resource_type, payload)` | Writes domain audit event for either `settlement` or `escrow_account` |
| `fn_next_settlement_code` / `fn_next_escrow_code` | Code generators (`STL-YYYY-XXXXXXXX`, `ESC-YYYY-XXXXXXXX`) |
| `fn_record_settlement_event` | Inserts immutable settlement events row |
| `fn_record_escrow_status_event` | Inserts immutable escrow status events row |
| `fn_record_escrow_entry` | **Single point of ledger mutation**. Validates amount > 0. |
| `fn_recompute_escrow_balances` | Sums ledger entries into `escrow_accounts` totals. Auto-activates from `open` on first credit. |
| `fn_recompute_settlement_totals` | Sums items into `planned_amount`, `fees_amount`, `platform_fee_amount`, `net_to_supplier_amount` |
| `fn_assert_buyer_for_settlement` | Owner + role gate |
| `fn_assert_buyer_for_escrow` | Owner + role gate for escrow account |
| `fn_assert_settlement_editable` | Status ≠ draft → P0001 |

### Balance semantics

```
total_credited = sum(credit) + sum(adjustment) - sum(reverse)
total_debited  = sum(debit)
total_held     = max(sum(hold) - sum(release) - sum(reverse), 0)
total_released = sum(release)
available      = total_credited - total_debited - total_held
```

`reverse` undoes both the credit and the hold for the same amount (used when cancelling a `holding` settlement — the credit/hold pair is undone with a single `reverse` entry).

## RPC inventory (24)

### Buyer (11)

| RPC | Vol | Purpose |
|-----|-----|---------|
| `buyer_open_escrow_account(supplier_id, currency?, metadata?)` returns uuid | volatile | Open active escrow account for `(caller_org, supplier, currency)`. |
| `buyer_create_draft_settlement(executed_contract_id?, shipment_id?, escrow_account_id?, currency?, ...)` returns uuid | volatile | Create draft settlement. At least one anchor required. |
| `buyer_update_settlement(settlement_id, ...)` | volatile | Draft-only update. |
| `buyer_upsert_settlement_item(settlement_id, description, amount, fees, platform_fee, ...)` returns uuid | volatile | Add/update item; recomputes totals. |
| `buyer_remove_settlement_item(item_id)` | volatile | Soft-delete; recomputes totals. |
| `buyer_mark_settlement_ready(settlement_id)` | volatile | draft → ready. Requires planned_amount > 0. |
| `buyer_hold_settlement(settlement_id)` | volatile | ready → holding. Writes escrow credit + hold pair. |
| `buyer_release_settlement(settlement_id, reason?)` | volatile | holding → released. Writes release + debit pair. |
| `buyer_cancel_settlement(settlement_id, reason?)` | volatile | draft/ready/holding → cancelled. Holding cancel writes `reverse` entry. |
| `buyer_list_settlements(escrow_account_id?, status?, limit, offset)` | stable | List own org settlements. |
| `buyer_get_settlement(settlement_id)` returns jsonb | stable | Detail with items + events. |

### Supplier (4)

| RPC | Vol | Purpose |
|-----|-----|---------|
| `supplier_list_my_settlements(status?, limit, offset)` | stable | List settlements on caller's supplier. |
| `supplier_get_my_settlement(settlement_id)` returns jsonb | stable | Detail. |
| `supplier_confirm_reconciliation(settlement_id, notes?)` | volatile | released → reconciled. Full `released_amount` only. |
| `supplier_open_dispute(settlement_id, reason)` | volatile | Sets `dispute_status='opened'`; flips holding/released → disputed. |

### Admin (9)

| RPC | Vol | Purpose |
|-----|-----|---------|
| `admin_list_escrow_accounts(organization_id?, supplier_id?, status?, limit, offset)` | stable | Cross-org list. |
| `admin_get_escrow_account(account_id)` returns jsonb | stable | Detail with balances + entries count. |
| `admin_freeze_escrow_account(account_id, reason?)` | volatile | open/active → frozen. |
| `admin_unfreeze_escrow_account(account_id, reason?)` | volatile | frozen → active. |
| `admin_close_escrow_account(account_id, reason?)` | volatile | Requires zero held + zero available. |
| `admin_list_settlements(organization_id?, supplier_id?, status?, limit, offset)` | stable | Cross-org list. |
| `admin_get_settlement(settlement_id)` returns jsonb | stable | Detail with counts. |
| `admin_list_settlement_events(settlement_id)` | stable | Event trail. |
| `admin_force_settlement_status(settlement_id, status, reason?)` | volatile | Override hatch (incl. voided). |

**24 RPCs total.** All `SECURITY DEFINER`, all `search_path=""`, single owner `postgres`. Volatility: 9 stable / 15 volatile.

## Validation Summary

### Migration apply

```
Applying migration 20260623090028_settlement_escrow_foundation.sql...
Finished supabase db reset on branch main.
```

All 28 migrations apply cleanly. One mid-implementation fix was required: `fn_recompute_escrow_balances` originally subtracted `reverse` from `total_held` only, but the `available_balance` formula didn't account for `reverse` undoing the credit too. Updated to `total_credited = credit + adjustment - reverse`.

### Verification queries (snapshot)

- 6 `settlement.*` tables, all `relrowsecurity = t`, `relforcerowsecurity = f`
- 0 INSERT/UPDATE/DELETE direct grants on `settlement.*`
- 24 RPCs (11 buyer + 4 supplier + 9 admin)
- All RPCs `owner=postgres`, `security_definer=t`, `search_path=""`
- 9 stable + 15 volatile (split matches read/write intent)
- 0 `buyer_*` RPCs accept `p_buyer_organization_id`; 0 `supplier_*` RPCs accept `p_supplier_id`
- Single distinct RPC owner
- 0 forbidden side-effect schemas (`banking/psp/gateway/license/insurance_claim/gps/arbitration`)

### pgTAP suite

```
================================================================
Files: 66 passed, 0 failed
Assertions: 449 passed, 0 failed
================================================================
```

| File | Assertions | Coverage |
|------|------------|----------|
| 001–061 | 407 | CC-05 through CC-16 (incl. acceptance) |
| **062 settlement RLS, grants, RPC metadata, safety, forbidden schemas** | **13** | **CC-17** |
| **063 buyer settlement lifecycle** (open escrow → draft → item → ready → hold → release; escrow balances + auto-active + 2 entries per hold) | **10** | **CC-17** |
| **064 scope + transitions** (cross-buyer block, draft cannot release, missing anchor 22023, duplicate active escrow 23505, currency mismatch P0001, mark_ready with planned=0 P0001) | **6** | **CC-17** |
| **065 supplier reconciliation + dispute scaffolding** (own visible, confirm_reconciliation released→reconciled, dispute opens + flips holding→disputed, unrelated supplier 42501, reconcile-before-release P0001) | **6** | **CC-17** |
| **066 escrow ledger + event immutability** (cancel-from-holding writes reverse entry, balances zero, direct UPDATE/DELETE blocked on entries + 2 event tables, close rejected with non-zero balances) | **7** | **CC-17** |
| **CC-17 new** | **42** | |
| **Suite total** | **449** | **across 66 files** |

Note: tests `040`, `045`, `050`, `053`, `057` were also updated (documentation-only change to their schema-exclusion lists) — `settlement` legitimately lands in CC-17, so it was removed from those tests' "no forbidden schemas" assertions. No migration was modified.

### Frontend

CC-17 added no frontend code (Q2). The frontend remains at its CC-07 surface (22 routes). `supabase/config.toml` is unchanged (Q1) — the `settlement` schema (and `contract / evaluation / offer / shipment / app_storage / finance`) remains unexposed to PostgREST. A future frontend-focused CC will handle exposure + UI.

## Known limitations / handoff notes for CC-18

1. **No banking integration.** Balances are logical only; no SWIFT, SEPA, Shaparak, or Iranian banking rails.
2. **No PSP / payment gateway.** Settlement transitions are admin/buyer-driven; no automated webhook from Stripe, Shaparak, PayPal, etc.
3. **No escrow license workflow.** No KYC, no regulatory submissions, no compliance attestations.
4. **No arbitration workflow.** `dispute_status` is scaffolding — the resolution-decision engine, document workflow, SLAs, and notification dispatch are out of scope.
5. **No partial reconciliation.** Per Q8, `supplier_confirm_reconciliation` confirms the full `released_amount` only.
6. **No multi-currency conversion.** Per Q7, settlement currency must match escrow account currency. FX is a future CC concern.
7. **No platform fee policy engine.** Per Q9, `platform_fee_amount` is a manual field on settlements and items. A `platform_fee_policies` table can be added later.
8. **No automatic supplier-side balance ledger.** The escrow is from the buyer's perspective. A separate supplier-receivable ledger is a future addition.
9. **No accounting integration.** No GL, no AP/AR, no COGS, no deferred revenue.
10. **No tax engine, no insurance, no GPS.** Same exclusion boundary as CC-14/15/16. Test 062/13 verifies that no `banking/psp/gateway/license/insurance_claim/gps/arbitration` schemas exist.
11. **No `Database` type entry for `settlement`** in the frontend types file (Q2 deferred).
12. **No `supabase/config.toml` exposure** for `settlement` (Q1 deferred).
13. **`reverse` semantics**: a `reverse` entry undoes both the credit and the hold for the same amount. Used for cancel-from-holding only. The 1:1 pairing is enforced by RPC, not at FK level — direct service_role inserts could violate.
14. **Cross-domain integrity is RPC-enforced.** `settlements.executed_contract_id → executed_contracts.id` and the buyer-org match are checked in `buyer_create_draft_settlement`. Direct INSERTs by `service_role` bypassing RPCs could violate; mitigated by no-direct-write-grants on `authenticated`.
