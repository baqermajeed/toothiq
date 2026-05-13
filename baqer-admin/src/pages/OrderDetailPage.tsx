import { useEffect, useState, type FormEvent } from 'react'
import { Link, useParams } from 'react-router-dom'
import { ApiError } from '../lib/api'
import { adminApi } from '../api/admin'
import { ORDER_STATUS, type OrderStatusKey } from '../lib/constants'

export function OrderDetailPage() {
  const { id } = useParams<{ id: string }>()
  const [order, setOrder] = useState<Record<string, unknown> | null>(null)
  const [err, setErr] = useState('')
  const [msg, setMsg] = useState('')
  const [status, setStatus] = useState<OrderStatusKey>('pending')
  const [cancelReason, setCancelReason] = useState('')
  const [postponedReason, setPostponedReason] = useState('')

  useEffect(() => {
    if (!id) return
    let cancelled = false
    ;(async () => {
      setErr('')
      try {
        const o = await adminApi.orders.get(id)
        if (cancelled) return
        setOrder(o)
        setStatus((String(o.status) as OrderStatusKey) || 'pending')
      } catch (e) {
        if (!cancelled) setErr(e instanceof ApiError ? e.message : 'فشل التحميل')
      }
    })()
    return () => {
      cancelled = true
    }
  }, [id])

  async function onStatus(e: FormEvent) {
    e.preventDefault()
    if (!id) return
    setErr('')
    setMsg('')
    try {
      const body: Record<string, unknown> = { status }
      if (cancelReason) body.cancelReason = cancelReason
      if (postponedReason) body.postponedReason = postponedReason
      const o = await adminApi.orders.patchStatus(id, body)
      setOrder(o)
      setMsg('تم تحديث الحالة')
    } catch (ex) {
      setErr(ex instanceof ApiError ? ex.message : 'فشل')
    }
  }

  async function onDelete() {
    if (!id) return
    if (!window.confirm('حذف الطلب نهائياً؟')) return
    setErr('')
    try {
      await adminApi.orders.remove(id)
      window.location.href = '/orders'
    } catch (ex) {
      setErr(ex instanceof ApiError ? ex.message : 'فشل')
    }
  }

  async function deliverStale() {
    setErr('')
    setMsg('')
    try {
      const r = await adminApi.orders.deliverStale()
      setMsg(`تم تحديث طلبات قديمة: ${r.updatedCount}`)
    } catch (ex) {
      setErr(ex instanceof ApiError ? ex.message : 'فشل')
    }
  }

  if (err && !order) return <div className="alert alert-error">{err}</div>
  if (!order) return <p className="muted">جاري التحميل…</p>

  return (
    <div>
      <p>
        <Link to="/orders">← الطلبات</Link>
      </p>
      <h1 style={{ marginTop: 0 }}>طلب {String(order._id ?? order.id).slice(-8)}</h1>
      {err ? <div className="alert alert-error">{err}</div> : null}
      {msg ? <div className="alert alert-success">{msg}</div> : null}

      <div className="card">
        <p>
          <strong>الحالة:</strong> {ORDER_STATUS[String(order.status) as OrderStatusKey] ?? String(order.status)}
        </p>
        <p>
          <strong>المحل:</strong> {String(order.shopName ?? '')}
        </p>
        <p>
          <strong>العميل:</strong> {String(order.customerName ?? '')} — {String(order.customerPhone ?? '')}
        </p>
        <p>
          <strong>الإجمالي:</strong> {String(order.totalPrice ?? '')} + توصيل {String(order.deliveryFee ?? '')}
        </p>
        <pre
          style={{
            background: 'var(--bg)',
            padding: '1rem',
            borderRadius: 8,
            fontSize: '0.75rem',
            overflow: 'auto',
            maxHeight: 320,
            border: '1px solid var(--border)',
          }}
        >
          {JSON.stringify(order, null, 2)}
        </pre>
      </div>

      <div className="card">
        <h2>تحديث الحالة</h2>
        <form onSubmit={onStatus}>
          <div className="field">
            <label>الحالة</label>
            <select className="select" value={status} onChange={(e) => setStatus(e.target.value as OrderStatusKey)}>
              {(Object.keys(ORDER_STATUS) as OrderStatusKey[]).map((k) => (
                <option key={k} value={k}>
                  {ORDER_STATUS[k]}
                </option>
              ))}
            </select>
          </div>
          <div className="field">
            <label>سبب الإلغاء (إن وُجد)</label>
            <input className="input" value={cancelReason} onChange={(e) => setCancelReason(e.target.value)} />
          </div>
          <div className="field">
            <label>سبب التأجيل</label>
            <input className="input" value={postponedReason} onChange={(e) => setPostponedReason(e.target.value)} />
          </div>
          <button type="submit" className="btn btn-primary">
            تطبيق الحالة
          </button>
        </form>
      </div>

      <div className="card">
        <h2>أدوات</h2>
        <button type="button" className="btn btn-danger" onClick={() => void onDelete()}>
          حذف الطلب
        </button>{' '}
        <button type="button" className="btn" onClick={() => void deliverStale()}>
          تسليم صامت لطلبات «في الطريق» القديمة
        </button>
        <p className="muted" style={{ marginTop: '0.5rem' }}>
          زر التسليم الصامت يستدعي مسار الأدمن العام وليس هذا الطلب فقط.
        </p>
      </div>
    </div>
  )
}
