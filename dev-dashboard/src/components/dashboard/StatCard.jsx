import { motion } from 'framer-motion'

export default function StatCard({ icon: Icon, label, value, gradient }) {
  return (
    <motion.div
      whileHover={{ translateY: -4 }}
      className="card"
    >
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-slate-400 font-medium">{label}</p>
          <p className="text-3xl font-bold text-slate-100 mt-2">{value}</p>
        </div>
        <div className={`p-3 rounded-lg bg-gradient-to-br ${gradient}`}>
          <Icon size={24} className="text-white" />
        </div>
      </div>
    </motion.div>
  )
}
