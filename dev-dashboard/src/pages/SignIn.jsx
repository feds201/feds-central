import { useState } from 'react'
import { motion } from 'framer-motion'
import { Shield, Lock, KeyRound, Activity, Fingerprint, Loader2 } from 'lucide-react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '@/auth'

export default function SignIn() {
  const { login, signInPasskey } = useAuth()
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')

  const handleLogin = async (e) => {
    e.preventDefault()
    setLoading(true)
    setError(null)
    try {
      await login(email, password)
      navigate('/dashboard')
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  const handlePasskeyLogin = async () => {
    if (!email) {
      setError('Please enter your email to sign in with Passkey')
      return
    }
    setLoading(true)
    setError(null)
    try {
      await signInPasskey(email)
      navigate('/dashboard')
    } catch (err) {
      setError(err.message || 'Passkey login failed')
    } finally {
      setLoading(false)
    }
  }

  const features = [
    { icon: Shield, text: 'Secure credential storage', color: 'from-indigo-500 to-purple-500' },
    { icon: Lock, text: 'Service management', color: 'from-purple-500 to-pink-500' },
    { icon: KeyRound, text: 'TOTP authenticators', color: 'from-pink-500 to-rose-500' },
    { icon: Activity, text: 'Audit logging', color: 'from-rose-500 to-orange-500' },
  ]

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6 }}
      className="space-y-8 max-w-md mx-auto"
    >
      {/* Header */}
      <div className="text-center space-y-4">
        <motion.div
          initial={{ scale: 0.5, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ delay: 0.2, type: 'spring', stiffness: 200 }}
          className="inline-flex p-4 rounded-2xl bg-gradient-to-br from-indigo-500/20 to-purple-500/20 border border-indigo-500/30 glow-effect"
        >
          <Shield size={48} className="text-indigo-400" />
        </motion.div>
        <h1 className="text-5xl font-bold gradient-text">FEDS Console</h1>
        <p className="text-slate-400 text-lg">
          Secure Access
        </p>
      </div>

      {/* Features Grid */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.4 }}
        className="grid grid-cols-2 gap-3"
      >
        {features.map((feature, i) => (
          <motion.div
            key={i}
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.5 + i * 0.1 }}
            className="flex items-center gap-2 p-3 rounded-xl bg-slate-800/40 border border-slate-700/50"
          >
            <div className={`p-2 rounded-lg bg-gradient-to-br ${feature.color}`}>
              <feature.icon size={16} className="text-white" />
            </div>
            <span className="text-xs text-slate-300 font-medium">{feature.text}</span>
          </motion.div>
        ))}
      </motion.div>

      {/* Custom Auth Form */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.6 }}
        className="card shadow-2xl overflow-hidden p-6 space-y-6"
      >
        {error && (
          <div className="p-3 bg-red-500/10 border border-red-500/20 rounded-lg text-sm text-red-400 text-center">
            {error}
          </div>
        )}

        <form onSubmit={handleLogin} className="space-y-4">
          <div>
            <label className="text-xs font-bold text-slate-500 uppercase tracking-wider block mb-1">Email Address</label>
            <input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-3 text-slate-200 focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition-all placeholder:text-slate-600"
              placeholder="Enter your email"
            />
          </div>
          <div>
            <label className="text-xs font-bold text-slate-500 uppercase tracking-wider block mb-1">Password</label>
            <input
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-3 text-slate-200 focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition-all placeholder:text-slate-600"
              placeholder="Enter your password"
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            className="w-full btn-primary py-3 flex items-center justify-center gap-2"
          >
            {loading && <Loader2 size={18} className="animate-spin" />}
            Sign In
          </button>
        </form>

        <div className="relative">
          <div className="absolute inset-0 flex items-center"><div className="w-full border-t border-slate-700"></div></div>
          <div className="relative flex justify-center text-xs uppercase"><span className="bg-slate-900 px-2 text-slate-500">Or continue with</span></div>
        </div>

        <button
          onClick={handlePasskeyLogin}
          disabled={loading}
          className="w-full btn-secondary py-3 flex items-center justify-center gap-2"
        >
          <Fingerprint size={18} />
          Sign in with Passkey
        </button>

        <div className="text-center text-sm text-slate-400">
          Don't have an account? <Link to="/sign-up" className="text-indigo-400 hover:text-indigo-300 hover:underline">Sign up</Link>
        </div>
      </motion.div>

      {/* Footer */}
      <motion.p
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.8 }}
        className="text-center text-xs text-slate-500"
      >
        🔒 Securely powered by FEDS Custom Auth
      </motion.p>
    </motion.div>
  )
}
