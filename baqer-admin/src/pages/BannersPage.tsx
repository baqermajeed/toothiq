import { useEffect, useState, type FormEvent } from 'react'
import { ApiError, assetUrl } from '../lib/api'
import { adminApi } from '../api/admin'

export function BannersPage() {
  const [items, setItems] = useState<Record<string, unknown>[]>([])
  const [err, setErr] = useState('')
  const [msg, setMsg] = useState('')
  const [modal, setModal] = useState<'create' | 'edit' | null>(null)
  const [editId, setEditId] = useState<string | null>(null)
  const [title, setTitle] = useState('')
  const [actionType, setActionType] = useState('external_url')
  const [shopId, setShopId] = useState('')
  const [productId, setProductId] = useState('')
  const [externalUrl, setExternalUrl] = useState('')
  const [order, setOrder] = useState('0')
  const [isActive, setIsActive] = useState(true)
  const [polygon, setPolygon] = useState('')
  const [imageFile, setImageFile] = useState<File | null>(null)

  async function load() {
    setErr('')
    try {
      setItems(await adminApi.banners.list())
    } catch (e) {
      setErr(e instanceof ApiError ? e.message : 'فشل')
    }
  }

  useEffect(() => {
    void load()
  }, [])

  function openCreate() {
    setModal('create')
    setEditId(null)
    setTitle('')
    setActionType('external_url')
    setShopId('')
    setProductId('')
    setExternalUrl('https://')
    setOrder('0')
    setIsActive(true)
    setPolygon('')
    setImageFile(null)
  }

  function openEdit(b: Record<string, unknown>) {
    setModal('edit')
    setEditId(String(b._id))
    setTitle(String(b.title ?? ''))
    setActionType(String(b.actionType ?? 'external_url'))
    setShopId(String(b.shopId ?? ''))
    setProductId(String(b.productId ?? ''))
    setExternalUrl(String(b.externalUrl ?? ''))
    setOrder(String(b.order ?? 0))
    setIsActive(b.isActive !== false)
    setPolygon(b.polygon ? JSON.stringify(b.polygon, null, 2) : '')
    setImageFile(null)
  }

  function appendForm(fd: FormData) {
    fd.append('title', title)
    fd.append('actionType', actionType)
    if (shopId.trim()) fd.append('shopId', shopId.trim())
    if (productId.trim()) fd.append('productId', productId.trim())
    fd.append('externalUrl', externalUrl)
    fd.append('order', order)
    fd.append('isActive', String(isActive))
    if (polygon.trim()) fd.append('polygon', polygon.trim())
    if (imageFile) fd.append('image', imageFile)
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault()
    setErr('')
    setMsg('')
    const fd = new FormData()
    appendForm(fd)
    if (modal === 'create' && !imageFile) {
      setErr('الصورة مطلوبة عند الإنشاء')
      return
    }
    try {
      if (modal === 'create') await adminApi.banners.create(fd)
      else if (editId) await adminApi.banners.patch(editId, fd)
      setModal(null)
      setMsg('تم الحفظ')
      void load()
    } catch (ex) {
      setErr(ex instanceof ApiError ? ex.message : 'فشل')
    }
  }

  async function remove(id: string) {
    if (!window.confirm('حذف البانر؟')) return
    setErr('')
    try {
      await adminApi.banners.remove(id)
      void load()
    } catch (ex) {
      setErr(ex instanceof ApiError ? ex.message : 'فشل')
    }
  }

  return (
    <div>
      <h1 style={{ marginTop: 0 }}>البانرات</h1>
      <button type="button" className="btn btn-primary" onClick={openCreate}>
        + بانر
      </button>
      {err ? <div className="alert alert-error">{err}</div> : null}
      {msg ? <div className="alert alert-success">{msg}</div> : null}

      <div className="table-wrap" style={{ marginTop: '1rem' }}>
        <table className="data">
          <thead>
            <tr>
              <th>صورة</th>
              <th>العنوان</th>
              <th>الإجراء</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {items.map((b) => {
              const img = b.image as string | undefined
              return (
                <tr key={String(b._id)}>
                  <td>{img ? <img className="thumb" src={assetUrl(img)} alt="" /> : '—'}</td>
                  <td>{String(b.title ?? '')}</td>
                  <td>{String(b.actionType ?? '')}</td>
                  <td>
                    <button type="button" className="btn" onClick={() => openEdit(b)}>
                      تعديل
                    </button>{' '}
                    <button type="button" className="btn btn-danger" onClick={() => remove(String(b._id))}>
                      حذف
                    </button>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>

      {modal ? (
        <div className="modal-backdrop" onClick={() => setModal(null)} role="presentation">
          <div className="modal" onClick={(e) => e.stopPropagation()} role="dialog">
            <h3>{modal === 'create' ? 'بانر جديد' : 'تعديل بانر'}</h3>
            <form onSubmit={onSubmit}>
              <div className="field">
                <label>صورة {modal === 'create' ? '(مطلوب)' : '(اختياري)'}</label>
                <input type="file" accept="image/jpeg,image/png,image/webp" onChange={(e) => setImageFile(e.target.files?.[0] ?? null)} />
              </div>
              <div className="field">
                <label>عنوان</label>
                <input className="input" value={title} onChange={(e) => setTitle(e.target.value)} />
              </div>
              <div className="field">
                <label>نوع الإجراء</label>
                <select className="select" value={actionType} onChange={(e) => setActionType(e.target.value)}>
                  <option value="shop">محل</option>
                  <option value="product">منتج</option>
                  <option value="external_url">رابط خارجي</option>
                </select>
              </div>
              <div className="field">
                <label>معرّف المحل</label>
                <input className="input" dir="ltr" value={shopId} onChange={(e) => setShopId(e.target.value)} />
              </div>
              <div className="field">
                <label>معرّف المنتج</label>
                <input className="input" dir="ltr" value={productId} onChange={(e) => setProductId(e.target.value)} />
              </div>
              <div className="field">
                <label>رابط خارجي</label>
                <input className="input" dir="ltr" value={externalUrl} onChange={(e) => setExternalUrl(e.target.value)} />
              </div>
              <div className="field">
                <label>الترتيب</label>
                <input className="input" type="number" value={order} onChange={(e) => setOrder(e.target.value)} />
              </div>
              <div className="field">
                <label>مضلع اختياري (JSON)</label>
                <textarea className="textarea" dir="ltr" value={polygon} onChange={(e) => setPolygon(e.target.value)} rows={4} />
              </div>
              <label className="muted" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <input type="checkbox" checked={isActive} onChange={(e) => setIsActive(e.target.checked)} /> نشط
              </label>
              <div style={{ marginTop: '1rem', display: 'flex', gap: 8 }}>
                <button type="submit" className="btn btn-primary">
                  حفظ
                </button>
                <button type="button" className="btn" onClick={() => setModal(null)}>
                  إلغاء
                </button>
              </div>
            </form>
          </div>
        </div>
      ) : null}
    </div>
  )
}
