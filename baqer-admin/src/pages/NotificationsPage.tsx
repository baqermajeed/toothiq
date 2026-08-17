import { useEffect, useState, type FormEvent } from 'react'
import { ApiError } from '../lib/api'
import { adminApi } from '../api/admin'

type TargetType = 'product' | 'store'

export function NotificationsPage() {
  const [err, setErr] = useState('')
  const [msg, setMsg] = useState('')
  const [sending, setSending] = useState(false)
  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const [targetType, setTargetType] = useState<TargetType>('product')
  const [shopId, setShopId] = useState('')
  const [productId, setProductId] = useState('')
  const [shops, setShops] = useState<Record<string, unknown>[]>([])
  const [products, setProducts] = useState<Record<string, unknown>[]>([])
  const [loadingLists, setLoadingLists] = useState(false)

  async function loadShops() {
    const res = await adminApi.shops.list({ page: 1, limit: 200 })
    setShops(res.items || [])
  }

  async function loadProducts(forShopId?: string) {
    const res = await adminApi.products.list({
      page: 1,
      limit: 200,
      shopId: forShopId || undefined,
    })
    setProducts(res.items || [])
  }

  useEffect(() => {
    setLoadingLists(true)
    void Promise.all([loadShops(), loadProducts()])
      .catch((e) => setErr(e instanceof ApiError ? e.message : 'فشل تحميل القوائم'))
      .finally(() => setLoadingLists(false))
  }, [])

  useEffect(() => {
    if (targetType !== 'product') return
    void loadProducts(shopId || undefined).catch(() => {})
  }, [shopId, targetType])

  async function onSubmit(e: FormEvent) {
    e.preventDefault()
    setErr('')
    setMsg('')
    setSending(true)
    try {
      const payload =
        targetType === 'product'
          ? {
              title: title.trim(),
              body: body.trim(),
              type: 'product' as const,
              productId,
              shopId: shopId || undefined,
            }
          : {
              title: title.trim(),
              body: body.trim(),
              type: 'store' as const,
              shopId,
            }

      if (targetType === 'product' && !productId) {
        setErr('اختر منتجاً')
        return
      }
      if (targetType === 'store' && !shopId) {
        setErr('اختر متجراً')
        return
      }

      const result = await adminApi.notifications.broadcast(payload)
      const inboxCount = Number(result.inboxCount ?? 0)
      setMsg(`تم إرسال الإشعار إلى ${inboxCount} عميل`)
      setTitle('')
      setBody('')
      setProductId('')
    } catch (ex) {
      setErr(ex instanceof ApiError ? ex.message : 'فشل إرسال الإشعار')
    } finally {
      setSending(false)
    }
  }

  function itemId(item: Record<string, unknown>) {
    return String(item._id ?? item.id ?? '')
  }

  function itemLabel(item: Record<string, unknown>) {
    return String(item.nameAr ?? item.name ?? item.title ?? itemId(item))
  }

  return (
    <div>
      <h1 style={{ marginTop: 0 }}>إرسال إشعار</h1>
      <p className="muted">
        إشعار لجميع العملاء — عند الضغط يفتح المنتج أو المتجر في تطبيق الزبون.
        طلبات الزبائن الجديدة تُرسل تلقائياً لتطبيق التاجر، وبعد قبول المتجر تُرسل للسائقين.
      </p>
      {err ? <div className="alert alert-error">{err}</div> : null}
      {msg ? <div className="alert alert-success">{msg}</div> : null}

      <form className="card" onSubmit={onSubmit}>
        <div className="field">
          <label>نوع الهدف</label>
          <select
            className="select"
            value={targetType}
            onChange={(e) => {
              setTargetType(e.target.value as TargetType)
              setProductId('')
            }}
          >
            <option value="product">منتج</option>
            <option value="store">متجر</option>
          </select>
        </div>

        <div className="field">
          <label>العنوان</label>
          <input
            className="input"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            required
            minLength={2}
            placeholder="مثال: عرض جديد"
          />
        </div>

        <div className="field">
          <label>نص الإشعار</label>
          <textarea
            className="input"
            value={body}
            onChange={(e) => setBody(e.target.value)}
            required
            minLength={2}
            rows={3}
            placeholder="اكتب نص الإشعار الذي يظهر للعميل"
          />
        </div>

        <div className="field">
          <label>{targetType === 'store' ? 'المتجر' : 'المتجر (اختياري للتصفية)'}</label>
          <select
            className="select"
            value={shopId}
            onChange={(e) => {
              setShopId(e.target.value)
              setProductId('')
            }}
            required={targetType === 'store'}
            disabled={loadingLists}
          >
            <option value="">{targetType === 'store' ? 'اختر متجراً' : 'كل المتاجر'}</option>
            {shops.map((s) => (
              <option key={itemId(s)} value={itemId(s)}>
                {itemLabel(s)}
              </option>
            ))}
          </select>
        </div>

        {targetType === 'product' ? (
          <div className="field">
            <label>المنتج</label>
            <select
              className="select"
              value={productId}
              onChange={(e) => {
                const id = e.target.value
                setProductId(id)
                const found = products.find((p) => itemId(p) === id)
                const sid = found?.shopId
                if (sid && typeof sid === 'object' && sid !== null && '_id' in (sid as object)) {
                  setShopId(String((sid as { _id: unknown })._id))
                } else if (sid) {
                  setShopId(String(sid))
                }
              }}
              required
              disabled={loadingLists}
            >
              <option value="">اختر منتجاً</option>
              {products.map((p) => (
                <option key={itemId(p)} value={itemId(p)}>
                  {itemLabel(p)}
                </option>
              ))}
            </select>
          </div>
        ) : null}

        <button type="submit" className="btn btn-primary" disabled={sending}>
          {sending ? 'جارٍ الإرسال…' : 'إرسال الإشعار'}
        </button>
      </form>
    </div>
  )
}
