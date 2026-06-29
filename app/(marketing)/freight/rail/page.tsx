import type { Metadata } from "next";
import { LandingTemplate } from "@/components/sections/LandingTemplate";
import { moduleByKey } from "@/content/siteArchitecture";
import { buildMetadata } from "@/lib/seo";

const MODULE = moduleByKey("rail")!;

export const metadata: Metadata = buildMetadata({
  title: `${MODULE.faTitle} — iKIA`,
  description: MODULE.value,
  path: "/freight/rail",
});

export default function Page() {
  return <LandingTemplate module={MODULE} />;
}
