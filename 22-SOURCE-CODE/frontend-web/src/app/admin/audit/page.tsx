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
import { listAdminAuditEvents } from "@/lib/admin/list-audit";

interface PageProps {
  searchParams: Promise<{ page?: string; since?: string }>;
}

function actionBadge(code: string) {
  switch (code) {
    case "login":
      return <Badge variant="success">ورود</Badge>;
    case "logout":
      return <Badge variant="muted">خروج</Badge>;
    case "token_refresh":
      return <Badge variant="outline">به‌روزسازی توکن</Badge>;
    default:
      return <Badge variant="outline">{code}</Badge>;
  }
}

export default async function AdminAuditPage({ searchParams }: PageProps) {
  const { page: pageParam, since } = await searchParams;
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const { rows, pageSize } = await listAdminAuditEvents({ page, since: since ?? null });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">ممیزی</h1>
        <p className="text-sm text-muted-foreground">
          رویدادهای اخیر سامانه — ورود، خروج، به‌روزرسانی توکن و سایر اقدامات حسابرسی‌شده.
        </p>
      </div>

      {rows.length === 0 ? (
        <TableEmpty>هیچ رویدادی برای نمایش وجود ندارد.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>زمان</TableHead>
                <TableHead>اقدام</TableHead>
                <TableHead>کاربر</TableHead>
                <TableHead>تننت</TableHead>
                <TableHead>سازمان</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((e) => (
                <TableRow key={e.id}>
                  <TableCell className="text-xs">
                    {new Date(e.occurred_at).toLocaleString("fa-IR")}
                  </TableCell>
                  <TableCell>{actionBadge(e.action_code)}</TableCell>
                  <TableCell className="font-mono text-xs">
                    {e.actor_user_id ? e.actor_user_id.slice(0, 8) + "…" : "—"}
                  </TableCell>
                  <TableCell className="font-mono text-xs">
                    {e.tenant_id ? e.tenant_id.slice(0, 8) + "…" : "—"}
                  </TableCell>
                  <TableCell className="font-mono text-xs">
                    {e.organization_id ? e.organization_id.slice(0, 8) + "…" : "—"}
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
              <Link href={`/admin/audit?page=${page - 1}`}>قبلی</Link>
            </Button>
          ) : null}
          {rows.length === pageSize ? (
            <Button asChild variant="outline" size="sm">
              <Link href={`/admin/audit?page=${page + 1}`}>بعدی</Link>
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
