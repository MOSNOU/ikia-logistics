"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { startPersonal, type KycActionState } from "@/lib/kyc/portal-actions";

export function StartButton() {
  const [state, action, pending] = useActionState<KycActionState | null, FormData>(
    startPersonal,
    null,
  );
  return (
    <form action={action} className="space-y-2">
      <Button type="submit" disabled={pending}>
        {pending ? "در حال شروع..." : "شروع احراز هویت"}
      </Button>
      {state?.error ? <p className="text-xs text-destructive">{state.error}</p> : null}
    </form>
  );
}
