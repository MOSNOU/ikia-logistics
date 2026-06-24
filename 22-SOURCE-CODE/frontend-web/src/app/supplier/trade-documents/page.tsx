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
import { listSupplierTradeDocuments } from "@/lib/trade-document/list-supplier-documents";

export default async function SupplierTradeDocumentsPage() {
  const { rows } = await listSupplierTradeDocuments();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">مدارک تجاری</h1>
        <p className="text-sm text-muted-foreground">
          فهرست محموله‌های شما با امکان مشاهده مدارک حمل و تطبیق (فاکتور تجاری، بارنامه، گواهی مبدأ، گواهی بازرسی و …). برای دسترسی به مدارک هر محموله، روی «مشاهده محموله» کلیک کنید.
        </p>
      </div>

      {rows.length === 0 ? (
        <TableEmpty>محموله‌ای برای نمایش مدارک وجود ندارد.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>کد محموله</TableHead>
                <TableHead>وضعیت</TableHead>
                <TableHead>مود حمل</TableHead>
                <TableHead>قرارداد اجرایی</TableHead>
                <TableHead>به‌روزرسانی</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((r) => (
                <TableRow key={r.shipment_id}>
                  <TableCell className="font-mono text-xs">{r.shipment_code}</TableCell>
                  <TableCell><Badge variant="outline">{r.status}</Badge></TableCell>
                  <TableCell>{r.transport_mode ?? "—"}</TableCell>
                  <TableCell className="font-mono text-xs">{r.executed_contract_id}</TableCell>
                  <TableCell className="text-xs">{r.updated_at}</TableCell>
                  <TableCell>
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/supplier/shipments/${r.shipment_id}`}>مشاهده محموله</Link>
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}
    </div>
  );
}
