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
  listBuyerPreparations,
  listBuyerExecuted,
} from "@/lib/contract/list-buyer-contracts";

type Tab = "preparations" | "executed";

const TABS: { value: Tab; label: string }[] = [
  { value: "preparations", label: "آماده‌سازی‌ها" },
  { value: "executed", label: "قراردادهای اجرایی" },
];

interface PageProps {
  searchParams: Promise<{ tab?: string }>;
}

export default async function BuyerContractsPage({ searchParams }: PageProps) {
  const { tab: tabParam } = await searchParams;
  const tab: Tab = (TABS.some((t) => t.value === tabParam) ? tabParam : "preparations") as Tab;

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">قراردادها</h1>
          <p className="text-sm text-muted-foreground">
            آماده‌سازی و اجرای قراردادها — از تصمیم انتخاب پیشنهاد تا امضا و اجرا.
          </p>
        </div>
        <Button asChild>
          <Link href="/buyer/contracts/new">ایجاد آماده‌سازی قرارداد</Link>
        </Button>
      </div>

      <div className="flex flex-wrap gap-2 border-b pb-3">
        {TABS.map((t) => (
          <Button
            key={t.value}
            asChild
            variant={tab === t.value ? "default" : "outline"}
            size="sm"
          >
            <Link href={`/buyer/contracts?tab=${t.value}`}>{t.label}</Link>
          </Button>
        ))}
      </div>

      {tab === "preparations" ? <PreparationsTab /> : null}
      {tab === "executed" ? <ExecutedTab /> : null}
    </div>
  );
}

async function PreparationsTab() {
  const { rows } = await listBuyerPreparations({});
  if (rows.length === 0) return <TableEmpty>آماده‌سازی ثبت نشده است.</TableEmpty>;
  return (
    <div className="rounded-md border">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>کد</TableHead>
            <TableHead>عنوان</TableHead>
            <TableHead>RFQ</TableHead>
            <TableHead>پیشنهاد</TableHead>
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
              <TableCell className="font-mono text-xs">{p.request_id}</TableCell>
              <TableCell className="font-mono text-xs">{p.offer_id}</TableCell>
              <TableCell className="font-mono text-xs">{p.supplier_id}</TableCell>
              <TableCell><Badge variant="outline">{p.status}</Badge></TableCell>
              <TableCell className="text-xs">{p.updated_at}</TableCell>
              <TableCell>
                <Button asChild variant="outline" size="sm">
                  <Link href={`/buyer/contracts/${p.id}`}>مشاهده</Link>
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
  const { rows } = await listBuyerExecuted({});
  if (rows.length === 0) return <TableEmpty>قرارداد اجرایی یافت نشد.</TableEmpty>;
  return (
    <div className="rounded-md border">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>کد</TableHead>
            <TableHead>عنوان</TableHead>
            <TableHead>RFQ</TableHead>
            <TableHead>پیشنهاد</TableHead>
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
              <TableCell className="font-mono text-xs">{c.request_id}</TableCell>
              <TableCell className="font-mono text-xs">{c.offer_id}</TableCell>
              <TableCell className="font-mono text-xs">{c.supplier_id ?? "—"}</TableCell>
              <TableCell><Badge variant="outline">{c.status}</Badge></TableCell>
              <TableCell className="text-xs">{c.updated_at}</TableCell>
              <TableCell>
                <Button asChild variant="outline" size="sm">
                  <Link href={`/buyer/contracts/${c.id}`}>مشاهده</Link>
                </Button>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
