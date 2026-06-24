import { redirect } from "next/navigation";
import { getMySupplier } from "@/lib/supplier/get-my-supplier";
import { CreateQuotationForm } from "./create-quotation-form";

export default async function SupplierNewQuotationPage() {
  const { supplier } = await getMySupplier();
  if (!supplier) redirect("/supplier/quotations");

  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">ایجاد پیشنهاد قیمت</h1>
        <p className="text-sm text-muted-foreground">
          پیشنهاد در حالت پیش‌نویس ایجاد می‌شود. پس از افزودن ردیف‌ها می‌توانید آن را برای خریدار ارسال کنید.
        </p>
      </div>
      <CreateQuotationForm supplierId={supplier.id} />
    </div>
  );
}
