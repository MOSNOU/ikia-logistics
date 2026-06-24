import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import type { CapacityListing, CapacityStatus } from "@/types/database";

interface Props {
  listing: CapacityListing;
}

const STATUS_LABEL: Record<CapacityStatus, string> = {
  draft: "پیش‌نویس",
  active: "در دسترس",
  reserved: "رزرو شده",
  expired: "منقضی",
  archived: "بایگانی",
};

function statusVariant(s: CapacityStatus): "outline" | "success" | "warning" {
  if (s === "active") return "success";
  if (s === "reserved" || s === "draft") return "warning";
  return "outline";
}

export function CapacityCard({ listing }: Props) {
  const carrierLabel =
    listing.carrier_name_fa ?? listing.carrier_name_en ?? listing.carrier_organization_id;
  const originLabel = listing.origin_city ?? listing.origin_country_code ?? "—";
  const destinationLabel =
    listing.destination_city ?? listing.destination_country_code ?? "—";

  return (
    <Card>
      <CardContent className="p-4 space-y-2">
        <div className="flex items-start justify-between gap-2">
          <div>
            <div className="text-sm font-medium">{carrierLabel}</div>
            <div className="text-xs text-muted-foreground">
              {originLabel}
              {" → "}
              {destinationLabel}
            </div>
          </div>
          <div className="flex flex-col items-end gap-1">
            <Badge variant="outline">{listing.transport_mode}</Badge>
            {listing.status ? (
              <Badge variant={statusVariant(listing.status)}>
                {STATUS_LABEL[listing.status]}
              </Badge>
            ) : null}
          </div>
        </div>
        <div className="grid grid-cols-3 gap-2 text-xs">
          <div>
            <div className="text-muted-foreground">ظرفیت</div>
            <div className="font-mono">
              {listing.capacity_units != null
                ? `${listing.capacity_units} ${listing.capacity_unit_label ?? ""}`.trim()
                : "—"}
            </div>
          </div>
          <div>
            <div className="text-muted-foreground">از</div>
            <div className="text-xs">{listing.valid_from ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">تا</div>
            <div className="text-xs">{listing.valid_until ?? "—"}</div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
