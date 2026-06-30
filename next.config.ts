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
  // Temporary redirects (permanent: false → 307) while domains are still being
  // validated; flip to permanent once the marketing domain layout is final.
  async redirects() {
    return [
      { source: "/login", destination: "/", permanent: false },
      { source: "/admin", destination: "/", permanent: false },
      { source: "/admin/:path*", destination: "/", permanent: false },
      { source: "/shipper", destination: "/", permanent: false },
      { source: "/cargo", destination: "/", permanent: false },
      { source: "/cargo/:path*", destination: "/", permanent: false },
      { source: "/carrier", destination: "/", permanent: false },
      { source: "/profile", destination: "/", permanent: false },
      { source: "/bookings", destination: "/", permanent: false },
      { source: "/bookings/:path*", destination: "/", permanent: false },
    ];
  },
};

export default nextConfig;
