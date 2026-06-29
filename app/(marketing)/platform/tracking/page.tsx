import type { Metadata } from "next";
import { ServicePage } from "@/components/sections/ServicePage";
import { PLATFORM_TRACKING } from "@/content/platform";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({ ...PLATFORM_TRACKING.seo, path: "/platform/tracking" });

export default function Page() {
  return <ServicePage content={PLATFORM_TRACKING} />;
}
