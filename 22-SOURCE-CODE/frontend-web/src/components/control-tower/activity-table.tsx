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
import type { ControlTowerActivityRow } from "@/types/database";

const DOMAIN_LABEL: Record<string, string> = {
  booking: "رزرو",
  dispatch: "اعزام",
  settlement: "تسویه",
  shipment: "شیپمنت",
};

interface Props {
  rows: ControlTowerActivityRow[];
}

export function ControlTowerActivityTable({ rows }: Props) {
  if (rows.length === 0) {
    return (
      <Card>
        <CardContent className="p-4">
          <TableEmpty>رویدادی برای نمایش وجود ندارد.</TableEmpty>
        </CardContent>
      </Card>
    );
  }
  return (
    <Card>
      <CardContent className="p-4 space-y-3">
        <div className="text-sm font-medium">جریان رویدادهای پلتفرم</div>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>دامنه</TableHead>
              <TableHead>رویداد</TableHead>
              <TableHead>از</TableHead>
              <TableHead>به</TableHead>
              <TableHead>کنش‌گر</TableHead>
              <TableHead>زمان</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {rows.map((r) => (
              <TableRow key={r.event_id}>
                <TableCell>
                  <Badge variant="outline">{DOMAIN_LABEL[r.source_domain] ?? r.source_domain}</Badge>
                </TableCell>
                <TableCell className="text-xs">{r.source_event}</TableCell>
                <TableCell className="text-xs">{r.from_status ?? "—"}</TableCell>
                <TableCell className="text-xs">{r.to_status ?? "—"}</TableCell>
                <TableCell className="text-xs">{r.actor_party ?? "—"}</TableCell>
                <TableCell className="text-xs">{r.created_at}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  );
}
