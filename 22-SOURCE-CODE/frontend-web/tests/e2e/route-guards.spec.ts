import { test, expect } from "@playwright/test";

// Test A — route-guard smoke. No credentials needed; unauthenticated access to
// the operational routes must redirect to /login.
const GUARDED = [
  "/carrier/dispatches/dede0000-0000-4000-8000-000000000301",
  "/driver",
  "/admin/driver-trips",
];

test.describe("route guards (unauthenticated)", () => {
  for (const path of GUARDED) {
    test(`${path} redirects to /login`, async ({ page }) => {
      await page.goto(path);
      await expect(page).toHaveURL(/\/login/);
    });
  }
});
