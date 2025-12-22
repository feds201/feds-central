import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { X } from 'lucide-react'

export default function EditServiceModal({ service, onUpdate, onClose }) {
  const [formData, setFormData] = useState({
    name: '',
    url: '',
    description: '',
    tags: [],
  })
  const [tagInput, setTagInput] = useState('')

  useEffect(() => {
    if (service) {
      setFormData({
        name: service.name || '',
        url: service.url || '',
        description: service.description || '',
        tags: service.tags || [],
      })
    }
  }, [service])

  const handleSubmit = (e) => {
    e.preventDefault()
    onUpdate(service.id, formData)
  }

  const addTag = () => {
    if (tagInput.trim() && !formData.tags.includes(tagInput.trim())) {
      setFormData({ ...formData, tags: [...formData.tags, tagInput.trim()] })
      setTagInput('')
    }
  }

  const removeTag = (tagToRemove) => {
    setFormData({ ...formData, tags: formData.tags.filter((tag) => tag !== tagToRemove) })
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
          <h2 className="text-2xl font-bold text-slate-100">Edit Service</h2>
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
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              className="input-field"
              placeholder="GitHub, AWS, etc."
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-300 mb-2">URL</label>
            <input
              type="url"
              value={formData.url}
              onChange={(e) => setFormData({ ...formData, url: e.target.value })}
              className="input-field"
              placeholder="https://example.com"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-300 mb-2">
              Description
            </label>
            <textarea
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              className="input-field resize-none"
              rows="3"
              placeholder="Brief description..."
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-300 mb-2">Tags</label>
            <div className="flex gap-2 mb-2">
              <input
                type="text"
                value={tagInput}
                onChange={(e) => setTagInput(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    e.preventDefault()
                    addTag()
                  }
                }}
                className="input-field flex-1"
                placeholder="Add a tag..."
              />
              <button
                type="button"
                onClick={addTag}
                className="btn-secondary"
              >
                Add
              </button>
            </div>
            <div className="flex flex-wrap gap-2">
              {formData.tags.map((tag, i) => (
                <span
                  key={i}
                  className="badge-primary flex items-center gap-1 cursor-pointer hover:bg-indigo-500/30"
                  onClick={() => removeTag(tag)}
                >
                  {tag}
                  <X size={12} />
                </span>
              ))}
            </div>
          </div>

          <div className="flex gap-2 pt-4">
            <button type="button" onClick={onClose} className="btn-secondary flex-1">
              Cancel
            </button>
            <button type="submit" className="btn-primary flex-1">
              Update Service
            </button>
          </div>
        </form>
      </motion.div>
    </motion.div>
  )
}
