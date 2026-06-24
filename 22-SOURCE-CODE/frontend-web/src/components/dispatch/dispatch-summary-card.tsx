import { Card, CardContent } from "@/components/ui/card";
import { DispatchStatusBadge } from "./dispatch-status-badge";
import type { DispatchDetail } from "@/types/database";

interface Props {
  detail: DispatchDetail;
}

export function DispatchSummaryCard({ detail }: Props) {
  const d = detail.dispatch;
  return (
    <Card>
      <CardContent className="p-6 grid gap-3 md:grid-cols-3 text-sm">
        <div>
          <div className="text-muted-foreground">وضعیت</div>
          <DispatchStatusBadge status={d.status} />
        </div>
        <div>
          <div className="text-muted-foreground">رزرو مرتبط</div>
          <div className="font-mono text-xs">{d.booking_request_id}</div>
        </div>
        <div>
          <div className="text-muted-foreground">برداشت برنامه‌ریزی‌شده</div>
          <div className="text-xs">{d.planned_pickup_at ?? "—"}</div>
        </div>
        <div>
          <div className="text-muted-foreground">سازمان خریدار</div>
          <div className="font-mono text-xs">{d.buyer_organization_id}</div>
        </div>
        <div>
          <div className="text-muted-foreground">سازمان حمل‌کننده</div>
          <div className="font-mono text-xs">{d.carrier_organization_id}</div>
        </div>
        <div>
          <div className="text-muted-foreground">به‌روزرسانی</div>
          <div className="text-xs">{d.updated_at}</div>
        </div>
        <div>
          <div className="text-muted-foreground">شماره خودرو</div>
          <div className="font-mono text-xs">{d.vehicle_reference ?? "—"}</div>
        </div>
        <div>
          <div className="text-muted-foreground">نوع خودرو</div>
          <div className="text-xs">{d.vehicle_type ?? "—"}</div>
        </div>
        <div>
          <div className="text-muted-foreground">راننده</div>
          <div className="text-xs">
            {d.driver_name ?? "—"}
            {d.driver_phone ? ` (${d.driver_phone})` : ""}
          </div>
        </div>
        {d.notes_fa ? (
          <div className="md:col-span-3">
            <div className="text-muted-foreground">یادداشت</div>
            <div className="text-xs whitespace-pre-line">{d.notes_fa}</div>
          </div>
        ) : null}
        {d.cancelled_reason ? (
          <div className="md:col-span-3">
            <div className="text-muted-foreground">دلیل لغو</div>
            <div className="text-xs whitespace-pre-line">{d.cancelled_reason}</div>
          </div>
        ) : null}
      </CardContent>
    </Card>
  );
}
