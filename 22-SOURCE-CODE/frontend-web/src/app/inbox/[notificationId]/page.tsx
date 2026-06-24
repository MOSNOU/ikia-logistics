import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { getProfile } from "@/lib/auth/get-profile";
import { createClient } from "@/lib/supabase/server";
import { getNotification } from "@/lib/notify/get-notification";
import { ArchiveForm } from "./archive-form";

const isAuthEnabled =
  !!process.env.NEXT_PUBLIC_SUPABASE_URL && !!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

// Q9=B: internal hrefs (starting with "/") get a Next.js <Link>; external
// hrefs render as a native anchor (and only if the value is an http/https URL).
function ActionLink({ href }: { href: string }) {
  if (href.startsWith("/")) {
    return (
      <Button asChild>
        <Link href={href}>اقدام</Link>
      </Button>
    );
  }
  if (href.startsWith("http://") || href.startsWith("https://")) {
    return (
      <Button asChild>
        <a href={href} target="_blank" rel="noopener noreferrer">
          اقدام
        </a>
      </Button>
    );
  }
  return null;
}

interface PageProps {
  params: Promise<{ notificationId: string }>;
}

export default async function InboxDetailPage({ params }: PageProps) {
  if (!isAuthEnabled) redirect("/");
  const profile = await getProfile();
  if (!profile) redirect("/login");

  const { notificationId } = await params;
  const detail = await getNotification(notificationId);
  if (!detail) notFound();

  // Server-side: auto-mark as read if currently unread.
  if (detail.status === "unread") {
    const supabase = await createClient();
    await supabase
      .schema("notify")
      .rpc("portal_mark_read", { p_notification_id: notificationId });
    detail.status = "read";
    detail.read_at = new Date().toISOString();
  }

  return (
    <div className="mx-auto max-w-3xl space-y-6 px-4 py-10">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">{detail.title_fa || detail.title_en}</h1>
          <p className="text-sm text-muted-foreground">
            <Badge variant="outline">{detail.category}</Badge>
            {" · "}
            <Badge variant="outline">{detail.priority}</Badge>
            {" · "}
            <Badge variant="outline">{detail.status}</Badge>
          </p>
        </div>
        <div className="flex flex-col items-end gap-2">
          {detail.action_url ? <ActionLink href={detail.action_url} /> : null}
          <ArchiveForm notificationId={notificationId} />
        </div>
      </div>

      {detail.body_fa || detail.body_en ? (
        <Card>
          <CardContent className="p-6 space-y-3 text-sm">
            {detail.body_fa ? <div>{detail.body_fa}</div> : null}
            {detail.body_en ? (
              <div className="text-muted-foreground" dir="ltr">
                {detail.body_en}
              </div>
            ) : null}
          </CardContent>
        </Card>
      ) : null}

      <Card>
        <CardContent className="p-6 grid gap-3 md:grid-cols-2 text-sm">
          <div>
            <div className="text-muted-foreground">منبع رویداد</div>
            <div className="text-xs font-mono">{detail.source_event_type ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">نوع موجودیت منبع</div>
            <div className="text-xs font-mono">{detail.source_entity_type ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">شناسه موجودیت منبع</div>
            <div className="text-xs font-mono">{detail.source_entity_id ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">ایجاد در</div>
            <div className="text-xs">{detail.created_at}</div>
          </div>
          <div>
            <div className="text-muted-foreground">خوانده‌شده در</div>
            <div className="text-xs">{detail.read_at ?? "—"}</div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardContent className="p-6 text-sm">
          <details>
            <summary className="cursor-pointer text-muted-foreground">
              نمایش بار داده (Payload)
            </summary>
            <pre className="mt-3 overflow-x-auto rounded-md bg-muted/40 p-3 text-xs" dir="ltr">
              {JSON.stringify(detail.payload, null, 2)}
            </pre>
          </details>
        </CardContent>
      </Card>

      <div>
        <Button asChild variant="outline" size="sm">
          <Link href="/inbox">بازگشت به صندوق</Link>
        </Button>
      </div>
    </div>
  );
}
