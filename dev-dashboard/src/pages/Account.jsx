import { motion } from 'framer-motion'
import { AccountView } from '@neondatabase/neon-js/auth/react'

export default function Account() {
    return (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-6">
            <div>
                <h1 className="text-3xl font-bold text-slate-100">Account Settings</h1>
                <p className="text-slate-400 mt-1">Manage your profile and security</p>
            </div>

            <div className="card max-w-4xl">
                <AccountView />
            </div>
        </motion.div>
    )
}
