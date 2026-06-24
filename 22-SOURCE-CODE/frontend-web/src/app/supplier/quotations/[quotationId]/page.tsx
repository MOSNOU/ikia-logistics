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
import { getQuotation } from "@/lib/pricing/get-quotation";
import { AddItemForm } from "./add-item-form";
import { SendQuotationForm } from "./send-quotation-form";

interface PageProps {
  params: Promise<{ quotationId: string }>;
}

export default async function SupplierQuotationDetailPage({ params }: PageProps) {
  const { quotationId } = await params;
  const detail = await getQuotation(quotationId);
  if (!detail) notFound();

  const { quotation, items } = detail;
  const isDraft = quotation.status === "draft";

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">{quotation.quotation_code}</h1>
          <p className="text-sm text-muted-foreground">
            <span className="font-mono text-xs">{quotation.buyer_organization_id}</span>
            {" · "}
            ارز: <Badge variant="outline">{quotation.currency_code}</Badge>
            {" · "}
            وضعیت: <Badge variant="outline">{quotation.status}</Badge>
          </p>
        </div>
        {isDraft && items.length > 0 ? (
          <SendQuotationForm quotationId={quotation.id} />
        ) : null}
      </div>

      <Card>
        <CardContent className="p-6 grid gap-3 md:grid-cols-3 text-sm">
          <div>
            <div className="text-muted-foreground">مبلغ خالص</div>
            <div className="text-lg font-semibold">
              {Number(quotation.subtotal_amount).toLocaleString("fa-IR")} {quotation.currency_code}
            </div>
          </div>
          <div>
            <div className="text-muted-foreground">مجموع تخفیف</div>
            <div className="text-lg font-semibold">
              {Number(quotation.discount_amount).toLocaleString("fa-IR")} {quotation.currency_code}
            </div>
          </div>
          <div>
            <div className="text-muted-foreground">مبلغ نهایی</div>
            <div className="text-lg font-semibold">
              {Number(quotation.total_amount).toLocaleString("fa-IR")} {quotation.currency_code}
            </div>
          </div>
          <div>
            <div className="text-muted-foreground">اعتبار از</div>
            <div className="text-xs">{quotation.valid_from ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">اعتبار تا</div>
            <div className="text-xs">{quotation.valid_until ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">ارسال‌شده در</div>
            <div className="text-xs">{quotation.sent_at ?? "—"}</div>
          </div>
        </CardContent>
      </Card>

      <div>
        <h2 className="text-lg font-semibold mb-3">ردیف‌ها</h2>
        {items.length === 0 ? (
          <TableEmpty>هنوز ردیفی ثبت نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>کالا</TableHead>
                  <TableHead>تعداد</TableHead>
                  <TableHead>واحد</TableHead>
                  <TableHead>قیمت واحد</TableHead>
                  <TableHead>تخفیف</TableHead>
                  <TableHead>جمع</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {items.map((it) => (
                  <TableRow key={it.id}>
                    <TableCell className="font-mono text-xs">{it.product_id}</TableCell>
                    <TableCell>{Number(it.quantity).toLocaleString("fa-IR")}</TableCell>
                    <TableCell>{it.unit_of_measure}</TableCell>
                    <TableCell>{Number(it.unit_price).toLocaleString("fa-IR")}</TableCell>
                    <TableCell>{Number(it.discount_amount).toLocaleString("fa-IR")}</TableCell>
                    <TableCell>{Number(it.line_total).toLocaleString("fa-IR")}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </div>

      {isDraft ? (
        <div>
          <h2 className="text-lg font-semibold mb-3">افزودن ردیف</h2>
          <AddItemForm quotationId={quotation.id} />
        </div>
      ) : (
        <p className="text-sm text-muted-foreground">
          ویرایش ردیف‌ها در وضعیت <Badge variant="outline">{quotation.status}</Badge> امکان‌پذیر نیست.
        </p>
      )}
    </div>
  );
}
