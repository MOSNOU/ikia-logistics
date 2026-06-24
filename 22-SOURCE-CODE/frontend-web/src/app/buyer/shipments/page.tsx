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
import { listBuyerShipments } from "@/lib/shipment/list-buyer-shipments";
import type { ShipmentStatus } from "@/types/database";

const STATUS_OPTIONS: { value: ShipmentStatus | ""; label: string }[] = [
  { value: "", label: "همه" },
  { value: "draft", label: "پیش‌نویس" },
  { value: "planned", label: "برنامه‌ریزی‌شده" },
  { value: "booked", label: "رزرو‌شده" },
  { value: "in_transit", label: "در حال حمل" },
  { value: "arrived", label: "رسیده" },
  { value: "delivered", label: "تحویل‌شده" },
  { value: "cancelled", label: "لغوشده" },
  { value: "closed", label: "بسته‌شده" },
];

function statusBadge(s: ShipmentStatus) {
  switch (s) {
    case "delivered":
    case "closed":
      return <Badge variant="success">{s === "delivered" ? "تحویل‌شده" : "بسته‌شده"}</Badge>;
    case "in_transit":
    case "arrived":
      return <Badge variant="warning">{s === "in_transit" ? "در حال حمل" : "رسیده"}</Badge>;
    case "booked":
      return <Badge variant="warning">رزرو‌شده</Badge>;
    case "planned":
      return <Badge variant="outline">برنامه‌ریزی‌شده</Badge>;
    case "draft":
      return <Badge variant="muted">پیش‌نویس</Badge>;
    case "cancelled":
      return <Badge variant="danger">لغوشده</Badge>;
    default:
      return <Badge variant="outline">{s}</Badge>;
  }
}

interface PageProps {
  searchParams: Promise<{ status?: string; contractId?: string; page?: string }>;
}

export default async function BuyerShipmentsPage({ searchParams }: PageProps) {
  const { status, contractId, page: pageParam } = await searchParams;
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const statusFilter =
    status && STATUS_OPTIONS.some((o) => o.value === status)
      ? (status as ShipmentStatus)
      : null;
  const contractFilter = contractId?.trim() || null;

  const { rows, pageSize } = await listBuyerShipments({
    status: statusFilter,
    executedContractId: contractFilter,
    page,
  });

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">محموله‌ها</h1>
          <p className="text-sm text-muted-foreground">
            محموله‌های متصل به قراردادهای اجرایی شما — از برنامه‌ریزی تا تحویل.
          </p>
        </div>
        <Button asChild>
          <Link href="/buyer/shipments/new">ایجاد محموله جدید</Link>
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
        <div className="space-y-1">
          <label htmlFor="contractId" className="text-sm font-medium">شناسه قرارداد</label>
          <input
            id="contractId"
            name="contractId"
            defaultValue={contractFilter ?? ""}
            dir="ltr"
            className="h-9 rounded-md border border-input bg-background px-2 text-sm font-mono"
            placeholder="UUID"
          />
        </div>
        <Button type="submit" variant="outline">اعمال فیلتر</Button>
      </form>

      {rows.length === 0 ? (
        <TableEmpty>محموله‌ای یافت نشد.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>کد</TableHead>
                <TableHead>قرارداد</TableHead>
                <TableHead>تأمین‌کننده</TableHead>
                <TableHead>مود حمل</TableHead>
                <TableHead>وضعیت</TableHead>
                <TableHead>به‌روزرسانی</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((s) => (
                <TableRow key={s.id}>
                  <TableCell className="font-mono text-xs">{s.shipment_code}</TableCell>
                  <TableCell className="font-mono text-xs">{s.executed_contract_id}</TableCell>
                  <TableCell className="font-mono text-xs">{s.supplier_id ?? "—"}</TableCell>
                  <TableCell><Badge variant="outline">{s.transport_mode ?? "—"}</Badge></TableCell>
                  <TableCell>{statusBadge(s.status)}</TableCell>
                  <TableCell className="text-xs">{s.updated_at}</TableCell>
                  <TableCell>
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/buyer/shipments/${s.id}`}>مشاهده</Link>
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
                href={`/buyer/shipments?status=${statusFilter ?? ""}&contractId=${contractFilter ?? ""}&page=${page - 1}`}
              >قبلی</Link>
            </Button>
          ) : null}
          {rows.length === pageSize ? (
            <Button asChild variant="outline" size="sm">
              <Link
                href={`/buyer/shipments?status=${statusFilter ?? ""}&contractId=${contractFilter ?? ""}&page=${page + 1}`}
              >بعدی</Link>
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
