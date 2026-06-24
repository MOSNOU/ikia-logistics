import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import type { CarrierSummary } from "@/types/database";

interface Props {
  carrier: CarrierSummary;
}

// CC-40: carrier-profile status comes from marketplace.carrier_profile_status.
const STATUS_LABEL: Record<string, string> = {
  draft: "پیش‌نویس",
  active: "فعال",
  suspended: "تعلیق",
  archived: "بایگانی",
};

export function CarrierCard({ carrier }: Props) {
  const headerFa = carrier.display_name_fa || carrier.name_fa;
  const headerEn = carrier.display_name_en || carrier.name_en;
  return (
    <Card>
      <CardContent className="p-4 space-y-2">
        <div className="flex items-start justify-between gap-2">
          <div>
            <div className="text-sm font-medium">{headerFa}</div>
            <div className="text-xs text-muted-foreground" dir="ltr">{headerEn}</div>
          </div>
          <Badge variant="outline">{STATUS_LABEL[carrier.status] ?? carrier.status}</Badge>
        </div>
        <div className="grid grid-cols-2 gap-2 text-xs">
          <div>
            <div className="text-muted-foreground">کد</div>
            <div className="font-mono">{carrier.code}</div>
          </div>
          <div>
            <div className="text-muted-foreground">کشور</div>
            <div className="font-mono">{carrier.country_code ?? "—"}</div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
