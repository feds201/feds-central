import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { Plus } from 'lucide-react'
import { db } from '@/lib/db'
import CredentialCard from '@/components/credentials/CredentialCard'
import AddCredentialModal from '@/components/credentials/AddCredentialModal'
import EditCredentialModal from '@/components/credentials/EditCredentialModal'

export default function Credentials({ session }) {
  const [credentials, setCredentials] = useState([])
  const [services, setServices] = useState([])
  const [loading, setLoading] = useState(true)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [editingCredential, setEditingCredential] = useState(null)

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
      const userId = session.user.id

      // Fetch credentials
      const credData = await db(
        'SELECT * FROM credentials WHERE owner_id = $1 ORDER BY created_at DESC',
        [userId]
      )

      // Fetch services for reference
      const servData = await db(
        'SELECT * FROM services WHERE owner_id = $1',
        [userId]
      )

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
      const userId = session.user.id

      const result = await db(
        `INSERT INTO credentials (service_id, username, password_encrypted, notes, owner_id)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [newCredential.service_id, newCredential.username, newCredential.password_encrypted, newCredential.notes, userId]
      )

      if (!result || result.length === 0) throw new Error('Failed to create credential')
      const createdCred = result[0]

      // Log audit event
      await db(
        `INSERT INTO audit_logs (user_id, action, details) VALUES ($1, $2, $3)`,
        [userId, 'credential_created', JSON.stringify({ credential_id: createdCred.id })]
      )

      setCredentials([createdCred, ...credentials])
      setIsModalOpen(false)
    } catch (error) {
      console.error('Error adding credential:', error)
    }
  }

  const handleUpdateCredential = async (credentialId, updatedData) => {
    if (!session?.user?.id) {
      console.error('No authenticated user session')
      return
    }

    try {
      const userId = session.user.id

      const result = await db(
        `UPDATE credentials 
         SET service_id = $1, username = $2, password_encrypted = $3, notes = $4, updated_at = now()
         WHERE id = $5 AND owner_id = $6
         RETURNING *`,
        [updatedData.service_id, updatedData.username, updatedData.password_encrypted, updatedData.notes, credentialId, userId]
      )

      if (!result || result.length === 0) throw new Error('Failed to update credential')
      const updated = result[0]

      // Log audit event
      await db(
        `INSERT INTO audit_logs (user_id, action, details) VALUES ($1, $2, $3)`,
        [userId, 'credential_updated', JSON.stringify({ credential_id: credentialId })]
      )

      setCredentials(credentials.map((c) => (c.id === credentialId ? updated : c)))
      setEditingCredential(null)
    } catch (error) {
      console.error('Error updating credential:', error)
    }
  }

  const handleDeleteCredential = async (id) => {
    if (!session?.user?.id) {
      console.error('No authenticated user session')
      return
    }

    try {
      await db('DELETE FROM credentials WHERE id = $1', [id])

      // Log audit event
      await db(
        `INSERT INTO audit_logs (user_id, action, details) VALUES ($1, $2, $3)`,
        [session.user.id, 'credential_deleted', JSON.stringify({ credential_id: id })]
      )

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
                    onEdit={setEditingCredential}
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

      {/* Edit Credential Modal */}
      {editingCredential && (
        <EditCredentialModal
          credential={editingCredential}
          services={services}
          onUpdate={handleUpdateCredential}
          onClose={() => setEditingCredential(null)}
        />
      )}
    </motion.div>
  )
}
