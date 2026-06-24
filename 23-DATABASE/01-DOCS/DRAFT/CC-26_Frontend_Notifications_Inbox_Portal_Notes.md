# CC-26 — Phase 2.19 Frontend Notifications / Inbox Portal Foundation, Notes

Version: 1.0 (DRAFT)
Scope: Twentieth platform step. Frontend-only — wires the CC-19 `notify.*` RPCs
through Next.js Server Actions + server-rendered pages.
Migration: **none.** DB baseline 0001–0032 is unchanged.
Status: Implementation complete; all directives met. Pending user acceptance.

## Locked decisions (Q1–Q10)

| # | Decision | Notes |
|---|----------|--------|
| Q1 | A — all 4 routes | `/inbox`, `/inbox/[notificationId]`, `/inbox/preferences`, `/admin/notifications`. |
| Q2 | A — explicit "mark read" + detail-page auto-mark | Row button + server-side mark on detail load. |
| Q3 | A — skip top-nav unread badge | Layout-level data fetch deferred. |
| Q4 | A — per-(category, channel) grid for primary org | One organization scope; matrix UI. |
| Q5 | A — read-only templates | `admin_upsert_template` not exposed. |
| Q6 | A — admin-only delivery attempts | Subject inbox detail stays clean. |
| Q7 | A — verifier extended | All 4 routes + `/inbox/*` per-page guard pattern. |
| Q8 | A — plain text body | Persian + English plain rendering. |
| Q9 | B — internal hrefs use `<Link>`, external use native anchor | Action URL routed correctly per prefix. |
| Q10 | A — stop at typecheck + build + verifier green | No manual browser smoke. |

## What changed

### Files created (15)

**Server modules (7):**

| File | RPCs |
|---|---|
| `src/lib/notify/list-my-notifications.ts` | `notify.portal_list_my_notifications` |
| `src/lib/notify/get-notification.ts` | `notify.portal_get_notification` |
| `src/lib/notify/unread-count.ts` | `notify.portal_unread_count` |
| `src/lib/notify/inbox-actions.ts` | 4 Server Actions: `markRead`, `markAllRead`, `archiveNotification`, `upsertPreferences` |
| `src/lib/admin/list-admin-notifications.ts` | `notify.admin_list_notifications` |
| `src/lib/admin/list-notification-templates.ts` | `notify.admin_list_templates` |
| `src/lib/admin/list-delivery-attempts.ts` | `notify.admin_list_delivery_attempts` |

**Pages + components (8):**

| Path | Purpose |
|---|---|
| `app/inbox/page.tsx` | inbox list with status/category filters + unread count |
| `app/inbox/mark-all-read-form.tsx` | scoped mark-all-read action |
| `app/inbox/row-actions.tsx` | per-row mark-read / archive |
| `app/inbox/[notificationId]/page.tsx` | detail view with payload + metadata + action_url |
| `app/inbox/[notificationId]/archive-form.tsx` | archive action on detail |
| `app/inbox/preferences/page.tsx` | preferences page (per-org) |
| `app/inbox/preferences/preferences-form.tsx` | per-(category × channel) toggle matrix |
| `app/admin/notifications/page.tsx` | tabbed admin dashboard (all / templates / deliveries) |

### Files modified (2)

| File | Change |
|---|---|
| `src/types/database.compat.ts` | Added "CC-26: Notify portal types" section with 5 wrapper interfaces + 6 enum aliases. |
| `scripts/verify-admin-route-guards.sh` | Header expanded to CC-26. Added admin notifications check. Added "Inbox portal" section that loops three paths (`""`, `[notificationId]`, `preferences`) and asserts `getProfile() + redirect("/login")` in each. |

**Files NOT touched:** every prior migration, every `notify.*` SQL surface, `database.ts` generated file, `supabase/config.toml`, all KYC / pricing / supplier / admin / buyer code from CC-19..CC-25, every other domain.

### Route inventory

4 new routes:

```
/inbox                                  (per-page getProfile() guard)
/inbox/[notificationId]                 (per-page getProfile() guard + server-side mark-read)
/inbox/preferences                      (per-page getProfile() guard)
/admin/notifications                    (admin layout's PLATFORM_ADMIN gate)
```

Build route count: **39 → 43 (+4).**

## Validation results

| Gate | Required | Actual |
|---|---|---|
| `bash 23-DATABASE/tests/run.sh` | 101 / 790 / 0 (unchanged) | **101 files / 790 assertions / 0 failures** |
| `npm run typecheck` | 0 errors | **0 errors** |
| `npm run build` | exit 0; route count grows by 4 | **43 routes built**, exit 0 |
| `bash scripts/verify-admin-route-guards.sh` | extended + pass | **VERIFICATION PASSED** (admin + supplier + buyer + Inbox + Personal KYC sections all green) |

### Type wiring

- Canonical notify enums + table rows come from regenerated `database.ts` (no regeneration needed in CC-26).
- 5 sidecar wrapper interfaces model the projected RPC shapes:
  - `NotificationInboxRow` (subject list)
  - `NotificationDetail` (subject detail jsonb)
  - `AdminNotificationRow` (admin list)
  - `NotificationTemplateRow` (template list)
  - `DeliveryAttemptRow` (delivery list)
- 6 enum aliases: `NotificationCategory`, `NotificationPriority`, `NotificationStatus`, `ChannelType`, `DeliveryStatus`, `TemplateStatus`.

### Preferences form encoding

The preferences form encodes each `(category, channel)` pair with two hidden inputs:
- `known:<category>:<channel>` (always `"1"`)
- `pref:<category>:<channel>` (`"on"` if checkbox is checked)

The server action iterates `formData.keys()` looking for `known:*` markers, then reads the matching `pref:*` value to determine `enabled`. This handles HTML's "unchecked checkbox sends nothing" behavior — without the `known` marker we couldn't tell "unchecked" from "field not present".

### Action URL routing (Q9=B)

`/inbox/[notificationId]` inspects `detail.action_url`:
- starts with `/` → renders as Next.js `<Link>` (prefetched).
- starts with `http://` or `https://` → renders as native `<a target="_blank" rel="noopener noreferrer">`.
- anything else → no button.

## Mid-execution findings

None. CC-19's RPC signatures mapped cleanly to TypeScript on the first pass; typecheck went green without iteration; build went green on the first attempt.

## Boundaries respected

- ✅ No DB / RPC / RLS / grant / trigger / template-seed changes. CC-19 baseline is byte-identical.
- ✅ No new migrations.
- ✅ No new channel implementations — `in_app` only; other channels disabled in preferences UI (visible but unchecked + disabled).
- ✅ No admin template editor (CRUD). Read-only list only.
- ✅ No client-side Supabase mutations.
- ✅ No WebSocket / real-time / polling. No push notifications. No service worker.
- ✅ No KYC / pricing / quotation cross-domain UI changes.
- ✅ No bulk archive / bulk delete.
- ✅ No notification deletion (`dismissed` path not exposed).
- ✅ No new dependencies. `package.json` untouched.

## Known limitations / handoff notes

1. **`portal_unread_count` is fetched only on the inbox page** (Q3=A — no header badge). A later CC could add a layout-level fetch and surface the count in `top-nav.tsx`.
2. **Preferences scope is the user's primary organization only.** Q4=A defers the full multi-org matrix. The server action `upsertPreferences` accepts `p_organization_id` from a hidden input so the contract is already organization-aware.
3. **Templates tab is read-only.** Admins must SQL into `notify.notification_templates` to edit. A follow-up CC could add the `admin_upsert_template` form (the RPC is already exposed).
4. **Delivery-attempts list is unfiltered by default.** Filters (`p_notification_id`, `p_channel`, `p_status`) are passed as `null` from the page; a follow-up CC could add filter inputs.
5. **Detail page auto-marks read** without batching across multiple visits. If a user opens 50 notifications in rapid succession, that's 50 `portal_mark_read` calls — fine at CC-19 in-app scale, but a hint to consider client-side batching if delivery channels ever go live.
6. **No empty-organization handling on `/inbox/preferences`** beyond a friendly card. Users without a primary org are rare in the existing data model (CC-22 `getProfile` falls through to `/welcome` for them on `/profile`).
7. **`NotificationDetail.payload` is rendered as collapsed JSON.** The Persian-first body lives in `body_fa`. If templates start carrying structured "fields" inside payload, a richer renderer becomes a future polish CC.

## Acceptance criteria

- [ ] `bash 23-DATABASE/tests/run.sh` reports **101 / 790 / 0** (unchanged). ✓
- [ ] `npm run typecheck` exits 0. ✓
- [ ] `npm run build` exits 0 with 43 routes. ✓
- [ ] `bash scripts/verify-admin-route-guards.sh` passes the extended verifier. ✓
- [ ] Confirm preferences scoping to primary organization is acceptable for the first iteration (vs. full membership matrix).
- [ ] Confirm read-only templates UI is acceptable (vs. exposing `admin_upsert_template`).
- [ ] Confirm CC-27 may proceed.
