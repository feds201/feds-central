import { Trash2 } from 'lucide-react'
import { motion } from 'framer-motion'

export default function ServiceCard({ service, onDelete }) {
  return (
    <motion.div whileHover={{ y: -4 }} className="card space-y-4">
      <div className="flex items-start justify-between">
        <div>
          <h3 className="text-lg font-semibold text-slate-100">{service.name}</h3>
          {service.description && (
            <p className="text-sm text-slate-400 mt-1">{service.description}</p>
          )}
        </div>
        <button
          onClick={() => onDelete(service.id)}
          className="p-2 rounded-lg hover:bg-red-950/50 text-red-400 transition-colors"
        >
          <Trash2 size={18} />
        </button>
      </div>

      {service.url && (
        <div>
          <a
            href={service.url}
            target="_blank"
            rel="noopener noreferrer"
            className="text-sm text-indigo-400 hover:text-indigo-300 truncate block"
          >
            {service.url}
          </a>
        </div>
      )}

      {service.tags && service.tags.length > 0 && (
        <div className="flex flex-wrap gap-2">
          {service.tags.map((tag, i) => (
            <span key={i} className="px-2 py-1 rounded-md bg-indigo-900/30 text-xs text-indigo-300">
              {tag}
            </span>
          ))}
        </div>
      )}
    </motion.div>
  )
}
