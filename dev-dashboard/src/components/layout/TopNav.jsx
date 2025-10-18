import { Moon, Sun } from 'lucide-react'
import { useEffect, useState } from 'react'

export default function TopNav({ session }) {
  const [isDark, setIsDark] = useState(true)

  useEffect(() => {
    // Check for saved theme preference
    const saved = localStorage.getItem('theme')
    if (saved === 'light') {
      setIsDark(false)
      document.documentElement.classList.remove('dark')
    }
  }, [])

  const toggleTheme = () => {
    if (isDark) {
      localStorage.setItem('theme', 'light')
      document.documentElement.classList.add('light')
      setIsDark(false)
    } else {
      localStorage.setItem('theme', 'dark')
      document.documentElement.classList.remove('light')
      setIsDark(true)
    }
  }

  return (
    <div className="h-16 glass-dark border-b border-slate-700/50 px-8 flex items-center justify-between">
      <div className="hidden md:flex items-center gap-4">
        <h2 className="text-lg font-semibold text-slate-100">
          Welcome back, {session?.user?.email?.split('@')[0]}
        </h2>
      </div>

      <button
        onClick={toggleTheme}
        className="p-2 rounded-lg glass hover:bg-white/20 transition-colors"
      >
        {isDark ? <Sun size={20} /> : <Moon size={20} />}
      </button>
    </div>
  )
}
