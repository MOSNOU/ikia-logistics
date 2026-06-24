"use client";

import { useActionState, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  adminForceCloseRfq,
  adminForceCancelRfq,
  type RfqAdminActionState,
} from "@/lib/admin/rfq-admin-actions";
import type { RfqStatus } from "@/types/database";

export function ForceRfqActions({
  requestId,
  status,
}: {
  requestId: string;
  status: RfqStatus;
}) {
  const [closeState, closeAction, closePending] =
    useActionState<RfqAdminActionState | null, FormData>(adminForceCloseRfq, null);
  const [cancelState, cancelAction, cancelPending] =
    useActionState<RfqAdminActionState | null, FormData>(adminForceCancelRfq, null);
  const [openForm, setOpenForm] = useState<"close" | "cancel" | null>(null);

  const isTerminal =
    status === "closed" || status === "cancelled" || status === "expired";
  if (isTerminal) {
    return (
      <p className="text-xs text-muted-foreground">
        پرونده در وضعیت پایانی است — اقدام مدیریتی ممکن نیست.
      </p>
    );
  }

  return (
    <div className="flex flex-col items-end gap-2 w-full max-w-md">
      <div className="flex flex-wrap gap-2">
        <Button
          type="button"
          size="sm"
          variant="outline"
          onClick={() => setOpenForm(openForm === "close" ? null : "close")}
        >
          بستن اضطراری
        </Button>
        <Button
          type="button"
          size="sm"
          variant="outline"
          onClick={() => setOpenForm(openForm === "cancel" ? null : "cancel")}
        >
          لغو اضطراری
        </Button>
      </div>

      {openForm === "close" ? (
        <form action={closeAction} className="flex items-end gap-2 w-full">
          <input type="hidden" name="requestId" value={requestId} />
          <Input name="reason" placeholder="دلیل بستن" className="h-9 flex-1" />
          <Button type="submit" size="sm" disabled={closePending}>
            {closePending ? "..." : "تأیید بستن"}
          </Button>
        </form>
      ) : null}

      {openForm === "cancel" ? (
        <form action={cancelAction} className="flex items-end gap-2 w-full">
          <input type="hidden" name="requestId" value={requestId} />
          <Input name="reason" placeholder="دلیل لغو" className="h-9 flex-1" />
          <Button type="submit" size="sm" variant="outline" disabled={cancelPending}>
            {cancelPending ? "..." : "تأیید لغو"}
          </Button>
        </form>
      ) : null}

      {closeState?.error ? <p className="text-xs text-destructive">{closeState.error}</p> : null}
      {cancelState?.error ? <p className="text-xs text-destructive">{cancelState.error}</p> : null}
    </div>
  );
}
