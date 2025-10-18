import { motion } from 'framer-motion'
import { formatDistanceToNow } from 'date-fns'
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

const actionColors = {
  service_created: 'from-indigo-600 to-indigo-400',
  service_deleted: 'from-red-600 to-red-400',
  credential_created: 'from-rose-600 to-rose-400',
  credential_deleted: 'from-red-600 to-red-400',
  authenticator_entry_created: 'from-amber-600 to-amber-400',
  authenticator_entry_deleted: 'from-red-600 to-red-400',
  totp_setup: 'from-emerald-600 to-emerald-400',
  user_login: 'from-blue-600 to-blue-400',
}

export default function RecentActivity({ logs }) {
  return (
    <div className="card">
      <h2 className="text-lg font-semibold text-slate-100 mb-4">Recent Activity</h2>
      {logs.length === 0 ? (
        <p className="text-slate-400 text-sm">No activity yet</p>
      ) : (
        <div className="space-y-3">
          {logs.map((log, i) => {
            const Icon = actionIcons[log.action] || Shield
            const label = actionLabels[log.action] || log.action
            const color = actionColors[log.action] || 'from-slate-600 to-slate-400'
            return (
              <motion.div
                key={log.id}
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: i * 0.05 }}
                className="flex items-start gap-3 pb-3 last:pb-0 last:border-b-0 border-b border-slate-700/50"
              >
                <div className={`p-2 rounded-lg bg-gradient-to-br ${color} mt-0.5`}>
                  <Icon size={16} className="text-white" />
                </div>
                <div className="flex-1">
                  <p className="font-medium text-slate-100">{label}</p>
                  <p className="text-xs text-slate-500">
                    {formatDistanceToNow(new Date(log.created_at), {
                      addSuffix: true,
                    })}
                  </p>
                </div>
              </motion.div>
            )
          })}
        </div>
      )}
    </div>
  )
}
