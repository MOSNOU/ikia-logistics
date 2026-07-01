import { test, expect } from "@playwright/test";
import { loginAs } from "./helpers/auth";

// Test C — driver sees the assigned trip. Password from the environment only.
const EMAIL = process.env.E2E_DEMO_DRIVER_EMAIL ?? "demo-driver@local.test";
const PASSWORD = process.env.E2E_DEMO_DRIVER_PASSWORD;
const DISPATCH = "dede0000-0000-4000-8000-000000000301";

test.describe("driver sees assigned trip", () => {
  test.skip(
    !PASSWORD,
    "Set E2E_DEMO_DRIVER_PASSWORD (local demo driver password) to run this test.",
  );

  test("driver dashboard shows the trip and detail loads", async ({ page }) => {
    await loginAs(page, EMAIL, PASSWORD!);

    await page.goto("/driver");
    await expect(page.getByText("داشبورد راننده")).toBeVisible();
    // Not the empty state, and at least one trip link is present.
    await expect(
      page.getByText("در حال حاضر سفری به شما اختصاص داده نشده است."),
    ).toHaveCount(0);
    await expect(
      page.locator('a[href*="/driver/trips/"]').first(),
    ).toBeVisible();

    await page.goto(`/driver/trips/${DISPATCH}`);
    await expect(page.getByText("جزئیات سفر")).toBeVisible();
    // The next-action section is rendered on the trip detail.
    await expect(page.getByText("اقدام بعدی سفر")).toBeVisible();
  });
});
