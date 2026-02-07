import { Trash2, Copy, Check, X, Shield } from 'lucide-react'
import { motion, AnimatePresence } from 'framer-motion'
import { useState, useEffect } from 'react'
import * as OTPAuth from 'otpauth'

export default function TOTPEntry({ entry, onDelete }) {
  const [code, setCode] = useState('')
  const [timeLeft, setTimeLeft] = useState(30)
  const [copied, setCopied] = useState(false)
  const [isConfirmingDelete, setIsConfirmingDelete] = useState(false)
  const [piAttempt, setPiAttempt] = useState('')
  const PI_12 = "314159265358"

  const period = entry?.totp_period || 30
  const digits = entry?.digits || 6

  useEffect(() => {
    let totpInstance = null

    const generateCode = () => {
      if (!entry?.totp_secret || typeof entry.totp_secret !== 'string' || entry.totp_secret.trim() === '') {
        setCode('NO SECRET')
        return null
      }
      try {
        // Ensure the secret is properly formatted
        const secret = entry.totp_secret.trim().toUpperCase().replace(/[^A-Z2-7]/g, '')
        if (secret.length < 16) {
          setCode('INVALID')
          return null
        }

        // Create TOTP instance with otpauth
        const totp = new OTPAuth.TOTP({
          issuer: entry.issuer || entry.service_name,
          label: entry.account_name || 'Account',
          algorithm: 'SHA1',
          digits: digits,
          period: period,
          secret: secret,
        })

        const newCode = totp.generate()
        setCode(newCode)
        return totp
      } catch (error) {
        console.error('Error generating TOTP code:', error)
        setCode('ERROR')
        return null
      }
    }

    const updateTimer = () => {
      // Calculate actual remaining time based on Unix epoch and period
      const now = Math.floor(Date.now() / 1000) // Current Unix timestamp in seconds
      const currentPeriod = Math.floor(now / period)
      const nextPeriodStart = (currentPeriod + 1) * period
      const remaining = nextPeriodStart - now

      setTimeLeft(remaining)

      // Regenerate code when period changes (when remaining === period)
      if (remaining === period) {
        totpInstance = generateCode()
      }
    }

    // Initial generation
    totpInstance = generateCode()
    updateTimer()

    // Update timer every 100ms for smooth countdown and accuracy
    const interval = setInterval(updateTimer, 100)

    return () => clearInterval(interval)
  }, [entry?.totp_secret, entry?.service_name, entry?.issuer, entry?.account_name, period, digits])

  const handleCopy = () => {
    navigator.clipboard.writeText(code)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  const handleConfirmDelete = () => {
    // Remove dots if the user included them
    const cleanedAttempt = piAttempt.replace(/\./g, '')
    if (cleanedAttempt === PI_12) {
      onDelete(entry.id)
    } else {
      // Small shake effect or visual feedback could be added here
      setPiAttempt('')
    }
  }

  // Calculate progress percentage for color transitions
  const progressPercent = (timeLeft / period) * 100
  const isExpiringSoon = timeLeft <= 5

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      whileHover={{ y: -6, scale: 1.02 }}
      transition={{ duration: 0.2 }}
      className="relative group h-full"
    >
      {/* Gradient border effect */}
      <div className="absolute -inset-0.5 bg-gradient-to-br from-indigo-500/20 via-purple-500/20 to-pink-500/20 rounded-2xl blur opacity-0 group-hover:opacity-100 transition-opacity duration-300" />

      {/* Main card */}
      <div className="relative h-full bg-gradient-to-br from-slate-800/90 to-slate-900/90 backdrop-blur-xl rounded-2xl border border-slate-700/50 overflow-hidden">
        {/* Subtle background pattern */}
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_30%_20%,rgba(99,102,241,0.05),transparent_50%)]" />

        {/* Content */}
        <div className="relative p-6 flex flex-col h-full">
          {/* Header */}
          <div className="flex items-start justify-between mb-6">
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2.5 mb-1.5">
                <div className="flex items-center justify-center w-8 h-8 rounded-lg bg-gradient-to-br from-indigo-500/20 to-purple-500/20 border border-indigo-500/30">
                  <Shield className="w-4 h-4 text-indigo-400" />
                </div>
                <h3 className="text-lg font-bold text-white truncate">
                  {entry.service_name}
                </h3>
              </div>
              {entry.account_name && (
                <p className="text-sm text-slate-400 ml-10 truncate">{entry.account_name}</p>
              )}
            </div>
            {entry.issuer && (
              <span className="px-2.5 py-1 text-[10px] font-semibold bg-gradient-to-r from-indigo-500/20 to-purple-500/20 text-indigo-300 rounded-full border border-indigo-500/30 whitespace-nowrap">
                {entry.issuer}
              </span>
            )}
          </div>

          {/* TOTP Code Display - Centered & Prominent */}
          <div className="flex-1 flex flex-col items-center justify-center py-4">
            {/* Timer Circle */}
            <div className="relative mb-4">
              <svg className="w-48 h-48 -rotate-90" viewBox="0 0 250 250">
                {/* Background circle */}
                <circle
                  cx="125"
                  cy="125"
                  r="110"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="6"
                  className="text-slate-700/30"
                />
                {/* Progress circle with gradient */}
                <circle
                  cx="125"
                  cy="125"
                  r="110"
                  fill="none"
                  stroke={`url(#gradient-${entry.id})`}
                  strokeWidth="6"
                  strokeLinecap="round"
                  className={`transition-all duration-1000 ${isExpiringSoon ? 'animate-pulse' : ''}`}
                  style={{
                    strokeDasharray: `${(timeLeft / period) * 690.8} 690.8`,
                  }}
                />
                <defs>
                  <linearGradient id={`gradient-${entry.id}`} x1="0%" y1="0%" x2="100%" y2="100%">
                    {isExpiringSoon ? (
                      <>
                        <stop offset="0%" stopColor="#f87171" />
                        <stop offset="100%" stopColor="#fb923c" />
                      </>
                    ) : (
                      <>
                        <stop offset="0%" stopColor="#34d399" />
                        <stop offset="100%" stopColor="#22d3ee" />
                      </>
                    )}
                  </linearGradient>
                </defs>
              </svg>

              {/* Code in center of circle */}
              <div className="absolute inset-0 flex items-center justify-center">
                <div className="text-center">
                  <motion.div
                    key={code}
                    initial={{ scale: 1.1, opacity: 0 }}
                    animate={{ scale: 1, opacity: 1 }}
                    transition={{ duration: 0.3 }}
                  >
                    <code className={`text-3xl font-bold font-mono tracking-wider ${isExpiringSoon
                      ? 'text-transparent bg-clip-text bg-gradient-to-r from-red-400 to-orange-400'
                      : 'text-transparent bg-clip-text bg-gradient-to-r from-emerald-400 to-cyan-400'
                      }`}>
                      {code}
                    </code>
                  </motion.div>
                  <p className="text-xs text-slate-500 mt-2 font-medium">
                    {timeLeft}s
                  </p>
                </div>
              </div>
            </div>

            {entry.notes && (
              <p className="text-xs text-slate-500 text-center mt-2 px-4">{entry.notes}</p>
            )}
          </div>

          {/* Action Buttons */}
          <div className="flex items-center justify-center gap-2 pt-4 border-t border-slate-700/50">
            <AnimatePresence mode="wait">
              {isConfirmingDelete ? (
                <motion.div
                  key="delete-confirm"
                  initial={{ opacity: 0, scale: 0.9 }}
                  animate={{ opacity: 1, scale: 1 }}
                  exit={{ opacity: 0, scale: 0.9 }}
                  className="flex items-center gap-2 bg-gradient-to-r from-red-950/40 to-orange-950/40 p-2 rounded-xl border border-red-500/30 backdrop-blur-sm w-full"
                >
                  <input
                    type="text"
                    placeholder="12 digits of π"
                    className="flex-1 px-3 py-1.5 bg-slate-900/80 border border-slate-700/50 rounded-lg text-xs text-slate-100 placeholder:text-slate-600 focus:outline-none focus:border-red-500/50 focus:ring-2 focus:ring-red-500/20 font-mono"
                    value={piAttempt}
                    onChange={(e) => setPiAttempt(e.target.value)}
                    autoFocus
                    onKeyDown={(e) => e.key === 'Enter' && handleConfirmDelete()}
                  />
                  <div className="flex gap-1">
                    <motion.button
                      whileHover={{ scale: 1.1 }}
                      whileTap={{ scale: 0.95 }}
                      onClick={handleConfirmDelete}
                      className="p-1.5 bg-emerald-500/20 hover:bg-emerald-500/30 text-emerald-400 rounded-lg transition-colors"
                      title="Confirm"
                    >
                      <Check size={16} />
                    </motion.button>
                    <motion.button
                      whileHover={{ scale: 1.1 }}
                      whileTap={{ scale: 0.95 }}
                      onClick={() => {
                        setIsConfirmingDelete(false)
                        setPiAttempt('')
                      }}
                      className="p-1.5 bg-red-500/20 hover:bg-red-500/30 text-red-400 rounded-lg transition-colors"
                      title="Cancel"
                    >
                      <X size={16} />
                    </motion.button>
                  </div>
                </motion.div>
              ) : (
                <motion.div
                  key="action-buttons"
                  initial={{ opacity: 0, scale: 0.9 }}
                  animate={{ opacity: 1, scale: 1 }}
                  exit={{ opacity: 0, scale: 0.9 }}
                  className="flex items-center gap-2"
                >
                  <motion.button
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                    onClick={handleCopy}
                    className={`flex items-center gap-2 px-4 py-2 rounded-xl font-medium text-sm transition-all ${copied
                      ? 'bg-gradient-to-r from-emerald-500/20 to-cyan-500/20 text-emerald-400 border border-emerald-500/30'
                      : 'bg-slate-800/50 hover:bg-slate-700/50 text-slate-300 hover:text-white border border-slate-600/50'
                      }`}
                    title={copied ? 'Copied!' : 'Copy code'}
                  >
                    {copied ? (
                      <>
                        <Check size={16} />
                        <span className="text-xs">Copied!</span>
                      </>
                    ) : (
                      <>
                        <Copy size={16} />
                        <span className="text-xs">Copy</span>
                      </>
                    )}
                  </motion.button>

                  <motion.button
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                    onClick={() => setIsConfirmingDelete(true)}
                    className="p-2 rounded-xl bg-slate-800/50 hover:bg-red-950/30 text-slate-400 hover:text-red-400 transition-all border border-slate-600/50 hover:border-red-500/30"
                    title="Delete entry"
                  >
                    <Trash2 size={16} />
                  </motion.button>
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        </div>
      </div>
    </motion.div>
  )
}
