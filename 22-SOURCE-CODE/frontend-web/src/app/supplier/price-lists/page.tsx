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
import { listMyPriceLists } from "@/lib/pricing/list-my-price-lists";
import type { PriceListStatus } from "@/types/database";

const STATUS_OPTIONS: { value: PriceListStatus | ""; label: string }[] = [
  { value: "", label: "همه" },
  { value: "draft", label: "پیش‌نویس" },
  { value: "active", label: "فعال" },
  { value: "paused", label: "موقت متوقف" },
  { value: "archived", label: "بایگانی‌شده" },
];

function statusBadge(s: PriceListStatus) {
  switch (s) {
    case "active":
      return <Badge variant="success">فعال</Badge>;
    case "draft":
      return <Badge variant="muted">پیش‌نویس</Badge>;
    case "paused":
      return <Badge variant="warning">موقت متوقف</Badge>;
    case "archived":
      return <Badge variant="outline">بایگانی</Badge>;
    default:
      return <Badge variant="outline">{s}</Badge>;
  }
}

interface PageProps {
  searchParams: Promise<{ status?: string; page?: string }>;
}

export default async function SupplierPriceListsPage({ searchParams }: PageProps) {
  const { status, page: pageParam } = await searchParams;
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const statusFilter =
    status && STATUS_OPTIONS.some((o) => o.value === status)
      ? (status as PriceListStatus)
      : null;

  const { rows, pageSize } = await listMyPriceLists({ status: statusFilter, page });

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">فهرست‌های قیمت</h1>
          <p className="text-sm text-muted-foreground">
            فهرست‌های قیمت تأمین‌کننده — پیش‌نویس، فعال‌سازی، توقف موقت و بایگانی.
          </p>
        </div>
        <Button asChild>
          <Link href="/supplier/price-lists/new">ایجاد فهرست جدید</Link>
        </Button>
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
        <Button type="submit" variant="outline">اعمال فیلتر</Button>
      </form>

      {rows.length === 0 ? (
        <TableEmpty>هیچ فهرست قیمتی یافت نشد.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>کد</TableHead>
                <TableHead>عنوان</TableHead>
                <TableHead>ارز</TableHead>
                <TableHead>وضعیت</TableHead>
                <TableHead>اعتبار از</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((pl) => (
                <TableRow key={pl.id}>
                  <TableCell className="font-mono text-xs">{pl.code}</TableCell>
                  <TableCell>{pl.name_fa ?? pl.name_en}</TableCell>
                  <TableCell><Badge variant="outline">{pl.currency_code}</Badge></TableCell>
                  <TableCell>{statusBadge(pl.status)}</TableCell>
                  <TableCell className="text-xs">{pl.effective_from ?? "—"}</TableCell>
                  <TableCell>
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/supplier/price-lists/${pl.id}`}>مشاهده</Link>
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
              <Link href={`/supplier/price-lists?status=${statusFilter ?? ""}&page=${page - 1}`}>
                قبلی
              </Link>
            </Button>
          ) : null}
          {rows.length === pageSize ? (
            <Button asChild variant="outline" size="sm">
              <Link href={`/supplier/price-lists?status=${statusFilter ?? ""}&page=${page + 1}`}>
                بعدی
              </Link>
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
