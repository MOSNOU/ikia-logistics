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
import { listAdminNotifications } from "@/lib/admin/list-admin-notifications";
import { listNotificationTemplates } from "@/lib/admin/list-notification-templates";
import { listDeliveryAttempts } from "@/lib/admin/list-delivery-attempts";

type Tab = "all" | "templates" | "deliveries";

const TABS: { value: Tab; label: string }[] = [
  { value: "all", label: "همه پیام‌ها" },
  { value: "templates", label: "قالب‌ها" },
  { value: "deliveries", label: "تلاش‌های تحویل" },
];

interface PageProps {
  searchParams: Promise<{ tab?: string }>;
}

export default async function AdminNotificationsPage({ searchParams }: PageProps) {
  const { tab: tabParam } = await searchParams;
  const tab: Tab = (TABS.some((t) => t.value === tabParam) ? tabParam : "all") as Tab;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">پیام‌ها و قالب‌ها</h1>
        <p className="text-sm text-muted-foreground">
          نظارت پلتفرمی بر پیام‌ها، قالب‌های اعلان و تلاش‌های تحویل.
        </p>
      </div>

      <div className="flex flex-wrap gap-2 border-b pb-3">
        {TABS.map((t) => (
          <Button
            key={t.value}
            asChild
            variant={tab === t.value ? "default" : "outline"}
            size="sm"
          >
            <Link href={`/admin/notifications?tab=${t.value}`}>{t.label}</Link>
          </Button>
        ))}
      </div>

      {tab === "all" ? <AllNotificationsTab /> : null}
      {tab === "templates" ? <TemplatesTab /> : null}
      {tab === "deliveries" ? <DeliveriesTab /> : null}
    </div>
  );
}

async function AllNotificationsTab() {
  const { rows } = await listAdminNotifications({});
  if (rows.length === 0) return <TableEmpty>پیامی برای نمایش وجود ندارد.</TableEmpty>;
  return (
    <div className="rounded-md border">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>گیرنده</TableHead>
            <TableHead>سازمان</TableHead>
            <TableHead>دسته</TableHead>
            <TableHead>وضعیت</TableHead>
            <TableHead>عنوان</TableHead>
            <TableHead>منبع رویداد</TableHead>
            <TableHead>زمان</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {rows.map((n) => (
            <TableRow key={n.id}>
              <TableCell className="font-mono text-xs">{n.recipient_user_id}</TableCell>
              <TableCell className="font-mono text-xs">{n.organization_id ?? "—"}</TableCell>
              <TableCell><Badge variant="outline">{n.category}</Badge></TableCell>
              <TableCell><Badge variant="outline">{n.status}</Badge></TableCell>
              <TableCell>{n.title_en}</TableCell>
              <TableCell className="text-xs font-mono">{n.source_event_type ?? "—"}</TableCell>
              <TableCell className="text-xs">{n.created_at}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}

async function TemplatesTab() {
  const rows = await listNotificationTemplates({});
  if (rows.length === 0) return <TableEmpty>قالبی ثبت نشده است.</TableEmpty>;
  return (
    <div className="rounded-md border">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>کد</TableHead>
            <TableHead>سازمان</TableHead>
            <TableHead>دسته</TableHead>
            <TableHead>اولویت پیش‌فرض</TableHead>
            <TableHead>وضعیت</TableHead>
            <TableHead>عنوان (EN)</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {rows.map((t) => (
            <TableRow key={t.id}>
              <TableCell className="font-mono text-xs">{t.template_code}</TableCell>
              <TableCell className="font-mono text-xs">{t.organization_id ?? "—"}</TableCell>
              <TableCell><Badge variant="outline">{t.category}</Badge></TableCell>
              <TableCell><Badge variant="outline">{t.default_priority}</Badge></TableCell>
              <TableCell><Badge variant="outline">{t.status}</Badge></TableCell>
              <TableCell>{t.title_en}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}

async function DeliveriesTab() {
  const { rows } = await listDeliveryAttempts({});
  if (rows.length === 0) return <TableEmpty>تلاش تحویلی ثبت نشده است.</TableEmpty>;
  return (
    <div className="rounded-md border">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>شناسه پیام</TableHead>
            <TableHead>کانال</TableHead>
            <TableHead>وضعیت</TableHead>
            <TableHead>تلاش در</TableHead>
            <TableHead>تحویل در</TableHead>
            <TableHead>دلیل خطا</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {rows.map((d) => (
            <TableRow key={d.id}>
              <TableCell className="font-mono text-xs">{d.notification_id}</TableCell>
              <TableCell><Badge variant="outline">{d.channel}</Badge></TableCell>
              <TableCell><Badge variant="outline">{d.status}</Badge></TableCell>
              <TableCell className="text-xs">{d.attempted_at ?? "—"}</TableCell>
              <TableCell className="text-xs">{d.delivered_at ?? "—"}</TableCell>
              <TableCell className="text-xs">{d.failure_reason ?? "—"}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
