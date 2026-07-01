import { execFileSync } from "node:child_process";

// Phase I (v1.2, Q9) — LOCAL-ONLY E2E fixture helper. Uses the postgres
// superuser (via psql) to set up deterministic state on the local Supabase DB:
//   - reset the seeded demo dispatch to a known baseline,
//   - force a specific execution status (to exercise the confirmation flow),
//   - grant the demo carrier-admin the platform_admin role so the admin
//     driver-trips surfaces are reachable in local E2E.
//
// It contains NO secrets: the local DB URL defaults to the well-known Supabase
// local connection and can be overridden with E2E_DATABASE_URL. It ONLY targets
// local Supabase (127.0.0.1). If psql is unavailable the dependent specs skip.

const DB_URL =
  process.env.E2E_DATABASE_URL ??
  "postgresql://postgres:postgres@127.0.0.1:54322/postgres";

export const DEMO_DISPATCH_ID = "dede0000-0000-4000-8000-000000000301";
const DEMO_DRIVER_EMAIL = "demo-driver@local.test";
const DEMO_ADMIN_EMAIL = "demo-carrier-admin@local.test";

// Guard: refuse to touch anything that is not a local database.
function assertLocal(): void {
  if (!/127\.0\.0\.1|localhost/.test(DB_URL)) {
    throw new Error(`E2E fixtures are LOCAL ONLY (got ${DB_URL}).`);
  }
}

function runSql(sql: string): void {
  assertLocal();
  execFileSync("psql", [DB_URL, "-X", "-v", "ON_ERROR_STOP=1", "-c", sql], {
    stdio: "pipe",
  });
}

/** True when psql is on PATH and the local DB is reachable. */
export function fixturesReady(): boolean {
  try {
    assertLocal();
    execFileSync("psql", [DB_URL, "-X", "-t", "-c", "select 1"], {
      stdio: "pipe",
    });
    return true;
  } catch {
    return false;
  }
}

/**
 * Reset the seeded demo dispatch to a clean baseline: assigned to the demo
 * driver, released, no events / PODs / issues. Deterministic starting point.
 */
export function resetDemoTrip(): void {
  runSql(`
    update dispatch.dispatch_assignments da
       set driver_user_id = (select id from auth.users where email = '${DEMO_DRIVER_EMAIL}'),
           execution_status = 'assigned',
           status = 'released',
           accepted_at = null,
           completed_at = null,
           updated_at = now()
     where da.id = '${DEMO_DISPATCH_ID}';
    delete from dispatch.driver_trip_events where dispatch_id = '${DEMO_DISPATCH_ID}';
    delete from dispatch.driver_trip_pods   where dispatch_id = '${DEMO_DISPATCH_ID}';
    delete from dispatch.driver_trip_issues where dispatch_id = '${DEMO_DISPATCH_ID}';
  `);
}

/** Force a specific execution status on the demo dispatch (test-only). */
export function setDemoTripStatus(status: string): void {
  runSql(
    `update dispatch.dispatch_assignments set execution_status = '${status}', updated_at = now() where id = '${DEMO_DISPATCH_ID}';`,
  );
}

/** Grant platform_admin to the demo carrier-admin (idempotent) for admin E2E. */
export function grantDemoAdmin(): void {
  runSql(`
    insert into identity.user_roles (user_id, role_id, scope_type, scope_id, granted_at)
    select u.id, r.id, 'platform', null, now()
      from auth.users u cross join identity.roles r
     where u.email = '${DEMO_ADMIN_EMAIL}' and r.code = 'platform_admin'
       and not exists (
         select 1 from identity.user_roles x
          where x.user_id = u.id and x.role_id = r.id
            and x.scope_type = 'platform' and x.revoked_at is null and x.deleted_at is null);
  `);
}
