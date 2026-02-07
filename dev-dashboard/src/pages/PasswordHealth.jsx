import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { Shield, AlertTriangle, CheckCircle, XCircle, TrendingUp, Clock, Download, Upload } from 'lucide-react'
import { db } from '@/lib/db'

export default function PasswordHealth({ session }) {
  const [credentials, setCredentials] = useState([])
  const [services, setServices] = useState([])
  const [loading, setLoading] = useState(true)
  const [healthStats, setHealthStats] = useState({
    total: 0,
    strong: 0,
    moderate: 0,
    weak: 0,
    veryWeak: 0,
    reused: 0,
    score: 0,
  })

  useEffect(() => {
    fetchData()
  }, [session])

  const fetchData = async () => {
    if (!session?.user?.id) {
      setLoading(false)
      return
    }

    try {
      setLoading(true)
      const userId = session.user.id

      const credData = await db(
        'SELECT * FROM credentials WHERE owner_id = $1 ORDER BY created_at DESC',
        [userId]
      )
      const servData = await db('SELECT * FROM services WHERE owner_id = $1', [userId])

      setCredentials(credData || [])
      setServices(servData || [])
      analyzePasswords(credData || [])
    } catch (error) {
      console.error('Error fetching data:', error)
    } finally {
      setLoading(false)
    }
  }

  const calculatePasswordStrength = (password) => {
    let score = 0
    if (!password) return 0

    if (password.length >= 12) score += 20
    if (password.length >= 16) score += 10
    if (password.length >= 20) score += 10
    if (/[a-z]/.test(password)) score += 15
    if (/[A-Z]/.test(password)) score += 15
    if (/[0-9]/.test(password)) score += 15
    if (/[^a-zA-Z0-9]/.test(password)) score += 15

    return Math.min(score, 100)
  }

  const getStrengthCategory = (score) => {
    if (score >= 80) return 'strong'
    if (score >= 60) return 'moderate'
    if (score >= 40) return 'weak'
    return 'veryWeak'
  }

  const analyzePasswords = (creds) => {
    const passwordMap = new Map()
    let strong = 0, moderate = 0, weak = 0, veryWeak = 0

    creds.forEach((cred) => {
      const score = calculatePasswordStrength(cred.password_encrypted)
      const category = getStrengthCategory(score)

      if (category === 'strong') strong++
      else if (category === 'moderate') moderate++
      else if (category === 'weak') weak++
      else veryWeak++

      // Track password reuse
      const pwd = cred.password_encrypted
      if (passwordMap.has(pwd)) {
        passwordMap.set(pwd, passwordMap.get(pwd) + 1)
      } else {
        passwordMap.set(pwd, 1)
      }
    })

    const reused = Array.from(passwordMap.values()).filter((count) => count > 1).length

    // Calculate overall health score
    const total = creds.length || 1
    const score = Math.round(
      ((strong * 100 + moderate * 60 + weak * 30 + veryWeak * 10) / total) * 0.8 +
      ((total - reused) / total) * 20
    )

    setHealthStats({
      total: creds.length,
      strong,
      moderate,
      weak,
      veryWeak,
      reused,
      score,
    })
  }

  const exportData = () => {
    const data = {
      services,
      credentials: credentials.map((c) => ({
        ...c,
        password_encrypted: '***REDACTED***', // Don't export actual passwords
      })),
      exportedAt: new Date().toISOString(),
    }

    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `feds-backup-${new Date().toISOString().split('T')[0]}.json`
    a.click()
    URL.revokeObjectURL(url)
  }

  const getScoreColor = () => {
    if (healthStats.score >= 80) return 'from-emerald-500 to-green-500'
    if (healthStats.score >= 60) return 'from-yellow-500 to-amber-500'
    if (healthStats.score >= 40) return 'from-orange-500 to-orange-600'
    return 'from-red-500 to-red-600'
  }

  const getScoreGrade = () => {
    if (healthStats.score >= 90) return 'A+'
    if (healthStats.score >= 80) return 'A'
    if (healthStats.score >= 70) return 'B'
    if (healthStats.score >= 60) return 'C'
    if (healthStats.score >= 50) return 'D'
    return 'F'
  }

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-slate-100">Password Health</h1>
          <p className="text-slate-400 mt-1">Analyze and improve your password security</p>
        </div>
        <button onClick={exportData} className="btn-secondary flex items-center gap-2">
          <Download size={20} />
          Export Backup
        </button>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin">
            <div className="w-12 h-12 border-4 border-slate-700 border-t-indigo-500 rounded-full"></div>
          </div>
        </div>
      ) : (
        <>
          {/* Overall Score */}
          <div className="card">
            <div className="flex items-center justify-between mb-6">
              <div>
                <h2 className="text-2xl font-bold text-slate-100">Security Score</h2>
                <p className="text-sm text-slate-400 mt-1">Based on password strength and reuse</p>
              </div>
              <div className="text-center">
                <div className={`text-6xl font-bold bg-gradient-to-r ${getScoreColor()} bg-clip-text text-transparent`}>
                  {getScoreGrade()}
                </div>
                <div className="text-sm text-slate-400 mt-1">{healthStats.score}/100</div>
              </div>
            </div>

            <div className="space-y-2">
              <div className="flex items-center justify-between text-sm">
                <span className="text-slate-400">Overall Health</span>
                <span className={`font-semibold bg-gradient-to-r ${getScoreColor()} bg-clip-text text-transparent`}>
                  {healthStats.score >= 80 ? 'Excellent' : healthStats.score >= 60 ? 'Good' : healthStats.score >= 40 ? 'Fair' : 'Poor'}
                </span>
              </div>
              <div className="h-3 bg-slate-700 rounded-full overflow-hidden">
                <motion.div
                  initial={{ width: 0 }}
                  animate={{ width: `${healthStats.score}%` }}
                  className={`h-full bg-gradient-to-r ${getScoreColor()}`}
                  transition={{ duration: 1, ease: 'easeOut' }}
                />
              </div>
            </div>
          </div>

          {/* Stats Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
            <motion.div whileHover={{ scale: 1.02 }} className="card">
              <div className="flex items-center gap-3">
                <div className="p-3 rounded-xl bg-gradient-to-br from-emerald-600 to-green-600">
                  <CheckCircle size={24} className="text-white" />
                </div>
                <div>
                  <p className="text-2xl font-bold text-slate-100">{healthStats.strong}</p>
                  <p className="text-xs text-slate-400">Strong</p>
                </div>
              </div>
            </motion.div>

            <motion.div whileHover={{ scale: 1.02 }} className="card">
              <div className="flex items-center gap-3">
                <div className="p-3 rounded-xl bg-gradient-to-br from-yellow-600 to-amber-600">
                  <TrendingUp size={24} className="text-white" />
                </div>
                <div>
                  <p className="text-2xl font-bold text-slate-100">{healthStats.moderate}</p>
                  <p className="text-xs text-slate-400">Moderate</p>
                </div>
              </div>
            </motion.div>

            <motion.div whileHover={{ scale: 1.02 }} className="card">
              <div className="flex items-center gap-3">
                <div className="p-3 rounded-xl bg-gradient-to-br from-orange-600 to-orange-700">
                  <AlertTriangle size={24} className="text-white" />
                </div>
                <div>
                  <p className="text-2xl font-bold text-slate-100">{healthStats.weak}</p>
                  <p className="text-xs text-slate-400">Weak</p>
                </div>
              </div>
            </motion.div>

            <motion.div whileHover={{ scale: 1.02 }} className="card">
              <div className="flex items-center gap-3">
                <div className="p-3 rounded-xl bg-gradient-to-br from-red-600 to-red-700">
                  <XCircle size={24} className="text-white" />
                </div>
                <div>
                  <p className="text-2xl font-bold text-slate-100">{healthStats.veryWeak}</p>
                  <p className="text-xs text-slate-400">Very Weak</p>
                </div>
              </div>
            </motion.div>

            <motion.div whileHover={{ scale: 1.02 }} className="card">
              <div className="flex items-center gap-3">
                <div className="p-3 rounded-xl bg-gradient-to-br from-purple-600 to-pink-600">
                  <Clock size={24} className="text-white" />
                </div>
                <div>
                  <p className="text-2xl font-bold text-slate-100">{healthStats.reused}</p>
                  <p className="text-xs text-slate-400">Reused</p>
                </div>
              </div>
            </motion.div>
          </div>

          {/* Recommendations */}
          <div className="card">
            <h3 className="text-xl font-bold text-slate-100 mb-4">Security Recommendations</h3>
            <div className="space-y-3">
              {healthStats.veryWeak > 0 && (
                <div className="flex items-start gap-3 p-3 rounded-xl bg-red-950/20 border border-red-500/30">
                  <XCircle size={20} className="text-red-400 flex-shrink-0 mt-0.5" />
                  <div>
                    <p className="text-sm font-semibold text-red-300">
                      Replace {healthStats.veryWeak} very weak password{healthStats.veryWeak > 1 ? 's' : ''}
                    </p>
                    <p className="text-xs text-red-400 mt-1">
                      These passwords are highly vulnerable. Update them immediately with stronger alternatives.
                    </p>
                  </div>
                </div>
              )}

              {healthStats.weak > 0 && (
                <div className="flex items-start gap-3 p-3 rounded-xl bg-orange-950/20 border border-orange-500/30">
                  <AlertTriangle size={20} className="text-orange-400 flex-shrink-0 mt-0.5" />
                  <div>
                    <p className="text-sm font-semibold text-orange-300">
                      Strengthen {healthStats.weak} weak password{healthStats.weak > 1 ? 's' : ''}
                    </p>
                    <p className="text-xs text-orange-400 mt-1">
                      Use longer passwords with mixed case, numbers, and special characters.
                    </p>
                  </div>
                </div>
              )}

              {healthStats.reused > 0 && (
                <div className="flex items-start gap-3 p-3 rounded-xl bg-purple-950/20 border border-purple-500/30">
                  <Clock size={20} className="text-purple-400 flex-shrink-0 mt-0.5" />
                  <div>
                    <p className="text-sm font-semibold text-purple-300">
                      {healthStats.reused} password{healthStats.reused > 1 ? 's are' : ' is'} reused across multiple services
                    </p>
                    <p className="text-xs text-purple-400 mt-1">
                      Reusing passwords increases risk. Create unique passwords for each service.
                    </p>
                  </div>
                </div>
              )}

              {healthStats.score >= 80 && (
                <div className="flex items-start gap-3 p-3 rounded-xl bg-emerald-950/20 border border-emerald-500/30">
                  <CheckCircle size={20} className="text-emerald-400 flex-shrink-0 mt-0.5" />
                  <div>
                    <p className="text-sm font-semibold text-emerald-300">Great job! Your passwords are secure</p>
                    <p className="text-xs text-emerald-400 mt-1">
                      Keep up the good work. Remember to update passwords periodically.
                    </p>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Credential List with Health Indicators */}
          <div className="card">
            <h3 className="text-xl font-bold text-slate-100 mb-4">Password Details</h3>
            <div className="space-y-2">
              {credentials.length === 0 ? (
                <p className="text-center text-slate-400 py-8">No credentials to analyze</p>
              ) : (
                credentials.map((cred) => {
                  const service = services.find((s) => s.id === cred.service_id)
                  const strength = calculatePasswordStrength(cred.password_encrypted)
                  const category = getStrengthCategory(strength)
                  
                  const categoryConfig = {
                    strong: { color: 'emerald', label: 'Strong', icon: CheckCircle },
                    moderate: { color: 'yellow', label: 'Moderate', icon: TrendingUp },
                    weak: { color: 'orange', label: 'Weak', icon: AlertTriangle },
                    veryWeak: { color: 'red', label: 'Very Weak', icon: XCircle },
                  }
                  
                  const config = categoryConfig[category]
                  const Icon = config.icon

                  return (
                    <div key={cred.id} className="flex items-center justify-between p-3 rounded-xl bg-slate-800/30 hover:bg-slate-800/50 transition-colors">
                      <div className="flex items-center gap-3 flex-1">
                        <Icon size={20} className={`text-${config.color}-400`} />
                        <div>
                          <p className="text-sm font-semibold text-slate-200">{service?.name || 'Unknown Service'}</p>
                          <p className="text-xs text-slate-400">{cred.username}</p>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className={`text-sm font-semibold text-${config.color}-400`}>{config.label}</p>
                        <p className="text-xs text-slate-500">{strength}/100</p>
                      </div>
                    </div>
                  )
                })
              )}
            </div>
          </div>
        </>
      )}
    </motion.div>
  )
}
