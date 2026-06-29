import type { Metadata } from "next";
import { ServicePage } from "@/components/sections/ServicePage";
import { SERVICE_LOAD_MANAGEMENT } from "@/content/services";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({
  ...SERVICE_LOAD_MANAGEMENT.seo,
  path: "/services/load-management",
});

export default function Page() {
  return <ServicePage content={SERVICE_LOAD_MANAGEMENT} />;
}
