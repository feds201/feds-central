import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { X, Eye, EyeOff } from 'lucide-react'

export default function EditCredentialModal({ credential, services, onUpdate, onClose }) {
  const [formData, setFormData] = useState({
    service_id: '',
    username: '',
    password_encrypted: '',
    notes: '',
  })
  const [showPassword, setShowPassword] = useState(false)

  useEffect(() => {
    if (credential) {
      setFormData({
        service_id: credential.service_id || '',
        username: credential.username || '',
        password_encrypted: credential.password_encrypted || '',
        notes: credential.notes || '',
      })
    }
  }, [credential])

  const handleSubmit = (e) => {
    e.preventDefault()
    onUpdate(credential.id, formData)
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
          <h2 className="text-2xl font-bold text-slate-100">Edit Credential</h2>
          <button onClick={onClose} className="p-1 hover:bg-slate-800 rounded-lg">
            <X size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-slate-300 mb-2">
              Service *
            </label>
            <select
              required
              value={formData.service_id}
              onChange={(e) => setFormData({ ...formData, service_id: e.target.value })}
              className="input-field"
            >
              <option value="">Select a service</option>
              {services.map((service) => (
                <option key={service.id} value={service.id}>
                  {service.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-300 mb-2">
              Username / Email *
            </label>
            <input
              type="text"
              required
              value={formData.username}
              onChange={(e) => setFormData({ ...formData, username: e.target.value })}
              className="input-field"
              placeholder="user@example.com"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-300 mb-2">
              Password *
            </label>
            <div className="relative">
              <input
                type={showPassword ? 'text' : 'password'}
                required
                value={formData.password_encrypted}
                onChange={(e) =>
                  setFormData({ ...formData, password_encrypted: e.target.value })
                }
                className="input-field pr-12"
                placeholder="Enter password"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-200"
              >
                {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-300 mb-2">Notes</label>
            <textarea
              value={formData.notes}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
              className="input-field resize-none"
              rows="3"
              placeholder="Additional notes..."
            />
          </div>

          <div className="flex gap-2 pt-4">
            <button type="button" onClick={onClose} className="btn-secondary flex-1">
              Cancel
            </button>
            <button type="submit" className="btn-primary flex-1">
              Update Credential
            </button>
          </div>
        </form>
      </motion.div>
    </motion.div>
  )
}
