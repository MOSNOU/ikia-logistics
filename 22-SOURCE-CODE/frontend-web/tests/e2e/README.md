# Local Playwright E2E — Driver App / Carrier Assign-Driver (v1.1 Phase F)

**LOCAL ONLY.** These tests run the real app against **local Supabase**. Never
point them at production. Passwords are read from env vars and must never be
committed.

## Coverage
- `route-guards.spec.ts` — unauthenticated `/carrier/dispatches/<id>`, `/driver`,
  `/admin/driver-trips` redirect to `/login` (no credentials needed).
- `carrier-assign-driver.spec.ts` — carrier admin logs in, opens the seeded
  dispatch, sees the assign-driver panel, selects the demo driver, submits, and
  gets the success state. *(skips without `E2E_DEMO_CARRIER_PASSWORD`)*
- `driver-sees-trip.spec.ts` — demo driver logs in, sees the assigned trip on
  `/driver`, and the trip detail + next action on `/driver/trips/<id>`.
  *(skips without `E2E_DEMO_DRIVER_PASSWORD`)*

## One-time
```
cd 22-SOURCE-CODE/frontend-web
npm install                 # installs @playwright/test (devDependency)
npx playwright install chromium
```

## Prepare local data
```
cd /Users/mostafanourabi/Desktop/iKIA-LOGISTICS
supabase status             # local stack must be running
# create demo auth users (Studio or Admin API): demo-driver@local.test,
# demo-carrier-admin@local.test (throwaway local passwords)
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" \
  -v ON_ERROR_STOP=1 -f 23-DATABASE/seeds/local_driver_e2e_demo.sql
```

## Local frontend env (`22-SOURCE-CODE/frontend-web/.env.local`, gitignored)
```
NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=<local anon key from `supabase status`>
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

## E2E-only env (shell — do NOT commit)
```
export E2E_DEMO_DRIVER_PASSWORD='<local demo driver password>'
export E2E_DEMO_CARRIER_PASSWORD='<local demo carrier-admin password>'
# optional overrides: E2E_DEMO_DRIVER_EMAIL, E2E_DEMO_CARRIER_EMAIL, E2E_BASE_URL
```

## Run
```
cd 22-SOURCE-CODE/frontend-web
npm run test:e2e            # headless
npm run test:e2e:headed     # visible browser
```
The config's `webServer` reuses a running `npm run dev` or starts one. The
config refuses any `E2E_BASE_URL` that is not `localhost`/`127.0.0.1`.

## Phase I — expanded coverage + local DB fixtures

Additional specs:
- `driver-lifecycle.spec.ts` — trip detail renders POD readiness + empty
  timeline; normal step is one-tap; the irreversible delivery step shows a
  confirmation prompt.
- `carrier-visibility.spec.ts` — carrier dispatch detail shows the compact
  driver-progress read-back (no full timeline).
- `admin-visibility.spec.ts` — admin driver-trips list shows the progress
  columns + filters, filters apply without crashing, and the detail shows the
  progress read-back block.

These use a **local-only** fixture helper (`helpers/fixture.ts`) that drives the
local DB via `psql` (postgres superuser) to reset the seeded demo dispatch,
force a status for the confirmation flow, and grant the demo carrier-admin the
`platform_admin` role so the admin surfaces are reachable. It contains **no
secrets** and only targets local Supabase.

Extra env (optional — sensible local defaults):
```
# defaults to the local Supabase DB; override only if your local port differs
export E2E_DATABASE_URL='postgresql://postgres:postgres@127.0.0.1:54322/postgres'
```
Requirements: `psql` on PATH + a running local Supabase. Specs that need the
fixture **skip with a message** when psql / the local DB is unavailable. The
admin specs reuse `E2E_DEMO_CARRIER_PASSWORD`.
