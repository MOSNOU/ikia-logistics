import type { Metadata } from "next";
import { ServicePage } from "@/components/sections/ServicePage";
import { SERVICE_ROAD_FREIGHT } from "@/content/services";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({
  ...SERVICE_ROAD_FREIGHT.seo,
  path: "/services/road-freight",
});

export default function Page() {
  return <ServicePage content={SERVICE_ROAD_FREIGHT} />;
}
