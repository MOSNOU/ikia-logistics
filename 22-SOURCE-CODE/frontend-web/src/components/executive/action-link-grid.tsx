import Link from "next/link";
import { Card, CardContent } from "@/components/ui/card";
import type { QuickLink } from "@/types/database";

interface Props {
  links: QuickLink[];
  title?: string;
}

export function ActionLinkGrid({ links, title = "لینک‌های سریع" }: Props) {
  return (
    <Card>
      <CardContent className="p-4 space-y-3">
        <div className="text-sm font-medium">{title}</div>
        <div className="grid gap-2 grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
          {links.map((l) => (
            <Link
              key={l.href}
              href={l.href}
              className="rounded-md border px-3 py-2 hover:bg-muted/30 transition-colors"
            >
              <div className="text-sm font-medium">{l.label}</div>
              {l.caption ? (
                <div className="text-xs text-muted-foreground">{l.caption}</div>
              ) : null}
            </Link>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
