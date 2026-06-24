import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableEmpty,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import type { ShipmentDetail } from "@/types/database";

export function ShipmentSummary({ detail }: { detail: ShipmentDetail }) {
  const { shipment, doc_requirements: docReqs, documents, events } = detail;

  return (
    <>
      <Card>
        <CardContent className="p-6 grid gap-3 md:grid-cols-3 text-sm">
          <div>
            <div className="text-muted-foreground">قرارداد اجرایی</div>
            <div className="font-mono text-xs">{shipment.executed_contract_id}</div>
          </div>
          <div>
            <div className="text-muted-foreground">تأمین‌کننده</div>
            <div className="font-mono text-xs">{shipment.supplier_id ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">اینکوترم</div>
            <div>{shipment.incoterm ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">مبدأ</div>
            <div className="text-xs">
              {shipment.origin_city ?? "—"}
              {shipment.origin_country ? ` (${shipment.origin_country})` : ""}
            </div>
          </div>
          <div>
            <div className="text-muted-foreground">مقصد</div>
            <div className="text-xs">
              {shipment.destination_city ?? "—"}
              {shipment.destination_country ? ` (${shipment.destination_country})` : ""}
            </div>
          </div>
          <div>
            <div className="text-muted-foreground">حمل‌کننده</div>
            <div className="text-xs">{shipment.carrier_name ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">تاریخ بارگیری برنامه‌ریزی‌شده</div>
            <div className="text-xs">{shipment.planned_pickup_date ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">تاریخ تحویل برنامه‌ریزی‌شده</div>
            <div className="text-xs">{shipment.planned_delivery_date ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">شماره ردیابی</div>
            <div className="font-mono text-xs">{shipment.tracking_reference ?? "—"}</div>
          </div>
          {shipment.notes ? (
            <div className="md:col-span-3">
              <div className="text-muted-foreground">یادداشت</div>
              <div>{shipment.notes}</div>
            </div>
          ) : null}
        </CardContent>
      </Card>

      <div>
        <h2 className="text-lg font-semibold mb-3">نیازمندی‌های مدرک ({docReqs?.length ?? 0})</h2>
        {!docReqs || docReqs.length === 0 ? (
          <TableEmpty>نیازمندی ثبت نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>نوع</TableHead>
                  <TableHead>سطح</TableHead>
                  <TableHead>عنوان فارسی</TableHead>
                  <TableHead>یادداشت</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {docReqs.map((r) => (
                  <TableRow key={r.id}>
                    <TableCell><Badge variant="outline">{r.document_kind}</Badge></TableCell>
                    <TableCell><Badge variant="outline">{r.requirement_level}</Badge></TableCell>
                    <TableCell>{r.display_name_fa ?? "—"}</TableCell>
                    <TableCell className="text-xs">{r.notes ?? "—"}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </div>

      <div>
        <h2 className="text-lg font-semibold mb-3">مدارک ({documents?.length ?? 0})</h2>
        {!documents || documents.length === 0 ? (
          <TableEmpty>مدرکی ثبت نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>نوع</TableHead>
                  <TableHead>وضعیت</TableHead>
                  <TableHead>مرجع خارجی</TableHead>
                  <TableHead>تاریخ صدور</TableHead>
                  <TableHead>تاریخ انقضا</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {documents.map((d) => (
                  <TableRow key={d.id}>
                    <TableCell><Badge variant="outline">{d.document_kind}</Badge></TableCell>
                    <TableCell><Badge variant="outline">{d.document_status}</Badge></TableCell>
                    <TableCell className="text-xs">{d.external_reference ?? "—"}</TableCell>
                    <TableCell className="text-xs">{d.issued_at ?? "—"}</TableCell>
                    <TableCell className="text-xs">{d.expires_at ?? "—"}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </div>

      {events && events.length > 0 ? (
        <div>
          <h2 className="text-lg font-semibold mb-3">رویدادها ({events.length})</h2>
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>نوع رویداد</TableHead>
                  <TableHead>از</TableHead>
                  <TableHead>به</TableHead>
                  <TableHead>دلیل</TableHead>
                  <TableHead>کاربر</TableHead>
                  <TableHead>زمان</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {events.map((e) => (
                  <TableRow key={e.id}>
                    <TableCell><Badge variant="outline">{e.event_type}</Badge></TableCell>
                    <TableCell className="text-xs">{e.from_status ?? "—"}</TableCell>
                    <TableCell className="text-xs">{e.to_status ?? "—"}</TableCell>
                    <TableCell className="text-xs">{e.reason ?? "—"}</TableCell>
                    <TableCell className="font-mono text-xs">{e.actor_user_id ?? "—"}</TableCell>
                    <TableCell className="text-xs">{e.created_at}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        </div>
      ) : null}
    </>
  );
}
