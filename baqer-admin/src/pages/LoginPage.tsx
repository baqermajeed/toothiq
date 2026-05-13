import { useState, type FormEvent } from 'react'
import { Navigate, useNavigate } from 'react-router-dom'
import { ApiError } from '../lib/api'
import { useAuth } from '../context/AuthContext'

export function LoginPage() {
  const { token, login, ready } = useAuth()
  const navigate = useNavigate()
  const [phone, setPhone] = useState('')
  const [password, setPassword] = useState('')
  const [err, setErr] = useState('')
  const [loading, setLoading] = useState(false)

  if (ready && token) return <Navigate to="/" replace />

  async function onSubmit(e: FormEvent) {
    e.preventDefault()
    setErr('')
    setLoading(true)
    try {
      await login(phone.trim(), password)
      navigate('/', { replace: true })
    } catch (ex) {
      setErr(ex instanceof ApiError ? ex.message : 'حدث خطأ')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="login-page">
      <div className="card login-card">
        <h1 style={{ marginTop: 0, fontSize: '1.25rem' }}>باقر داشبورد</h1>
        <p className="muted">تسجيل دخول الإدارة — رقم الهاتف ١١ رقماً (مثل 07xxxxxxxx) وكلمة المرور.</p>
        {err ? <div className="alert alert-error">{err}</div> : null}
        <form onSubmit={onSubmit}>
          <div className="field">
            <label htmlFor="phone">الهاتف</label>
            <input
              id="phone"
              className="input"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              autoComplete="username"
              dir="ltr"
              style={{ textAlign: 'left' }}
            />
          </div>
          <div className="field">
            <label htmlFor="password">كلمة المرور</label>
            <input
              id="password"
              type="password"
              className="input"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoComplete="current-password"
            />
          </div>
          <button type="submit" className="btn btn-primary" disabled={loading} style={{ width: '100%' }}>
            {loading ? 'جاري الدخول…' : 'دخول'}
          </button>
        </form>
      </div>
    </div>
  )
}
