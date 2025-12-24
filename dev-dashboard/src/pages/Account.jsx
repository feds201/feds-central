import { motion } from 'framer-motion'
import { ShieldCheck, UserCircle, Settings2, Globe, Mail, Fingerprint } from 'lucide-react'
import { useAuth } from '@/auth'
import PasskeyManager from '@/components/account/PasskeyManager'

export default function Account() {
    const { user } = useAuth()

    return (
        <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="space-y-10 pb-12"
        >
            {/* Page Header */}
            <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
                <div>
                    <div className="flex items-center gap-2 mb-2">
                        <Settings2 className="text-indigo-400" size={18} />
                        <span className="text-xs font-bold uppercase tracking-[0.2em] text-slate-500">System Preferences</span>
                    </div>
                    <h1 className="text-2xl md:text-4xl font-extrabold text-slate-100 tracking-tight">Account Settings</h1>
                    <p className="text-slate-400 mt-2 max-w-xl">
                        Manage your digital presence, security credentials, and platform preferences from one central dashboard.
                    </p>
                </div>
            </div>

            <div className="grid grid-cols-1 xl:grid-cols-12 gap-8 items-start">
                {/* Left Column: Account Details */}
                <div className="xl:col-span-5 space-y-6">
                    <div className="flex items-center gap-2 mb-1 px-1">
                        <UserCircle className="text-indigo-400" size={20} />
                        <h2 className="text-lg font-bold text-slate-200">Personal Information</h2>
                    </div>
                    <motion.div
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ delay: 0.1 }}
                        className="card !p-0 overflow-hidden border-white/5 bg-slate-900/40 backdrop-blur-md"
                    >
                        <div className="p-6 border-b border-white/5 bg-white/[0.02] space-y-6">
                            <div className="flex items-center justify-between">
                                <span className="text-sm font-medium text-slate-400">Full Name</span>
                                <span className="text-sm font-semibold text-slate-200">{user?.full_name || 'Not set'}</span>
                            </div>
                            <div className="flex items-center justify-between">
                                <span className="text-sm font-medium text-slate-400">Email Address</span>
                                <div className="flex items-center gap-2">
                                    <Mail size={14} className="text-slate-500" />
                                    <span className="text-sm font-semibold text-slate-200">{user?.email}</span>
                                </div>
                            </div>
                            <div className="flex items-center justify-between">
                                <span className="text-sm font-medium text-slate-400">User ID</span>
                                <span className="text-xs font-mono text-slate-500 bg-slate-950 px-2 py-1 rounded">{user?.id}</span>
                            </div>
                        </div>
                        <div className="p-4 bg-indigo-500/5 flex items-center gap-3">
                            <Globe size={14} className="text-indigo-400" />
                            <p className="text-[10px] text-slate-500 uppercase font-bold tracking-widest">
                                Profile data is stored securely in FEDS Cloud
                            </p>
                        </div>
                    </motion.div>
                </div>

                {/* Right Column: Security & Passkeys */}
                <div className="xl:col-span-7 space-y-6">
                    <div className="flex items-center gap-2 mb-1 px-1">
                        <ShieldCheck className="text-indigo-400" size={20} />
                        <h2 className="text-lg font-bold text-slate-200">Advanced Security</h2>
                    </div>
                    <motion.div
                        initial={{ opacity: 0, x: 20 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ delay: 0.2 }}
                        className="card border-white/5 bg-slate-900/60 shadow-2xl relative overflow-hidden"
                    >
                        {/* Decorative background element */}
                        <div className="absolute top-0 right-0 w-64 h-64 bg-indigo-600/5 blur-[80px] -z-10 rounded-full" />

                        <PasskeyManager />
                    </motion.div>

                    {/* Security Tip Card */}
                    <motion.div
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: 0.3 }}
                        className="p-6 rounded-2xl bg-gradient-to-br from-indigo-600/10 to-purple-600/10 border border-white/5 shadow-inner"
                    >
                        <h3 className="text-sm font-bold text-slate-200 mb-2 flex items-center gap-2">
                            <ShieldCheck className="text-emerald-400" size={16} />
                            Security Recommendation
                        </h3>
                        <p className="text-xs text-slate-400 leading-relaxed">
                            For maximum account protection, we recommend registering at least two passkeys (e.g., your laptop and your smartphone) and keeping your recovery codes in a safe, offline location.
                        </p>
                    </motion.div>
                </div>
            </div>
        </motion.div>
    )
}
