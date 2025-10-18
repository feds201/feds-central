import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { Plus, RefreshCw } from 'lucide-react'
import { supabase } from '@/lib/supabase'
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
    try {
      setLoading(true)

      // Fetch main authenticator
      const { data: mainData, error: mainError } = await supabase
        .from('authenticator')
        .select('*')
        .eq('user_id', session?.user?.id)
        .single()

      if (mainError && mainError.code !== 'PGRST116') {
        throw mainError
      }
      setMainTotp(mainData || null)

      // Fetch authenticator entries
      const { data: entriesData, error: entriesError } = await supabase
        .from('authenticator_entries')
        .select('*')
        .eq('user_id', session?.user?.id)
        .order('created_at', { ascending: false })

      if (entriesError) throw entriesError
      setEntries(entriesData || [])
    } catch (error) {
      console.error('Error fetching TOTP data:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleSetupTOTP = async (secret, recoveryCodes) => {
    try {
      const { error } = await supabase
        .from('authenticator')
        .upsert(
          [
            {
              user_id: session?.user?.id,
              totp_secret: secret,
              recovery_codes: recoveryCodes,
              updated_at: new Date(),
            },
          ],
          { onConflict: 'user_id' }
        )

      if (error) throw error

      // Log audit event
      await supabase.from('audit_logs').insert([
        {
          user_id: session?.user?.id,
          action: 'totp_setup',
          details: {},
        },
      ])

      fetchTOTPData()
      setIsSetupModalOpen(false)
    } catch (error) {
      console.error('Error setting up TOTP:', error)
    }
  }

  const handleAddEntry = async (newEntry) => {
    try {
      const { data, error } = await supabase
        .from('authenticator_entries')
        .insert([
          {
            ...newEntry,
            user_id: session?.user?.id,
          },
        ])
        .select()

      if (error) throw error

      // Log audit event
      await supabase.from('audit_logs').insert([
        {
          user_id: session?.user?.id,
          action: 'authenticator_entry_created',
          details: { service_name: newEntry.service_name },
        },
      ])

      setEntries([data[0], ...entries])
      setIsAddModalOpen(false)
    } catch (error) {
      console.error('Error adding entry:', error)
    }
  }

  const handleDeleteEntry = async (id) => {
    try {
      const { error } = await supabase
        .from('authenticator_entries')
        .delete()
        .eq('id', id)

      if (error) throw error

      // Log audit event
      await supabase.from('audit_logs').insert([
        {
          user_id: session?.user?.id,
          action: 'authenticator_entry_deleted',
          details: { entry_id: id },
        },
      ])

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
