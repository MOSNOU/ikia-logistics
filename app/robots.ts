import type { MetadataRoute } from "next";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: "*",
        allow: "/",
        disallow: [
          "/login",
          "/admin",
          "/shipper",
          "/cargo",
          "/carrier",
          "/profile",
          "/bookings",
        ],
      },
    ],
    sitemap: "https://www.ikialogistic.com/sitemap.xml",
  };
}
