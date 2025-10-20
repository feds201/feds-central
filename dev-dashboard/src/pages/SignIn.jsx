import { useState, useEffect } from 'react'
import { useLocation } from 'react-router-dom'
import { supabase } from '@/lib/supabase'
import { motion } from 'framer-motion'

export default function SignIn() {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const location = useLocation()

  useEffect(() => {
    // Check if there's an error from the callback
    if (location.state?.error) {
      setError(location.state.error)
    }
  }, [location.state])

  const handleGoogleSignIn = async () => {
    try {
      setLoading(true)
      setError('')
      const { error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: `http://localhost:5173/auth/callback`,
        },
      })
      if (error) throw error
    } catch (err) {
      setError(err.message || 'An error occurred during sign-in')
    } finally {
      setLoading(false)
    }
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6 }}
      className="space-y-8"
    >
      {/* Header */}
      <div className="text-center space-y-2">
        <h1 className="text-4xl font-bold gradient-text">FEDS Dev Console</h1>
        <p className="text-slate-400">
          Your secure command center for managing credentials and authenticators
        </p>
      </div>

      {/* Card */}
      <div className="card space-y-6">
        {/* Features Preview */}
        <div className="grid grid-cols-1 gap-4 py-6">
          {[
            { icon: '🔐', title: 'Secure Auth', desc: 'Google OAuth powered' },
            { icon: '🔑', title: 'Credentials', desc: 'Manage all your secrets' },
            { icon: '⏱️', title: 'TOTP Manager', desc: 'Real-time authenticators' },
          ].map((feature, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: i * 0.1 }}
              className="flex items-center gap-3 p-3 rounded-lg bg-slate-800/50"
            >
              <span className="text-2xl">{feature.icon}</span>
              <div>
                <p className="font-medium text-slate-100">{feature.title}</p>
                <p className="text-xs text-slate-400">{feature.desc}</p>
              </div>
            </motion.div>
          ))}
        </div>

        {/* Error Message */}
        {error && (
          <div className="p-3 rounded-lg bg-red-950/50 border border-red-900/50 text-red-200 text-sm">
            {error}
          </div>
        )}

        {/* Sign In Button */}
        <button
          onClick={handleGoogleSignIn}
          disabled={loading}
          className="w-full py-3 rounded-xl bg-gradient-to-r from-indigo-600 to-rose-600 text-white font-semibold hover:from-indigo-700 hover:to-rose-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all active:scale-95"
        >
          {loading ? (
            <span className="flex items-center justify-center gap-2">
              <div className="animate-spin w-4 h-4 border-2 border-white border-t-transparent rounded-full" />
              Signing in...
            </span>
          ) : (
            <span className="flex items-center justify-center gap-2">
              <span>🔑</span> Sign in with Google
            </span>
          )}
        </button>
      </div>

      {/* Footer */}
      <p className="text-center text-xs text-slate-500">
        By signing in, you agree to our Terms of Service
      </p>
    </motion.div>
  )
}
