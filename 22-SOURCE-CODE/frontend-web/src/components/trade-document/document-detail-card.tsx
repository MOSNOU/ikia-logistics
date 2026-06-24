import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import {
  docKindLabel,
  docStatusLabel,
} from "@/lib/trade-document/labels";
import type { TradeDocumentRow } from "@/types/database";

interface Props {
  doc: TradeDocumentRow;
  audience: "buyer" | "admin";
}

export function DocumentDetailCard({ doc, audience }: Props) {
  const ship = doc.shipments ?? null;
  const shipmentHref =
    audience === "admin"
      ? `/admin/shipments/${doc.shipment_id}`
      : `/buyer/shipments/${doc.shipment_id}`;

  return (
    <>
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">{docKindLabel(doc.document_kind)}</h1>
          <p className="text-sm text-muted-foreground">
            <Badge variant="outline">{doc.document_kind}</Badge>
            {" · "}
            <Badge variant="outline">{docStatusLabel(doc.document_status)}</Badge>
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href={shipmentHref}>مشاهده شیپمنت</Link>
        </Button>
      </div>

      <Card>
        <CardContent className="p-6 grid gap-3 md:grid-cols-3 text-sm">
          <div>
            <div className="text-muted-foreground">شیپمنت</div>
            <div className="font-mono text-xs">{ship?.shipment_code ?? doc.shipment_id}</div>
          </div>
          <div>
            <div className="text-muted-foreground">قرارداد اجرایی</div>
            <div className="font-mono text-xs">{ship?.executed_contract_id ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">سازمان مالک</div>
            <div className="font-mono text-xs">{doc.organization_id}</div>
          </div>
          <div>
            <div className="text-muted-foreground">تأمین‌کننده</div>
            <div className="font-mono text-xs">{ship?.supplier_id ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">مود حمل</div>
            <div>{ship?.transport_mode ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">وضعیت شیپمنت</div>
            <div><Badge variant="outline">{ship?.status ?? "—"}</Badge></div>
          </div>
          <div>
            <div className="text-muted-foreground">مرجع خارجی</div>
            <div className="font-mono text-xs">{doc.external_reference ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">تاریخ صدور</div>
            <div className="text-xs">{doc.issued_at ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">تاریخ انقضا</div>
            <div className="text-xs">{doc.expires_at ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">ایجاد</div>
            <div className="text-xs">{doc.created_at}</div>
          </div>
          <div>
            <div className="text-muted-foreground">به‌روزرسانی</div>
            <div className="text-xs">{doc.updated_at}</div>
          </div>
          <div>
            <div className="text-muted-foreground">شناسه نیازمندی</div>
            <div className="font-mono text-xs">{doc.requirement_id ?? "—"}</div>
          </div>
          {doc.notes ? (
            <div className="md:col-span-3">
              <div className="text-muted-foreground">یادداشت</div>
              <div>{doc.notes}</div>
            </div>
          ) : null}
        </CardContent>
      </Card>

      <Card>
        <CardContent className="p-6 text-sm">
          <details>
            <summary className="cursor-pointer text-muted-foreground">
              نمایش متادیتای فنی (JSON)
            </summary>
            <pre className="mt-3 overflow-x-auto rounded-md bg-muted/40 p-3 text-xs" dir="ltr">
              {JSON.stringify(doc.metadata, null, 2)}
            </pre>
          </details>
        </CardContent>
      </Card>
    </>
  );
}
