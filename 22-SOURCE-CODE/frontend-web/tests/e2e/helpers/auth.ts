import { expect, type Page } from "@playwright/test";

// Logs in via the app's real /login form (server action + Supabase). A
// successful sign-in redirects away from /login; we then assert no error banner.
export async function loginAs(page: Page, email: string, password: string) {
  await page.goto("/login");
  await page.locator('input[name="email"]').fill(email);
  await page.locator('input[name="password"]').fill(password);
  await page.getByRole("button", { name: "ورود" }).click();

  await page.waitForURL((url) => !url.pathname.startsWith("/login"), {
    timeout: 20_000,
  });
  await expect(page.getByText("اطلاعات ورود نادرست است")).toHaveCount(0);
}
