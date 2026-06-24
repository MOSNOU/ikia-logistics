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
import { listAdminShipments } from "@/lib/admin/list-shipments";
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

interface PageProps {
  searchParams: Promise<{
    status?: string;
    contractId?: string;
    supplierId?: string;
    page?: string;
  }>;
}

export default async function AdminShipmentsPage({ searchParams }: PageProps) {
  const { status, contractId, supplierId, page: pageParam } = await searchParams;
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const statusFilter =
    status && STATUS_OPTIONS.some((o) => o.value === status)
      ? (status as ShipmentStatus)
      : null;
  const contractFilter = contractId?.trim() || null;
  const supplierFilter = supplierId?.trim() || null;

  const { rows, pageSize } = await listAdminShipments({
    status: statusFilter,
    executedContractId: contractFilter,
    supplierId: supplierFilter,
    page,
  });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">صف محموله‌ها (مدیریت)</h1>
        <p className="text-sm text-muted-foreground">
          نمای پلتفرمی روی همه محموله‌ها — پایش و اقدام اضطراری.
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
        <div className="space-y-1">
          <label htmlFor="supplierId" className="text-sm font-medium">شناسه تأمین‌کننده</label>
          <input
            id="supplierId"
            name="supplierId"
            defaultValue={supplierFilter ?? ""}
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
                <TableHead>سازمان</TableHead>
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
                  <TableCell className="font-mono text-xs">{s.organization_id ?? "—"}</TableCell>
                  <TableCell className="font-mono text-xs">{s.supplier_id ?? "—"}</TableCell>
                  <TableCell><Badge variant="outline">{s.transport_mode ?? "—"}</Badge></TableCell>
                  <TableCell><Badge variant="outline">{s.status}</Badge></TableCell>
                  <TableCell className="text-xs">{s.updated_at}</TableCell>
                  <TableCell>
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/admin/shipments/${s.id}`}>مشاهده</Link>
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
                href={`/admin/shipments?status=${statusFilter ?? ""}&contractId=${contractFilter ?? ""}&supplierId=${supplierFilter ?? ""}&page=${page - 1}`}
              >قبلی</Link>
            </Button>
          ) : null}
          {rows.length === pageSize ? (
            <Button asChild variant="outline" size="sm">
              <Link
                href={`/admin/shipments?status=${statusFilter ?? ""}&contractId=${contractFilter ?? ""}&supplierId=${supplierFilter ?? ""}&page=${page + 1}`}
              >بعدی</Link>
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
