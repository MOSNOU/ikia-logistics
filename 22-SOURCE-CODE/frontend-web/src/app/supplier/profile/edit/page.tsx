import { redirect } from "next/navigation";
import { getMySupplier } from "@/lib/supplier/get-my-supplier";
import { ProfileEditForm } from "./profile-edit-form";

export default async function SupplierProfileEditPage() {
  const { supplier } = await getMySupplier();
  if (!supplier) redirect("/supplier/profile");
  if (supplier.status !== "draft") redirect("/supplier/profile");

  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">ویرایش پروفایل تأمین‌کننده</h1>
        <p className="text-sm text-muted-foreground">
          فیلدها را تکمیل کنید و سپس از صفحه پروفایل، آن را برای بررسی ارسال کنید.
        </p>
      </div>
      <ProfileEditForm
        defaults={{
          displayName: supplier.display_name,
          description: supplier.description,
          website: supplier.website,
          contactEmail: supplier.contact_email,
          contactPhone: supplier.contact_phone,
          countryCode: supplier.country_code,
          establishedYear: supplier.established_year,
        }}
      />
    </div>
  );
}
