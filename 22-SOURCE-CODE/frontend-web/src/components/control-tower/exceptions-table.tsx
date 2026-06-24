import Link from "next/link";
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
import type { ControlTowerExceptionRow } from "@/types/database";

const CATEGORY_LABEL: Record<string, string> = {
  booking_stale_pending: "رزرو معطل",
  dispatch_stale_draft: "اعزام بدون تخصیص",
  settlement_disputed: "تسویه در منازعه",
  dispute_open: "اختلاف باز",
  shipment_planned_no_booking: "شیپمنت بدون رزرو",
};

function severityVariant(s: string): "outline" | "warning" | "danger" {
  if (s === "danger") return "danger";
  if (s === "warning") return "warning";
  return "outline";
}

interface Props {
  rows: ControlTowerExceptionRow[];
}

export function ControlTowerExceptionsTable({ rows }: Props) {
  if (rows.length === 0) {
    return (
      <Card>
        <CardContent className="p-4">
          <TableEmpty>هیچ مورد استثنایی برای بررسی وجود ندارد.</TableEmpty>
        </CardContent>
      </Card>
    );
  }
  return (
    <Card>
      <CardContent className="p-4 space-y-3">
        <div className="text-sm font-medium">صف استثناهای عملیاتی</div>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>دسته</TableHead>
              <TableHead>اولویت</TableHead>
              <TableHead>کد موضوع</TableHead>
              <TableHead>سازمان</TableHead>
              <TableHead>سن (ساعت)</TableHead>
              <TableHead>عملیات</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {rows.map((r) => (
              <TableRow key={`${r.category}-${r.subject_id}`}>
                <TableCell>
                  <Badge variant="outline">
                    {CATEGORY_LABEL[r.category] ?? r.category}
                  </Badge>
                </TableCell>
                <TableCell>
                  <Badge variant={severityVariant(r.severity)}>{r.severity}</Badge>
                </TableCell>
                <TableCell className="font-mono text-xs">
                  {r.subject_code ?? r.subject_id}
                </TableCell>
                <TableCell className="font-mono text-xs">{r.organization_id ?? "—"}</TableCell>
                <TableCell className="text-xs tabular-nums">
                  {Math.round(r.age_hours)}
                </TableCell>
                <TableCell>
                  <Link
                    href={r.detail_href}
                    className="text-xs underline text-muted-foreground"
                  >
                    مشاهده
                  </Link>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  );
}
