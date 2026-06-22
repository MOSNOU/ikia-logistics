import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableEmpty,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { listAdminSuppliers } from "@/lib/admin/list-suppliers";
import type { SupplierStatus, VerificationStatus } from "@/types/database";

const STATUS_OPTIONS: { value: SupplierStatus | ""; label: string }[] = [
  { value: "", label: "همه" },
  { value: "draft", label: "پیش‌نویس" },
  { value: "submitted", label: "ارسال‌شده" },
  { value: "under_review", label: "در حال بررسی" },
  { value: "approved", label: "تأییدشده" },
  { value: "suspended", label: "تعلیق" },
  { value: "rejected", label: "ردشده" },
];

const VERIFICATION_OPTIONS: { value: VerificationStatus | ""; label: string }[] = [
  { value: "", label: "همه" },
  { value: "unverified", label: "احرازنشده" },
  { value: "pending", label: "در حال احراز" },
  { value: "verified", label: "احرازشده" },
  { value: "expired", label: "منقضی" },
  { value: "rejected", label: "ردشده" },
];

function statusBadge(s: SupplierStatus) {
  switch (s) {
    case "approved":
      return <Badge variant="success">تأییدشده</Badge>;
    case "submitted":
    case "under_review":
      return <Badge variant="warning">{s === "submitted" ? "ارسال‌شده" : "در حال بررسی"}</Badge>;
    case "suspended":
    case "rejected":
      return <Badge variant="danger">{s === "suspended" ? "تعلیق" : "ردشده"}</Badge>;
    case "draft":
      return <Badge variant="muted">پیش‌نویس</Badge>;
    default:
      return <Badge variant="outline">{s}</Badge>;
  }
}

interface PageProps {
  searchParams: Promise<{ status?: string; verification?: string; page?: string }>;
}

export default async function AdminSuppliersPage({ searchParams }: PageProps) {
  const { status, verification, page: pageParam } = await searchParams;
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const statusFilter =
    status && STATUS_OPTIONS.some((o) => o.value === status) ? (status as SupplierStatus) : null;
  const verificationFilter =
    verification && VERIFICATION_OPTIONS.some((o) => o.value === verification)
      ? (verification as VerificationStatus)
      : null;

  const { rows, pageSize } = await listAdminSuppliers({
    page,
    status: statusFilter,
    verification: verificationFilter,
  });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">تأمین‌کنندگان</h1>
        <p className="text-sm text-muted-foreground">
          فهرست تأمین‌کنندگان ثبت‌شده — بررسی، تأیید، تعلیق و احراز هویت.
        </p>
      </div>

      <form className="flex flex-wrap items-end gap-3">
        <div className="space-y-1">
          <label htmlFor="status" className="text-sm font-medium">وضعیت</label>
          <select
            id="status"
            name="status"
            defaultValue={statusFilter ?? ""}
            className="h-9 rounded-md border border-input bg-background px-2 text-sm"
          >
            {STATUS_OPTIONS.map((o) => (
              <option key={o.value} value={o.value}>{o.label}</option>
            ))}
          </select>
        </div>
        <div className="space-y-1">
          <label htmlFor="verification" className="text-sm font-medium">احراز هویت</label>
          <select
            id="verification"
            name="verification"
            defaultValue={verificationFilter ?? ""}
            className="h-9 rounded-md border border-input bg-background px-2 text-sm"
          >
            {VERIFICATION_OPTIONS.map((o) => (
              <option key={o.value} value={o.value}>{o.label}</option>
            ))}
          </select>
        </div>
        <Button type="submit" variant="outline">اعمال فیلتر</Button>
      </form>

      {rows.length === 0 ? (
        <TableEmpty>هیچ تأمین‌کننده‌ای با این فیلتر یافت نشد.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>نام سازمان</TableHead>
                <TableHead>کد</TableHead>
                <TableHead>وضعیت</TableHead>
                <TableHead>احراز</TableHead>
                <TableHead>دسته‌بندی</TableHead>
                <TableHead>مدارک</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((s) => (
                <TableRow key={s.supplier_id}>
                  <TableCell>{s.organization_name_fa}</TableCell>
                  <TableCell className="font-mono text-xs">{s.organization_code}</TableCell>
                  <TableCell>{statusBadge(s.status)}</TableCell>
                  <TableCell><Badge variant="outline">{s.verification_status}</Badge></TableCell>
                  <TableCell>{s.category_count}</TableCell>
                  <TableCell>{s.document_count}</TableCell>
                  <TableCell>
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/admin/suppliers/${s.supplier_id}`}>مشاهده</Link>
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}

      <div className="flex items-center justify-between text-sm text-muted-foreground">
        <span>صفحه {page + 1} — {rows.length} ردیف</span>
        <div className="flex gap-2">
          {page > 0 ? (
            <Button asChild variant="outline" size="sm">
              <Link
                href={`/admin/suppliers?status=${statusFilter ?? ""}&verification=${verificationFilter ?? ""}&page=${page - 1}`}
              >قبلی</Link>
            </Button>
          ) : null}
          {rows.length === pageSize ? (
            <Button asChild variant="outline" size="sm">
              <Link
                href={`/admin/suppliers?status=${statusFilter ?? ""}&verification=${verificationFilter ?? ""}&page=${page + 1}`}
              >بعدی</Link>
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
