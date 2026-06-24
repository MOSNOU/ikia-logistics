"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import {
  markRead,
  archiveNotification,
  type InboxActionState,
} from "@/lib/notify/inbox-actions";
import type { NotificationStatus } from "@/types/database";

export function RowActions({
  notificationId,
  status,
}: {
  notificationId: string;
  status: NotificationStatus;
}) {
  const [markState, markAction, markPending] = useActionState<InboxActionState | null, FormData>(
    markRead,
    null,
  );
  const [archState, archAction, archPending] = useActionState<InboxActionState | null, FormData>(
    archiveNotification,
    null,
  );

  return (
    <div className="flex flex-col items-end gap-1">
      <div className="flex flex-wrap gap-2">
        {status === "unread" ? (
          <form action={markAction}>
            <input type="hidden" name="notificationId" value={notificationId} />
            <Button type="submit" size="sm" variant="outline" disabled={markPending}>
              {markPending ? "..." : "خوانده‌شد"}
            </Button>
          </form>
        ) : null}
        {status !== "archived" ? (
          <form action={archAction}>
            <input type="hidden" name="notificationId" value={notificationId} />
            <Button type="submit" size="sm" variant="outline" disabled={archPending}>
              {archPending ? "..." : "بایگانی"}
            </Button>
          </form>
        ) : null}
      </div>
      {markState?.error ? (
        <p className="text-xs text-destructive">{markState.error}</p>
      ) : null}
      {archState?.error ? (
        <p className="text-xs text-destructive">{archState.error}</p>
      ) : null}
    </div>
  );
}
