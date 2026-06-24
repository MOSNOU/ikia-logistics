# CC-19 — Phase 2.12 Notifications & Messaging Foundation, Schema Notes

Version: 1.0 (DRAFT)
Scope: Thirteenth business-domain step — application-layer notifications inbox over CC-09..CC-18. Per-user inbox with category-based templates, opt-out preferences, immutable materialization-audit trail, and per-channel delivery records. Synchronous trigger-based materialization from 12 upstream event tables. **Record-keeping + in-app inbox only**; no email/SMS/push provider integration, no real-time WebSocket fan-out, no worker, no UI.
Migration: `23-DATABASE/migrations/0030_notifications_foundation.sql` (single, append-only).
Status: Implementation complete; tests 072–076 pass (48 assertions). Pending user acceptance.

## Locked decisions (Q1–Q10)

| # | Decision | Source |
|---|----------|--------|
| Q1 | A — per-domain AFTER INSERT triggers, synchronous. | CC-19 prompt |
| Q2 | Skip `notify.subscriptions`. Membership-based resolution only. | CC-19 prompt |
| Q3 | Adopt `notify.materialization_audit` (immutable trace). | CC-19 prompt |
| Q4 | Ship platform-level seed templates (30 loaded: 22 event-specific + 8 category fallbacks). | CC-19 prompt |
| Q5 | Opt-out default (notifications enabled until explicitly disabled). | CC-19 prompt |
| Q6 | Non-`in_app` channels write rows in `skipped` with `failure_reason='channel_not_implemented'`. | CC-19 prompt |
| Q7 | No `portal_dismiss_notification`. Archive is sufficient. | CC-19 prompt |
| Q8 | Buyer-side receives evaluation notifications; suppliers do not (CC-11 privacy boundary). | CC-19 prompt |
| Q9 | All 12 source event tables hooked. | CC-19 prompt |
| Q10 | No UI in CC-19. | CC-19 prompt |

## Relationship to existing foundations

| Foundation | How CC-19 uses it |
|---|---|
| identity | `is_platform_admin()`, `current_user_id()`, `auth.uid()` for recipient identity |
| organization | `memberships` for buyer/supplier recipient resolution |
| supplier | `supplier.suppliers(id) → organization_id` for supplier-side fan-out |
| audit | `audit.audit_event` complements `notify.materialization_audit` |
| rfq/offer/evaluation/contract/shipment/finance/settlement/dispute | 12 event tables hooked via additive AFTER INSERT triggers — no domain table or RPC body modified |

## Schema overview

### Enums (6)

- `notify.notification_category` — `rfq, offer, evaluation, contract, shipment, finance, settlement, dispute, supplier_admin, platform, other`
- `notify.notification_priority` — `low, normal, high, urgent`
- `notify.notification_status` — `unread, read, archived, dismissed`
- `notify.channel_type` — `in_app, email, sms, push, webhook`
- `notify.delivery_status` — `pending, sent, delivered, failed, skipped, suppressed`
- `notify.template_status` — `draft, active, deprecated`

### Tables (5)

| Table | Purpose |
|-------|---------|
| `notify.notification_templates` | Template registry. `tenant_id IS NULL` = platform-scoped; org-scoped wins resolution. |
| `notify.user_preferences` | Q5 opt-out: absence = enabled. |
| `notify.notifications` | Per-user inbox. One source event → N rows (one per recipient × channel). |
| `notify.delivery_attempts` | Per-channel delivery record. `in_app` = delivered immediately; others = `skipped` (Q6). |
| `notify.materialization_audit` | Q3 immutable trace. Records every event the materializer processed. No UPDATE/DELETE policies. |

### Triggers (Q1 = A; 12 additive)

| Source event table | Trigger function |
|---|---|
| `rfq.request_status_events` | `notify.fn_trg_from_rfq_status` |
| `offer.supplier_offer_status_events` | `notify.fn_trg_from_offer_status` |
| `evaluation.offer_decision_events` | `notify.fn_trg_from_evaluation_decision` |
| `contract.contract_preparation_events` | `notify.fn_trg_from_preparation` |
| `contract.executed_contract_events` | `notify.fn_trg_from_executed_contract` |
| `contract.contract_signature_events` | `notify.fn_trg_from_signature` |
| `shipment.shipment_events` | `notify.fn_trg_from_shipment` |
| `finance.invoice_status_events` | `notify.fn_trg_from_invoice` |
| `finance.payment_status_events` | `notify.fn_trg_from_payment` |
| `settlement.settlement_events` | `notify.fn_trg_from_settlement` |
| `settlement.escrow_status_events` | `notify.fn_trg_from_escrow` |
| `dispute.dispute_events` | `notify.fn_trg_from_dispute` |

12 triggers verified present (test 072/14).

### Seed templates (Q4)

30 platform-level templates loaded at migration time:
- 22 event-specific (contract executed/pending/draft, signature requested/signed, shipment planned/booked/in-transit/delivered, invoice issued/sent/paid/partial/overdue, settlement ready/held/released/reconciled, dispute opened/under-review/decided/evidence_submitted)
- 8 category fallbacks (one per category)

Templates have full bilingual `_en` / `_fa` titles + bodies, and `action_url_template` strings that substitute `${entity_id}` at materialization time.

## Materialization pipeline

```
Domain RPC writes to *_events table
       │
       ▼
   AFTER INSERT trigger
       │
       ▼
notify.fn_trg_from_<domain>(NEW)
       │
       ▼
notify.fn_materialize_event(...)
       │
       ├─ fn_resolve_template(template_code, category, tenant_id)
       │     • exact tenant+code → platform+code → category fallback
       │     • returns one template (or no-match → audit row, return)
       │
       ├─ fn_resolve_recipients(entity_type, entity_id, category)
       │     • walks domain entity to find buyer_org / supplier_id / mediator
       │     • DISTINCT users via memberships (buyer_admin, organization_admin,
       │       supplier_admin, organization_admin)
       │     • Q8: suppliers SUPPRESSED for category='evaluation'
       │     • mediator added for disputes when assigned
       │
       ├─ for each recipient × channel:
       │     • Q5 opt-out check (skip if explicit enabled=false)
       │     • insert notify.notifications row
       │     • insert notify.delivery_attempts row
       │       (in_app → delivered, others → skipped per Q6)
       │
       └─ insert notify.materialization_audit row (notes=ok|no_recipients|no_template_matched|error:...)
```

All operations wrapped in exception handler — the upstream domain write is **never** blocked by a notification failure. Errors land in `materialization_audit.notes` with the SQLSTATE message.

## Security model

### RLS

| Table | Read audience |
|---|---|
| `notify.notification_templates` | platform_admin OR org members (org-scoped) OR all authenticated (platform-scoped, `tenant_id IS NULL`) |
| `notify.user_preferences` | own user only (or platform_admin) |
| `notify.notifications` | `recipient_user_id = current_user_id()` (or platform_admin) |
| `notify.delivery_attempts` | recipient of parent notification (or platform_admin) |
| `notify.materialization_audit` | platform_admin only |

Backstop `*_admin_modify` policies on mutable tables (`notification_templates`, `user_preferences`, `notifications`) allow only `platform_admin`. SECURITY DEFINER RPCs bypass.

### Grants

```
anon          → no select grants (notifications are inherently authenticated)
authenticated → notify.notification_templates, user_preferences,
                notifications, delivery_attempts                 SELECT
materialization_audit                                            no grant (admin RPCs only)
```

**No INSERT/UPDATE/DELETE direct grants on any notify table.** Test 076/7-8 verifies UPDATE/DELETE on `notify.notifications` is blocked with `42501` even for the recipient — all mutations must go through portal RPCs.

### Internal helpers (SECURITY DEFINER, `search_path=''`)

| Helper | Purpose |
|---|---|
| `fn_audit(action, notification_id, payload)` | Domain audit write |
| `fn_resolve_template(template_code, category, tenant_id)` | Lookup with org → platform → category fallback |
| `fn_resolve_recipients(entity_type, entity_id, category)` | Walks all 12 domain entity types; honors Q8 evaluation privacy |
| `fn_substitute_action_url(template, entity_id)` | `${entity_id}` substitution |
| `fn_materialize_event(...)` | Main entry point — called by every per-domain trigger |
| 12 per-domain `fn_trg_from_<domain>()` functions | Thin wrappers that translate NEW row → `fn_materialize_event(...)` |

## RPC inventory (11)

### Portal (7)

| RPC | Vol | Purpose |
|-----|-----|---------|
| `portal_list_my_notifications(status?, category?, limit, offset)` returns table | stable | Caller's inbox, sorted by priority desc, created_at desc. |
| `portal_get_notification(notification_id)` returns jsonb | stable | Detail. Does NOT mark read. |
| `portal_unread_count(category?)` returns integer | stable | Cheap counter for badge UI. |
| `portal_mark_read(notification_id)` | volatile | unread → read. |
| `portal_mark_all_read(category?)` returns integer | volatile | Sweep all caller's unread; returns count. |
| `portal_archive_notification(notification_id)` | volatile | read/unread → archived. |
| `portal_upsert_preferences(category, channel, enabled, org_id?, quiet_*)` returns uuid | volatile | Manage own preferences (Q5 opt-out path). |

### Admin (4)

| RPC | Vol | Purpose |
|-----|-----|---------|
| `admin_list_notifications(recipient_user_id?, organization_id?, category?, limit, offset)` | stable | Cross-user ops view. |
| `admin_upsert_template(template_code, category, title_en/fa, body_en/fa, ...)` returns uuid | volatile | Manage templates. Platform or org-scoped. |
| `admin_list_templates(category?, status?)` returns table | stable | Template registry view. |
| `admin_list_delivery_attempts(notification_id?, channel?, status?, limit, offset)` | stable | Operational view of deliveries. |

**11 RPCs total.** All `SECURITY DEFINER`, `search_path=""`, single owner `postgres`. Volatility: 6 stable / 5 volatile.

## Validation Summary

### Migration apply

```
Applying migration 20260623090030_notifications_foundation.sql...
Finished supabase db reset on branch main.
```

All 30 migrations apply cleanly. One mid-implementation defect was fixed: the `set_updated_at` trigger was initially attached to `notify.notifications`, but that table carries only state-specific timestamps (`read_at`, `archived_at`, `dismissed_at`) and has no generic `updated_at` column. Trigger removed from notifications; kept on `notification_templates` + `user_preferences` only.

### Verification queries (snapshot)

- 5 `notify.*` tables, RLS enabled, `relforcerowsecurity = f`
- 0 INSERT/UPDATE/DELETE direct grants on `notify.*`
- 11 RPCs (7 portal + 4 admin); all `owner=postgres`, `security_definer=t`, `search_path=""`
- 5 stable + 6 volatile
- 0 portal RPCs accept `p_buyer_organization_id` / `p_supplier_id` / `p_user_id`
- Single distinct RPC owner
- 0 forbidden schemas (`messaging_gateway/push_provider/email_provider/sms_provider/ws_realtime/pubsub`)
- **12 `trg_notify_from_*` triggers attached** to upstream event tables (Q1+Q9 verified)
- **30 seed templates loaded** (`tenant_id IS NULL`)

### pgTAP suite

```
================================================================
Files: 76 passed, 0 failed
Assertions: 543 passed, 0 failed
================================================================
```

| File | Assertions | Coverage |
|------|------------|----------|
| 001–071 | 495 | CC-05 through CC-18 (incl. acceptance) |
| **072 notify RLS, grants, metadata, safety, forbidden schemas, triggers** | **14** | **CC-19** |
| **073 inbox lifecycle** (fresh inbox empty, settlement chain → unread notifications, in_app=delivered, audit ok, mark_read, mark_all_read, archive, cross-user 42501) | **10** | **CC-19** |
| **074 cross-domain trigger materialization** (settlement → buyer+supplier; dispute → +mediator; **Q8: evaluation buyer-only**; invoice → buyer+supplier) | **8** | **CC-19** |
| **075 preferences + opt-out** (baseline delivery, opt-out suppresses, supplier unaffected, re-enable restores, RLS hides preferences) | **7** | **CC-19** |
| **076 templates + isolation** (Q4 seed count, gated upsert, admin list, RLS cross-user hide, UPDATE/DELETE blocked) | **9** | **CC-19** |
| **CC-19 new** | **48** | |
| **Suite total** | **543** | **across 76 files** |

### Frontend

CC-19 added no frontend code (Q10). The frontend remains at its CC-07 surface (22 routes). `supabase/config.toml` is unchanged.

## Known limitations / handoff notes for CC-20

1. **No real delivery.** `in_app` is functional (notifications surface via portal RPCs). Email/SMS/push/webhook all write `delivery_attempts` rows in `skipped` with `failure_reason='channel_not_implemented'`. A future CC introduces a worker that picks these up.
2. **No WebSocket / Realtime fan-out.** The inbox is polled via `portal_unread_count` / `portal_list_my_notifications`. A push channel would require Supabase Realtime or an edge function.
3. **No worker / cron / edge function.** Outbox-style decoupling can be added by switching delivery_attempts default to `pending` (Q6 deferred) and adding a poll RPC; not in scope here.
4. **No template designer / WYSIWYG.** Templates are managed via `admin_upsert_template`. The 30 seed templates cover the core CC-13/14/16/17/18 events.
5. **No internationalization beyond `_en` / `_fa`.** Templates have title_en/fa + body_en/fa. Locale selection at render time is a UI concern (CC-20+).
6. **No notification dedup across categories.** A single domain event could fan out to multiple notifications if templates overlap categories — but in practice each template is bound to one category.
7. **No SLA timers or escalation rules.** Priority is informational only; the dispute notification gets `urgent` but nothing chases it.
8. **No attachment support.** Use `app_storage` if a UI needs to attach files to a notification.
9. **No subscription table (Q2 deferred).** Entity-scoped opt-in (e.g. "notify me about this specific RFQ only") is not modeled. Membership-based recipient resolution suffices for the first cut.
10. **Q8 evaluation privacy** is enforced inside `fn_resolve_recipients` (the supplier branch is skipped when `category = 'evaluation'`). If a future event hooks into a different category but still references evaluation data, the privacy boundary may need revisiting.
11. **No UI** (Q10). Inbox widget, badge, preferences page all deferred to a frontend CC.
12. **No `Database` type entry for `notify`** in the frontend types file.
13. **No `supabase/config.toml` exposure** for `notify` schema.
14. **`notify.notifications` has no `updated_at` column.** State transitions are captured via `read_at`, `archived_at`, `dismissed_at`. Audit trigger fires on all mutations.
15. **Triggers add a small per-event latency** to upstream domain writes (one stored-procedure call per event). All exceptions inside materialization are swallowed and logged to `materialization_audit` so the upstream write never fails.
16. **No banking / PSP / gateway / accounting / tax / insurance / GPS / arbitration provider / SLA engine / court export / messaging gateway.** Same exclusion boundary as CC-14..CC-18.
