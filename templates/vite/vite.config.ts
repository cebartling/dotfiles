import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { visualizer } from "rollup-plugin-visualizer";

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react(),
    visualizer({
      filename: "./stats.html",
      template: "sunburst", // 'treemap' or 'sunburst', 'network'
      gzipSize: true,
      brotliSize: true,
      open: false,
      title: "Bundle Analysis",
      projectRoot: process.cwd(),
    }),
  ],
});
