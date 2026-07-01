# Driver App v1.1 — Local End-to-End Acceptance Runbook (Phase A)

> **LOCAL SUPABASE ONLY. Do not run any of this against the production/linked
> Supabase project.** No production seeding, no production migrations.

This runbook drives a full authenticated pass of the Driver App on a throwaway
local Supabase database, using the v1.1 Phase B `dispatch.carrier_assign_driver`
RPC (migration `0048`) to attach a real driver to a released dispatch.

## Artifacts
- Migration: `23-DATABASE/migrations/0048_driver_assignment_rpc.sql`
  (mirror symlink `supabase/migrations/20260701000048_driver_assignment_rpc.sql`)
- Seed: `23-DATABASE/seeds/local_driver_e2e_demo.sql`
- Tests: `23-DATABASE/tests/181…185_*.sql`

## Demo identities (created via Studio/Admin API — NOT by SQL)
| Role | Email | Purpose |
|------|-------|---------|
| Driver | `demo-driver@local.test` | drives `/driver` |
| Carrier admin | `demo-carrier-admin@local.test` | assigns driver / represents carrier ops |
| Platform admin | (earliest local user, promoted by `dev_tenant_org.sql`) | `/admin/driver-trips` |

## Steps

1. **Start local stack**
   ```
   supabase start
   ```

2. **Apply migrations to the LOCAL db** (never `--linked`)
   ```
   supabase db reset          # applies all migrations incl. 0048 to LOCAL
   ```

3. **Create the demo auth users (local)** — Supabase Studio → Authentication →
   Add user (auto-confirm), or the Admin API with the local service_role key:
   - `demo-driver@local.test` (set any local password)
   - `demo-carrier-admin@local.test`
   Also ensure a platform admin exists (sign up once, then run
   `23-DATABASE/seeds/dev_tenant_org.sql` to promote the earliest user).

4. **Run the local seed**
   ```
   psql "postgres://postgres:postgres@127.0.0.1:54322/postgres" \
        -f 23-DATABASE/seeds/local_driver_e2e_demo.sql
   ```
   It wires the tenant/orgs/roles/membership/profile, creates one **released**
   dispatch, and assigns the demo driver. Re-runnable (idempotent); it no-ops
   with a NOTICE if the demo auth users are missing.

   > The seed assigns the driver directly for a deterministic fixture. To
   > exercise the real path instead, log in as the carrier admin and call:
   > `select * from dispatch.carrier_assign_driver('<dispatch_id>','<driver_id>');`

5. **Point the app at LOCAL Supabase** — set the web app's
   `NEXT_PUBLIC_SUPABASE_URL` / `ANON_KEY` to the values from `supabase start`,
   then run the product app locally (`pnpm dev` in `22-SOURCE-CODE/frontend-web`).

6. **Driver acceptance flow** — log in as `demo-driver@local.test`, then:
   - [ ] `/driver` shows the assigned trip (not the empty state).
   - [ ] Open trip detail; status = `assigned`.
   - [ ] accept → arrive_pickup → start_loading → confirm_loaded → start_transit
         → arrive_delivery → start_unloading → confirm_delivered (only the next
         legal action is offered at each step).
   - [ ] Send a manual GPS ping (one-shot; browser will prompt for location).
   - [ ] Upload a POD (image/PDF).
   - [ ] `complete` becomes available only after the POD; complete the trip.
   - [ ] Report an issue (category + severity); trip status is unchanged.

7. **Admin verification** — log in as the platform admin:
   - [ ] `/admin/driver-trips` lists the trip with status + open-issue count.
   - [ ] Detail shows the event timeline, last GPS, POD list, and issue list.
   - [ ] Acknowledge the issue → `acknowledged`.
   - [ ] Resolve the issue (+note) → `resolved`.

## Cleanup
- Fastest: `supabase db reset` (wipes the local database entirely).
- The seed data is confined to sentinel UUIDs (prefix `dede…`) + the two
  `@local.test` users, so it is trivially identifiable if manual teardown is
  preferred.

## Notes
- The `app-documents` storage bucket + its driver upload policy must exist
  locally for the POD step (created by the storage-foundation migrations).
- Assigning after a trip has started, cross-carrier assignment, and assigning a
  non-/other-org driver are all rejected by `carrier_assign_driver` (see tests
  183–185).
