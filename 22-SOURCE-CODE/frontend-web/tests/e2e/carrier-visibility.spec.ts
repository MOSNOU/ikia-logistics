import { test, expect } from "@playwright/test";
import { loginAs } from "./helpers/auth";
import { fixturesReady, resetDemoTrip, DEMO_DISPATCH_ID } from "./helpers/fixture";

// Phase I (v1.2) — carrier dispatch detail compact driver-progress read-back
// (Phase H, Q5). Needs the demo carrier-admin password; a clean fixture makes
// the assertions deterministic.
const EMAIL =
  process.env.E2E_DEMO_CARRIER_EMAIL ?? "demo-carrier-admin@local.test";
const PASSWORD = process.env.E2E_DEMO_CARRIER_PASSWORD;
const READY = fixturesReady();

test.describe("carrier dispatch progress read-back", () => {
  test.skip(!PASSWORD, "Set E2E_DEMO_CARRIER_PASSWORD to run this test.");

  test.beforeAll(() => {
    if (READY) resetDemoTrip();
  });

  test("carrier detail shows the compact driver progress card", async ({
    page,
  }) => {
    await loginAs(page, EMAIL, PASSWORD!);
    await page.goto(`/carrier/dispatches/${DEMO_DISPATCH_ID}`);

    // Compact read-back card + its fields.
    await expect(page.getByText("پیشرفت راننده")).toBeVisible();
    await expect(page.getByText("آخرین موقعیت")).toBeVisible();
    await expect(page.getByText("سند تحویل")).toBeVisible();
    // No full timeline on the carrier surface.
    await expect(page.getByText("سابقه سفر")).toHaveCount(0);
  });
});
