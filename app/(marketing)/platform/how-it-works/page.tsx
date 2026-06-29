import type { Metadata } from "next";
import { ServicePage } from "@/components/sections/ServicePage";
import { PLATFORM_HOW_IT_WORKS } from "@/content/platform";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({
  ...PLATFORM_HOW_IT_WORKS.seo,
  path: "/platform/how-it-works",
});

export default function Page() {
  return <ServicePage content={PLATFORM_HOW_IT_WORKS} />;
}
