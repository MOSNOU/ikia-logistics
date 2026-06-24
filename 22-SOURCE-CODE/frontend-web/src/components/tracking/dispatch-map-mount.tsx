"use client";

// react-leaflet uses browser-only APIs (window, document) at module init time,
// so the map component is dynamically imported with ssr:false. This wrapper
// runs on the client and lets server routes render placeholders cleanly.
import dynamic from "next/dynamic";
import type { ComponentProps } from "react";

const DispatchMap = dynamic(
  () => import("./dispatch-map").then((m) => m.DispatchMap),
  { ssr: false, loading: () => (
    <div className="h-[480px] flex items-center justify-center rounded-md border text-xs text-muted-foreground">
      در حال بارگذاری نقشه...
    </div>
  ) },
);

export function DispatchMapMount(props: ComponentProps<typeof DispatchMap>) {
  return <DispatchMap {...props} />;
}
