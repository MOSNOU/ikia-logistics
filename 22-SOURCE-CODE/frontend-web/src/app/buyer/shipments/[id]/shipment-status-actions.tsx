"use client";

import { useActionState, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  buyerMarkPlanned,
  buyerMarkBooked,
  buyerMarkInTransit,
  buyerMarkArrived,
  buyerMarkDelivered,
  buyerCancelShipment,
  type ShipmentActionState,
} from "@/lib/shipment/buyer-actions";
import type { ShipmentStatus } from "@/types/database";

export function ShipmentStatusActions({
  shipmentId,
  status,
}: {
  shipmentId: string;
  status: ShipmentStatus;
}) {
  const [plannedState, plannedAction, plannedPending] =
    useActionState<ShipmentActionState | null, FormData>(buyerMarkPlanned, null);
  const [bookedState, bookedAction, bookedPending] =
    useActionState<ShipmentActionState | null, FormData>(buyerMarkBooked, null);
  const [transitState, transitAction, transitPending] =
    useActionState<ShipmentActionState | null, FormData>(buyerMarkInTransit, null);
  const [arrivedState, arrivedAction, arrivedPending] =
    useActionState<ShipmentActionState | null, FormData>(buyerMarkArrived, null);
  const [deliveredState, deliveredAction, deliveredPending] =
    useActionState<ShipmentActionState | null, FormData>(buyerMarkDelivered, null);
  const [cancelState, cancelAction, cancelPending] =
    useActionState<ShipmentActionState | null, FormData>(buyerCancelShipment, null);
  const [openForm, setOpenForm] = useState<"book" | "cancel" | null>(null);

  const canPlan = status === "draft";
  const canBook = status === "planned";
  const canTransit = status === "booked";
  const canArrive = status === "in_transit";
  const canDeliver = status === "arrived";
  const canCancel = !["delivered", "cancelled", "closed"].includes(status);

  return (
    <div className="flex flex-col items-end gap-2 w-full max-w-2xl">
      <div className="flex flex-wrap gap-2">
        {canPlan ? (
          <form action={plannedAction}>
            <input type="hidden" name="shipmentId" value={shipmentId} />
            <Button type="submit" size="sm" disabled={plannedPending}>
              {plannedPending ? "..." : "برنامه‌ریزی"}
            </Button>
          </form>
        ) : null}
        {canBook ? (
          <Button
            type="button"
            size="sm"
            onClick={() => setOpenForm(openForm === "book" ? null : "book")}
          >
            رزرو
          </Button>
        ) : null}
        {canTransit ? (
          <form action={transitAction}>
            <input type="hidden" name="shipmentId" value={shipmentId} />
            <Button type="submit" size="sm" disabled={transitPending}>
              {transitPending ? "..." : "شروع حمل"}
            </Button>
          </form>
        ) : null}
        {canArrive ? (
          <form action={arrivedAction}>
            <input type="hidden" name="shipmentId" value={shipmentId} />
            <Button type="submit" size="sm" disabled={arrivedPending}>
              {arrivedPending ? "..." : "علامت‌گذاری رسیده"}
            </Button>
          </form>
        ) : null}
        {canDeliver ? (
          <form action={deliveredAction}>
            <input type="hidden" name="shipmentId" value={shipmentId} />
            <Button type="submit" size="sm" disabled={deliveredPending}>
              {deliveredPending ? "..." : "علامت‌گذاری تحویل‌شده"}
            </Button>
          </form>
        ) : null}
        {canCancel ? (
          <Button
            type="button"
            size="sm"
            variant="outline"
            onClick={() => setOpenForm(openForm === "cancel" ? null : "cancel")}
          >
            لغو
          </Button>
        ) : null}
      </div>

      {openForm === "book" ? (
        <form action={bookedAction} className="grid gap-2 w-full md:grid-cols-3">
          <input type="hidden" name="shipmentId" value={shipmentId} />
          <Input name="carrierName" placeholder="نام حمل‌کننده" className="h-9" />
          <Input name="trackingReference" placeholder="شماره ردیابی" className="h-9" dir="ltr" />
          <Input name="vehicleReference" placeholder="مشخصات وسیله" className="h-9" />
          <div className="md:col-span-3">
            <Button type="submit" size="sm" disabled={bookedPending}>
              {bookedPending ? "..." : "تأیید رزرو"}
            </Button>
          </div>
        </form>
      ) : null}

      {openForm === "cancel" ? (
        <form action={cancelAction} className="flex items-end gap-2 w-full">
          <input type="hidden" name="shipmentId" value={shipmentId} />
          <Input name="reason" placeholder="دلیل لغو" className="h-9 flex-1" />
          <Button type="submit" size="sm" variant="outline" disabled={cancelPending}>
            {cancelPending ? "..." : "تأیید لغو"}
          </Button>
        </form>
      ) : null}

      {plannedState?.error ? <p className="text-xs text-destructive">{plannedState.error}</p> : null}
      {bookedState?.error ? <p className="text-xs text-destructive">{bookedState.error}</p> : null}
      {transitState?.error ? <p className="text-xs text-destructive">{transitState.error}</p> : null}
      {arrivedState?.error ? <p className="text-xs text-destructive">{arrivedState.error}</p> : null}
      {deliveredState?.error ? <p className="text-xs text-destructive">{deliveredState.error}</p> : null}
      {cancelState?.error ? <p className="text-xs text-destructive">{cancelState.error}</p> : null}
    </div>
  );
}
