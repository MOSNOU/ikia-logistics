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
import type { RiskItem } from "@/types/database";

interface Props {
  items: RiskItem[];
}

function severityBadge(s: RiskItem["severity"], count: number) {
  if (count === 0) return <Badge variant="outline">{count}</Badge>;
  if (s === "danger") return <Badge variant="danger">{count}</Badge>;
  if (s === "warning") return <Badge variant="warning">{count}</Badge>;
  return <Badge variant="outline">{count}</Badge>;
}

export function RiskPanel({ items }: Props) {
  const available = items.filter((i) => i.available);
  return (
    <Card>
      <CardContent className="p-4 space-y-3">
        <div className="text-sm font-medium">پانل ریسک و استثناها</div>
        {available.length === 0 ? (
          <TableEmpty>منبع داده‌ای برای ریسک در دسترس نیست.</TableEmpty>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>مورد</TableHead>
                <TableHead>تعداد</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {available.map((r) => (
                <TableRow key={r.id}>
                  <TableCell className="text-sm">{r.label}</TableCell>
                  <TableCell>{severityBadge(r.severity, r.count)}</TableCell>
                  <TableCell>
                    {r.href ? (
                      <Link
                        href={r.href}
                        className="text-xs underline text-muted-foreground"
                      >
                        مشاهده
                      </Link>
                    ) : null}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </CardContent>
    </Card>
  );
}
