import { Trash2, Eye, EyeOff, Edit2 } from 'lucide-react'
import { motion } from 'framer-motion'
import { useState } from 'react'

export default function CredentialCard({ credential, services, onDelete, onEdit }) {
  const [showPassword, setShowPassword] = useState(false)
  const service = services.find((s) => s.id === credential.service_id)

  return (
    <motion.div whileHover={{ x: 4 }} className="card flex items-center justify-between">
      <div className="flex-1">
        <div className="flex items-center gap-2">
          <h3 className="text-lg font-semibold text-slate-100">
            {service?.name || 'Unknown Service'}
          </h3>
        </div>
        <p className="text-sm text-slate-400 mt-1">
          Username: <span className="text-slate-200">{credential.username}</span>
        </p>
        <div className="flex items-center gap-2 mt-2">
          <p className="text-sm text-slate-400">Password:</p>
          <code className="text-sm bg-slate-800 px-2 py-1 rounded text-slate-300">
            {showPassword ? credential.password_encrypted : '••••••••'}
          </code>
          <button
            onClick={() => setShowPassword(!showPassword)}
            className="p-1 hover:bg-slate-800 rounded text-slate-400 hover:text-slate-200"
          >
            {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
          </button>
        </div>
        {credential.notes && (
          <p className="text-xs text-slate-500 mt-2">Notes: {credential.notes}</p>
        )}
      </div>

      <div className="flex gap-2">
        <button
          onClick={() => onEdit(credential)}
          className="p-2 rounded-lg hover:bg-indigo-950/50 text-indigo-400 transition-colors"
          title="Edit credential"
        >
          <Edit2 size={18} />
        </button>
        <button
          onClick={() => onDelete(credential.id)}
          className="p-2 rounded-lg hover:bg-red-950/50 text-red-400 transition-colors"
          title="Delete credential"
        >
          <Trash2 size={18} />
        </button>
      </div>
    </motion.div>
  )
}
