import { useState, useEffect } from 'react'
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { supabase } from '@/lib/supabase'
import AuthLayout from '@/components/layout/AuthLayout'
import DashboardLayout from '@/components/layout/DashboardLayout'
import SignIn from '@/pages/SignIn'
import AuthCallback from '@/pages/AuthCallback'
import Dashboard from '@/pages/Dashboard'
import Services from '@/pages/Services'
import Credentials from '@/pages/Credentials'
import Authenticator from '@/pages/Authenticator'
import AuditLog from '@/pages/AuditLog'

function App() {
  const [session, setSession] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Check current session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session)
      setLoading(false)
    })

    // Listen for auth changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session)
    })

    return () => subscription?.unsubscribe()
  }, [])

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen bg-slate-950">
        <div className="animate-spin">
          <div className="w-12 h-12 border-4 border-slate-700 border-t-indigo-500 rounded-full"></div>
        </div>
      </div>
    )
  }

  return (
    <Router future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
      <Routes>
        {!session ? (
          <>
            <Route element={<AuthLayout />}>
              <Route path="/signin" element={<SignIn />} />
              <Route path="/auth/callback" element={<AuthCallback />} />
              <Route path="*" element={<Navigate to="/signin" replace />} />
            </Route>
          </>
        ) : (
          <>
            <Route element={<DashboardLayout session={session} />}>
              <Route path="/dashboard" element={<Dashboard session={session} />} />
              <Route path="/services" element={<Services session={session} />} />
              <Route path="/credentials" element={<Credentials session={session} />} />
              <Route path="/authenticator" element={<Authenticator session={session} />} />
              <Route path="/audit" element={<AuditLog session={session} />} />
              <Route path="*" element={<Navigate to="/dashboard" replace />} />
            </Route>
          </>
        )}
      </Routes>
    </Router>
  )
}

export default App
