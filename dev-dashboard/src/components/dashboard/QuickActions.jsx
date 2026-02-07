import { Link } from 'react-router-dom'
import { motion } from 'framer-motion'
import { Plus, Settings, BarChart3, Database } from 'lucide-react'

export default function QuickActions({ onImportExport }) {
  const actions = [
    {
      label: 'Add Service',
      description: 'Register a new service',
      icon: Plus,
      to: '/services',
      color: 'from-indigo-600 to-indigo-400',
    },
    {
      label: 'Manage Credentials',
      description: 'View & edit credentials',
      icon: Settings,
      to: '/credentials',
      color: 'from-rose-600 to-rose-400',
    },
    {
      label: 'Activity',
      description: 'Check recent actions',
      icon: BarChart3,
      to: '/audit',
      color: 'from-emerald-600 to-emerald-400',
    },
  ]

  return (
    <div className="space-y-3">
      <h2 className="text-lg font-semibold text-slate-100">Quick Actions</h2>
      <div className="space-y-2">
        {actions.map((action, i) => {
          const Icon = action.icon
          return (
            <motion.div
              key={i}
              whileHover={{ x: 4 }}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: i * 0.05 }}
            >
              <Link
                to={action.to}
                className="card flex items-center gap-3 hover:border-slate-600 group"
              >
                <div className={`p-2 rounded-lg bg-gradient-to-br ${action.color}`}>
                  <Icon size={20} className="text-white" />
                </div>
                <div className="flex-1">
                  <p className="font-medium text-slate-100 group-hover:text-white">
                    {action.label}
                  </p>
                  <p className="text-xs text-slate-500">{action.description}</p>
                </div>
              </Link>
            </motion.div>
          )
        })}

        {/* Import/Export Button */}
        {onImportExport && (
          <motion.div
            whileHover={{ x: 4 }}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: actions.length * 0.05 }}
          >
            <button
              onClick={onImportExport}
              className="card flex items-center gap-3 hover:border-slate-600 group w-full text-left"
            >
              <div className="p-2 rounded-lg bg-gradient-to-br from-purple-600 to-pink-400">
                <Database size={20} className="text-white" />
              </div>
              <div className="flex-1">
                <p className="font-medium text-slate-100 group-hover:text-white">
                  Import / Export
                </p>
                <p className="text-xs text-slate-500">Backup or restore data</p>
              </div>
            </button>
          </motion.div>
        )}
      </div>
    </div>
  )
}
