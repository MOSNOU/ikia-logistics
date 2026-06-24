"use client";

import dynamic from "next/dynamic";
import type { ComponentProps } from "react";

const LiveOpsMap = dynamic(
  () => import("./live-ops-map").then((m) => m.LiveOpsMap),
  { ssr: false, loading: () => (
    <div className="h-[520px] flex items-center justify-center rounded-md border text-xs text-muted-foreground">
      در حال بارگذاری نقشه...
    </div>
  ) },
);

export function LiveOpsMapMount(props: ComponentProps<typeof LiveOpsMap>) {
  return <LiveOpsMap {...props} />;
}
