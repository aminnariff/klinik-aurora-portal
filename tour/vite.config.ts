import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// The tour is served by the Flutter web build at /tour/.
// `npm run build` writes into ../web/tour, which `flutter build web` copies into build/web.
export default defineConfig({
  base: '/tour/',
  plugins: [react()],
  build: {
    outDir: '../web/tour',
    emptyOutDir: true,
    assetsDir: 'assets',
  },
});
