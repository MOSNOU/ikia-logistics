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
import { listAdminUsers } from "@/lib/admin/list-users";
import type { AdminUserStatus } from "@/types/database";

const STATUS_OPTIONS: { value: AdminUserStatus | ""; label: string }[] = [
  { value: "", label: "همه" },
  { value: "pending_profile", label: "در انتظار تأیید" },
  { value: "active", label: "فعال" },
  { value: "pending", label: "در حال بررسی" },
  { value: "suspended", label: "تعلیق" },
  { value: "deactivated", label: "غیرفعال" },
];

function statusBadge(status: string) {
  switch (status) {
    case "active":
      return <Badge variant="success">فعال</Badge>;
    case "pending_profile":
      return <Badge variant="warning">در انتظار تأیید</Badge>;
    case "pending":
      return <Badge variant="warning">در حال بررسی</Badge>;
    case "suspended":
      return <Badge variant="danger">تعلیق</Badge>;
    case "deactivated":
      return <Badge variant="muted">غیرفعال</Badge>;
    default:
      return <Badge variant="outline">{status}</Badge>;
  }
}

interface PageProps {
  searchParams: Promise<{ status?: string; page?: string }>;
}

export default async function AdminUsersPage({ searchParams }: PageProps) {
  const { status, page: pageParam } = await searchParams;
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const statusFilter = status === undefined || status === "" ? null : status;

  const { rows, pageSize } = await listAdminUsers({ page, status: statusFilter });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">کاربران</h1>
        <p className="text-sm text-muted-foreground">
          مدیریت کاربران پلتفرم — تأیید، تغییر وضعیت و اختصاص نقش.
        </p>
      </div>

      <form className="flex items-end gap-3">
        <div className="space-y-1">
          <label htmlFor="status" className="text-sm font-medium">
            وضعیت
          </label>
          <select
            id="status"
            name="status"
            defaultValue={statusFilter ?? ""}
            className="h-9 rounded-md border border-input bg-background px-2 text-sm"
          >
            {STATUS_OPTIONS.map((o) => (
              <option key={o.value} value={o.value}>
                {o.label}
              </option>
            ))}
          </select>
        </div>
        <Button type="submit" variant="outline">
          اعمال فیلتر
        </Button>
      </form>

      {rows.length === 0 ? (
        <TableEmpty>هیچ کاربری با این فیلتر یافت نشد.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>ایمیل</TableHead>
                <TableHead>نام</TableHead>
                <TableHead>وضعیت</TableHead>
                <TableHead>سازمان فعال</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((u) => (
                <TableRow key={u.user_id}>
                  <TableCell className="font-mono text-xs">{u.email}</TableCell>
                  <TableCell>{u.full_name ?? "—"}</TableCell>
                  <TableCell>{statusBadge(u.status)}</TableCell>
                  <TableCell className="font-mono text-xs">
                    {u.primary_organization_id ?? "—"}
                  </TableCell>
                  <TableCell>
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/admin/users/${u.user_id}`}>مشاهده</Link>
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}

      <div className="flex items-center justify-between text-sm text-muted-foreground">
        <span>
          صفحه {page + 1} — {rows.length} ردیف
        </span>
        <div className="flex gap-2">
          {page > 0 ? (
            <Button asChild variant="outline" size="sm">
              <Link href={`/admin/users?status=${statusFilter ?? ""}&page=${page - 1}`}>
                قبلی
              </Link>
            </Button>
          ) : null}
          {rows.length === pageSize ? (
            <Button asChild variant="outline" size="sm">
              <Link href={`/admin/users?status=${statusFilter ?? ""}&page=${page + 1}`}>
                بعدی
              </Link>
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
