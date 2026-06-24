"use client";

import { useActionState, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent } from "@/components/ui/card";
import {
  adminCloseShipment,
  adminForceCancelShipment,
  type ShipmentAdminActionState,
} from "@/lib/admin/shipment-admin-actions";
import type { ShipmentStatus } from "@/types/database";

export function AdminForceActions({
  shipmentId,
  status,
}: {
  shipmentId: string;
  status: ShipmentStatus;
}) {
  const [closeState, closeAction, closePending] =
    useActionState<ShipmentAdminActionState | null, FormData>(adminCloseShipment, null);
  const [cancelState, cancelAction, cancelPending] =
    useActionState<ShipmentAdminActionState | null, FormData>(adminForceCancelShipment, null);
  const [openForm, setOpenForm] = useState<"close" | "cancel" | null>(null);

  const isTerminal = ["delivered", "cancelled", "closed"].includes(status);

  return (
    <Card>
      <CardContent className="p-6 space-y-3">
        <h2 className="text-lg font-semibold">اقدامات اضطراری مدیریت</h2>
        {isTerminal ? (
          <p className="text-xs text-muted-foreground">
            محموله در وضعیت پایانی است — اقدام اضطراری ممکن نیست.
          </p>
        ) : (
          <>
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
              <form action={closeAction} className="flex items-end gap-2 w-full max-w-xl">
                <input type="hidden" name="shipmentId" value={shipmentId} />
                <Input name="reason" placeholder="دلیل بستن" className="h-9 flex-1" />
                <Button type="submit" size="sm" disabled={closePending}>
                  {closePending ? "..." : "تأیید بستن"}
                </Button>
              </form>
            ) : null}

            {openForm === "cancel" ? (
              <form action={cancelAction} className="flex items-end gap-2 w-full max-w-xl">
                <input type="hidden" name="shipmentId" value={shipmentId} />
                <Input name="reason" placeholder="دلیل لغو" className="h-9 flex-1" />
                <Button type="submit" size="sm" variant="outline" disabled={cancelPending}>
                  {cancelPending ? "..." : "تأیید لغو"}
                </Button>
              </form>
            ) : null}

            {closeState?.error ? <p className="text-xs text-destructive">{closeState.error}</p> : null}
            {cancelState?.error ? <p className="text-xs text-destructive">{cancelState.error}</p> : null}
          </>
        )}
      </CardContent>
    </Card>
  );
}
