"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { markAllRead, type InboxActionState } from "@/lib/notify/inbox-actions";
import type { NotificationCategory } from "@/types/database";

export function MarkAllReadForm({ category }: { category: NotificationCategory | null }) {
  const [state, action, pending] = useActionState<InboxActionState | null, FormData>(
    markAllRead,
    null,
  );
  return (
    <form action={action} className="flex flex-col items-end gap-1">
      <input type="hidden" name="category" value={category ?? ""} />
      <Button type="submit" size="sm" variant="outline" disabled={pending}>
        {pending ? "..." : "علامت همه به‌عنوان خوانده‌شده"}
      </Button>
      {state?.ok ? (
        <p className="text-xs text-emerald-600">
          {state.count ?? 0} پیام علامت‌گذاری شد.
        </p>
      ) : null}
      {state?.error ? <p className="text-xs text-destructive">{state.error}</p> : null}
    </form>
  );
}
