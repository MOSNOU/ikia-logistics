"use client";

import { useActionState, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  assignVerification,
  requestInfo,
  approveVerification,
  rejectVerification,
  type KycAdminActionState,
} from "@/lib/admin/kyc-admin-actions";
import type { KycStatus, KycSubjectType } from "@/types/database";

interface VerificationActionsProps {
  verificationId: string;
  subjectType: KycSubjectType;
  status: KycStatus;
}

export function VerificationActions({
  verificationId,
  subjectType,
  status,
}: VerificationActionsProps) {
  const [assignState, assignAction, assignPending] =
    useActionState<KycAdminActionState | null, FormData>(assignVerification, null);
  const [infoState, infoAction, infoPending] =
    useActionState<KycAdminActionState | null, FormData>(requestInfo, null);
  const [approveState, approveAction, approvePending] =
    useActionState<KycAdminActionState | null, FormData>(approveVerification, null);
  const [rejectState, rejectAction, rejectPending] =
    useActionState<KycAdminActionState | null, FormData>(rejectVerification, null);

  const [openForm, setOpenForm] = useState<"info" | "approve" | "reject" | null>(null);

  const sharedHidden = (
    <>
      <input type="hidden" name="verificationId" value={verificationId} />
      <input type="hidden" name="subjectType" value={subjectType} />
    </>
  );

  return (
    <div className="flex flex-col items-end gap-2">
      <div className="flex flex-wrap gap-2">
        {status === "submitted" ? (
          <form action={assignAction}>
            {sharedHidden}
            <Button type="submit" size="sm" disabled={assignPending}>
              {assignPending ? "..." : "ارجاع به خودم"}
            </Button>
          </form>
        ) : null}

        {status === "in_review" ? (
          <>
            <Button
              size="sm"
              variant="outline"
              type="button"
              onClick={() => setOpenForm(openForm === "info" ? null : "info")}
            >
              درخواست اطلاعات
            </Button>
            <Button
              size="sm"
              type="button"
              onClick={() => setOpenForm(openForm === "approve" ? null : "approve")}
            >
              تأیید
            </Button>
            <Button
              size="sm"
              variant="outline"
              type="button"
              onClick={() => setOpenForm(openForm === "reject" ? null : "reject")}
            >
              رد
            </Button>
          </>
        ) : null}
      </div>

      {openForm === "info" ? (
        <form action={infoAction} className="flex items-end gap-2 w-full max-w-md">
          {sharedHidden}
          <Input name="reason" required placeholder="دلیل درخواست" className="h-9" />
          <Button type="submit" size="sm" variant="outline" disabled={infoPending}>
            {infoPending ? "..." : "ارسال"}
          </Button>
        </form>
      ) : null}

      {openForm === "approve" ? (
        <form action={approveAction} className="flex items-end gap-2 w-full max-w-md">
          {sharedHidden}
          <Input
            name="validityMonths"
            type="number"
            min={1}
            defaultValue={12}
            className="h-9 w-24"
            dir="ltr"
          />
          <span className="text-xs text-muted-foreground">ماه اعتبار</span>
          <Button type="submit" size="sm" disabled={approvePending}>
            {approvePending ? "..." : "تأیید نهایی"}
          </Button>
        </form>
      ) : null}

      {openForm === "reject" ? (
        <form action={rejectAction} className="flex items-end gap-2 w-full max-w-md">
          {sharedHidden}
          <Input name="reason" required placeholder="دلیل رد" className="h-9" />
          <Button type="submit" size="sm" variant="outline" disabled={rejectPending}>
            {rejectPending ? "..." : "تأیید رد"}
          </Button>
        </form>
      ) : null}

      {assignState?.error ? (
        <p className="text-xs text-destructive">{assignState.error}</p>
      ) : null}
      {infoState?.error ? (
        <p className="text-xs text-destructive">{infoState.error}</p>
      ) : null}
      {approveState?.error ? (
        <p className="text-xs text-destructive">{approveState.error}</p>
      ) : null}
      {rejectState?.error ? (
        <p className="text-xs text-destructive">{rejectState.error}</p>
      ) : null}
    </div>
  );
}
