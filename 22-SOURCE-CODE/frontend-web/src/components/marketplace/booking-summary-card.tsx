import { Card, CardContent } from "@/components/ui/card";
import { BookingStatusBadge } from "./booking-status-badge";
import type { BookingDetail } from "@/types/database";

interface Props {
  detail: BookingDetail;
}

export function BookingSummaryCard({ detail }: Props) {
  const b = detail.booking;
  return (
    <Card>
      <CardContent className="p-6 grid gap-3 md:grid-cols-3 text-sm">
        <div>
          <div className="text-muted-foreground">وضعیت</div>
          <BookingStatusBadge status={b.status} />
        </div>
        <div>
          <div className="text-muted-foreground">شیپمنت</div>
          <div className="font-mono text-xs">{b.shipment_id}</div>
        </div>
        <div>
          <div className="text-muted-foreground">ظرفیت</div>
          <div className="font-mono text-xs">{b.capacity_listing_id}</div>
        </div>
        <div>
          <div className="text-muted-foreground">سازمان خریدار</div>
          <div className="font-mono text-xs">{b.buyer_organization_id}</div>
        </div>
        <div>
          <div className="text-muted-foreground">سازمان حمل‌کننده</div>
          <div className="font-mono text-xs">{b.carrier_organization_id}</div>
        </div>
        <div>
          <div className="text-muted-foreground">ظرفیت درخواست‌شده</div>
          <div className="text-xs">
            {b.requested_quantity_units != null
              ? `${b.requested_quantity_units} ${b.requested_unit_label ?? ""}`.trim()
              : "—"}
          </div>
        </div>
        <div>
          <div className="text-muted-foreground">برداشت درخواست‌شده</div>
          <div className="text-xs">{b.requested_pickup_at ?? "—"}</div>
        </div>
        <div>
          <div className="text-muted-foreground">انقضای پیشنهاد</div>
          <div className="text-xs">{b.expires_at ?? "—"}</div>
        </div>
        <div>
          <div className="text-muted-foreground">به‌روزرسانی</div>
          <div className="text-xs">{b.updated_at}</div>
        </div>
        {b.notes_fa ? (
          <div className="md:col-span-3">
            <div className="text-muted-foreground">یادداشت (فارسی)</div>
            <div className="text-xs whitespace-pre-line">{b.notes_fa}</div>
          </div>
        ) : null}
      </CardContent>
    </Card>
  );
}
