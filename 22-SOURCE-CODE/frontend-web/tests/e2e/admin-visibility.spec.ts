import { test, expect } from "@playwright/test";
import { loginAs } from "./helpers/auth";
import {
  fixturesReady,
  grantDemoAdmin,
  resetDemoTrip,
  DEMO_DISPATCH_ID,
} from "./helpers/fixture";

// Phase I (v1.2) — admin driver-trips progress visibility (Phase H). The demo
// carrier-admin is granted platform_admin locally (fixture) so the admin
// surfaces are reachable. Reuses the carrier-admin password.
const EMAIL =
  process.env.E2E_DEMO_CARRIER_EMAIL ?? "demo-carrier-admin@local.test";
const PASSWORD = process.env.E2E_DEMO_CARRIER_PASSWORD;
const READY = fixturesReady();

test.describe("admin driver-trips progress visibility", () => {
  test.skip(!PASSWORD, "Set E2E_DEMO_CARRIER_PASSWORD to run this test.");
  test.skip(
    !READY,
    "Local DB fixtures unavailable (psql / local Supabase) — skipping.",
  );

  test.beforeAll(() => {
    grantDemoAdmin();
    resetDemoTrip();
  });

  test("list shows progress columns and filters", async ({ page }) => {
    await loginAs(page, EMAIL, PASSWORD!);
    await page.goto("/admin/driver-trips");

    await expect(page.getByText("سفرهای رانندگان — ادمین")).toBeVisible();
    // Phase H progress columns.
    await expect(
      page.getByRole("columnheader", { name: "خودرو" }),
    ).toBeVisible();
    await expect(
      page.getByRole("columnheader", { name: "سند تحویل" }),
    ).toBeVisible();
    await expect(
      page.getByRole("columnheader", { name: "پایش" }),
    ).toBeVisible();
    // Filters.
    await expect(page.locator('select[name="status"]')).toBeVisible();
    await expect(page.locator('input[name="stalled"]')).toBeVisible();
  });

  test("filters apply without crashing", async ({ page }) => {
    await loginAs(page, EMAIL, PASSWORD!);
    await page.goto("/admin/driver-trips?status=in_transit&stalled=1");
    // Page renders (heading present); no crash regardless of matches.
    await expect(page.getByText("سفرهای رانندگان — ادمین")).toBeVisible();
  });

  test("detail shows the progress read-back block", async ({ page }) => {
    await loginAs(page, EMAIL, PASSWORD!);
    await page.goto(`/admin/driver-trips/${DEMO_DISPATCH_ID}`);
    await expect(page.getByText("جزئیات سفر راننده — ادمین")).toBeVisible();
    // Progress block fields (Phase H).
    await expect(page.getByText("پایش")).toBeVisible();
    await expect(page.getByText("آخرین موقعیت").first()).toBeVisible();
  });
});
