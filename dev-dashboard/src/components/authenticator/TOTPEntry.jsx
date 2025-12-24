import { Trash2, Copy, Check, X } from 'lucide-react'
import { motion } from 'framer-motion'
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

  return (
    <motion.div
      whileHover={{ x: 4 }}
      className="card flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 sm:gap-0"
    >
      <div className="flex-1">
        <div className="flex items-center gap-2">
          <h3 className="text-lg font-semibold text-slate-100">{entry.service_name}</h3>
          {entry.issuer && (
            <span className="badge-primary text-xs">{entry.issuer}</span>
          )}
        </div>
        {entry.account_name && (
          <p className="text-sm text-slate-400 mt-0.5">{entry.account_name}</p>
        )}
        {entry.notes && (
          <p className="text-sm text-slate-500 mt-1">{entry.notes}</p>
        )}
      </div>

      <div className="flex flex-wrap items-center gap-4 w-full sm:w-auto">
        {/* TOTP Code Display */}
        <div className="flex items-center gap-2">
          <div className="text-center">
            <p className="text-xs text-slate-400 mb-1">Code</p>
            <code className="text-2xl font-bold text-emerald-400 font-mono tracking-wider">
              {code}
            </code>
            <p className="text-xs text-slate-500 mt-1">{timeLeft}s / {period}s</p>
          </div>
          <div className="relative w-12 h-12 flex items-center justify-center">
            <svg className="w-full h-full" viewBox="0 0 100 100">
              <circle
                cx="50"
                cy="50"
                r="45"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                className="text-slate-700"
              />
              <circle
                cx="50"
                cy="50"
                r="45"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                className="text-emerald-500 origin-center"
                style={{
                  strokeDasharray: `${(timeLeft / period) * 283} 283`,
                  transform: 'rotate(-90deg)',
                  transition: 'stroke-dasharray 1s linear',
                }}
              />
            </svg>
          </div>
        </div>

        {/* Copy Button */}
        <button
          onClick={handleCopy}
          className="p-2 rounded-lg hover:bg-emerald-950/50 text-emerald-400 transition-colors"
          title={copied ? 'Copied!' : 'Copy code'}
        >
          <Copy size={18} />
        </button>

        {/* Delete Button / Challenge */}
        {isConfirmingDelete ? (
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="flex items-center gap-2 bg-red-950/20 p-1.5 rounded-xl border border-red-500/20"
          >
            <input
              type="text"
              placeholder="12 digits of π"
              className="w-32 px-2 py-1 bg-slate-900/50 border border-slate-700 rounded-lg text-xs text-slate-100 focus:outline-none focus:border-red-500 font-mono"
              value={piAttempt}
              onChange={(e) => setPiAttempt(e.target.value)}
              autoFocus
              onKeyDown={(e) => e.key === 'Enter' && handleConfirmDelete()}
            />
            <div className="flex gap-1">
              <button
                onClick={handleConfirmDelete}
                className="p-1 hover:bg-emerald-950/50 text-emerald-400 rounded-md transition-colors"
                title="Confirm"
              >
                <Check size={16} />
              </button>
              <button
                onClick={() => {
                  setIsConfirmingDelete(false)
                  setPiAttempt('')
                }}
                className="p-1 hover:bg-red-950/50 text-red-400 rounded-md transition-colors"
                title="Cancel"
              >
                <X size={16} />
              </button>
            </div>
          </motion.div>
        ) : (
          <button
            onClick={() => setIsConfirmingDelete(true)}
            className="p-2 rounded-lg hover:bg-red-950/50 text-red-400 transition-colors"
            title="Delete entry"
          >
            <Trash2 size={18} />
          </button>
        )}
      </div>
    </motion.div>
  )
}
