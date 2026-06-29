import type { Metadata } from "next";
import { ServicePage } from "@/components/sections/ServicePage";
import { PLATFORM_MATCHING } from "@/content/platform";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({ ...PLATFORM_MATCHING.seo, path: "/platform/matching" });

export default function Page() {
  return <ServicePage content={PLATFORM_MATCHING} />;
}
