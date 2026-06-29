import type { Metadata } from "next";
import { LandingTemplate } from "@/components/sections/LandingTemplate";
import { moduleByKey } from "@/content/siteArchitecture";
import { buildMetadata } from "@/lib/seo";

const MODULE = moduleByKey("carriers")!;

export const metadata: Metadata = buildMetadata({
  title: `${MODULE.faTitle} — iKIA`,
  description: MODULE.value,
  path: "/solutions/carriers",
});

export default function Page() {
  return <LandingTemplate module={MODULE} />;
}
