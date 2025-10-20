import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { Plus } from 'lucide-react'
import { supabase } from '@/lib/supabase'
import CredentialCard from '@/components/credentials/CredentialCard'
import AddCredentialModal from '@/components/credentials/AddCredentialModal'

export default function Credentials({ session }) {
  const [credentials, setCredentials] = useState([])
  const [services, setServices] = useState([])
  const [loading, setLoading] = useState(true)
  const [isModalOpen, setIsModalOpen] = useState(false)

  useEffect(() => {
    fetchData()
  }, [session])

  const fetchData = async () => {
    if (!session?.user?.id) {
      setLoading(false)
      return
    }

    try {
      setLoading(true)
      // Fetch credentials
      const { data: credData, error: credError } = await supabase
        .from('credentials')
        .select('*')
        .eq('owner_id', session.user.id)
        .order('created_at', { ascending: false })

      if (credError) throw credError

      // Fetch services for reference
      const { data: servData, error: servError } = await supabase
        .from('services')
        .select('*')
        .eq('owner_id', session.user.id)

      if (servError) throw servError

      setCredentials(credData || [])
      setServices(servData || [])
    } catch (error) {
      console.error('Error fetching data:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleAddCredential = async (newCredential) => {
    if (!session?.user?.id) {
      console.error('No authenticated user session')
      return
    }

    try {
      const { data, error } = await supabase
        .from('credentials')
        .insert([
          {
            ...newCredential,
            owner_id: session.user.id,
          },
        ])
        .select()

      if (error) throw error

      // Log audit event
      await supabase.from('audit_logs').insert([
        {
          user_id: session.user.id,
          action: 'credential_created',
          details: { credential_id: data?.[0]?.id },
        },
      ])

      setCredentials([data[0], ...credentials])
      setIsModalOpen(false)
    } catch (error) {
      console.error('Error adding credential:', error)
    }
  }

  const handleDeleteCredential = async (id) => {
    if (!session?.user?.id) {
      console.error('No authenticated user session')
      return
    }

    try {
      const { error } = await supabase.from('credentials').delete().eq('id', id)
      if (error) throw error

      // Log audit event
      await supabase.from('audit_logs').insert([
        {
          user_id: session.user.id,
          action: 'credential_deleted',
          details: { credential_id: id },
        },
      ])

      setCredentials(credentials.filter((c) => c.id !== id))
    } catch (error) {
      console.error('Error deleting credential:', error)
    }
  }

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-slate-100">Credentials</h1>
          <p className="text-slate-400 mt-1">Manage your stored credentials securely</p>
        </div>
        <button
          onClick={() => setIsModalOpen(true)}
          className="btn-primary flex items-center gap-2"
        >
          <Plus size={20} />
          Add Credential
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

      {/* Credentials List */}
      {!loading && (
        <>
          {credentials.length === 0 ? (
            <div className="card text-center py-12">
              <p className="text-slate-400">No credentials yet. Add one to get started!</p>
            </div>
          ) : (
            <div className="space-y-4">
              {credentials.map((credential, i) => (
                <motion.div
                  key={credential.id}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: i * 0.05 }}
                >
                  <CredentialCard
                    credential={credential}
                    services={services}
                    onDelete={handleDeleteCredential}
                  />
                </motion.div>
              ))}
            </div>
          )}
        </>
      )}

      {/* Add Credential Modal */}
      {isModalOpen && (
        <AddCredentialModal
          services={services}
          onAdd={handleAddCredential}
          onClose={() => setIsModalOpen(false)}
        />
      )}
    </motion.div>
  )
}
