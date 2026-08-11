import { useEffect, useState, type FormEvent } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { ApiError } from '../lib/api'
import { adminApi } from '../api/admin'
import { fetchGovernorates } from '../api/admin'
import { ROLES } from '../lib/constants'

export function UserDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const isNew = id === 'new'

  const [user, setUser] = useState<Record<string, unknown> | null>(null)
  const [govs, setGovs] = useState<{ id: string; nameAr: string }[]>([])
  const [name, setName] = useState('')
  const [phone, setPhone] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [roles, setRoles] = useState<string[]>(['shop'])
  const [governorateId, setGovernorateId] = useState('')
  const [clinicName, setClinicName] = useState('')
  const [err, setErr] = useState('')
  const [msg, setMsg] = useState('')
  const [loading, setLoading] = useState(!isNew)

  useEffect(() => {
    void fetchGovernorates().then(setGovs).catch(() => {})
  }, [])

  useEffect(() => {
    if (isNew || !id) {
      setLoading(false)
      return
    }
    let cancelled = false
    ;(async () => {
      setErr('')
      setLoading(true)
      try {
        const u = await adminApi.users.get(id)
        if (cancelled) return
        setUser(u)
        setName(String(u.name ?? ''))
        setPhone(String(u.phone ?? ''))
        setEmail(String(u.email ?? ''))
        setRoles(Array.isArray(u.roles) ? (u.roles as string[]) : [])
        setGovernorateId(String(u.governorateId ?? ''))
        setClinicName(String(u.clinicName ?? ''))
      } catch (e) {
        if (!cancelled) setErr(e instanceof ApiError ? e.message : 'فشل التحميل')
      } finally {
        if (!cancelled) setLoading(false)
      }
    })()
    return () => {
      cancelled = true
    }
  }, [id, isNew])

  async function onSave(e: FormEvent) {
    e.preventDefault()
    setErr('')
    setMsg('')
    try {
      if (isNew) {
        await adminApi.users.create({
          name,
          phone,
          email: email || null,
          password,
          roles,
          governorateId: governorateId || null,
          clinicName: clinicName || null,
        })
        setMsg('تم الإنشاء')
        navigate('/users')
        return
      }
      if (!id) return
      await adminApi.users.patch(id, {
        name,
        phone,
        email: email || null,
        roles,
      })
      setMsg('تم الحفظ')
    } catch (ex) {
      setErr(ex instanceof ApiError ? ex.message : 'فشل الحفظ')
    }
  }

  async function toggleActive() {
    if (!id || isNew || !user) return
    setErr('')
    try {
      const next = !user.isActive
      await adminApi.users.setActive(id, next)
      setUser({ ...user, isActive: next })
      setMsg(next ? 'تم التفعيل' : 'تم التعطيل')
    } catch (ex) {
      setErr(ex instanceof ApiError ? ex.message : 'فشل')
    }
  }

  async function removeUser() {
    if (!id || isNew) return
    if (!window.confirm('حذف المستخدم نهائياً؟')) return
    setErr('')
    try {
      await adminApi.users.remove(id)
      navigate('/users')
    } catch (ex) {
      setErr(ex instanceof ApiError ? ex.message : 'فشل الحذف')
    }
  }

  if (loading) return <p className="muted">جاري التحميل…</p>

  return (
    <div>
      <p>
        <Link to="/users">← المستخدمون</Link>
      </p>
      <h1 style={{ marginTop: 0 }}>{isNew ? 'مستخدم جديد' : 'تفاصيل المستخدم'}</h1>
      {err ? <div className="alert alert-error">{err}</div> : null}
      {msg ? <div className="alert alert-success">{msg}</div> : null}

      <form className="card" onSubmit={onSave}>
        <div className="field">
          <label>الاسم</label>
          <input className="input" value={name} onChange={(e) => setName(e.target.value)} required />
        </div>
        <div className="field">
          <label>الهاتف (١١ رقماً)</label>
          <input
            className="input"
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            required
            dir="ltr"
            style={{ textAlign: 'left' }}
          />
        </div>
        <div className="field">
          <label>البريد</label>
          <input className="input" type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
        </div>
        {isNew ? (
          <div className="field">
            <label>كلمة المرور</label>
            <input
              className="input"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              minLength={8}
            />
          </div>
        ) : null}
        <div className="field">
          <label>المحافظة</label>
          <select className="select" value={governorateId} onChange={(e) => setGovernorateId(e.target.value)}>
            <option value="">—</option>
            {govs.map((g) => (
              <option key={g.id} value={g.id}>
                {g.nameAr}
              </option>
            ))}
          </select>
        </div>
        <div className="field">
          <label>اسم العيادة (اختياري)</label>
          <input className="input" value={clinicName} onChange={(e) => setClinicName(e.target.value)} />
        </div>
        <div className="field">
          <label>الأدوار</label>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem' }}>
            {ROLES.map((r) => (
              <label key={r} className="muted" style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                <input
                  type="checkbox"
                  checked={roles.includes(r)}
                  onChange={() => {
                    setRoles((prev) => (prev.includes(r) ? prev.filter((x) => x !== r) : [...prev, r]))
                  }}
                />
                {r}
              </label>
            ))}
          </div>
        </div>
        <button type="submit" className="btn btn-primary">
          {isNew ? 'إنشاء' : 'حفظ التعديلات'}
        </button>
      </form>

      {!isNew && user ? (
        <div className="card" style={{ marginTop: '1rem' }}>
          <h2>إجراءات</h2>
          <p className="muted">الحالة الحالية: {user.isActive ? 'نشط' : 'معطّل'}</p>
          <button type="button" className="btn" onClick={() => void toggleActive()}>
            {user.isActive ? 'تعطيل الحساب' : 'تفعيل الحساب'}
          </button>{' '}
          <button type="button" className="btn btn-danger" onClick={() => void removeUser()}>
            حذف المستخدم
          </button>
        </div>
      ) : null}
    </div>
  )
}
