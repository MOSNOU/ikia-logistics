import type { Metadata } from "next";
import { PersonaLanding } from "@/components/sections/PersonaLanding";
import { ENTERPRISE } from "@/content/personas";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({ ...ENTERPRISE.seo, path: "/enterprise" });

export default function Page() {
  return <PersonaLanding persona={ENTERPRISE} />;
}
