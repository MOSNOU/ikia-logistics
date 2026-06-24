import { CreatePreparationForm } from "./create-preparation-form";

interface PageProps {
  searchParams: Promise<{ decision_id?: string }>;
}

export default async function BuyerNewContractPage({ searchParams }: PageProps) {
  const { decision_id: decisionId } = await searchParams;

  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">ایجاد آماده‌سازی قرارداد</h1>
        <p className="text-sm text-muted-foreground">
          آماده‌سازی به یک تصمیم «انتخاب برای قرارداد» در ارزیابی متصل می‌شود. شناسه تصمیم (UUID) را وارد کنید.
        </p>
      </div>
      <CreatePreparationForm defaultDecisionId={decisionId ?? ""} />
    </div>
  );
}
