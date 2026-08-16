import { useCallback, useEffect, useState, type FormEvent } from 'react'
import { ApiError, assetUrl } from '../lib/api'
import { adminApi } from '../api/admin'

const SECTIONS = [
  { id: 'best_sellers', label: 'الأكثر مبيعاً', itemType: 'product' as const },
  { id: 'for_you', label: 'خصيصاً لك', itemType: 'product' as const },
  { id: 'new', label: 'الجديد', itemType: 'product' as const },
  { id: 'top_rated', label: 'الأعلى تقييماً', itemType: 'shop' as const },
]

function refName(value: unknown) {
  if (value && typeof value === 'object' && 'name' in value) {
    return String((value as { name?: unknown }).name ?? '')
  }
  return ''
}

function refImage(value: unknown) {
  if (value && typeof value === 'object' && 'image' in value) {
    const image = (value as { image?: unknown }).image
    return typeof image === 'string' ? image : ''
  }
  return ''
}

export function HomeSectionsPage() {
  const [section, setSection] = useState(SECTIONS[0].id)
  const [items, setItems] = useState<Record<string, unknown>[]>([])
  const [err, setErr] = useState('')
  const [msg, setMsg] = useState('')
  const [loading, setLoading] = useState(true)
  const [showAdd, setShowAdd] = useState(false)
  const [q, setQ] = useState('')
  const [hits, setHits] = useState<Record<string, unknown>[]>([])
  const [searching, setSearching] = useState(false)

  const current = SECTIONS.find((s) => s.id === section) ?? SECTIONS[0]

  const load = useCallback(async () => {
    setErr('')
    setLoading(true)
    try {
      const res = await adminApi.homeSections.list(section)
      setItems(res.items || [])
    } catch (e) {
      setErr(e instanceof ApiError ? e.message : 'فشل التحميل')
      setItems([])
    } finally {
      setLoading(false)
    }
  }, [section])

  useEffect(() => {
    void load()
  }, [load])

  async function search(e?: FormEvent) {
    e?.preventDefault()
    setSearching(true)
    setErr('')
    try {
      if (current.itemType === 'shop') {
        const res = await adminApi.shops.list({ page: 1, limit: 200 })
        const query = q.trim().toLowerCase()
        const all = res.items || []
        setHits(
          query
            ? all.filter((s) => String(s.name ?? '').toLowerCase().includes(query))
            : all.slice(0, 30)
        )
      } else {
        const res = await adminApi.products.list({
          page: 1,
          limit: 20,
          q: q.trim() || undefined,
        })
        setHits(res.items || [])
      }
    } catch (e) {
      setErr(e instanceof ApiError ? e.message : 'فشل البحث')
    } finally {
      setSearching(false)
    }
  }

  async function addItem(hit: Record<string, unknown>) {
    setErr('')
    setMsg('')
    try {
      await adminApi.homeSections.create(
        current.itemType === 'shop'
          ? { section, shopId: String(hit._id) }
          : { section, productId: String(hit._id) }
      )
      setMsg('تمت الإضافة — سيظهر أولاً ثم تليه النتائج التلقائية')
      setShowAdd(false)
      setHits([])
      setQ('')
      void load()
    } catch (e) {
      setErr(e instanceof ApiError ? e.message : 'فشل الإضافة')
    }
  }

  async function toggleActive(item: Record<string, unknown>) {
    try {
      await adminApi.homeSections.patch(String(item._id), { isActive: item.isActive === false })
      void load()
    } catch (e) {
      setErr(e instanceof ApiError ? e.message : 'فشل التحديث')
    }
  }

  async function move(index: number, dir: -1 | 1) {
    const other = index + dir
    if (other < 0 || other >= items.length) return
    const a = items[index]
    const b = items[other]
    try {
      await Promise.all([
        adminApi.homeSections.patch(String(a._id), { order: Number(b.order ?? other) }),
        adminApi.homeSections.patch(String(b._id), { order: Number(a.order ?? index) }),
      ])
      void load()
    } catch (e) {
      setErr(e instanceof ApiError ? e.message : 'فشل الترتيب')
    }
  }

  async function remove(id: string) {
    if (!window.confirm('إزالة هذا العنصر من القسم؟')) return
    try {
      await adminApi.homeSections.remove(id)
      void load()
    } catch (e) {
      setErr(e instanceof ApiError ? e.message : 'فشل الحذف')
    }
  }

  return (
    <div>
      <h1 style={{ marginTop: 0 }}>أقسام الرئيسية</h1>
      <p className="muted">
        السيرفر يحسب محتويات كل قسم تلقائياً. ما تضيفه هنا يظهر <strong>أولاً</strong> في التطبيق، ثم تليه
        النتائج التلقائية بدون تكرار.
      </p>
      <div className="row" style={{ marginBottom: '1rem', flexWrap: 'wrap', gap: 8 }}>
        {SECTIONS.map((s) => (
          <button
            key={s.id}
            type="button"
            className={s.id === section ? 'btn btn-primary' : 'btn'}
            onClick={() => setSection(s.id)}
          >
            {s.label}
          </button>
        ))}
      </div>
      <button type="button" className="btn btn-primary" onClick={() => setShowAdd(true)}>
        + إضافة {current.itemType === 'shop' ? 'متجر' : 'منتج'}
      </button>
      {err ? <div className="alert alert-error">{err}</div> : null}
      {msg ? <div className="alert alert-success">{msg}</div> : null}
      {loading ? <p className="muted">جاري التحميل…</p> : null}
      {!loading ? (
        <div className="table-wrap" style={{ marginTop: '1rem' }}>
          <table className="data">
            <thead>
              <tr>
                <th>صورة</th>
                <th>الاسم</th>
                <th>الحالة</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {items.length === 0 ? (
                <tr>
                  <td colSpan={4} className="muted">
                    لا توجد عناصر مثبتة — التطبيق سيعرض الحساب التلقائي فقط.
                  </td>
                </tr>
              ) : (
                items.map((item, index) => {
                  const ref = current.itemType === 'shop' ? item.shopId : item.productId
                  const img = refImage(ref)
                  return (
                    <tr key={String(item._id)}>
                      <td>{img ? <img className="thumb" src={assetUrl(img)} alt="" /> : '—'}</td>
                      <td>{refName(ref) || String((ref as string | undefined) ?? '—')}</td>
                      <td>{item.isActive === false ? 'متوقف' : 'نشط'}</td>
                      <td>
                        <button type="button" className="btn" disabled={index === 0} onClick={() => move(index, -1)}>
                          أعلى
                        </button>{' '}
                        <button
                          type="button"
                          className="btn"
                          disabled={index === items.length - 1}
                          onClick={() => move(index, 1)}
                        >
                          أسفل
                        </button>{' '}
                        <button type="button" className="btn" onClick={() => toggleActive(item)}>
                          {item.isActive === false ? 'تفعيل' : 'إيقاف'}
                        </button>{' '}
                        <button type="button" className="btn btn-danger" onClick={() => remove(String(item._id))}>
                          حذف
                        </button>
                      </td>
                    </tr>
                  )
                })
              )}
            </tbody>
          </table>
        </div>
      ) : null}

      {showAdd ? (
        <div className="modal-backdrop" onClick={() => setShowAdd(false)} role="presentation">
          <div className="modal" role="dialog" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 560 }}>
            <h3>إضافة إلى «{current.label}»</h3>
            <form onSubmit={(e) => void search(e)}>
              <div className="field">
                <label>بحث</label>
                <input
                  className="input"
                  value={q}
                  onChange={(e) => setQ(e.target.value)}
                  placeholder={current.itemType === 'shop' ? 'اسم المتجر' : 'اسم المنتج'}
                />
              </div>
              <button type="submit" className="btn btn-primary" disabled={searching}>
                {searching ? 'جاري البحث…' : 'بحث'}
              </button>{' '}
              <button type="button" className="btn" onClick={() => setShowAdd(false)}>
                إلغاء
              </button>
            </form>
            <div className="table-wrap" style={{ marginTop: '1rem', maxHeight: 320, overflow: 'auto' }}>
              <table className="data">
                <tbody>
                  {hits.map((hit) => {
                    const img = (hit.image as string | undefined) || ''
                    return (
                      <tr key={String(hit._id)}>
                        <td>{img ? <img className="thumb" src={assetUrl(img)} alt="" /> : '—'}</td>
                        <td>{String(hit.name ?? '')}</td>
                        <td>
                          <button type="button" className="btn btn-primary" onClick={() => addItem(hit)}>
                            إضافة
                          </button>
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  )
}
