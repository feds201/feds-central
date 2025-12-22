import { useState } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { motion } from 'framer-motion'
import {
  LayoutDashboard,
  Lock,
  Shield,
  LogOut,
  Menu,
  X,
  Activity,
  User,
  KeyRound,
} from 'lucide-react'
import { authClient } from '@/auth'

const navItems = [
  { label: 'Dashboard', path: '/dashboard', icon: LayoutDashboard },
  { label: 'Services', path: '/services', icon: Lock },
  { label: 'Credentials', path: '/credentials', icon: Shield },
  { label: 'Authenticator', path: '/authenticator', icon: KeyRound },
  { label: 'Activity', path: '/audit', icon: Activity },
  { label: 'Account', path: '/account', icon: User },
]

export default function Sidebar({ session }) {
  const location = useLocation()
  const [isOpen, setIsOpen] = useState(false)

  const handleLogout = async () => {
    if (authClient) {
      await authClient.signOut()
    }
    window.location.href = '/sign-in'
  }

  const SidebarContent = () => (
    <>
      <div className="p-6 border-b border-slate-700/50">
        <div className="flex items-center gap-3">
          <div className="p-2 rounded-xl bg-gradient-to-br from-indigo-600 to-purple-600 shadow-lg shadow-indigo-500/30">
            <Shield size={24} className="text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold gradient-text">FEDS</h1>
            <p className="text-xs text-slate-400">Dev Console</p>
          </div>
        </div>
      </div>

      <nav className="flex-1 p-4 space-y-2">
        {navItems.map((item) => {
          const Icon = item.icon
          const isActive = location.pathname === item.path
          return (
            <Link
              key={item.path}
              to={item.path}
              className="relative block"
              onClick={() => setIsOpen(false)}
            >
              {isActive && (
                <motion.div
                  layoutId="sidebar-indicator"
                  className="absolute inset-0 bg-gradient-to-r from-indigo-600/20 to-rose-600/20 rounded-xl"
                  transition={{ type: 'spring', stiffness: 300, damping: 30 }}
                />
              )}
              <div className="relative flex items-center gap-3 px-4 py-3 rounded-xl text-slate-300 hover:text-slate-100 transition-colors">
                <Icon size={20} />
                <span className="font-medium">{item.label}</span>
                {isActive && (
                  <div className="ml-auto w-2 h-2 rounded-full bg-gradient-to-r from-indigo-400 to-rose-400" />
                )}
              </div>
            </Link>
          )
        })}
      </nav>

      <div className="p-4 border-t border-slate-700/50 space-y-2">
        <button
          onClick={handleLogout}
          className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-slate-300 hover:text-red-400 hover:bg-red-950/20 transition-colors"
        >
          <LogOut size={20} />
          <span className="font-medium">Sign Out</span>
        </button>
      </div>
    </>
  )

  return (
    <>
      {/* Mobile Menu Toggle */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="md:hidden fixed top-4 left-4 z-50 p-2 rounded-lg glass-dark"
      >
        {isOpen ? <X size={24} /> : <Menu size={24} />}
      </button>

      {/* Desktop Sidebar */}
      <aside className="flex flex-col w-64 glass-dark border-r border-slate-700/50">
        <SidebarContent />
      </aside>

      {/* Mobile Sidebar */}
      {isOpen && (
        <motion.aside
          initial={{ x: -300 }}
          animate={{ x: 0 }}
          exit={{ x: -300 }}
          className="md:hidden fixed left-0 top-0 h-full w-64 glass-dark border-r border-slate-700/50 z-40"
        >
          <SidebarContent />
        </motion.aside>
      )}
    </>
  )
}
