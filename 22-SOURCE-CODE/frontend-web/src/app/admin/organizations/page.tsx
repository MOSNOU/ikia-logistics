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
import { listAdminOrganizations } from "@/lib/admin/list-organizations";

interface PageProps {
  searchParams: Promise<{ page?: string }>;
}

const TYPE_LABELS: Record<string, string> = {
  buyer: "خریدار",
  supplier: "تأمین‌کننده",
  carrier: "حمل‌کننده",
  broker: "واسطه",
  government: "دولتی",
  platform: "پلتفرم",
};

function statusBadge(s: string) {
  switch (s) {
    case "active":
      return <Badge variant="success">فعال</Badge>;
    case "pending":
      return <Badge variant="warning">در حال بررسی</Badge>;
    case "suspended":
      return <Badge variant="danger">تعلیق</Badge>;
    case "closed":
      return <Badge variant="muted">بسته‌شده</Badge>;
    default:
      return <Badge variant="outline">{s}</Badge>;
  }
}

export default async function AdminOrganizationsPage({ searchParams }: PageProps) {
  const { page: pageParam } = await searchParams;
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const { rows, pageSize } = await listAdminOrganizations({ page });

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-semibold">سازمان‌ها</h1>
          <p className="text-sm text-muted-foreground">فهرست سازمان‌های ثبت‌شده.</p>
        </div>
        <Button asChild>
          <Link href="/admin/organizations/new">ایجاد سازمان جدید</Link>
        </Button>
      </div>

      {rows.length === 0 ? (
        <TableEmpty>هنوز سازمانی ثبت نشده است.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>کد</TableHead>
                <TableHead>نام</TableHead>
                <TableHead>نوع</TableHead>
                <TableHead>وضعیت</TableHead>
                <TableHead>تننت</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((o) => (
                <TableRow key={o.id}>
                  <TableCell className="font-mono text-xs">{o.code}</TableCell>
                  <TableCell>{o.nameFa}</TableCell>
                  <TableCell>
                    <Badge variant="outline">{TYPE_LABELS[o.type] ?? o.type}</Badge>
                  </TableCell>
                  <TableCell>{statusBadge(o.status)}</TableCell>
                  <TableCell className="font-mono text-xs">{o.tenantId.slice(0, 8)}…</TableCell>
                  <TableCell>
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/admin/organizations/${o.id}`}>مشاهده</Link>
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
              <Link href={`/admin/organizations?page=${page - 1}`}>قبلی</Link>
            </Button>
          ) : null}
          {rows.length === pageSize ? (
            <Button asChild variant="outline" size="sm">
              <Link href={`/admin/organizations?page=${page + 1}`}>بعدی</Link>
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
