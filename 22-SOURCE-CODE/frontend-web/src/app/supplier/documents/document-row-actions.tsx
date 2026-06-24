"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { removeMyDocument, type PortalActionState } from "@/lib/supplier/portal-actions";

export function DocumentRowActions({ documentId }: { documentId: string }) {
  const [state, formAction, pending] = useActionState<PortalActionState | null, FormData>(
    removeMyDocument,
    null,
  );
  return (
    <form action={formAction} className="flex items-center gap-2">
      <input type="hidden" name="documentId" value={documentId} />
      <Button type="submit" size="sm" variant="outline" disabled={pending}>
        {pending ? "..." : "حذف"}
      </Button>
      {state?.error ? <span className="text-xs text-destructive">{state.error}</span> : null}
    </form>
  );
}
