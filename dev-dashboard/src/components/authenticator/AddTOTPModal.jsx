import { useState } from 'react'
import { motion } from 'framer-motion'
import { X, Eye, EyeOff, Info, Key, Mail, Hash } from 'lucide-react'

export default function AddTOTPModal({ onAdd, onClose }) {
  const [formData, setFormData] = useState({
    service_name: '',
    totp_secret: '',
    totp_period: 30,
    notes: '',
    issuer: '',
    account_name: '',
    digits: 6,
  })
  const [showSecret, setShowSecret] = useState(false)
  const [secretType, setSecretType] = useState('manual') // 'manual' or 'uri'

  const handleSubmit = (e) => {
    e.preventDefault()
    onAdd(formData)
    setFormData({ 
      service_name: '', 
      totp_secret: '', 
      totp_period: 30, 
      notes: '',
      issuer: '',
      account_name: '',
      digits: 6,
    })
  }

  const parseOtpAuthUri = (uri) => {
    try {
      const url = new URL(uri)
      if (url.protocol !== 'otpauth:') throw new Error('Invalid OTP URI')
      
      const type = url.host // totp or hotp
      const path = url.pathname.slice(1) // Remove leading /
      const [issuer, account] = path.includes(':') ? path.split(':') : ['', path]
      
      const params = new URLSearchParams(url.search)
      const secret = params.get('secret')
      const period = params.get('period') || '30'
      const digits = params.get('digits') || '6'
      const issuerParam = params.get('issuer') || issuer
      
      setFormData({
        ...formData,
        service_name: issuerParam || account,
        totp_secret: secret,
        totp_period: parseInt(period),
        issuer: issuerParam,
        account_name: account,
        digits: parseInt(digits),
      })
    } catch (error) {
      alert('Invalid OTP Auth URI. Please check the format.')
    }
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
          <h2 className="text-2xl font-bold text-slate-100">Add TOTP Entry</h2>
          <button onClick={onClose} className="p-1 hover:bg-slate-800 rounded-lg">
            <X size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-5">
          {/* Import Method Toggle */}
          <div className="flex gap-2 p-1 bg-slate-800/50 rounded-xl">
            <button
              type="button"
              onClick={() => setSecretType('manual')}
              className={`flex-1 px-4 py-2 rounded-lg font-medium transition-all ${
                secretType === 'manual'
                  ? 'bg-indigo-600 text-white shadow-lg'
                  : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              <Key size={16} className="inline mr-2" />
              Manual Entry
            </button>
            <button
              type="button"
              onClick={() => setSecretType('uri')}
              className={`flex-1 px-4 py-2 rounded-lg font-medium transition-all ${
                secretType === 'uri'
                  ? 'bg-indigo-600 text-white shadow-lg'
                  : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              <Hash size={16} className="inline mr-2" />
              OTP URI
            </button>
          </div>

          {secretType === 'uri' ? (
            /* OTP Auth URI Input */
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-2 flex items-center gap-2">
                <Hash size={16} />
                OTP Auth URI
              </label>
              <textarea
                value={formData.totp_secret}
                onChange={(e) => {
                  setFormData({ ...formData, totp_secret: e.target.value })
                  if (e.target.value.startsWith('otpauth://')) {
                    parseOtpAuthUri(e.target.value)
                  }
                }}
                className="input-field resize-none font-mono text-xs"
                rows="3"
                placeholder="otpauth://totp/Example:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"
              />
              <p className="text-xs text-slate-500 mt-2 flex items-start gap-1">
                <Info size={14} className="mt-0.5 flex-shrink-0" />
                Paste the complete otpauth:// URI from your QR code
              </p>
            </div>
          ) : (
            <>
              {/* Service Name */}
              <div>
                <label className="block text-sm font-medium text-slate-300 mb-2">
                  Service Name *
                </label>
                <input
                  type="text"
                  required
                  value={formData.service_name}
                  onChange={(e) => setFormData({ ...formData, service_name: e.target.value })}
                  className="input-field"
                  placeholder="e.g., GitHub, Google, AWS"
                />
              </div>

              {/* Account/Email */}
              <div>
                <label className="block text-sm font-medium text-slate-300 mb-2 flex items-center gap-2">
                  <Mail size={16} />
                  Account / Email
                </label>
                <input
                  type="text"
                  value={formData.account_name}
                  onChange={(e) => setFormData({ ...formData, account_name: e.target.value })}
                  className="input-field"
                  placeholder="user@example.com"
                />
              </div>

              {/* Secret Key */}
              <div>
                <label className="block text-sm font-medium text-slate-300 mb-2 flex items-center gap-2">
                  <Key size={16} />
                  Secret Key *
                </label>
                <div className="relative">
                  <input
                    type={showSecret ? 'text' : 'password'}
                    required
                    value={formData.totp_secret}
                    onChange={(e) => setFormData({ ...formData, totp_secret: e.target.value.toUpperCase().replace(/\s/g, '') })}
                    className="input-field font-mono text-sm pr-12"
                    placeholder="JBSWY3DPEHPK3PXP"
                  />
                  <button
                    type="button"
                    onClick={() => setShowSecret(!showSecret)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-200"
                  >
                    {showSecret ? <EyeOff size={18} /> : <Eye size={18} />}
                  </button>
                </div>
                <p className="text-xs text-slate-500 mt-1">
                  Base32-encoded secret (usually 16-32 characters)
                </p>
              </div>

              {/* Advanced Options */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Time Period (sec)
                  </label>
                  <select
                    value={formData.totp_period}
                    onChange={(e) => setFormData({ ...formData, totp_period: parseInt(e.target.value) })}
                    className="input-field"
                  >
                    <option value="15">15s</option>
                    <option value="30">30s (Standard)</option>
                    <option value="60">60s</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Code Digits
                  </label>
                  <select
                    value={formData.digits}
                    onChange={(e) => setFormData({ ...formData, digits: parseInt(e.target.value) })}
                    className="input-field"
                  >
                    <option value="6">6 digits (Standard)</option>
                    <option value="7">7 digits</option>
                    <option value="8">8 digits</option>
                  </select>
                </div>
              </div>
            </>
          )}

          {/* Issuer (for both modes) */}
          {secretType === 'manual' && (
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-2">
                Issuer (Optional)
              </label>
              <input
                type="text"
                value={formData.issuer}
                onChange={(e) => setFormData({ ...formData, issuer: e.target.value })}
                className="input-field"
                placeholder="Organization or service provider"
              />
            </div>
          )}

          {/* Notes */}
          <div>
            <label className="block text-sm font-medium text-slate-300 mb-2">
              Notes
            </label>
            <textarea
              value={formData.notes}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
              className="input-field resize-none"
              rows="2"
              placeholder="Recovery codes, backup info, etc..."
            />
          </div>

          {/* Actions */}
          <div className="flex gap-3 pt-4 border-t border-slate-700/50">
            <button
              type="button"
              onClick={onClose}
              className="btn-secondary flex-1"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="btn-primary flex-1"
            >
              Add TOTP Entry
            </button>
          </div>
        </form>
      </motion.div>
    </motion.div>
  )
}
