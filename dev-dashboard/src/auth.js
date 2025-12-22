import { BetterAuthReactAdapter } from '@neondatabase/neon-js/auth/react'

// Create auth client with React adapter for hooks (useSession, etc.)
const neonAuthUrl = import.meta.env.VITE_NEON_AUTH_URL

if (!neonAuthUrl) {
  console.error('❌ VITE_NEON_AUTH_URL is not set! Check your .env file.')
}

// Create the adapter instance which provides React hooks
const adapter = neonAuthUrl ? BetterAuthReactAdapter()(neonAuthUrl) : null
export const authClient = adapter?.getBetterAuthInstance() ?? null
