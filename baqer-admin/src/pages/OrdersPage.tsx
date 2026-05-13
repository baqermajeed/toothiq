import { useCallback, useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { ApiError } from '../lib/api'
import { adminApi, type Paginated } from '../api/admin'
import { ORDER_STATUS, type OrderStatusKey } from '../lib/constants'

export function OrdersPage() {
  const [data, setData] = useState<Paginated<Record<string, unknown>> | null>(null)
  const [page, setPage] = useState(1)
  const [status, setStatus] = useState('')
  const [search, setSearch] = useState('')
  const [err, setErr] = useState('')
  const [loading, setLoading] = useState(true)

  const load = useCallback(async () => {
    setErr('')
    setLoading(true)
    try {
      const res = await adminApi.orders.list({
        page,
        limit: 20,
        status: status || undefined,
        search: search.trim() || undefined,
      })
      setData(res)
    } catch (e) {
      setErr(e instanceof ApiError ? e.message : 'فشل التحميل')
    } finally {
      setLoading(false)
    }
  }, [page, status, search])

  useEffect(() => {
    void load()
  }, [load])

  const totalPages = data ? Math.max(1, Math.ceil(data.pagination.total / data.pagination.limit)) : 1

  return (
    <div>
      <h1 style={{ marginTop: 0 }}>الطلبات</h1>
      <div className="card">
        <div className="row">
          <div className="field" style={{ flex: 1, minWidth: 140, marginBottom: 0 }}>
            <label>حالة الطلب</label>
            <select className="select" value={status} onChange={(e) => setStatus(e.target.value)}>
              <option value="">الكل</option>
              {(Object.keys(ORDER_STATUS) as OrderStatusKey[]).map((k) => (
                <option key={k} value={k}>
                  {ORDER_STATUS[k]}
                </option>
              ))}
            </select>
          </div>
          <div className="field" style={{ flex: 2, minWidth: 200, marginBottom: 0 }}>
            <label>بحث باسم/هاتف العميل</label>
            <input className="input" value={search} onChange={(e) => setSearch(e.target.value)} />
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
                  <th>المعرّف</th>
                  <th>الحالة</th>
                  <th>المحل</th>
                  <th>العميل</th>
                  <th>التاريخ</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {data.items.map((o) => (
                  <tr key={String(o._id ?? o.id)}>
                    <td dir="ltr" style={{ fontSize: '0.75rem' }}>
                      {String(o._id ?? o.id).slice(-8)}
                    </td>
                    <td>
                      <span className="badge">{ORDER_STATUS[String(o.status) as OrderStatusKey] ?? String(o.status)}</span>
                    </td>
                    <td>{String(o.shopName ?? '')}</td>
                    <td>
                      {String(o.customerName ?? '')}{' '}
                      <span className="muted" dir="ltr">
                        {String(o.customerPhone ?? '')}
                      </span>
                    </td>
                    <td>{o.createdAt ? new Date(String(o.createdAt)).toLocaleString('ar-IQ') : ''}</td>
                    <td>
                      <Link to={`/orders/${String(o._id ?? o.id)}`}>تفاصيل</Link>
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
              صفحة {page} / {totalPages} — {data.pagination.total} طلب
            </span>
            <button type="button" className="btn" disabled={page >= totalPages} onClick={() => setPage((p) => p + 1)}>
              التالي
            </button>
          </div>
        </>
      ) : null}
    </div>
  )
}
