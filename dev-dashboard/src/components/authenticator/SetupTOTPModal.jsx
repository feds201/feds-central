import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { X, Copy } from 'lucide-react'
import QRCode from 'qrcode.react'
import { TOTP } from 'jsotp'

export default function SetupTOTPModal({ onSetup, onClose }) {
  const [secret, setSecret] = useState('')
  const [recoveryCodes, setRecoveryCodes] = useState([])
  const [step, setStep] = useState('generate')
  const [confirmCode, setConfirmCode] = useState('')
  const [copied, setCopied] = useState(false)

  useEffect(() => {
    generateSecret()
  }, [])

  const generateSecret = () => {
    // Generate a random 32-character base32 secret
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'
    let newSecret = ''
    for (let i = 0; i < 32; i++) {
      newSecret += chars.charAt(Math.floor(Math.random() * chars.length))
    }
    setSecret(newSecret)

    // Generate recovery codes
    const codes = Array.from({ length: 10 }, () =>
      Math.random().toString(36).substring(2, 10).toUpperCase()
    )
    setRecoveryCodes(codes)
  }

  const handleCopy = (text) => {
    navigator.clipboard.writeText(text)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  const handleConfirm = () => {
    if (!confirmCode || confirmCode.length < 6) {
      alert('Please enter a valid 6-digit code')
      return
    }

    try {
      const totpInstance = new TOTP(secret)
      const isValid = totpInstance.verify(confirmCode)
      if (!isValid) {
        alert('Invalid code. Please check your authenticator app and try again.')
        return
      }
      onSetup(secret, recoveryCodes)
    } catch (error) {
      console.error('Error verifying TOTP code:', error)
      alert('Error verifying code. Please try again.')
    }
  }

  const getOtpauthUrl = () => {
    const issuer = encodeURIComponent('FEDS Dev Console')
    const account = encodeURIComponent('user@fedsdevconsole.dev')
    return `otpauth://totp/${issuer}:${account}?secret=${secret}&issuer=${issuer}&algorithm=SHA1&digits=6&period=30`
  }

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      onClick={onClose}
      className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4"
    >
      <motion.div
        initial={{ scale: 0.9, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        onClick={(e) => e.stopPropagation()}
        className="card max-w-md w-full max-h-[90vh] overflow-auto"
      >
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-slate-100">Setup TOTP</h2>
          <button onClick={onClose} className="p-1 hover:bg-slate-800 rounded-lg">
            <X size={20} />
          </button>
        </div>

        {step === 'generate' && (
          <div className="space-y-6">
            <p className="text-slate-300 text-sm">
              Scan this QR code with your authenticator app, or enter the secret key manually.
            </p>

            <div className="flex justify-center">
              <div className="p-4 bg-white rounded-lg">
                <QRCode value={getOtpauthUrl()} size={200} level="H" />
              </div>
            </div>

            <div>
              <p className="text-xs text-slate-400 mb-2">Manual Entry</p>
              <div className="flex items-center gap-2">
                <code className="flex-1 px-3 py-2 rounded-lg bg-slate-800 text-slate-300 font-mono text-sm break-all">
                  {secret}
                </code>
                <button
                  onClick={() => handleCopy(secret)}
                  className="p-2 rounded-lg hover:bg-slate-700 text-slate-400"
                >
                  <Copy size={18} />
                </button>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-300 mb-2">
                Verify Code
              </label>
              <input
                type="text"
                value={confirmCode}
                onChange={(e) => setConfirmCode(e.target.value.slice(0, 6))}
                maxLength="6"
                placeholder="000000"
                className="input-field text-center text-2xl tracking-widest font-mono"
              />
              <p className="text-xs text-slate-500 mt-2">
                Enter the 6-digit code from your authenticator app to verify
              </p>
            </div>

            <button
              onClick={() => setStep('backup')}
              className="btn-primary w-full"
            >
              Next: Backup Codes
            </button>
          </div>
        )}

        {step === 'backup' && (
          <div className="space-y-4">
            <p className="text-slate-300 text-sm">
              Save these recovery codes in a safe place. You can use them if you lose access to your authenticator.
            </p>

            <div className="bg-slate-800/50 border border-slate-700 rounded-lg p-4 space-y-2">
              {recoveryCodes.map((code, i) => (
                <div key={i} className="flex items-center justify-between">
                  <code className="font-mono text-sm text-slate-300">{code}</code>
                  <button
                    onClick={() => handleCopy(code)}
                    className="p-1 hover:bg-slate-700 text-slate-500 hover:text-slate-300"
                  >
                    <Copy size={14} />
                  </button>
                </div>
              ))}
            </div>

            <button
              onClick={() => handleCopy(recoveryCodes.join('\n'))}
              className="btn-secondary w-full"
            >
              {copied ? '✓ Copied!' : 'Copy All Codes'}
            </button>

            <p className="text-xs text-yellow-600 bg-yellow-900/30 border border-yellow-700 rounded p-2">
              ⚠️ Store these codes securely. You won't be able to view them again.
            </p>

            <div className="flex gap-2">
              <button
                onClick={() => setStep('generate')}
                className="btn-secondary flex-1"
              >
                Back
              </button>
              <button
                onClick={handleConfirm}
                className="btn-primary flex-1"
              >
                Confirm Setup
              </button>
            </div>
          </div>
        )}
      </motion.div>
    </motion.div>
  )
}
