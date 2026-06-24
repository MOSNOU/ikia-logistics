"use client";

import { useActionState, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent } from "@/components/ui/card";
import {
  adminForceCancelPreparation,
  adminSupersedePreparation,
  adminForceCancelContract,
  adminSupersedeContract,
  adminVoidContract,
  type ContractAdminActionState,
} from "@/lib/admin/contract-admin-actions";

interface Props {
  id: string;
  kind: "preparation" | "executed";
  status: string;
}

export function AdminForceActions({ id, kind, status }: Props) {
  const [cancelState, cancelAction, cancelPending] =
    useActionState<ContractAdminActionState | null, FormData>(
      kind === "preparation" ? adminForceCancelPreparation : adminForceCancelContract,
      null,
    );
  const [supersedeState, supersedeAction, supersedePending] =
    useActionState<ContractAdminActionState | null, FormData>(
      kind === "preparation" ? adminSupersedePreparation : adminSupersedeContract,
      null,
    );
  const [voidState, voidAction, voidPending] =
    useActionState<ContractAdminActionState | null, FormData>(
      adminVoidContract,
      null,
    );
  const [openForm, setOpenForm] = useState<"cancel" | "supersede" | "void" | null>(null);

  const isTerminal = ["cancelled", "voided", "superseded", "executed"].includes(status);
  const idFieldName = kind === "preparation" ? "preparationId" : "contractId";

  return (
    <Card>
      <CardContent className="p-6 space-y-3">
        <h2 className="text-lg font-semibold">اقدامات اضطراری مدیریت</h2>
        {isTerminal ? (
          <p className="text-xs text-muted-foreground">
            {status === "executed"
              ? "قرارداد اجرا شده — اقدامات اضطراری روی این حالت در دسترس نیست."
              : "پرونده در وضعیت پایانی است — اقدام اضطراری ممکن نیست."}
          </p>
        ) : (
          <>
            <div className="flex flex-wrap gap-2">
              <Button
                type="button"
                size="sm"
                variant="outline"
                onClick={() => setOpenForm(openForm === "cancel" ? null : "cancel")}
              >
                لغو اضطراری
              </Button>
              <Button
                type="button"
                size="sm"
                variant="outline"
                onClick={() => setOpenForm(openForm === "supersede" ? null : "supersede")}
              >
                جایگزینی
              </Button>
              {kind === "executed" ? (
                <Button
                  type="button"
                  size="sm"
                  variant="outline"
                  onClick={() => setOpenForm(openForm === "void" ? null : "void")}
                >
                  ابطال قرارداد
                </Button>
              ) : null}
            </div>

            {openForm === "cancel" ? (
              <form action={cancelAction} className="flex items-end gap-2 w-full max-w-xl">
                <input type="hidden" name={idFieldName} value={id} />
                <Input name="reason" placeholder="دلیل لغو" className="h-9 flex-1" />
                <Button type="submit" size="sm" variant="outline" disabled={cancelPending}>
                  {cancelPending ? "..." : "تأیید لغو"}
                </Button>
              </form>
            ) : null}

            {openForm === "supersede" ? (
              <form action={supersedeAction} className="flex items-end gap-2 w-full max-w-xl">
                <input type="hidden" name={idFieldName} value={id} />
                <Input name="reason" placeholder="دلیل جایگزینی" className="h-9 flex-1" />
                <Button type="submit" size="sm" variant="outline" disabled={supersedePending}>
                  {supersedePending ? "..." : "تأیید جایگزینی"}
                </Button>
              </form>
            ) : null}

            {openForm === "void" && kind === "executed" ? (
              <form action={voidAction} className="flex items-end gap-2 w-full max-w-xl">
                <input type="hidden" name="contractId" value={id} />
                <Input name="reason" placeholder="دلیل ابطال" className="h-9 flex-1" />
                <Button type="submit" size="sm" variant="outline" disabled={voidPending}>
                  {voidPending ? "..." : "تأیید ابطال"}
                </Button>
              </form>
            ) : null}

            {cancelState?.error ? <p className="text-xs text-destructive">{cancelState.error}</p> : null}
            {supersedeState?.error ? <p className="text-xs text-destructive">{supersedeState.error}</p> : null}
            {voidState?.error ? <p className="text-xs text-destructive">{voidState.error}</p> : null}
          </>
        )}
      </CardContent>
    </Card>
  );
}
