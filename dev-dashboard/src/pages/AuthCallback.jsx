import { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '@/lib/supabase'

export default function AuthCallback() {
  const navigate = useNavigate()

  useEffect(() => {
    const handleAuthCallback = async () => {
      try {
        // Handle the OAuth callback
        const { data, error } = await supabase.auth.getSession()

        if (error) {
          console.error('Auth callback error:', error)
          // Redirect to sign-in page with error
          navigate('/signin', {
            state: { error: 'Authentication failed. Please try again.' }
          })
          return
        }

        if (data.session) {
          // Successfully authenticated, redirect to dashboard
          navigate('/dashboard', { replace: true })
        } else {
          // No session, redirect to sign-in
          navigate('/signin', { replace: true })
        }
      } catch (err) {
        console.error('Unexpected error during auth callback:', err)
        navigate('/signin', {
          state: { error: 'An unexpected error occurred. Please try again.' }
        })
      }
    }

    handleAuthCallback()
  }, [navigate])

  return (
    <div className="flex items-center justify-center h-screen bg-slate-950">
      <div className="text-center space-y-4">
        <div className="animate-spin mx-auto">
          <div className="w-12 h-12 border-4 border-slate-700 border-t-indigo-500 rounded-full"></div>
        </div>
        <p className="text-slate-400">Completing sign-in...</p>
      </div>
    </div>
  )
}