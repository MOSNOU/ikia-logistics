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
import { listAdminRfqs } from "@/lib/admin/list-rfqs";
import type { RfqStatus } from "@/types/database";

const STATUS_OPTIONS: { value: RfqStatus | ""; label: string }[] = [
  { value: "", label: "همه" },
  { value: "draft", label: "پیش‌نویس" },
  { value: "submitted", label: "ارسال‌شده" },
  { value: "published", label: "منتشرشده" },
  { value: "invited", label: "دعوت‌شده" },
  { value: "closed", label: "بسته‌شده" },
  { value: "cancelled", label: "لغوشده" },
  { value: "expired", label: "منقضی" },
];

interface PageProps {
  searchParams: Promise<{ status?: string; organizationId?: string; page?: string }>;
}

export default async function AdminRfqsPage({ searchParams }: PageProps) {
  const { status, organizationId, page: pageParam } = await searchParams;
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const statusFilter =
    status && STATUS_OPTIONS.some((o) => o.value === status)
      ? (status as RfqStatus)
      : null;
  const orgFilter = organizationId?.trim() || null;

  const { rows, pageSize } = await listAdminRfqs({
    status: statusFilter,
    organizationId: orgFilter,
    page,
  });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">صف RFQها (مدیریت)</h1>
        <p className="text-sm text-muted-foreground">
          نمای پلتفرمی روی همه RFQها برای پایش و اقدام اضطراری.
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
          <label htmlFor="organizationId" className="text-sm font-medium">شناسه سازمان</label>
          <input
            id="organizationId"
            name="organizationId"
            defaultValue={orgFilter ?? ""}
            dir="ltr"
            className="h-9 rounded-md border border-input bg-background px-2 text-sm font-mono"
            placeholder="UUID"
          />
        </div>
        <Button type="submit" variant="outline">اعمال فیلتر</Button>
      </form>

      {rows.length === 0 ? (
        <TableEmpty>RFQی یافت نشد.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>کد</TableHead>
                <TableHead>عنوان</TableHead>
                <TableHead>سازمان</TableHead>
                <TableHead>وضعیت</TableHead>
                <TableHead>مهلت ارسال</TableHead>
                <TableHead>تعداد دعوت</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((r) => (
                <TableRow key={r.id}>
                  <TableCell className="font-mono text-xs">{r.rfq_code}</TableCell>
                  <TableCell>{r.title}</TableCell>
                  <TableCell className="font-mono text-xs">{r.organization_id ?? "—"}</TableCell>
                  <TableCell><Badge variant="outline">{r.status}</Badge></TableCell>
                  <TableCell className="text-xs">{r.submission_deadline ?? "—"}</TableCell>
                  <TableCell>{r.invitation_count ?? 0}</TableCell>
                  <TableCell>
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/admin/rfqs/${r.id}`}>مشاهده</Link>
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
              <Link href={`/admin/rfqs?status=${statusFilter ?? ""}&organizationId=${orgFilter ?? ""}&page=${page - 1}`}>
                قبلی
              </Link>
            </Button>
          ) : null}
          {rows.length === pageSize ? (
            <Button asChild variant="outline" size="sm">
              <Link href={`/admin/rfqs?status=${statusFilter ?? ""}&organizationId=${orgFilter ?? ""}&page=${page + 1}`}>
                بعدی
              </Link>
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
