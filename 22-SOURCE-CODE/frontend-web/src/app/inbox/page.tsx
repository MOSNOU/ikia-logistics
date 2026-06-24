import Link from "next/link";
import { redirect } from "next/navigation";
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
import { getProfile } from "@/lib/auth/get-profile";
import { listMyNotifications } from "@/lib/notify/list-my-notifications";
import { getUnreadCount } from "@/lib/notify/unread-count";
import type {
  NotificationCategory,
  NotificationPriority,
  NotificationStatus,
} from "@/types/database";
import { MarkAllReadForm } from "./mark-all-read-form";
import { RowActions } from "./row-actions";

const isAuthEnabled =
  !!process.env.NEXT_PUBLIC_SUPABASE_URL && !!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

const STATUS_OPTIONS: { value: NotificationStatus | ""; label: string }[] = [
  { value: "", label: "همه" },
  { value: "unread", label: "خوانده‌نشده" },
  { value: "read", label: "خوانده‌شده" },
  { value: "archived", label: "بایگانی" },
];

const CATEGORY_OPTIONS: { value: NotificationCategory | ""; label: string }[] = [
  { value: "", label: "همه دسته‌ها" },
  { value: "rfq", label: "RFQ" },
  { value: "offer", label: "پیشنهاد" },
  { value: "evaluation", label: "ارزیابی" },
  { value: "contract", label: "قرارداد" },
  { value: "shipment", label: "محموله" },
  { value: "finance", label: "مالی" },
  { value: "settlement", label: "تسویه" },
  { value: "dispute", label: "اختلاف" },
  { value: "supplier_admin", label: "مدیریت تأمین‌کننده" },
  { value: "platform", label: "پلتفرم" },
  { value: "other", label: "سایر" },
];

function priorityBadge(p: NotificationPriority) {
  switch (p) {
    case "urgent":
      return <Badge variant="danger">فوری</Badge>;
    case "high":
      return <Badge variant="warning">بالا</Badge>;
    case "normal":
      return <Badge variant="outline">عادی</Badge>;
    case "low":
      return <Badge variant="muted">پایین</Badge>;
    default:
      return <Badge variant="outline">{p}</Badge>;
  }
}

function statusBadge(s: NotificationStatus) {
  switch (s) {
    case "unread":
      return <Badge variant="warning">خوانده‌نشده</Badge>;
    case "read":
      return <Badge variant="outline">خوانده‌شده</Badge>;
    case "archived":
      return <Badge variant="muted">بایگانی</Badge>;
    case "dismissed":
      return <Badge variant="muted">رد‌شده</Badge>;
    default:
      return <Badge variant="outline">{s}</Badge>;
  }
}

interface PageProps {
  searchParams: Promise<{ status?: string; category?: string; page?: string }>;
}

export default async function InboxPage({ searchParams }: PageProps) {
  if (!isAuthEnabled) redirect("/");
  const profile = await getProfile();
  if (!profile) redirect("/login");

  const { status, category, page: pageParam } = await searchParams;
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const statusFilter =
    status && STATUS_OPTIONS.some((o) => o.value === status)
      ? (status as NotificationStatus)
      : null;
  const categoryFilter =
    category && CATEGORY_OPTIONS.some((o) => o.value === category)
      ? (category as NotificationCategory)
      : null;

  const [{ rows, pageSize }, unread] = await Promise.all([
    listMyNotifications({ status: statusFilter, category: categoryFilter, page }),
    getUnreadCount(),
  ]);

  return (
    <div className="mx-auto max-w-5xl space-y-6 px-4 py-10">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">صندوق پیام‌ها</h1>
          <p className="text-sm text-muted-foreground">
            {unread} پیام خوانده‌نشده.
          </p>
        </div>
        <div className="flex flex-col items-end gap-2">
          <MarkAllReadForm category={categoryFilter} />
          <Link href="/inbox/preferences" className="text-xs text-muted-foreground underline">
            تنظیمات اعلان
          </Link>
        </div>
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
          <label htmlFor="category" className="text-sm font-medium">دسته</label>
          <select
            id="category"
            name="category"
            defaultValue={categoryFilter ?? ""}
            className="h-9 rounded-md border border-input bg-background px-2 text-sm"
          >
            {CATEGORY_OPTIONS.map((o) => (
              <option key={o.value} value={o.value}>{o.label}</option>
            ))}
          </select>
        </div>
        <Button type="submit" variant="outline">اعمال فیلتر</Button>
      </form>

      {rows.length === 0 ? (
        <TableEmpty>پیامی برای نمایش وجود ندارد.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>اولویت</TableHead>
                <TableHead>عنوان</TableHead>
                <TableHead>دسته</TableHead>
                <TableHead>وضعیت</TableHead>
                <TableHead>زمان</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((n) => (
                <TableRow key={n.id}>
                  <TableCell>{priorityBadge(n.priority)}</TableCell>
                  <TableCell>
                    <Link href={`/inbox/${n.id}`} className="underline">
                      {n.title_fa || n.title_en}
                    </Link>
                  </TableCell>
                  <TableCell><Badge variant="outline">{n.category}</Badge></TableCell>
                  <TableCell>{statusBadge(n.status)}</TableCell>
                  <TableCell className="text-xs">{n.created_at}</TableCell>
                  <TableCell>
                    <RowActions
                      notificationId={n.id}
                      status={n.status}
                    />
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
                href={`/inbox?status=${statusFilter ?? ""}&category=${categoryFilter ?? ""}&page=${page - 1}`}
              >قبلی</Link>
            </Button>
          ) : null}
          {rows.length === pageSize ? (
            <Button asChild variant="outline" size="sm">
              <Link
                href={`/inbox?status=${statusFilter ?? ""}&category=${categoryFilter ?? ""}&page=${page + 1}`}
              >بعدی</Link>
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
