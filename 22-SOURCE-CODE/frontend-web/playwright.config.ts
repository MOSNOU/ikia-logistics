import { defineConfig, devices } from "@playwright/test";

// Phase F (v1.1) — LOCAL-ONLY Playwright E2E for the Driver App / Carrier
// Assign-Driver UI. Requires a locally-running app (npm run dev) backed by
// LOCAL Supabase (http://127.0.0.1:54321). Never point this at production.

const BASE_URL = process.env.E2E_BASE_URL ?? "http://localhost:3000";

// Hard safety rail: refuse to run against anything that isn't localhost.
const host = new URL(BASE_URL).hostname;
if (host !== "localhost" && host !== "127.0.0.1") {
  throw new Error(
    `Playwright E2E is LOCAL ONLY. E2E_BASE_URL must be localhost/127.0.0.1 (got ${BASE_URL}).`,
  );
}

export default defineConfig({
  testDir: "./tests/e2e",
  // Serial + single worker: the specs share one seeded dispatch, so keep them
  // deterministic and race-free.
  fullyParallel: false,
  workers: 1,
  forbidOnly: !!process.env.CI,
  retries: 0,
  reporter: [["list"]],
  use: {
    baseURL: BASE_URL,
    trace: "on-first-retry",
    screenshot: "only-on-failure",
  },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
  // Reuses an already-running dev server if present; otherwise starts one.
  // The dev server reads NEXT_PUBLIC_SUPABASE_* from .env.local (local values).
  webServer: {
    command: "npm run dev",
    url: BASE_URL,
    reuseExistingServer: true,
    timeout: 120_000,
  },
});
