import type { Metadata } from "next";
import { PersonaLanding } from "@/components/sections/PersonaLanding";
import { FORWARDERS } from "@/content/personas";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({ ...FORWARDERS.seo, path: "/forwarders" });

export default function Page() {
  return <PersonaLanding persona={FORWARDERS} />;
}
