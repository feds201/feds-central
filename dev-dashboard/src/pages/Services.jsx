import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { Plus } from 'lucide-react'
import { supabase } from '@/lib/supabase'
import ServiceCard from '@/components/services/ServiceCard'
import AddServiceModal from '@/components/services/AddServiceModal'

export default function Services({ session }) {
  const [services, setServices] = useState([])
  const [loading, setLoading] = useState(true)
  const [isModalOpen, setIsModalOpen] = useState(false)

  useEffect(() => {
    fetchServices()
  }, [session])

  const fetchServices = async () => {
    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('services')
        .select('*')
        .eq('owner_id', session?.user?.id)
        .order('created_at', { ascending: false })

      if (error) throw error
      setServices(data || [])
    } catch (error) {
      console.error('Error fetching services:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleAddService = async (newService) => {
    try {
      const { data, error } = await supabase
        .from('services')
        .insert([
          {
            ...newService,
            owner_id: session?.user?.id,
          },
        ])
        .select()

      if (error) throw error

      // Log audit event
      await supabase.from('audit_logs').insert([
        {
          user_id: session?.user?.id,
          action: 'service_created',
          details: { service_id: data?.[0]?.id, name: newService.name },
        },
      ])

      setServices([data[0], ...services])
      setIsModalOpen(false)
    } catch (error) {
      console.error('Error adding service:', error)
    }
  }

  const handleDeleteService = async (id) => {
    try {
      const { error } = await supabase.from('services').delete().eq('id', id)
      if (error) throw error

      // Log audit event
      await supabase.from('audit_logs').insert([
        {
          user_id: session?.user?.id,
          action: 'service_deleted',
          details: { service_id: id },
        },
      ])

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
                  <ServiceCard service={service} onDelete={handleDeleteService} />
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
    </motion.div>
  )
}
