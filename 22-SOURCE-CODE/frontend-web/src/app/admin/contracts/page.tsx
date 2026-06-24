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
import {
  listAdminPreparations,
  listAdminExecuted,
} from "@/lib/admin/list-contracts";

type Tab = "preparations" | "executed";

const TABS: { value: Tab; label: string }[] = [
  { value: "preparations", label: "آماده‌سازی‌ها" },
  { value: "executed", label: "قراردادهای اجرایی" },
];

interface PageProps {
  searchParams: Promise<{ tab?: string }>;
}

export default async function AdminContractsPage({ searchParams }: PageProps) {
  const { tab: tabParam } = await searchParams;
  const tab: Tab = (TABS.some((t) => t.value === tabParam) ? tabParam : "preparations") as Tab;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">صف قراردادها (مدیریت)</h1>
        <p className="text-sm text-muted-foreground">
          نمای پلتفرمی روی همه آماده‌سازی‌ها و قراردادهای اجرایی برای پایش و اقدام اضطراری.
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
            <Link href={`/admin/contracts?tab=${t.value}`}>{t.label}</Link>
          </Button>
        ))}
      </div>

      {tab === "preparations" ? <PreparationsTab /> : null}
      {tab === "executed" ? <ExecutedTab /> : null}
    </div>
  );
}

async function PreparationsTab() {
  const { rows } = await listAdminPreparations({});
  if (rows.length === 0) return <TableEmpty>آماده‌سازی یافت نشد.</TableEmpty>;
  return (
    <div className="rounded-md border">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>کد</TableHead>
            <TableHead>عنوان</TableHead>
            <TableHead>سازمان</TableHead>
            <TableHead>تأمین‌کننده</TableHead>
            <TableHead>وضعیت</TableHead>
            <TableHead>به‌روزرسانی</TableHead>
            <TableHead>عملیات</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {rows.map((p) => (
            <TableRow key={p.id}>
              <TableCell className="font-mono text-xs">{p.preparation_code}</TableCell>
              <TableCell>{p.title}</TableCell>
              <TableCell className="font-mono text-xs">{p.organization_id ?? "—"}</TableCell>
              <TableCell className="font-mono text-xs">{p.supplier_id}</TableCell>
              <TableCell><Badge variant="outline">{p.status}</Badge></TableCell>
              <TableCell className="text-xs">{p.updated_at}</TableCell>
              <TableCell>
                <Button asChild variant="outline" size="sm">
                  <Link href={`/admin/contracts/${p.id}`}>مشاهده</Link>
                </Button>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}

async function ExecutedTab() {
  const { rows } = await listAdminExecuted({});
  if (rows.length === 0) return <TableEmpty>قرارداد اجرایی یافت نشد.</TableEmpty>;
  return (
    <div className="rounded-md border">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>کد</TableHead>
            <TableHead>عنوان</TableHead>
            <TableHead>سازمان</TableHead>
            <TableHead>تأمین‌کننده</TableHead>
            <TableHead>وضعیت</TableHead>
            <TableHead>به‌روزرسانی</TableHead>
            <TableHead>عملیات</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {rows.map((c) => (
            <TableRow key={c.id}>
              <TableCell className="font-mono text-xs">{c.contract_code}</TableCell>
              <TableCell>{c.title}</TableCell>
              <TableCell className="font-mono text-xs">{c.organization_id ?? "—"}</TableCell>
              <TableCell className="font-mono text-xs">{c.supplier_id ?? "—"}</TableCell>
              <TableCell><Badge variant="outline">{c.status}</Badge></TableCell>
              <TableCell className="text-xs">{c.updated_at}</TableCell>
              <TableCell>
                <Button asChild variant="outline" size="sm">
                  <Link href={`/admin/contracts/${c.id}`}>مشاهده</Link>
                </Button>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
