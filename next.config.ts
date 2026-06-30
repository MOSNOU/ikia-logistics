import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Pin the workspace root to this app so Next does not infer a parent
  // directory from a stray lockfile elsewhere on the machine.
  turbopack: {
    root: __dirname,
  },
  env: {
    NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL || "https://placeholder.supabase.co",
    NEXT_PUBLIC_SUPABASE_ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || "placeholder-key",
  },
  // Block stale legacy product/dashboard routes from the marketing deployment.
  // Domain migration is complete, so these are permanent (308) — crawlers may
  // cache them and the legacy paths now live only on app.ikialogistic.com.
  async redirects() {
    return [
      { source: "/login", destination: "/", permanent: true },
      { source: "/admin", destination: "/", permanent: true },
      { source: "/admin/:path*", destination: "/", permanent: true },
      { source: "/shipper", destination: "/", permanent: true },
      { source: "/cargo", destination: "/", permanent: true },
      { source: "/cargo/:path*", destination: "/", permanent: true },
      { source: "/carrier", destination: "/", permanent: true },
      { source: "/profile", destination: "/", permanent: true },
      { source: "/bookings", destination: "/", permanent: true },
      { source: "/bookings/:path*", destination: "/", permanent: true },
    ];
  },
};

export default nextConfig;
