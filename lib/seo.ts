import type { Metadata } from "next";

const SITE_URL = "https://www.ikialogistic.com";
const SITE_NAME = "iKIA Logistics";

export type SeoInput = {
  title: string;
  description: string;
  path?: string; // e.g. "/forwarders"
};

// Per-page metadata helper. Keeps Persian SEO copy + OpenGraph consistent.
export function buildMetadata({ title, description, path }: SeoInput): Metadata {
  const url = path ? `${SITE_URL}${path}` : SITE_URL;
  return {
    title,
    description,
    alternates: { canonical: url },
    openGraph: {
      title,
      description,
      url,
      siteName: SITE_NAME,
      locale: "fa_IR",
      type: "website",
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
    },
  };
}
