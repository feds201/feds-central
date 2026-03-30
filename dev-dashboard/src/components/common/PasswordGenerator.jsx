import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { RefreshCw, Copy, Check, Zap } from 'lucide-react'

export default function PasswordGenerator({ onGenerate, inline = false }) {
  const [password, setPassword] = useState('')
  const [length, setLength] = useState(16)
  const [options, setOptions] = useState({
    uppercase: true,
    lowercase: true,
    numbers: true,
    symbols: true,
  })
  const [strength, setStrength] = useState(0)
  const [copied, setCopied] = useState(false)
  const [isOpen, setIsOpen] = useState(false)

  const charSets = {
    uppercase: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    lowercase: 'abcdefghijklmnopqrstuvwxyz',
    numbers: '0123456789',
    symbols: '!@#$%^&*()_+-=[]{}|;:,.<>?',
  }

  const calculateStrength = (pass) => {
    let score = 0
    if (pass.length >= 12) score += 20
    if (pass.length >= 16) score += 10
    if (pass.length >= 20) score += 10
    if (/[a-z]/.test(pass)) score += 15
    if (/[A-Z]/.test(pass)) score += 15
    if (/[0-9]/.test(pass)) score += 15
    if (/[^a-zA-Z0-9]/.test(pass)) score += 15
    return Math.min(score, 100)
  }

  const generatePassword = () => {
    let charset = ''
    Object.keys(options).forEach((key) => {
      if (options[key]) charset += charSets[key]
    })

    if (charset.length === 0) return

    let newPassword = ''
    const array = new Uint32Array(length)
    crypto.getRandomValues(array)

    for (let i = 0; i < length; i++) {
      newPassword += charset[array[i] % charset.length]
    }

    setPassword(newPassword)
    setStrength(calculateStrength(newPassword))
    if (onGenerate) onGenerate(newPassword)
  }

  useEffect(() => {
    if (password) {
      setStrength(calculateStrength(password))
    }
  }, [password])

  const handleCopy = () => {
    navigator.clipboard.writeText(password)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  const getStrengthColor = () => {
    if (strength >= 80) return 'from-emerald-500 to-green-500'
    if (strength >= 60) return 'from-yellow-500 to-amber-500'
    if (strength >= 40) return 'from-orange-500 to-orange-600'
    return 'from-red-500 to-red-600'
  }

  const getStrengthLabel = () => {
    if (strength >= 80) return 'Very Strong'
    if (strength >= 60) return 'Strong'
    if (strength >= 40) return 'Moderate'
    if (strength >= 20) return 'Weak'
    return 'Very Weak'
  }

  if (inline) {
    return (
      <div className="space-y-3">
        <button
          type="button"
          onClick={() => setIsOpen(!isOpen)}
          className="btn-secondary w-full flex items-center justify-center gap-2"
        >
          <Zap size={16} />
          Password Generator
        </button>

        <AnimatePresence>
          {isOpen && (
            <motion.div
              initial={{ height: 0, opacity: 0 }}
              animate={{ height: 'auto', opacity: 1 }}
              exit={{ height: 0, opacity: 0 }}
              className="space-y-3 overflow-hidden"
            >
              <div className="p-4 rounded-xl bg-slate-800/50 border border-slate-700/50 space-y-3">
                {/* Password Display */}
                {password && (
                  <div className="space-y-2">
                    <div className="flex items-center gap-2">
                      <input
                        type="text"
                        value={password}
                        readOnly
                        className="input-field flex-1 font-mono text-sm"
                      />
                      <button
                        type="button"
                        onClick={handleCopy}
                        className="p-2.5 rounded-lg bg-indigo-600 hover:bg-indigo-700 text-white transition-colors"
                      >
                        {copied ? <Check size={18} /> : <Copy size={18} />}
                      </button>
                    </div>

                    {/* Strength Meter */}
                    <div className="space-y-1">
                      <div className="flex items-center justify-between text-xs">
                        <span className="text-slate-400">Strength</span>
                        <span className={`font-semibold bg-gradient-to-r ${getStrengthColor()} bg-clip-text text-transparent`}>
                          {getStrengthLabel()}
                        </span>
                      </div>
                      <div className="h-2 bg-slate-700 rounded-full overflow-hidden">
                        <motion.div
                          initial={{ width: 0 }}
                          animate={{ width: `${strength}%` }}
                          className={`h-full bg-gradient-to-r ${getStrengthColor()}`}
                        />
                      </div>
                    </div>
                  </div>
                )}

                {/* Length Slider */}
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <label className="text-sm text-slate-300">Length</label>
                    <span className="text-sm font-semibold text-indigo-400">{length}</span>
                  </div>
                  <input
                    type="range"
                    min="8"
                    max="32"
                    value={length}
                    onChange={(e) => setLength(parseInt(e.target.value))}
                    className="w-full accent-indigo-500"
                  />
                </div>

                {/* Options */}
                <div className="grid grid-cols-2 gap-2">
                  {Object.keys(options).map((key) => (
                    <label key={key} className="flex items-center gap-2 text-sm text-slate-300 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={options[key]}
                        onChange={(e) => setOptions({ ...options, [key]: e.target.checked })}
                        className="accent-indigo-500"
                      />
                      <span className="capitalize">{key}</span>
                    </label>
                  ))}
                </div>

                {/* Generate Button */}
                <button
                  type="button"
                  onClick={generatePassword}
                  className="btn-primary w-full flex items-center justify-center gap-2"
                >
                  <RefreshCw size={16} />
                  Generate
                </button>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    )
  }

  // Full modal view (for standalone use)
  return (
    <div className="space-y-4">
      {/* Password Display */}
      {password && (
        <div className="space-y-2">
          <div className="flex items-center gap-2">
            <input
              type="text"
              value={password}
              readOnly
              className="input-field flex-1 font-mono"
            />
            <button
              onClick={handleCopy}
              className="p-3 rounded-lg bg-indigo-600 hover:bg-indigo-700 text-white transition-colors"
            >
              {copied ? <Check size={20} /> : <Copy size={20} />}
            </button>
          </div>

          {/* Strength Meter */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-sm text-slate-400">Password Strength</span>
              <span className={`text-sm font-semibold bg-gradient-to-r ${getStrengthColor()} bg-clip-text text-transparent`}>
                {getStrengthLabel()} ({strength}%)
              </span>
            </div>
            <div className="h-3 bg-slate-700 rounded-full overflow-hidden">
              <motion.div
                initial={{ width: 0 }}
                animate={{ width: `${strength}%` }}
                className={`h-full bg-gradient-to-r ${getStrengthColor()}`}
              />
            </div>
          </div>
        </div>
      )}

      {/* Length Slider */}
      <div>
        <div className="flex items-center justify-between mb-2">
          <label className="text-sm font-medium text-slate-300">Password Length</label>
          <span className="text-sm font-semibold text-indigo-400">{length} characters</span>
        </div>
        <input
          type="range"
          min="8"
          max="32"
          value={length}
          onChange={(e) => setLength(parseInt(e.target.value))}
          className="w-full accent-indigo-500"
        />
      </div>

      {/* Character Options */}
      <div className="grid grid-cols-2 gap-3">
        {Object.keys(options).map((key) => (
          <label key={key} className="flex items-center gap-2 text-sm text-slate-300 cursor-pointer hover:text-slate-100">
            <input
              type="checkbox"
              checked={options[key]}
              onChange={(e) => setOptions({ ...options, [key]: e.target.checked })}
              className="w-4 h-4 accent-indigo-500"
            />
            <span className="capitalize">{key}</span>
          </label>
        ))}
      </div>

      {/* Generate Button */}
      <button
        onClick={generatePassword}
        className="btn-primary w-full flex items-center justify-center gap-2"
      >
        <RefreshCw size={20} />
        Generate Password
      </button>
    </div>
  )
}
