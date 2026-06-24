import { SetCurrencyRateForm } from "./set-currency-rate-form";

export default function AdminNewCurrencyRatePage() {
  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">افزودن نرخ ارز</h1>
        <p className="text-sm text-muted-foreground">
          نرخ‌ها به‌صورت دستی وارد می‌شوند (Q5=A). هر ردیف یک نرخ یک‌طرفه است؛ تبدیل معکوس به‌صورت خودکار محاسبه می‌شود.
        </p>
      </div>
      <SetCurrencyRateForm />
    </div>
  );
}
