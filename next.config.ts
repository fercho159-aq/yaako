import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Preserve trailing slashes so API routes like /api/auth/ don't 308-redirect
  skipTrailingSlashRedirect: true,
  // Allow loading scripts from external domains
  async headers() {
    return [
      {
        source: "/(.*)",
        headers: [
          { key: "Access-Control-Allow-Origin", value: "*" },
          {
            key: "Access-Control-Allow-Methods",
            value: "GET, POST, OPTIONS",
          },
          { key: "Access-Control-Allow-Headers", value: "*" },
        ],
      },
    ];
  },
};

export default nextConfig;
