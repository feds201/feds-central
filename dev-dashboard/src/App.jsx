import { BrowserRouter as Router, Routes, Route, Navigate, useNavigate, Link } from 'react-router-dom'
import { NeonAuthUIProvider, AuthView } from '@neondatabase/neon-js/auth/react'
import { authClient } from '@/auth'
import AuthLayout from '@/components/layout/AuthLayout'
import DashboardLayout from '@/components/layout/DashboardLayout'
import SignIn from '@/pages/SignIn'
import SignUp from '@/pages/SignUp'
import AuthCallback from '@/pages/AuthCallback'
import Dashboard from '@/pages/Dashboard'
import Services from '@/pages/Services'
import Credentials from '@/pages/Credentials'
import Authenticator from '@/pages/Authenticator'
import AuditLog from '@/pages/AuditLog'
import Account from '@/pages/Account'

function AppRoutes() {
  const navigate = useNavigate()
  
  // Check if authClient is available
  if (!authClient) {
    return (
      <div className="flex items-center justify-center h-screen bg-slate-950">
        <div className="text-center space-y-4">
          <p className="text-red-400 text-lg">⚠️ Auth not configured</p>
          <p className="text-slate-400 text-sm">Check VITE_NEON_AUTH_URL in your .env file</p>
        </div>
      </div>
    )
  }

  const { data: sessionData, isPending } = authClient.useSession()

  if (isPending) {
    return (
      <div className="flex items-center justify-center h-screen bg-slate-950">
        <div className="animate-spin">
          <div className="w-12 h-12 border-4 border-slate-700 border-t-indigo-500 rounded-full"></div>
        </div>
      </div>
    )
  }

  const session = sessionData ? { user: sessionData.user, ...sessionData } : null

  return (
    <NeonAuthUIProvider authClient={authClient} navigate={navigate} Link={Link}>
      <Routes>
        {!session ? (
          <>
            <Route element={<AuthLayout />}>
              {/* Neon Auth default paths */}
              <Route path="/sign-in" element={<SignIn />} />
              <Route path="/sign-up" element={<SignUp />} />
              <Route path="/callback" element={<AuthCallback />} />
              <Route path="/auth/callback" element={<AuthCallback />} />

              {/* Back-compat aliases */}
              <Route path="/signin" element={<Navigate to="/sign-in" replace />} />
              <Route path="/signup" element={<Navigate to="/sign-up" replace />} />
              <Route path="/signout" element={<Navigate to="/sign-in" replace />} />

              <Route path="*" element={<Navigate to="/sign-in" replace />} />
            </Route>
          </>
        ) : (
          <>
            <Route element={<DashboardLayout session={session} />}>
              <Route path="/sign-in" element={<Navigate to="/dashboard" replace />} />
              <Route path="/sign-up" element={<Navigate to="/dashboard" replace />} />
              <Route path="/dashboard" element={<Dashboard session={session} />} />
              <Route path="/services" element={<Services session={session} />} />
              <Route path="/credentials" element={<Credentials session={session} />} />
              <Route path="/authenticator" element={<Authenticator session={session} />} />
              <Route path="/audit" element={<AuditLog session={session} />} />
              <Route path="/account" element={<Account session={session} />} />
              <Route path="/signout" element={<AuthView pathname="sign-out" />} />
              <Route path="*" element={<Navigate to="/dashboard" replace />} />
            </Route>
          </>
        )}
      </Routes>
    </NeonAuthUIProvider>
  )
}

function App() {
  return (
    <Router future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
      <AppRoutes />
    </Router>
  )
}

export default App
