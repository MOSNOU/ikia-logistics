import type { Metadata } from "next";
import { ServicePage } from "@/components/sections/ServicePage";
import { SERVICE_COMPLIANCE } from "@/content/services";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({ ...SERVICE_COMPLIANCE.seo, path: "/services/compliance" });

export default function Page() {
  return <ServicePage content={SERVICE_COMPLIANCE} />;
}
