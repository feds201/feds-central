import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { Plus } from 'lucide-react'
import { db } from '@/lib/db'
import ServiceCard from '@/components/services/ServiceCard'
import AddServiceModal from '@/components/services/AddServiceModal'
import EditServiceModal from '@/components/services/EditServiceModal'

export default function Services({ session }) {
  const [services, setServices] = useState([])
  const [loading, setLoading] = useState(true)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [editingService, setEditingService] = useState(null)

  useEffect(() => {
    fetchServices()
  }, [session])

  const fetchServices = async () => {
    if (!session?.user?.id) {
      setLoading(false)
      return
    }

    try {
      setLoading(true)
      const userId = session.user.id
      const data = await db('SELECT * FROM services WHERE owner_id = $1 ORDER BY created_at DESC', [userId])
      setServices(data || [])
    } catch (error) {
      console.error('Error fetching services:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleAddService = async (newService) => {
    if (!session?.user?.id) {
      console.error('No authenticated user session')
      return
    }

    try {
      const userId = session.user.id

      // Insert Service
      // Note: This relies on the table having DEFAULT gen_random_uuid() for id and now() for created_at
      const result = await db(
        `INSERT INTO services (name, url, description, tags, owner_id) 
         VALUES ($1, $2, $3, $4, $5) 
         RETURNING *`,
        [newService.name, newService.url, newService.description, newService.tags, userId]
      )

      if (!result || result.length === 0) throw new Error('Failed to create service')
      const createdService = result[0]

      // Log audit event
      await db(
        `INSERT INTO audit_logs (user_id, action, details) VALUES ($1, $2, $3)`,
        [userId, 'service_created', JSON.stringify({ service_id: createdService.id, name: newService.name })]
      )

      setServices([createdService, ...services])
      setIsModalOpen(false)
    } catch (error) {
      console.error('Error adding service:', error)
    }
  }

  const handleUpdateService = async (serviceId, updatedData) => {
    if (!session?.user?.id) {
      console.error('No authenticated user session')
      return
    }

    try {
      const userId = session.user.id

      const result = await db(
        `UPDATE services 
         SET name = $1, url = $2, description = $3, tags = $4, updated_at = now()
         WHERE id = $5 AND owner_id = $6
         RETURNING *`,
        [updatedData.name, updatedData.url, updatedData.description, updatedData.tags, serviceId, userId]
      )

      if (!result || result.length === 0) throw new Error('Failed to update service')
      const updated = result[0]

      // Log audit event
      await db(
        `INSERT INTO audit_logs (user_id, action, details) VALUES ($1, $2, $3)`,
        [userId, 'service_updated', JSON.stringify({ service_id: serviceId, name: updatedData.name })]
      )

      setServices(services.map((s) => (s.id === serviceId ? updated : s)))
      setEditingService(null)
    } catch (error) {
      console.error('Error updating service:', error)
    }
  }

  const handleDeleteService = async (id) => {
    if (!session?.user?.id) {
      console.error('No authenticated user session')
      return
    }

    try {
      await db('DELETE FROM services WHERE id = $1', [id])

      // Log audit event
      await db(
        `INSERT INTO audit_logs (user_id, action, details) VALUES ($1, $2, $3)`,
        [session.user.id, 'service_deleted', JSON.stringify({ service_id: id })]
      )

      setServices(services.filter((s) => s.id !== id))
    } catch (error) {
      console.error('Error deleting service:', error)
    }
  }

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-slate-100">Services</h1>
          <p className="text-slate-400 mt-1">Manage your connected services</p>
        </div>
        <button
          onClick={() => setIsModalOpen(true)}
          className="btn-primary flex items-center gap-2"
        >
          <Plus size={20} />
          Add Service
        </button>
      </div>

      {/* Loading State */}
      {loading && (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin">
            <div className="w-12 h-12 border-4 border-slate-700 border-t-indigo-500 rounded-full"></div>
          </div>
        </div>
      )}

      {/* Services Grid */}
      {!loading && (
        <>
          {services.length === 0 ? (
            <div className="card text-center py-12">
              <p className="text-slate-400">No services yet. Add one to get started!</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {services.map((service, i) => (
                <motion.div
                  key={service.id}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: i * 0.05 }}
                >
                  <ServiceCard service={service} onDelete={handleDeleteService} onEdit={setEditingService} />
                </motion.div>
              ))}
            </div>
          )}
        </>
      )}

      {/* Add Service Modal */}
      {isModalOpen && (
        <AddServiceModal
          onAdd={handleAddService}
          onClose={() => setIsModalOpen(false)}
        />
      )}

      {/* Edit Service Modal */}
      {editingService && (
        <EditServiceModal
          service={editingService}
          onUpdate={handleUpdateService}
          onClose={() => setEditingService(null)}
        />
      )}
    </motion.div>
  )
}
