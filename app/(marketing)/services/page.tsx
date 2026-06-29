import type { Metadata } from "next";
import { ServicePage } from "@/components/sections/ServicePage";
import { SERVICES_OVERVIEW } from "@/content/services";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({ ...SERVICES_OVERVIEW.seo, path: "/services" });

export default function ServicesPage() {
  return <ServicePage content={SERVICES_OVERVIEW} />;
}
