import type { Metadata } from "next";
import { ServicePage } from "@/components/sections/ServicePage";
import { SERVICE_ANALYTICS } from "@/content/services";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({ ...SERVICE_ANALYTICS.seo, path: "/services/analytics" });

export default function Page() {
  return <ServicePage content={SERVICE_ANALYTICS} />;
}
