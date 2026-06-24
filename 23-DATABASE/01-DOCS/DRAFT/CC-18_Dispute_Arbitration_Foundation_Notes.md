# CC-18 — Phase 2.11 Dispute & Arbitration Workflow Foundation, Schema Notes

Version: 1.0 (DRAFT)
Scope: Twelfth business-domain step — formal dispute cases with evidence, mediator decisions, and settlement-side wiring. Completes CC-17 dispute scaffolding (`settlement.settlements.dispute_status`) by adding a full `dispute.disputes` case object, participants, evidence (with confidentiality), immutable decisions, immutable events, and an AFTER UPDATE trigger on `settlement.settlements` that auto-creates dispute cases.
Migration: `23-DATABASE/migrations/0029_dispute_arbitration_foundation.sql` (single, append-only).
Status: Implementation complete; tests 067–071 pass (46 assertions). Pending user acceptance.

## Locked decisions (Q1–Q10)

| # | Decision | Source |
|---|----------|--------|
| Q1 | One active dispute per settlement. Resolved/withdrawn/cancelled free the slot. | CC-18 prompt |
| Q2 | Reuse `app_storage.file_associations` (`entity_type='dispute_evidence'`). No new evidence-file table. | CC-18 prompt |
| Q3 | Exactly one active decision per dispute (partial unique index `WHERE voided_at IS NULL`). Corrections via `admin_void_decision` + new `admin_record_decision`. | CC-18 prompt |
| Q4 | No new `settlement.settlement_status` enum value. Split uses `released` + `metadata.dispute_resolution.split=true`. | CC-18 prompt |
| Q5 | Buyer/supplier withdrawal allowed only before `admin_record_decision`. After decision → admin-only override. | CC-18 prompt |
| Q6 | Evidence confidentiality flag honoured via RLS: `metadata.confidential=true` hides narrative from opposing party. Mediator/admin always see. | CC-18 prompt |
| Q7 | Approach A: additive AFTER UPDATE trigger `trg_dispute_autocreate` on `settlement.settlements`. **No CC-17 RPC body modified.** | CC-18 prompt |
| Q8 | No UI in CC-18. | CC-18 prompt |
| Q9 | Mediator must be a `platform_admin` user. No new role. | CC-18 prompt |
| Q10 | Split writes 3 ledger entries: `release` + `debit` for supplier_share, `reverse` for buyer_share. | CC-18 prompt |

## Relationship to existing foundations

| Foundation | How CC-18 uses it |
|------------|-------------------|
| identity | `is_platform_admin()`, `has_role(...)`, `current_organization_id()`, `current_user_id()` |
| organization | RLS predicates for buyer/supplier audiences |
| supplier | `supplier.fn_portal_supplier_id()` for supplier-side visibility |
| contract | `executed_contract_id` denormalised onto disputes from settlement |
| shipment | `shipment_id` denormalised onto disputes from settlement (nullable) |
| settlement | `settlements(id)` is the anchor; dispute_status flag on settlements remains the user-facing summary; `fn_record_escrow_entry` is called by `fn_apply_decision_to_settlement` for split/release/reverse; **new trigger** on settlement.settlements auto-creates dispute case when CC-17's `supplier_open_dispute` flips dispute_status |
| app_storage | files attached via `portal_link_file_to_entity('dispute_evidence', evidence_id)` |
| audit | `audit.audit_event` via `dispute.fn_audit` and generic audit triggers |

## Schema overview

### Enums (6)

- `dispute.dispute_case_status` — `opened, under_review, resolved_buyer, resolved_supplier, resolved_split, withdrawn, cancelled`
- `dispute.party_role` — `buyer, supplier, platform_admin, mediator, observer`
- `dispute.evidence_kind` — `narrative, document, financial, photo, communication_log, inspection_report, other`
- `dispute.evidence_status` — `submitted, accepted, rejected, withdrawn`
- `dispute.decision_outcome` — `favor_buyer, favor_supplier, split, no_action, withdrawn`
- `dispute.settlement_action` — `release_to_supplier, reverse_to_buyer, split, no_change`

### Tables (5)

| Table | Purpose |
|-------|---------|
| `dispute.disputes` | Case object anchored to a settlement. Q1 unique active per settlement. |
| `dispute.dispute_participants` | Named participants. Auto-populated with buyer + supplier on case creation. |
| `dispute.dispute_evidence` | Evidence rows with confidentiality (Q6). Files in `app_storage`. |
| `dispute.dispute_decisions` | Mediator decisions. Q3 unique active per dispute via `WHERE voided_at IS NULL`. |
| `dispute.dispute_events` | **Immutable** case lifecycle + structural trail. |

### Trigger (Q7-A, additive)

```
trg_dispute_autocreate on settlement.settlements
  AFTER UPDATE FOR EACH ROW
  WHEN (old.dispute_status IS DISTINCT FROM new.dispute_status)
  EXECUTES dispute.fn_autocreate_from_settlement()
```

Fires when `settlement.dispute_status` transitions from `none` to `opened`. Auto-creates `dispute.disputes` row with participants from the settlement fields. Skips if a dispute row already exists for the settlement (so `dispute.buyer_open_dispute` can insert its own row first and the trigger no-ops).

## Lifecycles

### Dispute case

```
buyer_open_dispute (CC-18) — direct insert
or
settlement.supplier_open_dispute (CC-17, unchanged) — fires trg_dispute_autocreate
       │
       ▼
   opened
       │ admin_assign_mediator (Q9: platform_admin only)
       │ admin_start_review
       ▼
   under_review
       │ buyer/supplier_submit_evidence (any party)
       │ admin_review_evidence (accept/reject)
       │ admin_record_decision (immutable per Q3)
       ▼
   resolved_buyer | resolved_supplier | resolved_split  (terminal)
       │
       │ (non-terminal → withdrawn via opener before decision per Q5)
       │ (non-terminal → cancelled by admin)
       │ (admin_void_decision + admin_record_decision for corrections per Q3)
       ▼
   withdrawn | cancelled
```

### Settlement integration

When `admin_record_decision` inserts a row, `fn_apply_decision_to_settlement` runs:

| `settlement_action` | Effect on settlement | Effect on escrow ledger |
|---|---|---|
| `release_to_supplier` | `status='released'`, `released_amount=held_amount` | `release` + `debit` for held amount |
| `reverse_to_buyer` | `status='cancelled'`, `cancelled_reason='dispute_resolution_reverse'` | `reverse` for held amount |
| `split` (Q10) | `status='released'`, `metadata.dispute_resolution.split=true`, `released_amount=supplier_share` | `release` + `debit` for supplier_share **AND** `reverse` for buyer_share = 3 entries |
| `no_change` | No state change | No entries |

In all cases, `settlement.dispute_status` is updated to one of the CC-17 enum values:
- `release_to_supplier` / `split` → `resolved_supplier` (Q4: no new enum, metadata flag carries split)
- `reverse_to_buyer` → `resolved_buyer`
- `no_change` → `withdrawn` (neither party prevailed materially)

## Security model

### RLS

All 5 tables have RLS enabled (`relforcerowsecurity = f`).

| Table | Read audience |
|-------|---------------|
| `dispute.disputes` | buyer org members, supplier org members, platform_admin |
| `dispute.dispute_participants` | same audience as parent dispute |
| `dispute.dispute_evidence` | same audience as parent dispute, with **Q6 confidentiality filter** |
| `dispute.dispute_decisions` | same audience as parent dispute |
| `dispute.dispute_events` | same audience as parent dispute |

**Q6 confidentiality predicate** (on `dispute_evidence.SELECT`):
- platform_admin → see all
- submitter (`submitter_user_id = current_user_id()`) → see own
- `metadata.confidential` not true → see
- caller is same side as submitter (buyer-side reads buyer-submitted, supplier-side reads supplier-submitted) → see
- Otherwise → hide row

Backstop `*_admin_modify` policies on the 3 mutable tables (`disputes`, `dispute_participants`, `dispute_evidence`) allow only `platform_admin`. RPCs bypass via SECURITY DEFINER. Decisions and events have no INSERT/UPDATE/DELETE policies.

### Grants

```
anon          → dispute.disputes                                    SELECT (RLS returns 0)
authenticated → all 5 dispute.* tables                              SELECT
```

`dispute_participants`, `dispute_evidence`, `dispute_decisions`, `dispute_events` intentionally not exposed to `anon`. **No INSERT/UPDATE/DELETE direct grants on any dispute table.**

### Internal helpers (SECURITY DEFINER, `search_path=''`)

| Helper | Purpose |
|---|---|
| `fn_audit(action, dispute_id, payload)` | Domain audit write |
| `fn_next_dispute_code(tenant)` | `DSP-YYYY-XXXXXXXX` |
| `fn_record_dispute_event(...)` | Immutable event writer |
| `fn_assert_buyer_for_dispute` / `fn_assert_supplier_for_dispute` | Role + ownership gates |
| `fn_assert_dispute_open_for_submission` | Status ∈ (opened, under_review) → P0001 |
| `fn_apply_decision_to_settlement(dispute_id)` | Walks settlement_action; calls settlement helpers |
| `fn_autocreate_from_settlement()` | Trigger function for Q7-A |

## RPC inventory (22)

### Buyer (5)

| RPC | Vol | Purpose |
|-----|-----|---------|
| `buyer_open_dispute(settlement_id, title, description?, amount_in_dispute?)` returns uuid | volatile | Open case; auto-add buyer + supplier participants; mirror to settlement (no trigger duplication). |
| `buyer_submit_evidence(dispute_id, evidence_kind, title, narrative?, metadata?)` returns uuid | volatile | Submit evidence as buyer side. |
| `buyer_withdraw_dispute(dispute_id, reason?)` | volatile | Opener-only; blocked after decision (Q5). |
| `buyer_list_disputes(status?, settlement_id?, limit, offset)` | stable | List own org disputes. |
| `buyer_get_dispute(dispute_id)` returns jsonb | stable | Detail with participants/evidence/decision/events (RLS already filters Q6 confidential). |

### Supplier (4)

| RPC | Vol | Purpose |
|-----|-----|---------|
| `supplier_submit_evidence(dispute_id, evidence_kind, title, narrative?, metadata?)` returns uuid | volatile | Submit evidence as supplier side. |
| `supplier_withdraw_dispute(dispute_id, reason?)` | volatile | Opener-only; blocked after decision (Q5). |
| `supplier_list_my_disputes(status?, limit, offset)` | stable | List disputes on caller's supplier. |
| `supplier_get_my_dispute(dispute_id)` returns jsonb | stable | Detail. |

> Note: there is no `dispute.supplier_open_dispute` — supplier-side dispute opening continues to flow through CC-17's `settlement.supplier_open_dispute`, with the new trigger handling auto-creation in `dispute.disputes`. This honors Q7-A.

### Admin (13)

| RPC | Vol | Purpose |
|-----|-----|---------|
| `admin_list_disputes(...)` | stable | Cross-org list. |
| `admin_get_dispute(dispute_id)` | stable | Detail with mediator_notes. |
| `admin_add_participant(...)` | volatile | Add observer/witness/etc. |
| `admin_assign_mediator(dispute_id, mediator_user_id)` | volatile | Q9: mediator must be `platform_admin` user. |
| `admin_start_review(dispute_id)` | volatile | opened → under_review. |
| `admin_review_evidence(evidence_id, status, notes?)` | volatile | accept/reject evidence. |
| `admin_record_decision(...)` returns uuid | volatile | Insert decision + apply settlement action. |
| `admin_void_decision(decision_id, reason?)` | volatile | Q3 correction path. |
| `admin_cancel_dispute(dispute_id, reason?)` | volatile | Admin-only cancel. |
| `admin_list_dispute_events(dispute_id)` | stable | Event trail. |
| `admin_list_dispute_evidence(dispute_id, status?)` | stable | Evidence trail. |
| `admin_list_decisions(dispute_id)` | stable | All decisions including voided. |
| `admin_force_dispute_status(dispute_id, status, reason?)` | volatile | Override hatch. |

**22 RPCs total.** All `SECURITY DEFINER`, `search_path=""`, single owner `postgres`. Volatility: 9 stable / 13 volatile.

## Validation Summary

### Migration apply

```
Applying migration 20260623090029_dispute_arbitration_foundation.sql...
Finished supabase db reset on branch main.
```

All 29 migrations apply cleanly. Zero mid-implementation fixes required.

### Verification queries (snapshot)

- 5 `dispute.*` tables, all `relrowsecurity = t`, `relforcerowsecurity = f`
- 0 INSERT/UPDATE/DELETE direct grants
- 22 RPCs (5 buyer + 4 supplier + 13 admin); all `owner=postgres`, `security_definer=t`, `search_path=""`
- 9 stable + 13 volatile
- 0 buyer RPCs accept `p_buyer_organization_id`; 0 supplier RPCs accept `p_supplier_id`
- Single distinct owner
- 0 forbidden schemas (`banking/psp/gateway/license/insurance_claim/gps/arbitration_provider/sla_engine/court`)
- 1 new trigger on `settlement.settlements`: `trg_dispute_autocreate` (additive; CC-17 RPC bodies unchanged)

### pgTAP suite

```
================================================================
Files: 71 passed, 0 failed
Assertions: 495 passed, 0 failed
================================================================
```

| File | Assertions | Coverage |
|------|------------|----------|
| 001–066 | 449 | CC-05 through CC-17 (incl. acceptance) |
| **067 dispute RLS, grants, RPC metadata, safety, forbidden schemas, trigger** | **13** | **CC-18** |
| **068 buyer dispute lifecycle** (open from released settlement → flip to disputed → evidence → mediator assigned → review started → decision favor_supplier → settlement back to released + dispute_status=resolved_supplier + event written; Q1 duplicate-active rejected) | **11** | **CC-18** |
| **069 supplier path (Q7-A trigger) + cross-org isolation** (CC-17 supplier_open_dispute fires trigger and creates dispute.disputes row; own visibility; foreign supplier 42501; cross-org buyer 42501) | **6** | **CC-18** |
| **070 evidence + decision immutability + Q6 confidentiality + Q3 + Q5** (buyer-flagged confidential hidden from supplier; non-confidential visible; buyer sees own confidential; duplicate active decision 23505; admin_void_decision + new decision; direct UPDATE/DELETE blocked; Q5 withdrawal blocked after decision) | **8** | **CC-18** |
| **071 settlement integration: split + reverse + no_change** (Q10 3-entry split, Q4 released + metadata flag, dispute_status=resolved_supplier; reverse_to_buyer writes 1 reverse + settlement.cancelled; no_change writes 0 entries + dispute_status=withdrawn) | **8** | **CC-18** |
| **CC-18 new** | **46** | |
| **Suite total** | **495** | **across 71 files** |

### Frontend

CC-18 added no frontend code (Q8). The frontend remains at its CC-07 surface (22 routes). `supabase/config.toml` is unchanged.

## Known limitations / handoff notes for CC-19

1. **No SLA timers / auto-escalation.** No deadline enforcement; cases sit at `under_review` until admin records a decision.
2. **No notification dispatch.** Status changes write events but no email/SMS/push goes out. CC-19 candidate.
3. **No external arbitration provider integration.** All decisions are made by a `platform_admin` mediator inside the platform.
4. **No court export, no regulatory filing, no legal-document generator.**
5. **No reopening after resolution.** Once `resolved_*` / `withdrawn` / `cancelled`, the unique-active-per-settlement slot frees up so a new dispute can be opened, but the old case is final.
6. **Mediator is platform_admin only (Q9).** No external mediator role. A future `dispute_mediator` role could be added without migration changes.
7. **Q4 trade-off**: split resolution uses `settlement.status='released'` + `metadata.dispute_resolution.split=true`. Reading code/UI needs to check the metadata flag to distinguish a split-released settlement from a normal full release. A `released_split` enum value could be added later if needed.
8. **No partial reconciliation by supplier on a split.** Once split is recorded, the supplier sees the released portion; `supplier_confirm_reconciliation` (CC-17) only confirms the released amount.
9. **No participant invitations.** Participants are auto-added (buyer + supplier) plus admin can add. No invite flow with accept/decline.
10. **`dispute_evidence` files via app_storage** require the caller to also have access to the dispute entity per `app_storage.fn_caller_can_see_entity`. That helper currently does not recognize `dispute_evidence` — a small additive helper update would be needed if file attachments become a primary UX. **Not addressed in CC-18** (Q2 scope).
11. **CC-17 surface unmodified.** Q7-A trigger is the only addition to settlement.settlements. No CC-17 RPC body was rewritten. Verified by the trigger check in test 067/13.
12. **Decision corrections via Q3** require admin to `admin_void_decision` first, then `admin_record_decision`. The settlement-side action of the voided decision is not automatically rolled back — the new decision overwrites settlement state. UI should warn the mediator before void if reversing the settlement effects is desired.
13. **No `Database` type entry for `dispute`** in the frontend types file (Q8).
14. **No `supabase/config.toml` exposure** for `dispute` (Q1 carried from CC-17 default).
15. **No banking / PSP / payment gateway / accounting / tax / insurance / GPS.** Same exclusion boundary as CC-14/15/16/17.
