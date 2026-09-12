import path from "path";
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Pin the workspace root so Turbopack/webpack don't infer it from a
  // stray package-lock.json higher up the filesystem (e.g. a personal
  // profile folder), which otherwise prints a root-inference warning.
  turbopack: {
    root: path.join(__dirname),
  },
};

export default nextConfig;
