import type { MetadataRoute } from "next";

const BASE = "https://www.ikialogistic.com";

// Public marketing URLs only. Product app (app.ikialogistic.com) and legacy
// root dashboard routes (/login, /admin, …) are intentionally excluded.
const ROUTES: { path: string; priority: number; changeFrequency: MetadataRoute.Sitemap[number]["changeFrequency"] }[] = [
  { path: "/", priority: 1.0, changeFrequency: "weekly" },

  // Platform
  { path: "/platform", priority: 0.9, changeFrequency: "monthly" },
  { path: "/platform/visibility", priority: 0.8, changeFrequency: "monthly" },
  { path: "/platform/control-tower", priority: 0.8, changeFrequency: "monthly" },
  { path: "/platform/order-management", priority: 0.8, changeFrequency: "monthly" },
  { path: "/platform/documents-compliance", priority: 0.8, changeFrequency: "monthly" },
  { path: "/platform/integrations", priority: 0.8, changeFrequency: "monthly" },

  // Corridors
  { path: "/corridors", priority: 0.9, changeFrequency: "monthly" },
  { path: "/corridors/instc", priority: 0.7, changeFrequency: "monthly" },
  { path: "/corridors/east-west", priority: 0.7, changeFrequency: "monthly" },

  // Freight
  { path: "/freight/road", priority: 0.7, changeFrequency: "monthly" },
  { path: "/freight/rail", priority: 0.7, changeFrequency: "monthly" },
  { path: "/freight/ocean", priority: 0.7, changeFrequency: "monthly" },
  { path: "/freight/air", priority: 0.7, changeFrequency: "monthly" },
  { path: "/freight/multimodal", priority: 0.7, changeFrequency: "monthly" },

  // Solutions
  { path: "/solutions/shippers", priority: 0.7, changeFrequency: "monthly" },
  { path: "/solutions/forwarders", priority: 0.7, changeFrequency: "monthly" },
  { path: "/solutions/carriers", priority: 0.7, changeFrequency: "monthly" },
  { path: "/solutions/logistics-hubs", priority: 0.7, changeFrequency: "monthly" },
  { path: "/solutions/enterprise", priority: 0.7, changeFrequency: "monthly" },
  { path: "/solutions/government", priority: 0.7, changeFrequency: "monthly" },

  // Value added
  { path: "/value-added/warehousing", priority: 0.7, changeFrequency: "monthly" },
  { path: "/value-added/insurance", priority: 0.7, changeFrequency: "monthly" },
  { path: "/value-added/finance", priority: 0.7, changeFrequency: "monthly" },
  { path: "/value-added/customs", priority: 0.7, changeFrequency: "monthly" },
  { path: "/value-added/data-ai", priority: 0.7, changeFrequency: "monthly" },

  // Resources & company
  { path: "/developers", priority: 0.7, changeFrequency: "monthly" },
  { path: "/resources", priority: 0.7, changeFrequency: "weekly" },
  { path: "/resources/faq", priority: 0.6, changeFrequency: "monthly" },
  { path: "/resources/blog", priority: 0.6, changeFrequency: "weekly" },
  { path: "/contact", priority: 0.8, changeFrequency: "yearly" },
  { path: "/about", priority: 0.8, changeFrequency: "monthly" },

  // Legal
  { path: "/legal/terms", priority: 0.3, changeFrequency: "yearly" },
  { path: "/legal/privacy", priority: 0.3, changeFrequency: "yearly" },
];

export default function sitemap(): MetadataRoute.Sitemap {
  const lastModified = new Date();
  return ROUTES.map((r) => ({
    url: `${BASE}${r.path}`,
    lastModified,
    changeFrequency: r.changeFrequency,
    priority: r.priority,
  }));
}
