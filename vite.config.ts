import { defineConfig } from "vite";
import react from "@vitejs/plugin-react-swc";
import path from "path";

export default defineConfig({
  resolve: { alias: { "@": path.resolve(__dirname, "./src") } },
  base: "/", // Important for Render hosting
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          radix: ['@radix-ui/react-dialog', '@radix-ui/react-dropdown-menu', '@radix-ui/react-toast'],
          query: ['@tanstack/react-query'],
          router: ['react-router-dom']
        }
      }
    },
    chunkSizeWarningLimit: 1000
  },
  define: {
    global: 'globalThis'
  }
});