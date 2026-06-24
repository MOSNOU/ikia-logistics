"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { archiveNotification, type InboxActionState } from "@/lib/notify/inbox-actions";

export function ArchiveForm({ notificationId }: { notificationId: string }) {
  const [state, action, pending] = useActionState<InboxActionState | null, FormData>(
    archiveNotification,
    null,
  );
  return (
    <form action={action} className="flex flex-col items-end gap-1">
      <input type="hidden" name="notificationId" value={notificationId} />
      <Button type="submit" size="sm" variant="outline" disabled={pending}>
        {pending ? "..." : "بایگانی"}
      </Button>
      {state?.error ? <p className="text-xs text-destructive">{state.error}</p> : null}
    </form>
  );
}
