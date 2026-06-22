import { listTenants } from "@/lib/admin/list-tenants";
import { CreateOrganizationForm } from "./create-organization-form";

export default async function AdminCreateOrganizationPage() {
  const tenants = await listTenants();

  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">ایجاد سازمان</h1>
        <p className="text-sm text-muted-foreground">
          یک سازمان جدید در یکی از تننت‌های موجود ثبت کنید.
        </p>
      </div>
      <CreateOrganizationForm tenants={tenants} />
    </div>
  );
}
