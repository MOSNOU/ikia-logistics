import Link from "next/link";
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
import { Button } from "@/components/ui/button";
import { getOffer } from "@/lib/offer/get-offer";
import { SupplierOfferActions } from "./supplier-offer-actions";
import { UpsertOfferItemForm } from "./upsert-offer-item-form";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function SupplierOfferDetailPage({ params }: PageProps) {
  const { id } = await params;
  const detail = await getOffer(id, "supplier");
  if (!detail) notFound();

  const { offer, items } = detail;
  const isDraft = offer.status === "draft";
  const isSubmitted = offer.status === "submitted";

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">{offer.offer_code}</h1>
          <p className="text-sm text-muted-foreground">
            RFQ:{" "}
            <Link href={`/supplier/rfqs/${offer.request_id}`} className="font-mono text-xs underline">
              {offer.request_id}
            </Link>
            {" · "}
            <Badge variant="outline">{offer.currency}</Badge>
            {" · "}
            <Badge variant="outline">{offer.status}</Badge>
          </p>
        </div>
        <SupplierOfferActions
          offerId={offer.id}
          canSubmit={isDraft && (items?.length ?? 0) > 0}
          canWithdraw={isSubmitted}
        />
      </div>

      <Card>
        <CardContent className="p-6 grid gap-3 md:grid-cols-3 text-sm">
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
            <div className="text-muted-foreground">کشور تحویل</div>
            <div>{offer.delivery_country ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">شهر تحویل</div>
            <div>{offer.delivery_city ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">زمان تحویل</div>
            <div>{offer.delivery_lead_time_text ?? "—"}</div>
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
                  <TableHead>یادداشت</TableHead>
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
                    <TableCell className="text-xs">{it.notes ?? "—"}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}

        {isDraft ? (
          <div className="mt-4">
            <h3 className="text-sm font-medium mb-2">افزودن / به‌روزرسانی ردیف</h3>
            <UpsertOfferItemForm offerId={offer.id} />
          </div>
        ) : (
          <p className="text-sm text-muted-foreground mt-4">
            ویرایش ردیف‌ها در وضعیت <Badge variant="outline">{offer.status}</Badge> امکان‌پذیر نیست.
          </p>
        )}
      </div>

      <div>
        <Button asChild variant="outline" size="sm">
          <Link href="/supplier/offers">بازگشت به فهرست</Link>
        </Button>
      </div>
    </div>
  );
}
