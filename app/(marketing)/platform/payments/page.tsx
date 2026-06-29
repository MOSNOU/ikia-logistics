import type { Metadata } from "next";
import { ServicePage } from "@/components/sections/ServicePage";
import { PLATFORM_PAYMENTS } from "@/content/platform";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({ ...PLATFORM_PAYMENTS.seo, path: "/platform/payments" });

export default function Page() {
  return <ServicePage content={PLATFORM_PAYMENTS} />;
}
