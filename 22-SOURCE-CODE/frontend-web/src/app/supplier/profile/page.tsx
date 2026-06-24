import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { getMySupplier } from "@/lib/supplier/get-my-supplier";
import { SubmitForReviewForm } from "./submit-for-review-form";

const STATUS_LABELS_FA: Record<string, string> = {
  draft: "پیش‌نویس",
  submitted: "ارسال‌شده",
  under_review: "در حال بررسی",
  approved: "تأییدشده",
  suspended: "تعلیق",
  rejected: "ردشده",
};

export default async function SupplierProfilePage() {
  const { supplier, categoryLinks, documents } = await getMySupplier();

  if (!supplier) {
    return (
      <div className="mx-auto max-w-2xl space-y-4">
        <h1 className="text-2xl font-semibold">پروفایل تأمین‌کننده</h1>
        <Card>
          <CardContent className="p-6 text-sm text-muted-foreground">
            سازمان فعال شما هنوز به‌عنوان تأمین‌کننده ثبت نشده. لطفاً با مدیر تماس بگیرید.
          </CardContent>
        </Card>
      </div>
    );
  }

  const canEdit = supplier.status === "draft";
  const canSubmit = supplier.status === "draft";

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">پروفایل تأمین‌کننده</h1>
          <p className="text-sm text-muted-foreground">
            وضعیت: <Badge variant="outline">{STATUS_LABELS_FA[supplier.status] ?? supplier.status}</Badge>
            <span className="ms-3">احراز: <Badge variant="outline">{supplier.verification_status}</Badge></span>
          </p>
        </div>
        {canEdit ? (
          <Button asChild variant="outline">
            <Link href="/supplier/profile/edit">ویرایش</Link>
          </Button>
        ) : null}
      </div>

      <Card>
        <CardHeader>
          <CardTitle>اطلاعات پایه</CardTitle>
          <CardDescription>Profile fields</CardDescription>
        </CardHeader>
        <CardContent className="grid grid-cols-2 gap-4 text-sm">
          <Field label="نام نمایش">{supplier.display_name ?? "—"}</Field>
          <Field label="کد کشور">{supplier.country_code ?? "—"}</Field>
          <Field label="ایمیل تماس">{supplier.contact_email ?? "—"}</Field>
          <Field label="تلفن">{supplier.contact_phone ?? "—"}</Field>
          <Field label="وب‌سایت">{supplier.website ?? "—"}</Field>
          <Field label="سال تأسیس">{supplier.established_year ?? "—"}</Field>
          <Field label="توضیحات" full>{supplier.description ?? "—"}</Field>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>دسته‌بندی‌ها</CardTitle>
          <CardDescription>{categoryLinks.length} دسته فعال</CardDescription>
        </CardHeader>
        <CardContent>
          <Button asChild variant="outline" size="sm">
            <Link href="/supplier/categories">مدیریت دسته‌بندی‌ها</Link>
          </Button>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>مدارک</CardTitle>
          <CardDescription>{documents.length} مدرک ثبت‌شده</CardDescription>
        </CardHeader>
        <CardContent>
          <Button asChild variant="outline" size="sm">
            <Link href="/supplier/documents">مدیریت مدارک</Link>
          </Button>
        </CardContent>
      </Card>

      {canSubmit ? (
        <Card>
          <CardHeader>
            <CardTitle>ارسال برای بررسی</CardTitle>
            <CardDescription>
              پس از ارسال، پروفایل قفل می‌شود و فقط مدیر پلتفرم می‌تواند آن را تغییر دهد.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <SubmitForReviewForm />
          </CardContent>
        </Card>
      ) : null}

      {supplier.status === "rejected" && supplier.rejected_reason ? (
        <Card>
          <CardHeader>
            <CardTitle>دلیل رد</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm">{supplier.rejected_reason}</p>
          </CardContent>
        </Card>
      ) : null}

      {supplier.status === "suspended" && supplier.suspended_reason ? (
        <Card>
          <CardHeader>
            <CardTitle>دلیل تعلیق</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm">{supplier.suspended_reason}</p>
          </CardContent>
        </Card>
      ) : null}
    </div>
  );
}

function Field({ label, children, full }: { label: string; children: React.ReactNode; full?: boolean }) {
  return (
    <div className={full ? "col-span-2 space-y-1" : "space-y-1"}>
      <p className="text-xs text-muted-foreground">{label}</p>
      <div>{children}</div>
    </div>
  );
}
