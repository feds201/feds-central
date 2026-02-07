import { BrowserRouter as Router, Routes, Route, Navigate, useNavigate, Link } from 'react-router-dom'
import { AuthProvider, useAuth } from '@/auth'
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
import PasswordHealth from '@/pages/PasswordHealth'

function AppRoutes() {
  const { user, loading } = useAuth()

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen bg-slate-950">
        <div className="animate-spin">
          <div className="w-12 h-12 border-4 border-slate-700 border-t-indigo-500 rounded-full"></div>
        </div>
      </div>
    )
  }

  const session = user ? { user } : null

  return (
    <Routes>
      {!session ? (
        <>
          <Route element={<AuthLayout />}>
            <Route path="/sign-in" element={<SignIn />} />
            <Route path="/sign-up" element={<SignUp />} />
            <Route path="/callback" element={<AuthCallback />} />

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
            <Route path="/password-health" element={<PasswordHealth session={session} />} />
            <Route path="/audit" element={<AuditLog session={session} />} />
            <Route path="/account" element={<Account session={session} />} />
            <Route path="/signout" element={<Navigate to="/sign-in" replace />} />
            <Route path="*" element={<Navigate to="/dashboard" replace />} />
          </Route>
        </>
      )}
    </Routes>
  )
}

function App() {
  return (
    <AuthProvider>
      <Router future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <AppRoutes />
      </Router>
    </AuthProvider>
  )
}


export default App
