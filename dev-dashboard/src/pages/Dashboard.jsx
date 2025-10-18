import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { supabase } from '@/lib/supabase'
import StatCard from '@/components/dashboard/StatCard'
import RecentActivity from '@/components/dashboard/RecentActivity'
import QuickActions from '@/components/dashboard/QuickActions'
import { Lock, Shield, KeyRound, Activity } from 'lucide-react'

export default function Dashboard({ session }) {
  const [stats, setStats] = useState({
    services: 0,
    credentials: 0,
    authenticators: 0,
  })
  const [recentLogs, setRecentLogs] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchDashboardData()
  }, [session])

  const fetchDashboardData = async () => {
    try {
      setLoading(true)
      const userId = session?.user?.id

      // Fetch services count
      const { count: servicesCount } = await supabase
        .from('services')
        .select('*', { count: 'exact', head: true })
        .eq('owner_id', userId)

      // Fetch credentials count
      const { count: credentialsCount } = await supabase
        .from('credentials')
        .select('*', { count: 'exact', head: true })
        .eq('owner_id', userId)

      // Fetch authenticator entries count
      const { count: authenticatorsCount } = await supabase
        .from('authenticator_entries')
        .select('*', { count: 'exact', head: true })
        .eq('user_id', userId)

      // Fetch recent audit logs
      const { data: logs } = await supabase
        .from('audit_logs')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
        .limit(5)

      setStats({
        services: servicesCount || 0,
        credentials: credentialsCount || 0,
        authenticators: authenticatorsCount || 0,
      })
      setRecentLogs(logs || [])
    } catch (error) {
      console.error('Error fetching dashboard data:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-8">
      {/* Welcome Header */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
      >
        <h1 className="text-4xl font-bold gradient-text">
          Welcome back, {session?.user?.email?.split('@')[0]}
        </h1>
        <p className="text-slate-400 mt-2">
          Here's what's happening in your FEDS Dev Console
        </p>
      </motion.div>

      {/* Stats Grid */}
      {!loading && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.2 }}
          className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6"
        >
          <StatCard
            icon={Lock}
            label="Services"
            value={stats.services}
            gradient="from-indigo-600 to-indigo-400"
          />
          <StatCard
            icon={Shield}
            label="Credentials"
            value={stats.credentials}
            gradient="from-rose-600 to-rose-400"
          />
          <StatCard
            icon={KeyRound}
            label="Authenticators"
            value={stats.authenticators}
            gradient="from-amber-600 to-amber-400"
          />
          <StatCard
            icon={Activity}
            label="Recent Activities"
            value={recentLogs.length}
            gradient="from-emerald-600 to-emerald-400"
          />
        </motion.div>
      )}

      {/* Main Content Grid */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.3 }}
        className="grid grid-cols-1 lg:grid-cols-3 gap-6"
      >
        {/* Quick Actions */}
        <QuickActions />

        {/* Recent Activity */}
        <div className="lg:col-span-2">
          <RecentActivity logs={recentLogs} />
        </div>
      </motion.div>
    </motion.div>
  )
}
