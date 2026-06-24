# CC-28 — Phase 2.21 Frontend RFQ & Offer Portal Foundation, Notes

Version: 1.0 (DRAFT)
Scope: Twenty-second platform step. Frontend-only — wires CC-10 `rfq.*` and
CC-12 `offer.*` RPCs through Next.js Server Actions + server-rendered pages
across supplier, buyer, and admin portals.
Migration: **none.** DB baseline 0001–0032 is unchanged.
Status: Implementation complete; all directives met. Pending user acceptance.

## Locked decisions (Q1–Q10)

| # | Decision | Notes |
|---|----------|--------|
| Q1 | A — all 11 routes shipped | buyer × 3 + supplier × 4 + admin × 4. |
| Q2 | A — minimal RFQ creation fields | code auto-generated; title, currency, deadline, delivery hints, payment terms, description. |
| Q3 | A — add-by-UUID invitations | textarea accepts comma/space-separated UUIDs; calls `buyer_invite_suppliers`. |
| Q4 | C — read-only summary on buyer detail | no `/buyer/offers/[id]` route; received offers shown as a table only. |
| Q5 | A — full admin force-status | RFQ has close + cancel buttons; offer has full status selector. |
| Q6 | A — sidecar wrappers + enums | 8 wrapper interfaces + 4 enum aliases. |
| Q7 | A — verifier extended | All 11 routes asserted; included in CC-28 section. |
| Q8 | A — Server Actions | matches CC-21+ pattern. |
| Q9 | A — hard-coded IRR/USD/EUR | matches CC-24 quotation forms. |
| Q10 | A — stop at green pgTAP + typecheck + build + verifier | No manual browser smoke. |

## What changed

### Files created (24)

**Server modules (14):**

| File | Coverage |
|---|---|
| `src/lib/rfq/list-buyer-rfqs.ts` | `rfq.buyer_list_rfqs` |
| `src/lib/rfq/list-supplier-rfqs.ts` | `rfq.supplier_list_rfq_invitations` |
| `src/lib/rfq/get-rfq.ts` | Audience-switched buyer/supplier/admin read |
| `src/lib/rfq/buyer-actions.ts` | 7 Server Actions: create / upsert-item / remove-item / invite-suppliers / submit / close / cancel |
| `src/lib/offer/list-buyer-offers.ts` | `offer.buyer_list_received_offers` |
| `src/lib/offer/list-supplier-offers.ts` | `offer.supplier_list_my_offers` |
| `src/lib/offer/get-offer.ts` | Audience-switched read |
| `src/lib/offer/supplier-actions.ts` | 5 Server Actions: create-draft / upsert-item / remove-item / submit / withdraw |
| `src/lib/admin/list-rfqs.ts` | `rfq.admin_list_rfqs` |
| `src/lib/admin/list-rfq-invitations.ts` | `rfq.admin_list_invitations` |
| `src/lib/admin/rfq-admin-actions.ts` | 2 Server Actions: force-close / force-cancel |
| `src/lib/admin/list-offers.ts` | `offer.admin_list_offers` |
| `src/lib/admin/list-offer-events.ts` | `offer.admin_list_offer_status_events` |
| `src/lib/admin/offer-admin-actions.ts` | 1 Server Action: `admin_force_status_change` |

**Pages + components (10):**

| Path | Purpose |
|---|---|
| `app/buyer/rfqs/page.tsx` | List + filter |
| `app/buyer/rfqs/new/page.tsx` + `create-rfq-form.tsx` | Create form |
| `app/buyer/rfqs/[id]/page.tsx` + `buyer-rfq-actions.tsx` + `upsert-item-form.tsx` + `invite-suppliers-form.tsx` | Detail + items + invitations + received offers |
| `app/supplier/rfqs/page.tsx` | Invitation list |
| `app/supplier/rfqs/[id]/page.tsx` + `draft-offer-button.tsx` | Read-only RFQ + draft-offer CTA |
| `app/supplier/offers/page.tsx` | Supplier's own offers list |
| `app/supplier/offers/[id]/page.tsx` + `supplier-offer-actions.tsx` + `upsert-offer-item-form.tsx` | Detail + items + submit/withdraw |
| `app/admin/rfqs/page.tsx` | Cross-tenant RFQ queue |
| `app/admin/rfqs/[id]/page.tsx` + `force-rfq-actions.tsx` | Detail + invitations + events + force-close/cancel |
| `app/admin/offers/page.tsx` | Cross-tenant offer queue |
| `app/admin/offers/[id]/page.tsx` + `force-offer-status-form.tsx` | Detail + events + force-status |

### Files modified (2)

| File | Change |
|---|---|
| `src/types/database.compat.ts` | Added "CC-28: RFQ + Offer portal types" section with 8 wrapper interfaces + 4 enum aliases (`RfqStatus`, `RfqVisibilityModel`, `InvitationStatus`, `OfferStatus`). |
| `scripts/verify-admin-route-guards.sh` | Header expanded to CC-28. Added admin RFQ + offer checks, supplier RFQ + offer checks, buyer RFQ checks. |

**Files NOT touched:** all migrations 0001–0032, every `rfq.*` / `offer.*` SQL surface, `database.ts` generated file, `supabase/config.toml`, all CC-22..CC-27 portal code, every other domain.

### Route inventory

11 new routes:

```
buyer:     /rfqs, /rfqs/new, /rfqs/[id]
supplier:  /rfqs, /rfqs/[id], /offers, /offers/[id]
admin:     /rfqs, /rfqs/[id], /offers, /offers/[id]
```

Build route count: **55 → 66 (+11).**

## Validation results

| Gate | Required | Actual |
|---|---|---|
| `bash 23-DATABASE/tests/run.sh` | 101 / 790 / 0 (unchanged) | **101 files / 790 assertions / 0 failures** |
| `npm run typecheck` | 0 errors | **0 errors** |
| `npm run build` | exit 0; route count grows by 11 | **66 routes built**, exit 0 |
| `bash scripts/verify-admin-route-guards.sh` | extended + pass | **VERIFICATION PASSED** (admin + supplier + buyer + Inbox + Personal KYC sections all green) |

## Key design choices

1. **Admin force-status surface differs by domain.** RFQ has only `admin_force_close_rfq` + `admin_force_cancel_rfq` (two buttons → narrower than CC-27 settlement). Offer has `admin_force_status_change` accepting the full status enum, so the offer admin form mirrors CC-27 settlement's selector.
2. **Audience-switched RPC dispatch** (`getRfq(id, "buyer"|"supplier"|"admin")`, `getOffer(id, audience)`) — same pattern established by CC-27 settlement/dispute loaders.
3. **Buyer-side received offers are inline read-only** (Q4=C). The RFQ detail page surfaces a table of offers received for that RFQ; clicking them does not navigate to a buyer-side offer detail page. A future CC can add `/buyer/offers/[id]` if buyers ask for offer-level interaction.
4. **Supplier "draft offer" CTA** lives on `/supplier/rfqs/[id]`. It posts `supplier_create_draft_offer` and redirects to the new offer detail page. Currency is selectable from IRR/USD/EUR before draft creation.
5. **Multi-UUID invitation entry.** `/buyer/rfqs/[id]` invite form accepts a comma- or whitespace-separated list of supplier UUIDs and calls `buyer_invite_suppliers` with the parsed array; the RPC returns a count which is rendered as `count دعوت ارسال شد.`.
6. **Status-driven action visibility** mirrors CC-27 patterns:
   - **RFQ buyer**: submit / close / cancel surfaced only when each is a legal transition.
   - **RFQ admin**: only force-close + force-cancel; both hidden when the RFQ is already in a terminal status.
   - **Offer supplier**: submit only when status is `draft` AND items exist; withdraw only when status is `submitted`.

## Mid-execution findings

None. CC-10 and CC-12 RPC signatures mapped cleanly to TypeScript on the first pass; typecheck went green without iteration; build went green on the first attempt.

## Boundaries respected

- ✅ No DB / RPC / RLS / grant / trigger / migration changes. CC-10 + CC-12 byte-identical.
- ✅ No new migrations.
- ✅ No client-side Supabase mutations — all writes through Server Actions.
- ✅ No file upload UI for specifications or attachments.
- ✅ No evaluation, scoring, or offer-comparison UI beyond the received-offers list.
- ✅ No contract preparation UI.
- ✅ No KYC gating on RFQ publication or offer submission.
- ✅ No pricing autofill from supplier price lists.
- ✅ No nav-bar entries added (`lib/config/nav.ts` untouched).
- ✅ No buyer-side offer detail page on `/buyer/offers/[id]`.
- ✅ No bulk invitation import beyond multi-UUID textarea.
- ✅ No new dependencies — `package.json` untouched.

## Known limitations / handoff notes

1. **Invitation UUIDs are raw inputs.** No supplier-name picker yet. Buyers must paste supplier UUIDs (matching CC-24/27 minimum pattern).
2. **No invitation remove/withdraw UI.** CC-10 currently doesn't expose a `buyer_remove_invitation` or `buyer_withdraw_invitation` RPC; if added later, the existing invite list table is the natural place for per-row actions.
3. **No supplier `buyer_publish_rfq` RPC.** The buyer-side "submit" action calls `buyer_submit_rfq` which advances `draft → submitted`. Further progression to `published` / `invited` likely happens via `buyer_invite_suppliers` (RPC-internal status transition) or admin action. The UI is intentionally minimal here.
4. **Doc requirements + item specifications are not surfaced** in CC-28 UI. CC-10's `buyer_upsert_doc_requirement` / `buyer_upsert_item_specification` RPCs exist; a follow-up CC can add their forms.
5. **Spec response + doc commitment** on the supplier offer side are unsupported in the CC-28 UI for the same reason — covered by RPCs (`supplier_upsert_spec_response`, `supplier_upsert_doc_commitment`) but UI deferred.
6. **The admin RFQ events list relies on a non-zero `events` array** inside `admin_get_rfq`'s jsonb payload. If a future migration changes the projection, the page renders an empty events table without breaking.
7. **No buyer-side offer detail page (Q4=C).** Buyers see offer summaries inside the RFQ detail; for offer-level inspection, an admin or the supplier portal is needed today.
8. **`/buyer/rfqs/[id]` shows received offers without auto-filtering by status.** Future polish CC could add a status filter scoped to the same RFQ.

## Acceptance criteria

- [ ] `bash 23-DATABASE/tests/run.sh` reports **101 / 790 / 0** (unchanged). ✓
- [ ] `npm run typecheck` exits 0. ✓
- [ ] `npm run build` exits 0 with 66 routes. ✓
- [ ] `bash scripts/verify-admin-route-guards.sh` passes the extended verifier. ✓
- [ ] Confirm multi-UUID invitation entry is acceptable as a starting point.
- [ ] Confirm omitting `/buyer/offers/[id]` is acceptable.
- [ ] Confirm CC-29 may proceed.
