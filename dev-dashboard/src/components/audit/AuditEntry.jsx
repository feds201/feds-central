import { formatDistanceToNow } from 'date-fns'
import { motion } from 'framer-motion'
import {
  Shield,
  Lock,
  KeyRound,
  LogIn,
  Trash2,
  Plus,
  RefreshCw,
} from 'lucide-react'

const actionIcons = {
  service_created: Plus,
  service_deleted: Trash2,
  credential_created: Lock,
  credential_deleted: Trash2,
  authenticator_entry_created: KeyRound,
  authenticator_entry_deleted: Trash2,
  totp_setup: RefreshCw,
  user_login: LogIn,
}

const actionLabels = {
  service_created: 'Service created',
  service_deleted: 'Service deleted',
  credential_created: 'Credential added',
  credential_deleted: 'Credential deleted',
  authenticator_entry_created: 'Authenticator added',
  authenticator_entry_deleted: 'Authenticator deleted',
  totp_setup: 'TOTP configured',
  user_login: 'Signed in',
}

export default function AuditEntry({ log }) {
  const Icon = actionIcons[log.action] || Shield
  const label = actionLabels[log.action] || log.action

  return (
    <motion.div
      initial={{ opacity: 0, x: -10 }}
      animate={{ opacity: 1, x: 0 }}
      className="card flex items-start gap-4"
    >
      <div className="p-2 rounded-lg bg-indigo-900/30 text-indigo-400 mt-1">
        <Icon size={20} />
      </div>
      <div className="flex-1">
        <p className="font-medium text-slate-100">{label}</p>
        <p className="text-xs text-slate-500">
          {formatDistanceToNow(new Date(log.created_at), { addSuffix: true })}
        </p>
        {log.details && Object.keys(log.details).length > 0 && (
          <details className="text-xs text-slate-400 mt-2">
            <summary className="cursor-pointer hover:text-slate-300">Details</summary>
            <pre className="bg-slate-800/50 p-2 rounded mt-1 overflow-auto text-xs">
              {JSON.stringify(log.details, null, 2)}
            </pre>
          </details>
        )}
      </div>
    </motion.div>
  )
}
