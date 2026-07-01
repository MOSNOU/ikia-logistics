import { test, expect } from "@playwright/test";
import { loginAs } from "./helpers/auth";
import {
  fixturesReady,
  resetDemoTrip,
  setDemoTripStatus,
  DEMO_DISPATCH_ID,
} from "./helpers/fixture";

// Phase I (v1.2) — driver trip-detail lifecycle hardening (Phase G surfaces).
// Requires the local DB fixture helper (psql) + the demo driver password.
const EMAIL = process.env.E2E_DEMO_DRIVER_EMAIL ?? "demo-driver@local.test";
const PASSWORD = process.env.E2E_DEMO_DRIVER_PASSWORD;
const READY = fixturesReady();

test.describe("driver trip-detail lifecycle", () => {
  test.skip(
    !PASSWORD,
    "Set E2E_DEMO_DRIVER_PASSWORD to run the driver lifecycle tests.",
  );
  test.skip(
    !READY,
    "Local DB fixtures unavailable (psql / local Supabase) — skipping.",
  );

  test.beforeEach(() => resetDemoTrip());
  test.afterAll(() => {
    if (READY) resetDemoTrip();
  });

  test("trip detail renders POD readiness, timeline empty state, one-tap action", async ({
    page,
  }) => {
    await loginAs(page, EMAIL, PASSWORD!);
    await page.goto(`/driver/trips/${DEMO_DISPATCH_ID}`);

    await expect(page.getByText("جزئیات سفر")).toBeVisible();
    // POD readiness panel (read-only).
    await expect(page.getByText("وضعیت سند تحویل")).toBeVisible();
    // Timeline empty state.
    await expect(page.getByText("سابقه سفر")).toBeVisible();
    await expect(
      page.getByText("هنوز رویدادی برای این سفر ثبت نشده است."),
    ).toBeVisible();
    // Assigned → normal forward step is one-tap (no confirmation prompt).
    await expect(
      page.getByRole("button", { name: "پذیرش سفر" }),
    ).toBeVisible();
    await expect(page.getByText("تحویل بار را تأیید می‌کنید؟")).toHaveCount(0);
  });

  test("irreversible step shows a confirmation prompt", async ({ page }) => {
    // Force the trip to the delivery-confirmation step (irreversible).
    setDemoTripStatus("unloading_started");

    await loginAs(page, EMAIL, PASSWORD!);
    await page.goto(`/driver/trips/${DEMO_DISPATCH_ID}`);

    const deliver = page.getByRole("button", { name: "تحویل انجام شد" });
    await expect(deliver).toBeVisible();
    await deliver.click();

    // Confirmation appears; cancelling does not transition.
    await expect(page.getByText("تحویل بار را تأیید می‌کنید؟")).toBeVisible();
    await expect(page.getByRole("button", { name: "انصراف" })).toBeVisible();
    await page.getByRole("button", { name: "انصراف" }).click();
    await expect(deliver).toBeVisible();
  });
});
