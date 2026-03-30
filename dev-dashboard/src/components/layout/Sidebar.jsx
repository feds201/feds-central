import { useState, useEffect } from 'react'
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
  ShieldCheck,
  MessageCircle,
} from 'lucide-react'
import { authClient } from '@/auth'

const navItems = [
  { label: 'Dashboard', path: '/dashboard', icon: LayoutDashboard },
  { label: 'Services', path: '/services', icon: Lock },
  { label: 'Credentials', path: '/credentials', icon: Shield },
  { label: 'Authenticator', path: '/authenticator', icon: KeyRound },
  { label: 'Password Health', path: '/password-health', icon: ShieldCheck },
  { label: 'FEDSBot Chat', path: '/chat', icon: MessageCircle },
  { label: 'Activity', path: '/audit', icon: Activity },
  { label: 'Account', path: '/account', icon: User },
]

export default function Sidebar({ session }) {
  const location = useLocation()
  const [isOpen, setIsOpen] = useState(false)
  // Robust JS-based responsive check to avoid CSS flakiness
  const [isDesktop, setIsDesktop] = useState(window.innerWidth >= 768)

  useEffect(() => {
    const handleResize = () => {
      setIsDesktop(window.innerWidth >= 768)
      if (window.innerWidth >= 768) setIsOpen(false)
    }

    window.addEventListener('resize', handleResize)
    return () => window.removeEventListener('resize', handleResize)
  }, [])

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
      {/* Mobile Menu Toggle - Only show if NOT desktop */}
      {!isDesktop && (
        <button
          onClick={() => setIsOpen(!isOpen)}
          className="fixed top-4 left-4 z-[100] p-3 rounded-lg bg-indigo-600 shadow-lg text-white hover:bg-indigo-700 transition-colors"
          aria-label="Toggle Menu"
        >
          {isOpen ? <X size={24} /> : <Menu size={24} />}
        </button>
      )}

      {/* Desktop Sidebar - Always visible if isDesktop is true */}
      {isDesktop && (
        <aside className="flex flex-col w-64 glass-dark border-r border-slate-700/50">
          <SidebarContent />
        </aside>
      )}

      {/* Mobile Sidebar Overlay - Only if NOT desktop and isOpen */}
      {!isDesktop && isOpen && (
        <motion.aside
          initial={{ x: -300 }}
          animate={{ x: 0 }}
          exit={{ x: -300 }}
          className="fixed left-0 top-0 h-full w-64 glass-dark border-r border-slate-700/50 z-[90] bg-slate-900/95 backdrop-blur-xl"
        >
          <SidebarContent />
        </motion.aside>
      )}
    </>
  )
}
