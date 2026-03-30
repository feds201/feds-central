import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Fingerprint, Plus, Trash2, Key, Loader2, AlertCircle, ShieldCheck, ShieldAlert, Shield } from 'lucide-react'
import { browserSupportsWebAuthn } from '@simplewebauthn/browser'
import { useAuth } from '@/auth'
import { api } from '@/lib/api'
import { db } from '@/lib/db'

export default function PasskeyManager() {
    const { user } = useAuth()
    const [passkeys, setPasskeys] = useState([])
    const [loading, setLoading] = useState(true)
    const [adding, setAdding] = useState(false)
    const [error, setError] = useState(null)
    const [isSupported] = useState(browserSupportsWebAuthn())

    useEffect(() => {
        if (user) {
            fetchPasskeys()
        }
    }, [user])

    const fetchPasskeys = async () => {
        try {
            setLoading(true)
            setError(null)
            const list = await api.listPasskeys()
            setPasskeys(list || [])
        } catch (err) {
            console.error('Error fetching passkeys:', err)
            setError('Failed to fetch passkeys.')
        } finally {
            setLoading(false)
        }
    }

    const handleAddPasskey = async () => {
        try {
            setAdding(true)
            setError(null)
            // Name prompt or auto-naming handled by backend/browser logic if needed, 
            // but for now simplewebauthn usually uses user agent or we can prompt.
            // My backend implementation hardcoded 'My Passkey'. 
            // I'll stick to basic flow first.

            await api.registerPasskey()

            // Log audit event
            if (user?.id) {
                // Determine name... backend uses 'My Passkey' or we can update it later.
                // For audit log:
                await db('INSERT INTO audit_logs (user_id, action, details) VALUES ($1, $2, $3)', [
                    user.id,
                    'passkey_added',
                    JSON.stringify({ method: 'webauthn' })
                ])
            }

            await fetchPasskeys()
        } catch (err) {
            console.error('Error adding passkey:', err)
            setError(err.message || 'Failed to add passkey')
        } finally {
            setAdding(false)
        }
    }

    const handleDeletePasskey = async (id) => {
        if (!confirm('Are you sure you want to remove this passkey?')) return

        try {
            setError(null)
            await api.deletePasskey(id)

            // Log audit event
            if (user?.id) {
                await db('INSERT INTO audit_logs (user_id, action, details) VALUES ($1, $2, $3)', [
                    user.id,
                    'passkey_deleted',
                    JSON.stringify({ passkey_id: id })
                ])
            }

            await fetchPasskeys()
        } catch (err) {
            console.error('Error deleting passkey:', err)
            setError('Failed to delete passkey')
        }
    }

    if (!user) return null;

    if (!isSupported) {
        return (
            <div className="space-y-4">
                <div className="flex items-center gap-3 mb-2">
                    <div className="p-2 rounded-xl bg-slate-800 border border-slate-700">
                        <Fingerprint className="text-slate-500" size={24} />
                    </div>
                    <h3 className="text-xl font-bold text-slate-100">Passkeys</h3>
                </div>
                <div className="p-4 rounded-2xl bg-amber-950/10 border border-amber-500/20 text-amber-500/80 text-sm">
                    <div className="flex items-start gap-3">
                        <ShieldAlert size={20} className="mt-0.5" />
                        <div>
                            <p className="font-semibold text-amber-400 mb-1">Feature Restricted</p>
                            <p>Passkey support is not enabled in your current authentication configuration. Please contact your administrator or check your auth plugin settings.</p>
                        </div>
                    </div>
                </div>
            </div>
        )
    }

    return (
        <div className="space-y-6">
            {/* Header Section */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div className="flex items-center gap-3">
                    <div className="p-2.5 rounded-2xl bg-indigo-500/10 border border-indigo-500/20 shadow-inner">
                        <Fingerprint className="text-indigo-400" size={26} />
                    </div>
                    <div>
                        <h3 className="text-xl font-bold text-slate-100">Digital Identity</h3>
                        <p className="text-xs text-slate-500 font-medium uppercase tracking-wider">Passkey Security</p>
                    </div>
                </div>
                <button
                    onClick={handleAddPasskey}
                    disabled={adding}
                    className="btn-primary w-full sm:w-auto flex items-center justify-center gap-2 text-sm !py-2 shadow-indigo-500/20"
                >
                    {adding ? <Loader2 size={16} className="animate-spin" /> : <Plus size={16} />}
                    <span className="inline">Add Secure Passkey</span>
                </button>
            </div>

            {/* Security Status Ribbon */}
            <div className={`p-4 rounded-2xl border transition-all duration-500 flex items-center gap-4 ${passkeys.length > 0
                ? 'bg-emerald-500/5 border-emerald-500/20'
                : 'bg-amber-500/5 border-amber-500/20'
                }`}>
                <div className={`p-2 rounded-full ${passkeys.length > 0 ? 'bg-emerald-500/20' : 'bg-amber-500/20'
                    }`}>
                    {passkeys.length > 0 ? (
                        <ShieldCheck className="text-emerald-400" size={20} />
                    ) : (
                        <Shield className="text-amber-400" size={20} />
                    )}
                </div>
                <div className="flex-1">
                    <p className={`font-semibold ${passkeys.length > 0 ? 'text-emerald-400' : 'text-amber-400'}`}>
                        {passkeys.length > 0 ? 'Enhanced Security Active' : 'Basic Security Level'}
                    </p>
                    <p className="text-xs text-slate-400">
                        {passkeys.length > 0
                            ? `You have ${passkeys.length} active passkey${passkeys.length > 1 ? 's' : ''} protecting your account.`
                            : 'Add a passkey for passwordless, biometric-secured access.'}
                    </p>
                </div>
                <div className="text-right">
                    <div className="text-[10px] text-slate-500 uppercase tracking-tighter mb-1 font-bold">Security Score</div>
                    <div className="h-2 w-24 bg-slate-800 rounded-full overflow-hidden">
                        <motion.div
                            initial={{ width: 0 }}
                            animate={{ width: passkeys.length > 0 ? '100%' : '30%' }}
                            className={`h-full ${passkeys.length > 0 ? 'bg-emerald-500' : 'bg-amber-500 shadow-[0_0_8px_rgba(245,158,11,0.5)]'}`}
                        />
                    </div>
                </div>
            </div>

            {error && (
                <motion.div
                    initial={{ opacity: 0, y: -10 }}
                    animate={{ opacity: 1, y: 0 }}
                    className="p-4 rounded-2xl bg-red-500/10 border border-red-500/20 flex items-center gap-3 text-sm text-red-400"
                >
                    <AlertCircle size={18} />
                    <span className="font-medium">{error}</span>
                </motion.div>
            )}

            {/* Passkeys List */}
            <div className="space-y-3">
                {loading ? (
                    <div className="flex flex-col items-center justify-center py-12 space-y-4">
                        <Loader2 className="animate-spin text-indigo-500" size={32} />
                        <p className="text-slate-500 text-sm animate-pulse">Syncing security credentials...</p>
                    </div>
                ) : passkeys.length === 0 ? (
                    <motion.div
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        className="text-center py-12 border-2 border-dashed border-slate-800/50 rounded-[2rem] bg-slate-900/40"
                    >
                        <div className="relative inline-block mb-4">
                            <Key className="text-slate-700" size={48} />
                            <div className="absolute -top-1 -right-1 w-4 h-4 bg-slate-800 rounded-full flex items-center justify-center">
                                <div className="w-1.5 h-1.5 bg-slate-600 rounded-full" />
                            </div>
                        </div>
                        <h4 className="text-slate-300 font-semibold mb-1">No Passkeys Registered</h4>
                        <p className="text-slate-500 text-sm max-w-[200px] mx-auto">Passwords are old-school. Upgrade to biometric login.</p>
                    </motion.div>
                ) : (
                    <div className="grid gap-3">
                        <AnimatePresence mode='popLayout'>
                            {passkeys.map((pk) => (
                                <motion.div
                                    key={pk.id}
                                    layout
                                    initial={{ opacity: 0, scale: 0.95 }}
                                    animate={{ opacity: 1, scale: 1 }}
                                    exit={{ opacity: 0, scale: 0.95 }}
                                    className="flex items-center justify-between p-4 rounded-2xl bg-slate-900/60 border border-white/5 hover:border-indigo-500/30 transition-all group relative overflow-hidden"
                                >
                                    {/* Hover Shine Effect */}
                                    <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/5 to-transparent -translate-x-full group-hover:animate-[shimmer_2s_infinite] pointer-events-none" />

                                    <div className="flex items-center gap-4 relative z-10">
                                        <div className="p-3 rounded-xl bg-slate-800 shadow-lg group-hover:bg-indigo-500/10 transition-colors">
                                            <Fingerprint size={22} className="text-slate-400 group-hover:text-indigo-400 transition-colors" />
                                        </div>
                                        <div>
                                            <p className="font-bold text-slate-100 group-hover:text-white transition-colors">{pk.name || 'Unnamed Key'}</p>
                                            <div className="flex items-center gap-2 mt-1">
                                                <span className="text-[10px] bg-slate-800 text-slate-400 px-1.5 py-0.5 rounded leading-none uppercase font-bold tracking-tighter">Hardware backed</span>
                                                <span className="text-xs text-slate-500">
                                                    Added {new Date(pk.created_at).toLocaleDateString()}
                                                </span>
                                            </div>
                                        </div>
                                    </div>
                                    <button
                                        onClick={() => handleDeletePasskey(pk.id)}
                                        className="relative z-10 p-2.5 text-slate-500 hover:text-red-400 hover:bg-red-400/10 rounded-xl transition-all opacity-0 group-hover:opacity-100 translate-x-2 group-hover:translate-x-0"
                                        title="Revoke passkey"
                                    >
                                        <Trash2 size={18} />
                                    </button>
                                </motion.div>
                            ))}
                        </AnimatePresence>
                    </div>
                )}
            </div>

            {/* Info Footer */}
            <div className="flex items-start gap-3 bg-indigo-500/5 p-4 rounded-2xl border border-indigo-500/10">
                <Shield size={16} className="text-indigo-400 mt-0.5 flex-shrink-0" />
                <p className="text-[11px] text-slate-400 leading-relaxed">
                    Passkeys use cryptographic keys stored on your device. They protect you from phishing and password theft by requiring your device's local authentication.
                </p>
            </div>
        </div>
    )
}
