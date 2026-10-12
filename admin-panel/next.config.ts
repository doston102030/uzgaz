import path from "path";
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Setup SQL lives next to the panel and must ship with its API route.
  outputFileTracingRoot: path.join(__dirname, ".."),
  outputFileTracingIncludes: {
    "/api/setup-sql": ["../supabase/*_setup.sql"],
  },
  // Pin the workspace root so Turbopack/webpack don't infer it from a
  // stray package-lock.json higher up the filesystem (e.g. a personal
  // profile folder), which otherwise prints a root-inference warning.
  turbopack: {
    root: path.join(__dirname, ".."),
  },
  // The dev-only "N" badge sat on top of the sidebar's status card.
  devIndicators: {
    position: "bottom-right",
  },
};

export default nextConfig;
