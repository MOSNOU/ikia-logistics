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
import { getRfq } from "@/lib/rfq/get-rfq";
import { DraftOfferButton } from "./draft-offer-button";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function SupplierRfqDetailPage({ params }: PageProps) {
  const { id } = await params;
  const detail = await getRfq(id, "supplier");
  if (!detail) notFound();

  const { request, items } = detail;
  const canDraftOffer =
    request.status === "submitted" ||
    request.status === "published" ||
    request.status === "invited";

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">{request.title}</h1>
          <p className="text-sm text-muted-foreground">
            <span className="font-mono text-xs">{request.rfq_code}</span>
            {" · "}
            <Badge variant="outline">{request.preferred_currency}</Badge>
            {" · "}
            وضعیت RFQ: <Badge variant="outline">{request.status}</Badge>
          </p>
        </div>
        {canDraftOffer ? <DraftOfferButton requestId={request.id} /> : null}
      </div>

      <Card>
        <CardContent className="p-6 grid gap-3 md:grid-cols-3 text-sm">
          <div>
            <div className="text-muted-foreground">مهلت ارسال</div>
            <div className="text-xs">{request.submission_deadline ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">اعتبار تا</div>
            <div className="text-xs">{request.validity_until ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">کشور تحویل</div>
            <div>{request.delivery_country ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">شهر تحویل</div>
            <div>{request.delivery_city ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">بندر</div>
            <div>{request.delivery_port ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">شرایط پرداخت</div>
            <div>{request.payment_terms_text ?? "—"}</div>
          </div>
          {request.description ? (
            <div className="md:col-span-3">
              <div className="text-muted-foreground">توضیحات</div>
              <div>{request.description}</div>
            </div>
          ) : null}
        </CardContent>
      </Card>

      <div>
        <h2 className="text-lg font-semibold mb-3">ردیف‌ها ({items?.length ?? 0})</h2>
        {!items || items.length === 0 ? (
          <TableEmpty>ردیفی برای این RFQ ثبت نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>کالا</TableHead>
                  <TableHead>تعداد درخواستی</TableHead>
                  <TableHead>واحد</TableHead>
                  <TableHead>یادداشت</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {items.map((it) => (
                  <TableRow key={it.id}>
                    <TableCell className="font-mono text-xs">{it.product_id ?? "—"}</TableCell>
                    <TableCell>
                      {it.quantity != null ? Number(it.quantity).toLocaleString("fa-IR") : "—"}
                    </TableCell>
                    <TableCell>{it.quantity_unit ?? "—"}</TableCell>
                    <TableCell className="text-xs">{it.notes ?? "—"}</TableCell>
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
