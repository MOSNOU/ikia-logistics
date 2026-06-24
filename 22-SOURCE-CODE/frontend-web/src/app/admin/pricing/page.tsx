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
import { listAdminPriceLists } from "@/lib/admin/list-price-lists";
import { listAdminQuotations } from "@/lib/admin/list-quotations";
import { listCurrencyRates } from "@/lib/admin/list-currency-rates";
import { listQuoteCaptures } from "@/lib/admin/list-quote-captures";

type Tab = "price-lists" | "quotations" | "currency-rates" | "captures";

const TABS: { value: Tab; label: string }[] = [
  { value: "price-lists", label: "فهرست‌های قیمت" },
  { value: "quotations", label: "پیشنهادها" },
  { value: "currency-rates", label: "نرخ‌های ارز" },
  { value: "captures", label: "اسنپ‌شات‌ها" },
];

interface PageProps {
  searchParams: Promise<{ tab?: string }>;
}

export default async function AdminPricingPage({ searchParams }: PageProps) {
  const { tab: tabParam } = await searchParams;
  const tab: Tab = (TABS.some((t) => t.value === tabParam) ? tabParam : "price-lists") as Tab;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">قیمت‌گذاری و پیشنهادها</h1>
        <p className="text-sm text-muted-foreground">
          مدیریت فهرست‌های قیمت، پیشنهادها، نرخ‌های ارز و اسنپ‌شات‌های قیمت.
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
            <Link href={`/admin/pricing?tab=${t.value}`}>{t.label}</Link>
          </Button>
        ))}
      </div>

      {tab === "price-lists" ? <PriceListsTab /> : null}
      {tab === "quotations" ? <QuotationsTab /> : null}
      {tab === "currency-rates" ? <CurrencyRatesTab /> : null}
      {tab === "captures" ? <CapturesTab /> : null}
    </div>
  );
}

async function PriceListsTab() {
  const { rows } = await listAdminPriceLists({});
  if (rows.length === 0) return <TableEmpty>هیچ فهرست قیمتی یافت نشد.</TableEmpty>;
  return (
    <div className="rounded-md border">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>کد</TableHead>
            <TableHead>تأمین‌کننده</TableHead>
            <TableHead>ارز</TableHead>
            <TableHead>وضعیت</TableHead>
            <TableHead>ایجاد</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {rows.map((pl) => (
            <TableRow key={pl.id}>
              <TableCell className="font-mono text-xs">{pl.code}</TableCell>
              <TableCell className="font-mono text-xs">{pl.supplier_id}</TableCell>
              <TableCell><Badge variant="outline">{pl.currency_code}</Badge></TableCell>
              <TableCell><Badge variant="outline">{pl.status}</Badge></TableCell>
              <TableCell className="text-xs">{pl.created_at ?? "—"}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}

async function QuotationsTab() {
  const { rows } = await listAdminQuotations({});
  if (rows.length === 0) return <TableEmpty>هیچ پیشنهادی یافت نشد.</TableEmpty>;
  return (
    <div className="rounded-md border">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>کد</TableHead>
            <TableHead>تأمین‌کننده</TableHead>
            <TableHead>خریدار</TableHead>
            <TableHead>ارز</TableHead>
            <TableHead>مبلغ کل</TableHead>
            <TableHead>وضعیت</TableHead>
            <TableHead>اعتبار تا</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {rows.map((q) => (
            <TableRow key={q.id}>
              <TableCell className="font-mono text-xs">{q.quotation_code}</TableCell>
              <TableCell className="font-mono text-xs">{q.supplier_id}</TableCell>
              <TableCell className="font-mono text-xs">{q.buyer_organization_id}</TableCell>
              <TableCell><Badge variant="outline">{q.currency_code}</Badge></TableCell>
              <TableCell>{Number(q.total_amount).toLocaleString("fa-IR")}</TableCell>
              <TableCell><Badge variant="outline">{q.status}</Badge></TableCell>
              <TableCell className="text-xs">{q.valid_until ?? "—"}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}

async function CurrencyRatesTab() {
  const rates = await listCurrencyRates({});
  return (
    <div className="space-y-3">
      <div className="flex justify-end">
        <Button asChild size="sm">
          <Link href="/admin/pricing/currency-rates/new">افزودن نرخ جدید</Link>
        </Button>
      </div>
      {rates.length === 0 ? (
        <TableEmpty>هیچ نرخ ارزی ثبت نشده است.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>مبدا</TableHead>
                <TableHead>مقصد</TableHead>
                <TableHead>نرخ</TableHead>
                <TableHead>اعتبار از</TableHead>
                <TableHead>اعتبار تا</TableHead>
                <TableHead>منبع</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rates.map((r) => (
                <TableRow key={r.id}>
                  <TableCell><Badge variant="outline">{r.base_code}</Badge></TableCell>
                  <TableCell><Badge variant="outline">{r.quote_code}</Badge></TableCell>
                  <TableCell>{Number(r.rate).toLocaleString("fa-IR")}</TableCell>
                  <TableCell className="text-xs">{r.effective_from}</TableCell>
                  <TableCell className="text-xs">{r.effective_to ?? "—"}</TableCell>
                  <TableCell className="text-xs">{r.source}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}
    </div>
  );
}

async function CapturesTab() {
  const captures = await listQuoteCaptures({});
  if (captures.length === 0) return <TableEmpty>هیچ اسنپ‌شاتی ثبت نشده است.</TableEmpty>;
  return (
    <div className="rounded-md border">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>شناسه</TableHead>
            <TableHead>نوع</TableHead>
            <TableHead>تأمین‌کننده</TableHead>
            <TableHead>خریدار</TableHead>
            <TableHead>ارز</TableHead>
            <TableHead>زمان</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {captures.map((c) => (
            <TableRow key={c.id}>
              <TableCell className="font-mono text-xs">{c.id}</TableCell>
              <TableCell><Badge variant="outline">{c.kind}</Badge></TableCell>
              <TableCell className="font-mono text-xs">{c.supplier_id}</TableCell>
              <TableCell className="font-mono text-xs">{c.buyer_organization_id}</TableCell>
              <TableCell><Badge variant="outline">{c.currency_code}</Badge></TableCell>
              <TableCell className="text-xs">{c.captured_at}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
