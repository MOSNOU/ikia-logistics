"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import {
  acceptBookingAsCarrier,
  cancelBookingAsAdmin,
  cancelBookingAsBuyer,
  confirmBooking,
  rejectBookingAsCarrier,
  type BookingActionState,
} from "@/lib/marketplace/booking-actions";
import type { BookingStatus } from "@/types/database";

interface Props {
  bookingId: string;
  audience: "buyer" | "carrier" | "admin";
  status: BookingStatus;
}

function BuyerActions({ bookingId, status }: { bookingId: string; status: BookingStatus }) {
  const [confirmState, confirmAction, confirmPending] = useActionState<
    BookingActionState | null,
    FormData
  >(confirmBooking, null);
  const [cancelState, cancelAction, cancelPending] = useActionState<
    BookingActionState | null,
    FormData
  >(cancelBookingAsBuyer, null);
  const canConfirm = status === "carrier_accepted";
  const canCancel = status === "pending_carrier" || status === "carrier_accepted";
  return (
    <Card>
      <CardContent className="p-4 space-y-4">
        <div className="text-sm font-medium">اقدامات خریدار</div>
        {canConfirm ? (
          <form action={confirmAction} className="flex items-end gap-3">
            <input type="hidden" name="bookingId" value={bookingId} />
            <Button type="submit" disabled={confirmPending}>
              {confirmPending ? "..." : "تأیید رزرو"}
            </Button>
            {confirmState?.error ? (
              <span className="text-xs text-amber-600">{confirmState.error}</span>
            ) : null}
            {confirmState?.ok ? (
              <span className="text-xs text-emerald-600">تأیید شد.</span>
            ) : null}
          </form>
        ) : null}
        {canCancel ? (
          <form action={cancelAction} className="flex flex-wrap items-end gap-3">
            <input type="hidden" name="bookingId" value={bookingId} />
            <Field htmlFor="reason" label="دلیل لغو (اختیاری)">
              <Input id="reason" name="reason" />
            </Field>
            <Button type="submit" variant="outline" disabled={cancelPending}>
              {cancelPending ? "..." : "لغو رزرو"}
            </Button>
            {cancelState?.error ? (
              <span className="text-xs text-amber-600">{cancelState.error}</span>
            ) : null}
            {cancelState?.ok ? (
              <span className="text-xs text-emerald-600">لغو شد.</span>
            ) : null}
          </form>
        ) : null}
        {!canConfirm && !canCancel ? (
          <p className="text-xs text-muted-foreground">
            در وضعیت فعلی اقدامی برای خریدار قابل اجرا نیست.
          </p>
        ) : null}
      </CardContent>
    </Card>
  );
}

function CarrierActions({ bookingId, status }: { bookingId: string; status: BookingStatus }) {
  const [acceptState, acceptAction, acceptPending] = useActionState<
    BookingActionState | null,
    FormData
  >(acceptBookingAsCarrier, null);
  const [rejectState, rejectAction, rejectPending] = useActionState<
    BookingActionState | null,
    FormData
  >(rejectBookingAsCarrier, null);
  const canRespond = status === "pending_carrier";
  return (
    <Card>
      <CardContent className="p-4 space-y-4">
        <div className="text-sm font-medium">اقدامات حمل‌کننده</div>
        {!canRespond ? (
          <p className="text-xs text-muted-foreground">
            در وضعیت فعلی اقدامی برای حمل‌کننده قابل اجرا نیست.
          </p>
        ) : (
          <>
            <form action={acceptAction} className="flex flex-wrap items-end gap-3">
              <input type="hidden" name="bookingId" value={bookingId} />
              <Field htmlFor="notes" label="یادداشت (اختیاری)">
                <Input id="notes" name="notes" />
              </Field>
              <Button type="submit" disabled={acceptPending}>
                {acceptPending ? "..." : "پذیرش"}
              </Button>
              {acceptState?.error ? (
                <span className="text-xs text-amber-600">{acceptState.error}</span>
              ) : null}
              {acceptState?.ok ? (
                <span className="text-xs text-emerald-600">پذیرفته شد.</span>
              ) : null}
            </form>
            <form action={rejectAction} className="flex flex-wrap items-end gap-3">
              <input type="hidden" name="bookingId" value={bookingId} />
              <Field htmlFor="reason" label="دلیل رد (اختیاری)">
                <Input id="reason" name="reason" />
              </Field>
              <Button type="submit" variant="outline" disabled={rejectPending}>
                {rejectPending ? "..." : "رد"}
              </Button>
              {rejectState?.error ? (
                <span className="text-xs text-amber-600">{rejectState.error}</span>
              ) : null}
              {rejectState?.ok ? (
                <span className="text-xs text-emerald-600">رد شد.</span>
              ) : null}
            </form>
          </>
        )}
      </CardContent>
    </Card>
  );
}

function AdminActions({ bookingId, status }: { bookingId: string; status: BookingStatus }) {
  const [state, action, pending] = useActionState<BookingActionState | null, FormData>(
    cancelBookingAsAdmin,
    null,
  );
  const canCancel = !["carrier_rejected", "buyer_confirmed", "buyer_cancelled", "expired"].includes(
    status,
  );
  return (
    <Card>
      <CardContent className="p-4 space-y-4">
        <div className="text-sm font-medium">اقدامات ادمین (فقط لغو)</div>
        {!canCancel ? (
          <p className="text-xs text-muted-foreground">
            رزرو در وضعیت پایانی است و امکان لغو ادمین وجود ندارد.
          </p>
        ) : (
          <form action={action} className="flex flex-wrap items-end gap-3">
            <input type="hidden" name="bookingId" value={bookingId} />
            <Field htmlFor="reason" label="دلیل لغو ادمین">
              <Input id="reason" name="reason" required />
            </Field>
            <Button type="submit" variant="outline" disabled={pending}>
              {pending ? "..." : "لغو با تصمیم ادمین"}
            </Button>
            {state?.error ? (
              <span className="text-xs text-amber-600">{state.error}</span>
            ) : null}
            {state?.ok ? (
              <span className="text-xs text-emerald-600">لغو شد.</span>
            ) : null}
          </form>
        )}
      </CardContent>
    </Card>
  );
}

export function BookingActionButtons({ bookingId, audience, status }: Props) {
  if (audience === "buyer") return <BuyerActions bookingId={bookingId} status={status} />;
  if (audience === "carrier") return <CarrierActions bookingId={bookingId} status={status} />;
  return <AdminActions bookingId={bookingId} status={status} />;
}
