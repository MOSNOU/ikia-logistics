import type { Metadata } from "next";
import { ServicePage } from "@/components/sections/ServicePage";
import { PLATFORM_OVERVIEW } from "@/content/platform";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({ ...PLATFORM_OVERVIEW.seo, path: "/platform" });

export default function PlatformPage() {
  return <ServicePage content={PLATFORM_OVERVIEW} />;
}
