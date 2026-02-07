import { motion } from 'framer-motion'

export default function StatCard({ icon: Icon, label, value, gradient }) {
  return (
    <motion.div
      whileHover={{ translateY: -4, scale: 1.02 }}
      whileTap={{ scale: 0.98 }}
      className="card cursor-pointer group"
    >
      <div className="flex items-center justify-between">
        <div className="space-y-1">
          <p className="text-sm text-slate-400 font-semibold uppercase tracking-wide">{label}</p>
          <p className="text-4xl font-bold text-slate-100 tabular-nums">{value}</p>
        </div>
        <motion.div 
          className={`p-4 rounded-2xl bg-gradient-to-br ${gradient} shadow-lg`}
          whileHover={{ rotate: 360 }}
          transition={{ duration: 0.6 }}
        >
          <Icon size={28} className="text-white" strokeWidth={2.5} />
        </motion.div>
      </div>
      <div className="mt-4 pt-4 border-t border-slate-700/50">
        <p className="text-xs text-slate-500 group-hover:text-slate-400 transition-colors">
          View details →
        </p>
      </div>
    </motion.div>
  )
}
