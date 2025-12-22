import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { Plus, RefreshCw } from 'lucide-react'
import { db } from '@/lib/db'
import TOTPEntry from '@/components/authenticator/TOTPEntry'
import AddTOTPModal from '@/components/authenticator/AddTOTPModal'
import SetupTOTPModal from '@/components/authenticator/SetupTOTPModal'

export default function Authenticator({ session }) {
  const [entries, setEntries] = useState([])
  const [mainTotp, setMainTotp] = useState(null)
  const [loading, setLoading] = useState(true)
  const [isAddModalOpen, setIsAddModalOpen] = useState(false)
  const [isSetupModalOpen, setIsSetupModalOpen] = useState(false)

  useEffect(() => {
    fetchTOTPData()
  }, [session])

  const fetchTOTPData = async () => {
    if (!session?.user?.id) {
      setLoading(false)
      return
    }

    try {
      setLoading(true)
      const userId = session.user.id

      // Fetch main authenticator
      const mainData = await db('SELECT * FROM authenticator WHERE user_id = $1', [userId])
      setMainTotp(mainData?.[0] || null)

      // Fetch authenticator entries
      const entriesData = await db(
        'SELECT * FROM authenticator_entries WHERE user_id = $1 ORDER BY created_at DESC',
        [userId]
      )
      setEntries(entriesData || [])
    } catch (error) {
      console.error('Error fetching TOTP data:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleSetupTOTP = async (secret, recoveryCodes) => {
    if (!session?.user?.id) {
      console.error('No authenticated user session')
      return
    }

    try {
      const userId = session.user.id

      // Upsert Authenticator
      await db(
        `INSERT INTO authenticator (user_id, totp_secret, recovery_codes, updated_at)
         VALUES ($1, $2, $3, now())
         ON CONFLICT (user_id) DO UPDATE 
         SET totp_secret = EXCLUDED.totp_secret,
             recovery_codes = EXCLUDED.recovery_codes,
             updated_at = now()`,
        [userId, secret, recoveryCodes]
      )

      // Log audit event
      await db(
        `INSERT INTO audit_logs (user_id, action, details) VALUES ($1, $2, '{}')`,
        [userId, 'totp_setup']
      )

      fetchTOTPData()
      setIsSetupModalOpen(false)
    } catch (error) {
      console.error('Error setting up TOTP:', error)
    }
  }

  const handleAddEntry = async (newEntry) => {
    if (!session?.user?.id) {
      console.error('No authenticated user session')
      return
    }

    try {
      const userId = session.user.id

      const result = await db(
        `INSERT INTO authenticator_entries (user_id, service_name, totp_secret, totp_period, notes, issuer, account_name, digits)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING *`,
        [
          userId, 
          newEntry.service_name, 
          newEntry.totp_secret, 
          newEntry.totp_period || 30,
          newEntry.notes || null,
          newEntry.issuer || null,
          newEntry.account_name || null,
          newEntry.digits || 6
        ]
      )

      if (!result || result.length === 0) throw new Error('Failed to create entry')
      const createdEntry = result[0]

      // Log audit event
      await db(
        `INSERT INTO audit_logs (user_id, action, details) VALUES ($1, $2, $3)`,
        [userId, 'authenticator_entry_created', JSON.stringify({ service_name: newEntry.service_name })]
      )

      setEntries([createdEntry, ...entries])
      setIsAddModalOpen(false)
    } catch (error) {
      console.error('Error adding entry:', error)
    }
  }

  const handleDeleteEntry = async (id) => {
    if (!session?.user?.id) {
      console.error('No authenticated user session')
      return
    }

    try {
      await db('DELETE FROM authenticator_entries WHERE id = $1', [id])

      // Log audit event
      await db(
        `INSERT INTO audit_logs (user_id, action, details) VALUES ($1, $2, $3)`,
        [session.user.id, 'authenticator_entry_deleted', JSON.stringify({ entry_id: id })]
      )

      setEntries(entries.filter((e) => e.id !== id))
    } catch (error) {
      console.error('Error deleting entry:', error)
    }
  }

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-slate-100">Authenticator</h1>
          <p className="text-slate-400 mt-1">Manage your TOTP authenticators</p>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => setIsAddModalOpen(true)}
            className="btn-primary flex items-center gap-2"
          >
            <Plus size={20} />
            Add Entry
          </button>
          <button
            onClick={() => setIsSetupModalOpen(true)}
            className="btn-secondary flex items-center gap-2"
          >
            <RefreshCw size={20} />
            Setup TOTP
          </button>
        </div>
      </div>

      {/* Loading State */}
      {loading && (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin">
            <div className="w-12 h-12 border-4 border-slate-700 border-t-indigo-500 rounded-full"></div>
          </div>
        </div>
      )}

      {/* Main TOTP Status */}
      {!loading && mainTotp && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="card"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-slate-400">Account Authenticator</p>
              <p className="text-lg font-semibold text-green-400 mt-2">✓ Active</p>
            </div>
            <div className="text-right">
              <p className="text-xs text-slate-500">Setup on</p>
              <p className="text-sm text-slate-300">
                {new Date(mainTotp.created_at).toLocaleDateString()}
              </p>
            </div>
          </div>
        </motion.div>
      )}

      {/* Entries List */}
      {!loading && (
        <>
          {entries.length === 0 ? (
            <div className="card text-center py-12">
              <p className="text-slate-400">No TOTP entries yet. Add one to get started!</p>
            </div>
          ) : (
            <div className="space-y-4">
              {entries.map((entry, i) => (
                <motion.div
                  key={entry.id}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: i * 0.05 }}
                >
                  <TOTPEntry entry={entry} onDelete={handleDeleteEntry} />
                </motion.div>
              ))}
            </div>
          )}
        </>
      )}

      {/* Add Entry Modal */}
      {isAddModalOpen && (
        <AddTOTPModal
          onAdd={handleAddEntry}
          onClose={() => setIsAddModalOpen(false)}
        />
      )}

      {/* Setup TOTP Modal */}
      {isSetupModalOpen && (
        <SetupTOTPModal
          onSetup={handleSetupTOTP}
          onClose={() => setIsSetupModalOpen(false)}
        />
      )}
    </motion.div>
  )
}
