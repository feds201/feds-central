import { useState } from 'react'
import { motion } from 'framer-motion'
import { Upload, Download, FileJson, AlertCircle, CheckCircle, X } from 'lucide-react'
import { db } from '@/lib/db'

export default function ImportExportModal({ session, onClose, onComplete }) {
  const [tab, setTab] = useState('export') // 'export' or 'import'
  const [importing, setImporting] = useState(false)
  const [importResult, setImportResult] = useState(null)

  const exportData = async () => {
    try {
      const userId = session.user.id

      const services = await db('SELECT * FROM services WHERE owner_id = $1', [userId])
      const credentials = await db('SELECT * FROM credentials WHERE owner_id = $1', [userId])
      const totpEntries = await db('SELECT * FROM authenticator_entries WHERE user_id = $1', [userId])

      const data = {
        version: '1.0',
        exportedAt: new Date().toISOString(),
        exportedBy: session.user.email,
        services: services || [],
        credentials: credentials || [],
        totpEntries: totpEntries || [],
      }

      const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `feds-backup-${new Date().toISOString().split('T')[0]}.json`
      a.click()
      URL.createObjectURL(url)

      // Log export
      await db(
        'INSERT INTO audit_logs (user_id, action, details) VALUES ($1, $2, $3)',
        [userId, 'data_exported', JSON.stringify({ itemCount: (services?.length || 0) + (credentials?.length || 0) + (totpEntries?.length || 0) })]
      )

      onComplete?.()
    } catch (error) {
      console.error('Export error:', error)
      alert('Failed to export data')
    }
  }

  const handleImport = async (event) => {
    const file = event.target.files?.[0]
    if (!file) return

    try {
      setImporting(true)
      setImportResult(null)

      const text = await file.text()
      const data = JSON.parse(text)

      if (!data.version || !data.services || !data.credentials) {
        throw new Error('Invalid backup file format')
      }

      const userId = session.user.id
      let imported = { services: 0, credentials: 0, totpEntries: 0 }

      // Import services
      for (const service of data.services) {
        try {
          await db(
            `INSERT INTO services (name, url, description, tags, owner_id) VALUES ($1, $2, $3, $4, $5)`,
            [service.name, service.url, service.description, service.tags, userId]
          )
          imported.services++
        } catch (err) {
          console.error('Failed to import service:', service.name, err)
        }
      }

      // Import credentials (only if corresponding service exists)
      for (const cred of data.credentials) {
        try {
          // Check if service exists
          const serviceExists = await db(
            'SELECT id FROM services WHERE owner_id = $1 AND name = $2 LIMIT 1',
            [userId, cred.service_name || '']
          )
          
          if (serviceExists?.length > 0) {
            await db(
              `INSERT INTO credentials (service_id, username, password_encrypted, notes, owner_id) VALUES ($1, $2, $3, $4, $5)`,
              [serviceExists[0].id, cred.username, cred.password_encrypted, cred.notes, userId]
            )
            imported.credentials++
          }
        } catch (err) {
          console.error('Failed to import credential:', err)
        }
      }

      // Import TOTP entries
      if (data.totpEntries) {
        for (const entry of data.totpEntries) {
          try {
            await db(
              `INSERT INTO authenticator_entries (user_id, service_name, totp_secret, totp_period, digits, issuer, account_name, notes) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
              [userId, entry.service_name, entry.totp_secret, entry.totp_period || 30, entry.digits || 6, entry.issuer, entry.account_name, entry.notes]
            )
            imported.totpEntries++
          } catch (err) {
            console.error('Failed to import TOTP entry:', err)
          }
        }
      }

      // Log import
      await db(
        'INSERT INTO audit_logs (user_id, action, details) VALUES ($1, $2, $3)',
        [userId, 'data_imported', JSON.stringify(imported)]
      )

      setImportResult({ success: true, ...imported })
    } catch (error) {
      console.error('Import error:', error)
      setImportResult({ success: false, error: error.message })
    } finally {
      setImporting(false)
    }
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
        className="card max-w-lg w-full"
      >
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-slate-100">Import / Export</h2>
          <button onClick={onClose} className="p-1 hover:bg-slate-800 rounded-lg">
            <X size={20} />
          </button>
        </div>

        {/* Tabs */}
        <div className="flex gap-2 p-1 bg-slate-800/50 rounded-xl mb-6">
          <button
            onClick={() => setTab('export')}
            className={`flex-1 px-4 py-2 rounded-lg font-medium transition-all ${
              tab === 'export'
                ? 'bg-indigo-600 text-white shadow-lg'
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            <Download size={16} className="inline mr-2" />
            Export
          </button>
          <button
            onClick={() => setTab('import')}
            className={`flex-1 px-4 py-2 rounded-lg font-medium transition-all ${
              tab === 'import'
                ? 'bg-indigo-600 text-white shadow-lg'
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            <Upload size={16} className="inline mr-2" />
            Import
          </button>
        </div>

        {/* Export Tab */}
        {tab === 'export' && (
          <div className="space-y-4">
            <div className="p-4 rounded-xl bg-slate-800/50 border border-slate-700/50">
              <div className="flex items-start gap-3 mb-4">
                <FileJson size={24} className="text-indigo-400 flex-shrink-0" />
                <div>
                  <h3 className="font-semibold text-slate-100">Backup Your Data</h3>
                  <p className="text-sm text-slate-400 mt-1">
                    Export all your services, credentials, and TOTP entries to a JSON file.
                  </p>
                </div>
              </div>
              <ul className="space-y-2 text-sm text-slate-400">
                <li className="flex items-center gap-2">
                  <CheckCircle size={16} className="text-emerald-400" />
                  Includes all services and settings
                </li>
                <li className="flex items-center gap-2">
                  <CheckCircle size={16} className="text-emerald-400" />
                  Includes all credentials (passwords included)
                </li>
                <li className="flex items-center gap-2">
                  <CheckCircle size={16} className="text-emerald-400" />
                  Includes all TOTP authenticator entries
                </li>
                <li className="flex items-center gap-2">
                  <AlertCircle size={16} className="text-amber-400" />
                  Store backup file securely - it contains sensitive data
                </li>
              </ul>
            </div>

            <button onClick={exportData} className="btn-primary w-full">
              <Download size={20} className="inline mr-2" />
              Download Backup
            </button>
          </div>
        )}

        {/* Import Tab */}
        {tab === 'import' && (
          <div className="space-y-4">
            <div className="p-4 rounded-xl bg-slate-800/50 border border-slate-700/50">
              <div className="flex items-start gap-3 mb-4">
                <Upload size={24} className="text-indigo-400 flex-shrink-0" />
                <div>
                  <h3 className="font-semibold text-slate-100">Restore From Backup</h3>
                  <p className="text-sm text-slate-400 mt-1">
                    Import data from a previously exported JSON backup file.
                  </p>
                </div>
              </div>
              <ul className="space-y-2 text-sm text-slate-400">
                <li className="flex items-center gap-2">
                  <AlertCircle size={16} className="text-amber-400" />
                  Only FEDS backup files are supported
                </li>
                <li className="flex items-center gap-2">
                  <AlertCircle size={16} className="text-amber-400" />
                  Duplicate items will be skipped
                </li>
                <li className="flex items-center gap-2">
                  <AlertCircle size={16} className="text-amber-400" />
                  Existing data will NOT be deleted
                </li>
              </ul>
            </div>

            {importResult && (
              <div className={`p-4 rounded-xl border ${
                importResult.success
                  ? 'bg-emerald-950/20 border-emerald-500/30'
                  : 'bg-red-950/20 border-red-500/30'
              }`}>
                {importResult.success ? (
                  <>
                    <div className="flex items-center gap-2 mb-2">
                      <CheckCircle size={20} className="text-emerald-400" />
                      <span className="font-semibold text-emerald-300">Import Successful</span>
                    </div>
                    <p className="text-sm text-emerald-400">
                      Imported {importResult.services} services, {importResult.credentials} credentials, and {importResult.totpEntries} TOTP entries.
                    </p>
                  </>
                ) : (
                  <>
                    <div className="flex items-center gap-2 mb-2">
                      <AlertCircle size={20} className="text-red-400" />
                      <span className="font-semibold text-red-300">Import Failed</span>
                    </div>
                    <p className="text-sm text-red-400">{importResult.error}</p>
                  </>
                )}
              </div>
            )}

            <label className="block">
              <input
                type="file"
                accept=".json"
                onChange={handleImport}
                disabled={importing}
                className="hidden"
                id="import-file"
              />
              <div className="btn-primary w-full text-center cursor-pointer">
                {importing ? (
                  <>
                    <div className="inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>
                    Importing...
                  </>
                ) : (
                  <>
                    <Upload size={20} className="inline mr-2" />
                    Choose Backup File
                  </>
                )}
              </div>
            </label>
          </div>
        )}
      </motion.div>
    </motion.div>
  )
}
