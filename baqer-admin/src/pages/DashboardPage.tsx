import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { ApiError } from '../lib/api'
import { adminApi } from '../api/admin'
import { ORDER_STATUS, type OrderStatusKey } from '../lib/constants'

type Stats = {
  users?: number
  shops?: number
  products?: number
  orders?: number
  ordersByStatus?: Record<string, number>
}

export function DashboardPage() {
  const [stats, setStats] = useState<Stats | null>(null)
  const [ordersAgg, setOrdersAgg] = useState<unknown>(null)
  const [err, setErr] = useState('')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let cancelled = false
    ;(async () => {
      setErr('')
      setLoading(true)
      try {
        const [s, o] = await Promise.all([adminApi.stats(), adminApi.ordersStats({ days: '14' })])
        if (!cancelled) {
          setStats(s as Stats)
          setOrdersAgg(o)
        }
      } catch (e) {
        if (!cancelled) setErr(e instanceof ApiError ? e.message : 'فشل التحميل')
      } finally {
        if (!cancelled) setLoading(false)
      }
    })()
    return () => {
      cancelled = true
    }
  }, [])

  if (loading) return <p className="muted">جاري تحميل الإحصائيات…</p>
  if (err) return <div className="alert alert-error">{err}</div>

  return (
    <div>
      <h1 style={{ marginTop: 0 }}>نظرة عامة</h1>
      <div className="stats-grid">
        <div className="stat-box">
          <div className="lbl">المستخدمون</div>
          <div className="val">{stats?.users ?? '—'}</div>
        </div>
        <div className="stat-box">
          <div className="lbl">المحلات</div>
          <div className="val">{stats?.shops ?? '—'}</div>
        </div>
        <div className="stat-box">
          <div className="lbl">المنتجات</div>
          <div className="val">{stats?.products ?? '—'}</div>
        </div>
        <div className="stat-box">
          <div className="lbl">الطلبات</div>
          <div className="val">{stats?.orders ?? '—'}</div>
        </div>
      </div>

      {stats?.ordersByStatus ? (
        <div className="card" style={{ marginTop: '1.5rem' }}>
          <h2>الطلبات حسب الحالة</h2>
          <div className="table-wrap">
            <table className="data">
              <thead>
                <tr>
                  <th>الحالة</th>
                  <th>العدد</th>
                </tr>
              </thead>
              <tbody>
                {Object.entries(stats.ordersByStatus).map(([k, v]) => (
                  <tr key={k}>
                    <td>{ORDER_STATUS[k as OrderStatusKey] ?? k}</td>
                    <td>{v}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      ) : null}

      <div className="card" style={{ marginTop: '1rem' }}>
        <h2>إحصائيات الطلبات (تفصيلية)</h2>
        <p className="muted">آخر ١٤ يوماً — من المسار GET /api/admin/orders/stats</p>
        <pre
          style={{
            background: 'var(--bg)',
            padding: '1rem',
            borderRadius: 8,
            overflow: 'auto',
            fontSize: '0.8rem',
            border: '1px solid var(--border)',
          }}
        >
          {JSON.stringify(ordersAgg, null, 2)}
        </pre>
      </div>

      <p style={{ marginTop: '1.5rem' }}>
        <Link to="/orders">إدارة الطلبات</Link>
        {' — '}
        <Link to="/settings">إعدادات المنصة</Link>
      </p>
    </div>
  )
}
