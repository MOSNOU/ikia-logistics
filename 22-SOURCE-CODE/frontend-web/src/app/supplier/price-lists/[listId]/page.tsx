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
import { getPriceList } from "@/lib/pricing/get-price-list";
import { PriceListStatusActions } from "./status-actions";
import { UpsertItemForm } from "./upsert-item-form";

interface PageProps {
  params: Promise<{ listId: string }>;
}

export default async function SupplierPriceListDetailPage({ params }: PageProps) {
  const { listId } = await params;
  const { list, items } = await getPriceList(listId);
  if (!list) notFound();

  const canEdit = list.status === "draft" || list.status === "active";

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">{list.name_fa || list.name_en}</h1>
          <p className="text-sm text-muted-foreground">
            <span className="font-mono text-xs">{list.code}</span>
            {" · "}
            ارز: <Badge variant="outline">{list.currency_code}</Badge>
            {" · "}
            وضعیت: <Badge variant="outline">{list.status}</Badge>
          </p>
        </div>
        <PriceListStatusActions priceListId={list.id} status={list.status} />
      </div>

      {list.description ? (
        <Card>
          <CardContent className="p-6 text-sm">{list.description}</CardContent>
        </Card>
      ) : null}

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
                  <TableHead>قیمت واحد</TableHead>
                  <TableHead>واحد</TableHead>
                  <TableHead>حداقل</TableHead>
                  <TableHead>حداکثر</TableHead>
                  <TableHead>یادداشت</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {items.map((it) => (
                  <TableRow key={it.id}>
                    <TableCell className="font-mono text-xs">{it.product_id}</TableCell>
                    <TableCell>{Number(it.unit_price).toLocaleString("fa-IR")}</TableCell>
                    <TableCell>{it.unit_of_measure}</TableCell>
                    <TableCell>{it.min_order_quantity ?? "—"}</TableCell>
                    <TableCell>{it.max_order_quantity ?? "—"}</TableCell>
                    <TableCell className="text-xs">{it.notes ?? "—"}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </div>

      {canEdit ? (
        <div>
          <h2 className="text-lg font-semibold mb-3">افزودن / به‌روزرسانی ردیف</h2>
          <UpsertItemForm priceListId={list.id} />
        </div>
      ) : (
        <p className="text-sm text-muted-foreground">
          ویرایش ردیف‌ها در وضعیت <Badge variant="outline">{list.status}</Badge> امکان‌پذیر نیست.
        </p>
      )}
    </div>
  );
}
