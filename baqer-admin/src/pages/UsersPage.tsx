import { useCallback, useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { ApiError } from '../lib/api'
import { adminApi, type Paginated } from '../api/admin'

export function UsersPage() {
  const [data, setData] = useState<Paginated<Record<string, unknown>> | null>(null)
  const [page, setPage] = useState(1)
  const [q, setQ] = useState('')
  const [role, setRole] = useState('')
  const [err, setErr] = useState('')
  const [loading, setLoading] = useState(true)

  const load = useCallback(async () => {
    setErr('')
    setLoading(true)
    try {
      const res = await adminApi.users.list({
        page,
        limit: 20,
        q: q.trim() || undefined,
        role: role || undefined,
      })
      setData(res)
    } catch (e) {
      setErr(e instanceof ApiError ? e.message : 'فشل التحميل')
    } finally {
      setLoading(false)
    }
  }, [page, q, role])

  useEffect(() => {
    void load()
  }, [load])

  const totalPages = data ? Math.max(1, Math.ceil(data.pagination.total / data.pagination.limit)) : 1

  return (
    <div>
      <h1 style={{ marginTop: 0 }}>المستخدمون</h1>
      <div className="card">
        <div className="row">
          <div className="field" style={{ flex: 1, minWidth: 200, marginBottom: 0 }}>
            <label>بحث (اسم / هاتف / بريد)</label>
            <input className="input" value={q} onChange={(e) => setQ(e.target.value)} placeholder="بحث…" />
          </div>
          <div className="field" style={{ width: 160, marginBottom: 0 }}>
            <label>الدور</label>
            <select className="select" value={role} onChange={(e) => setRole(e.target.value)}>
              <option value="">الكل</option>
              <option value="customer">عميل</option>
              <option value="shop">محل</option>
              <option value="driver">سائق</option>
              <option value="admin">مدير</option>
            </select>
          </div>
          <button type="button" className="btn btn-primary" onClick={() => setPage(1)}>
            تطبيق
          </button>
        </div>
      </div>
      {err ? <div className="alert alert-error">{err}</div> : null}
      {loading ? <p className="muted">جاري التحميل…</p> : null}
      {!loading && data ? (
        <>
          <div className="table-wrap">
            <table className="data">
              <thead>
                <tr>
                  <th>الاسم</th>
                  <th>الهاتف</th>
                  <th>الأدوار</th>
                  <th>تقييم السائق</th>
                  <th>نشط</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {data.items.map((u) => (
                  <tr key={String(u._id)}>
                    <td>{String(u.name ?? '')}</td>
                    <td dir="ltr" style={{ textAlign: 'start' }}>
                      {String(u.phone ?? '')}
                    </td>
                    <td>{Array.isArray(u.roles) ? u.roles.join(', ') : ''}</td>
                    <td>
                      {Array.isArray(u.roles) && (u.roles as string[]).includes('driver')
                        ? `${Number(u.rating ?? 0).toFixed(1)} (${Number(u.ratingCount ?? 0)})`
                        : '—'}
                    </td>
                    <td>{u.isActive ? 'نعم' : 'لا'}</td>
                    <td>
                      <Link to={`/users/${String(u._id)}`}>تفاصيل</Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className="pager">
            <button type="button" className="btn" disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>
              السابق
            </button>
            <span className="muted">
              صفحة {page} من {totalPages} (إجمالي {data.pagination.total})
            </span>
            <button
              type="button"
              className="btn"
              disabled={page >= totalPages}
              onClick={() => setPage((p) => p + 1)}
            >
              التالي
            </button>
          </div>
        </>
      ) : null}
      <p>
        <Link to="/users/new">إنشاء مستخدم جديد</Link> (استخدم صفحة التفاصيل مع المسار /users/new — انظر أدناه)
      </p>
    </div>
  )
}
