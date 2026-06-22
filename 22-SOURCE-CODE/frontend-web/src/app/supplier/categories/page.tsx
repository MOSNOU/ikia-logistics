import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { getMySupplier } from "@/lib/supplier/get-my-supplier";
import { listSupplierCategories } from "@/lib/supplier/list-categories";
import { CategoriesManager } from "./categories-manager";

export default async function SupplierCategoriesPage() {
  const [{ supplier, categoryLinks }, allCategories] = await Promise.all([
    getMySupplier(),
    listSupplierCategories(),
  ]);

  if (!supplier) {
    return (
      <div className="mx-auto max-w-2xl">
        <Card>
          <CardContent className="p-6 text-sm text-muted-foreground">
            سازمان فعال شما هنوز به‌عنوان تأمین‌کننده ثبت نشده.
          </CardContent>
        </Card>
      </div>
    );
  }

  const selected = new Set(categoryLinks.map((c) => c.category_id));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">دسته‌بندی‌ها</h1>
        <p className="text-sm text-muted-foreground">حوزه‌های فعالیت تأمین‌کننده.</p>
      </div>
      <Card>
        <CardHeader>
          <CardTitle>مدیریت دسته‌بندی</CardTitle>
          <CardDescription>
            افزودن/حذف نرم — دسته‌بندی‌های حذف‌شده در پایگاه داده باقی می‌مانند و قابل احیاء هستند.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <CategoriesManager
            categories={allCategories.map((c) => ({
              id: c.id,
              code: c.code,
              nameFa: c.name_fa,
              nameEn: c.name_en,
              selected: selected.has(c.id),
            }))}
          />
        </CardContent>
      </Card>
    </div>
  );
}
