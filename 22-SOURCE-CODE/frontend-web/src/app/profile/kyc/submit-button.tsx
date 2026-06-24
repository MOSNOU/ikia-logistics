"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { submitPersonal, type KycActionState } from "@/lib/kyc/portal-actions";

export function SubmitButton({ verificationId }: { verificationId: string }) {
  const [state, action, pending] = useActionState<KycActionState | null, FormData>(
    submitPersonal,
    null,
  );
  return (
    <form action={action} className="space-y-2">
      <input type="hidden" name="verificationId" value={verificationId} />
      <Button type="submit" disabled={pending}>
        {pending ? "در حال ارسال..." : "ارسال برای بررسی"}
      </Button>
      {state?.error ? <p className="text-xs text-destructive">{state.error}</p> : null}
    </form>
  );
}
