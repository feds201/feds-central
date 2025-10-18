import { useState } from 'react'
import { motion } from 'framer-motion'
import { X } from 'lucide-react'

export default function AddTOTPModal({ onAdd, onClose }) {
  const [formData, setFormData] = useState({
    service_name: '',
    totp_secret: '',
    notes: '',
  })

  const handleSubmit = (e) => {
    e.preventDefault()
    onAdd(formData)
    setFormData({ service_name: '', totp_secret: '', notes: '' })
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

        <form onSubmit={handleSubmit} className="space-y-4">
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
              placeholder="e.g., GitHub, Google"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-300 mb-2">
              Secret Key *
            </label>
            <textarea
              required
              value={formData.totp_secret}
              onChange={(e) => setFormData({ ...formData, totp_secret: e.target.value })}
              className="input-field resize-none font-mono text-xs"
              rows="3"
              placeholder="Your base32-encoded secret key"
            />
            <p className="text-xs text-slate-500 mt-1">
              Paste your TOTP secret key here (usually provided by the service)
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-300 mb-2">
              Notes
            </label>
            <textarea
              value={formData.notes}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
              className="input-field resize-none"
              rows="2"
              placeholder="Additional notes..."
            />
          </div>

          <div className="flex gap-2 pt-4">
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
              Add Entry
            </button>
          </div>
        </form>
      </motion.div>
    </motion.div>
  )
}
