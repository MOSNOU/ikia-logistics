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
import { listAdminOffers } from "@/lib/admin/list-offers";
import type { OfferStatus } from "@/types/database";

const STATUS_OPTIONS: { value: OfferStatus | ""; label: string }[] = [
  { value: "", label: "همه" },
  { value: "draft", label: "پیش‌نویس" },
  { value: "submitted", label: "ارسال‌شده" },
  { value: "withdrawn", label: "پس‌گرفته" },
  { value: "expired", label: "منقضی" },
  { value: "rejected", label: "ردشده" },
  { value: "shortlisted", label: "فهرست کوتاه" },
  { value: "accepted", label: "پذیرفته‌شده" },
];

interface PageProps {
  searchParams: Promise<{
    status?: string;
    requestId?: string;
    supplierId?: string;
    page?: string;
  }>;
}

export default async function AdminOffersPage({ searchParams }: PageProps) {
  const { status, requestId, supplierId, page: pageParam } = await searchParams;
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const statusFilter =
    status && STATUS_OPTIONS.some((o) => o.value === status)
      ? (status as OfferStatus)
      : null;
  const rfqFilter = requestId?.trim() || null;
  const supFilter = supplierId?.trim() || null;

  const { rows, pageSize } = await listAdminOffers({
    status: statusFilter,
    requestId: rfqFilter,
    supplierId: supFilter,
    page,
  });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">صف پیشنهادها (مدیریت)</h1>
        <p className="text-sm text-muted-foreground">
          نمای پلتفرمی روی همه پیشنهادها — پایش، فیلتر بر اساس RFQ یا تأمین‌کننده و اقدام اضطراری.
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
          <label htmlFor="requestId" className="text-sm font-medium">شناسه RFQ</label>
          <input
            id="requestId"
            name="requestId"
            defaultValue={rfqFilter ?? ""}
            dir="ltr"
            className="h-9 rounded-md border border-input bg-background px-2 text-sm font-mono"
            placeholder="UUID"
          />
        </div>
        <div className="space-y-1">
          <label htmlFor="supplierId" className="text-sm font-medium">شناسه تأمین‌کننده</label>
          <input
            id="supplierId"
            name="supplierId"
            defaultValue={supFilter ?? ""}
            dir="ltr"
            className="h-9 rounded-md border border-input bg-background px-2 text-sm font-mono"
            placeholder="UUID"
          />
        </div>
        <Button type="submit" variant="outline">اعمال فیلتر</Button>
      </form>

      {rows.length === 0 ? (
        <TableEmpty>پیشنهادی یافت نشد.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>کد</TableHead>
                <TableHead>RFQ</TableHead>
                <TableHead>تأمین‌کننده</TableHead>
                <TableHead>سازمان</TableHead>
                <TableHead>ارز</TableHead>
                <TableHead>وضعیت</TableHead>
                <TableHead>ارسال در</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((o) => (
                <TableRow key={o.id}>
                  <TableCell className="font-mono text-xs">{o.offer_code}</TableCell>
                  <TableCell className="font-mono text-xs">{o.request_id}</TableCell>
                  <TableCell className="font-mono text-xs">{o.supplier_id ?? "—"}</TableCell>
                  <TableCell className="font-mono text-xs">{o.organization_id ?? "—"}</TableCell>
                  <TableCell><Badge variant="outline">{o.currency}</Badge></TableCell>
                  <TableCell><Badge variant="outline">{o.status}</Badge></TableCell>
                  <TableCell className="text-xs">{o.submitted_at ?? "—"}</TableCell>
                  <TableCell>
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/admin/offers/${o.id}`}>مشاهده</Link>
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
              <Link
                href={`/admin/offers?status=${statusFilter ?? ""}&requestId=${rfqFilter ?? ""}&supplierId=${supFilter ?? ""}&page=${page - 1}`}
              >
                قبلی
              </Link>
            </Button>
          ) : null}
          {rows.length === pageSize ? (
            <Button asChild variant="outline" size="sm">
              <Link
                href={`/admin/offers?status=${statusFilter ?? ""}&requestId=${rfqFilter ?? ""}&supplierId=${supFilter ?? ""}&page=${page + 1}`}
              >
                بعدی
              </Link>
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
