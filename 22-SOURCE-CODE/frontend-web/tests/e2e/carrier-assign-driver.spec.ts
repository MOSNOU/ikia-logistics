import { test, expect } from "@playwright/test";
import { loginAs } from "./helpers/auth";

// Test B — carrier assign-driver UI. Passwords come from the environment only;
// the test skips (with guidance) when the local demo password is not set.
const EMAIL =
  process.env.E2E_DEMO_CARRIER_EMAIL ?? "demo-carrier-admin@local.test";
const PASSWORD = process.env.E2E_DEMO_CARRIER_PASSWORD;
const DISPATCH = "dede0000-0000-4000-8000-000000000301";

test.describe("carrier assign-driver UI", () => {
  test.skip(
    !PASSWORD,
    "Set E2E_DEMO_CARRIER_PASSWORD (local demo carrier-admin password) to run this test.",
  );

  test("carrier admin assigns the demo driver", async ({ page }) => {
    await loginAs(page, EMAIL, PASSWORD!);
    await page.goto(`/carrier/dispatches/${DISPATCH}`);

    // Assign-driver panel is present.
    await expect(page.getByText("راننده فعلی:")).toBeVisible();
    const assignButton = page.getByRole("button", { name: "اختصاص راننده" });
    await expect(assignButton).toBeVisible();

    // Demo driver is an option, then select + submit.
    const select = page.locator('select[name="driverUserId"]');
    await expect(
      select.locator("option", { hasText: "راننده دمو" }),
    ).toHaveCount(1);
    await select.selectOption({ label: "راننده دمو" });
    await assignButton.click();

    // Success feedback, and no error banner.
    await expect(page.getByText("راننده اختصاص یافت.")).toBeVisible({
      timeout: 15_000,
    });
    await expect(
      page.getByText("اختصاص راننده ناموفق بود."),
    ).toHaveCount(0);
  });
});
