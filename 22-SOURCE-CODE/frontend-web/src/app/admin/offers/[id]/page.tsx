import { notFound } from "next/navigation";
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
import { getOffer } from "@/lib/offer/get-offer";
import { listOfferEvents } from "@/lib/admin/list-offer-events";
import { ForceOfferStatusForm } from "./force-offer-status-form";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function AdminOfferDetailPage({ params }: PageProps) {
  const { id } = await params;
  const [detail, events] = await Promise.all([
    getOffer(id, "admin"),
    listOfferEvents(id),
  ]);
  if (!detail) notFound();

  const { offer, items } = detail;

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">{offer.offer_code}</h1>
          <p className="text-sm text-muted-foreground">
            RFQ: <span className="font-mono text-xs">{offer.request_id}</span>
            {" · "}
            <Badge variant="outline">{offer.currency}</Badge>
            {" · "}
            <Badge variant="outline">{offer.status}</Badge>
          </p>
        </div>
        <ForceOfferStatusForm offerId={offer.id} currentStatus={offer.status} />
      </div>

      <Card>
        <CardContent className="p-6 grid gap-3 md:grid-cols-3 text-sm">
          <div>
            <div className="text-muted-foreground">تأمین‌کننده</div>
            <div className="font-mono text-xs">{offer.supplier_id}</div>
          </div>
          <div>
            <div className="text-muted-foreground">سازمان</div>
            <div className="font-mono text-xs">{offer.organization_id}</div>
          </div>
          <div>
            <div className="text-muted-foreground">اعتبار تا</div>
            <div className="text-xs">{offer.validity_until ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">ارسال در</div>
            <div className="text-xs">{offer.submitted_at ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">اینکوترم</div>
            <div>{offer.incoterm ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">شرایط پرداخت</div>
            <div>{offer.payment_terms_text ?? "—"}</div>
          </div>
          {offer.supplier_notes ? (
            <div className="md:col-span-3">
              <div className="text-muted-foreground">یادداشت تأمین‌کننده</div>
              <div>{offer.supplier_notes}</div>
            </div>
          ) : null}
        </CardContent>
      </Card>

      <div>
        <h2 className="text-lg font-semibold mb-3">ردیف‌ها ({items?.length ?? 0})</h2>
        {!items || items.length === 0 ? (
          <TableEmpty>ردیفی ثبت نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>ردیف RFQ</TableHead>
                  <TableHead>تعداد پیشنهادی</TableHead>
                  <TableHead>واحد</TableHead>
                  <TableHead>قیمت واحد</TableHead>
                  <TableHead>مبلغ کل</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {items.map((it) => (
                  <TableRow key={it.id}>
                    <TableCell className="font-mono text-xs">{it.request_item_id ?? "—"}</TableCell>
                    <TableCell>{it.offered_quantity != null ? Number(it.offered_quantity).toLocaleString("fa-IR") : "—"}</TableCell>
                    <TableCell>{it.quantity_unit ?? "—"}</TableCell>
                    <TableCell>{it.unit_price != null ? Number(it.unit_price).toLocaleString("fa-IR") : "—"}</TableCell>
                    <TableCell>{it.total_price != null ? Number(it.total_price).toLocaleString("fa-IR") : "—"}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </div>

      <div>
        <h2 className="text-lg font-semibold mb-3">رویدادها ({events.length})</h2>
        {events.length === 0 ? (
          <TableEmpty>رویدادی ثبت نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
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
        )}
      </div>
    </div>
  );
}
