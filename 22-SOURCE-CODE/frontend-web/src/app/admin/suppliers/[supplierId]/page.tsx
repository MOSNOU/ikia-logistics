import { notFound } from "next/navigation";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableEmpty,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { getAdminSupplier } from "@/lib/admin/get-supplier";
import { LifecycleActions } from "./lifecycle-actions";
import { VerificationForm } from "./verification-form";
import { DocumentStatusForm } from "./document-status-form";

interface PageProps {
  params: Promise<{ supplierId: string }>;
}

export default async function AdminSupplierDetailPage({ params }: PageProps) {
  const { supplierId } = await params;
  const { supplier, documents } = await getAdminSupplier(supplierId);
  if (!supplier) notFound();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">{supplier.organization_name_fa}</h1>
        <p className="text-sm text-muted-foreground">
          {supplier.organization_name_en} · {supplier.organization_code}
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>وضعیت چرخه</CardTitle>
          <CardDescription>Status: <Badge variant="outline">{supplier.status}</Badge>{" · "}
            Verification: <Badge variant="outline">{supplier.verification_status}</Badge>
          </CardDescription>
        </CardHeader>
        <CardContent>
          <LifecycleActions supplierId={supplier.supplier_id} status={supplier.status} />
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>احراز هویت</CardTitle>
          <CardDescription>Verification</CardDescription>
        </CardHeader>
        <CardContent>
          <VerificationForm
            supplierId={supplier.supplier_id}
            currentStatus={supplier.verification_status}
          />
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>اطلاعات تأمین‌کننده</CardTitle>
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
          <CardTitle>مدارک</CardTitle>
          <CardDescription>{documents.length} document(s)</CardDescription>
        </CardHeader>
        <CardContent>
          {documents.length === 0 ? (
            <TableEmpty>مدرکی ثبت نشده است.</TableEmpty>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>عنوان</TableHead>
                  <TableHead>نوع</TableHead>
                  <TableHead>وضعیت</TableHead>
                  <TableHead>صادر/انقضا</TableHead>
                  <TableHead>عملیات</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {documents.map((d) => (
                  <TableRow key={d.id}>
                    <TableCell className="text-sm">{d.title}</TableCell>
                    <TableCell><Badge variant="outline">{d.document_type}</Badge></TableCell>
                    <TableCell><Badge variant="outline">{d.status}</Badge></TableCell>
                    <TableCell className="text-xs text-muted-foreground">
                      {d.issued_at ?? "—"} / {d.expires_at ?? "—"}
                    </TableCell>
                    <TableCell>
                      <DocumentStatusForm
                        documentId={d.id}
                        supplierId={supplier.supplier_id}
                        currentStatus={d.status}
                      />
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
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
