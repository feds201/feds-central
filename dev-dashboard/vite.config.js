import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      buffer: 'buffer',
      crypto: 'crypto-browserify',
      stream: 'stream-browserify',
    },
  },
  define: {
    global: 'globalThis',
    'process.env': {},
    'process': {
      env: {},
      version: '',
      platform: 'browser',
      browser: true,
    },
  },
  optimizeDeps: {
    include: ['buffer', 'crypto-browserify', 'stream-browserify'],
  },
  server: {
    port: 5173,
    open: true,
    host: true, // Allow external access for OAuth redirects
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true,
        secure: false,
      },
    },
  },
})

// docker run --name devdashboard-db -e POSTGRES_PASSWORD=mysecretpassword -d postgres:14.20-alpine3.23