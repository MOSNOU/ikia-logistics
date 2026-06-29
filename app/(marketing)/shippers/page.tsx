import type { Metadata } from "next";
import { PersonaLanding } from "@/components/sections/PersonaLanding";
import { SHIPPERS } from "@/content/personas";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({ ...SHIPPERS.seo, path: "/shippers" });

export default function Page() {
  return <PersonaLanding persona={SHIPPERS} />;
}
