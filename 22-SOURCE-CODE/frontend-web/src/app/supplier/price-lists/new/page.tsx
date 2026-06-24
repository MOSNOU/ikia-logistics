import { redirect } from "next/navigation";
import { getMySupplier } from "@/lib/supplier/get-my-supplier";
import { CreatePriceListForm } from "./create-price-list-form";

export default async function SupplierNewPriceListPage() {
  const { supplier } = await getMySupplier();
  if (!supplier) redirect("/supplier/price-lists");

  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">ایجاد فهرست قیمت</h1>
        <p className="text-sm text-muted-foreground">
          فهرست در حالت پیش‌نویس ایجاد می‌شود. پس از افزودن ردیف‌ها می‌توانید آن را منتشر کنید.
        </p>
      </div>
      <CreatePriceListForm supplierId={supplier.id} />
    </div>
  );
}
