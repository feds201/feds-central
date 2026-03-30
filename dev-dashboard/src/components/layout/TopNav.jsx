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
    <div className="h-16 glass-dark border-b border-slate-700/50 px-8 flex items-center justify-end">
      <button
        onClick={toggleTheme}
        className="p-2.5 rounded-xl glass hover:bg-slate-700/50 transition-all hover:scale-110"
        title={isDark ? 'Switch to light mode' : 'Switch to dark mode'}
      >
        {isDark ? <Sun size={20} className="text-amber-400" /> : <Moon size={20} className="text-indigo-400" />}
      </button>
    </div>
  )
}
