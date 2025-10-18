import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { supabase } from '@/lib/supabase'
import AuditEntry from '@/components/audit/AuditEntry'

export default function AuditLog({ session }) {
  const [logs, setLogs] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchAuditLogs()
  }, [session])

  const fetchAuditLogs = async () => {
    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('audit_logs')
        .select('*')
        .eq('user_id', session?.user?.id)
        .order('created_at', { ascending: false })
        .limit(100)

      if (error) throw error
      setLogs(data || [])
    } catch (error) {
      console.error('Error fetching audit logs:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-slate-100">Activity Log</h1>
        <p className="text-slate-400 mt-1">View your recent actions and changes</p>
      </div>

      {/* Loading State */}
      {loading && (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin">
            <div className="w-12 h-12 border-4 border-slate-700 border-t-indigo-500 rounded-full"></div>
          </div>
        </div>
      )}

      {/* Audit Entries */}
      {!loading && (
        <>
          {logs.length === 0 ? (
            <div className="card text-center py-12">
              <p className="text-slate-400">No activity yet</p>
            </div>
          ) : (
            <div className="space-y-3">
              {logs.map((log, i) => (
                <motion.div
                  key={log.id}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: i * 0.05 }}
                >
                  <AuditEntry log={log} />
                </motion.div>
              ))}
            </div>
          )}
        </>
      )}
    </motion.div>
  )
}
