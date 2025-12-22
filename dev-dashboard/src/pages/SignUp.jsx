import { motion } from 'framer-motion'
import { AuthView } from '@neondatabase/neon-js/auth/react'
import { Shield, Sparkles, Zap, Lock } from 'lucide-react'

export default function SignUp() {
  const benefits = [
    { icon: Sparkles, text: 'Free forever', color: 'from-indigo-500 to-purple-500' },
    { icon: Zap, text: 'Instant setup', color: 'from-purple-500 to-pink-500' },
    { icon: Lock, text: 'End-to-end encrypted', color: 'from-pink-500 to-rose-500' },
    { icon: Shield, text: 'TOTP 2FA support', color: 'from-rose-500 to-orange-500' },
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
          initial={{ scale: 0.5, opacity: 0, rotate: -180 }}
          animate={{ scale: 1, opacity: 1, rotate: 0 }}
          transition={{ delay: 0.2, type: 'spring', stiffness: 200 }}
          className="inline-flex p-4 rounded-2xl bg-gradient-to-br from-indigo-500/20 to-purple-500/20 border border-indigo-500/30 glow-effect"
        >
          <Sparkles size={48} className="text-indigo-400" />
        </motion.div>
        <h1 className="text-5xl font-bold gradient-text">Join FEDS</h1>
        <p className="text-slate-400 text-lg">
          Create your account and start securing your credentials today
        </p>
      </div>

      {/* Benefits Grid */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.4 }}
        className="grid grid-cols-2 gap-3"
      >
        {benefits.map((benefit, i) => (
          <motion.div
            key={i}
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.5 + i * 0.1 }}
            className="flex items-center gap-2 p-3 rounded-xl bg-slate-800/40 border border-slate-700/50"
          >
            <div className={`p-2 rounded-lg bg-gradient-to-br ${benefit.color}`}>
              <benefit.icon size={16} className="text-white" />
            </div>
            <span className="text-xs text-slate-300 font-medium">{benefit.text}</span>
          </motion.div>
        ))}
      </motion.div>

      {/* Neon Auth View Card */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.6 }}
        className="card shadow-2xl overflow-hidden"
      >
        <AuthView pathname="sign-up" />
      </motion.div>

      {/* Footer */}
      <motion.p
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.8 }}
        className="text-center text-xs text-slate-500"
      >
        🔒 Securely powered by Neon Auth
      </motion.p>
    </motion.div>
  )
}
