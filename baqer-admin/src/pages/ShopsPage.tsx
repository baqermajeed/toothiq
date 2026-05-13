import { useCallback, useEffect, useState, type FormEvent } from 'react'
import { ApiError, assetUrl } from '../lib/api'
import { adminApi, fetchGovernorates, type Paginated } from '../api/admin'
import { ShopLocationMap } from '../components/ShopLocationMap'

export function ShopsPage() {
  const [data, setData] = useState<Paginated<Record<string, unknown>> | null>(null)
  const [page, setPage] = useState(1)
  const [err, setErr] = useState('')
  const [loading, setLoading] = useState(true)
  const [modal, setModal] = useState<'create' | 'edit' | 'reorder' | null>(null)
  const [editId, setEditId] = useState<string | null>(null)

  const [name, setName] = useState('')
  const [description, setDescription] = useState('')
  const [lng, setLng] = useState(44.3661)
  const [lat, setLat] = useState(33.3152)
  const [openFrom, setOpenFrom] = useState('09:00')
  const [openTo, setOpenTo] = useState('22:00')
  const [ownerPhone, setOwnerPhone] = useState('')
  const [ownerPassword, setOwnerPassword] = useState('')
  const [ownerName, setOwnerName] = useState('')
  const [ownerGovernorateId, setOwnerGovernorateId] = useState('baghdad')
  const [govs, setGovs] = useState<{ id: string; nameAr: string }[]>([])
  const [isOpen, setIsOpen] = useState(true)
  const [isHidden, setIsHidden] = useState(false)
  const [isActive, setIsActive] = useState(true)
  const [imageFile, setImageFile] = useState<File | null>(null)
  const [reorderText, setReorderText] = useState('')

  useEffect(() => {
    void fetchGovernorates().then(setGovs).catch(() => {})
  }, [])

  const load = useCallback(async () => {
    setErr('')
    setLoading(true)
    try {
      const res = await adminApi.shops.list({ page, limit: 20 })
      setData(res)
    } catch (e) {
      setErr(e instanceof ApiError ? e.message : 'فشل التحميل')
    } finally {
      setLoading(false)
    }
  }, [page])

  useEffect(() => {
    void load()
  }, [load])

  function openCreate() {
    setModal('create')
    setEditId(null)
    setName('')
    setDescription('')
    setLng(44.3661)
    setLat(33.3152)
    setOwnerPhone('')
    setOwnerPassword('')
    setOwnerName('')
    setOwnerGovernorateId('baghdad')
    setImageFile(null)
  }

  function openEdit(row: Record<string, unknown>) {
    setModal('edit')
    setEditId(String(row._id))
    setName(String(row.name ?? ''))
    setDescription(String(row.description ?? ''))
    const loc = row.location as { coordinates?: number[] } | undefined
    const c = loc?.coordinates
    setLng(c && c[0] != null ? Number(c[0]) : 44.3661)
    setLat(c && c[1] != null ? Number(c[1]) : 33.3152)
    const oh = row.openHours as { from?: string; to?: string } | undefined
    setOpenFrom(String(oh?.from ?? '09:00'))
    setOpenTo(String(oh?.to ?? '22:00'))
    setIsOpen(Boolean(row.isOpen))
    setIsHidden(Boolean(row.isHidden))
    setIsActive(row.isActive !== false)
    setImageFile(null)
  }

  function setLocationFromMap(newLat: number, newLng: number) {
    setLat(newLat)
    setLng(newLng)
  }

  async function submitShop(e: FormEvent) {
    e.preventDefault()
    setErr('')
    const fd = new FormData()
    fd.append('name', name)
    fd.append('description', description)
    fd.append('lng', String(lng))
    fd.append('lat', String(lat))
    fd.append('openHoursFrom', openFrom)
    fd.append('openHoursTo', openTo)
    fd.append('isOpen', String(isOpen))
    fd.append('isHidden', String(isHidden))
    if (modal === 'edit') {
      fd.append('isActive', String(isActive))
    }
    if (modal === 'create') {
      fd.append('ownerPhone', ownerPhone.trim())
      if (ownerPassword.trim()) fd.append('ownerPassword', ownerPassword)
      fd.append('ownerName', ownerName.trim() || 'مالك المحل')
      if (ownerGovernorateId) fd.append('ownerGovernorateId', ownerGovernorateId)
    }
    if (imageFile) fd.append('image', imageFile)
    try {
      if (modal === 'create') {
        await adminApi.shops.create(fd)
      } else if (modal === 'edit' && editId) {
        await adminApi.shops.patch(editId, fd)
      }
      setModal(null)
      void load()
    } catch (ex) {
      setErr(ex instanceof ApiError ? ex.message : 'فشل الحفظ')
    }
  }

  async function deleteShop(id: string) {
    if (!window.confirm('حذف المحل؟')) return
    setErr('')
    try {
      await adminApi.shops.remove(id)
      void load()
    } catch (ex) {
      setErr(ex instanceof ApiError ? ex.message : 'فشل الحذف')
    }
  }

  async function submitReorder(e: FormEvent) {
    e.preventDefault()
    setErr('')
    const ids = reorderText
      .split(/[\s,]+/)
      .map((s) => s.trim())
      .filter(Boolean)
    try {
      await adminApi.shops.reorder(ids)
      setModal(null)
      void load()
    } catch (ex) {
      setErr(ex instanceof ApiError ? ex.message : 'فشل')
    }
  }

  const totalPages = data ? Math.max(1, Math.ceil(data.pagination.total / data.pagination.limit)) : 1

  return (
    <div>
      <h1 style={{ marginTop: 0 }}>المحلات</h1>
      <p className="muted">
        رسوم التوصيل للطلبات تُحسب من إعدادات المنصة (عامة لكل التطبيق) وليس لكل محل. عدّلها من صفحة «إعدادات المنصة».
      </p>
      <div className="row" style={{ marginBottom: '1rem' }}>
        <button type="button" className="btn btn-primary" onClick={openCreate}>
          + محل جديد
        </button>
        <button type="button" className="btn" onClick={() => setModal('reorder')}>
          إعادة ترتيب المحلات
        </button>
      </div>
      {err ? <div className="alert alert-error">{err}</div> : null}
      {loading ? <p className="muted">جاري التحميل…</p> : null}
      {!loading && data ? (
        <>
          <div className="table-wrap">
            <table className="data">
              <thead>
                <tr>
                  <th>صورة</th>
                  <th>الاسم</th>
                  <th>مفتوح</th>
                  <th>نشط</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {data.items.map((s) => {
                  const img = s.image as string | undefined
                  return (
                    <tr key={String(s._id)}>
                      <td>{img ? <img className="thumb" src={assetUrl(img)} alt="" /> : '—'}</td>
                      <td>{String(s.name ?? '')}</td>
                      <td>{s.isOpen ? 'نعم' : 'لا'}</td>
                      <td>{s.isActive !== false ? 'نعم' : 'لا'}</td>
                      <td>
                        <button type="button" className="btn" onClick={() => openEdit(s)}>
                          تعديل
                        </button>{' '}
                        <button type="button" className="btn btn-danger" onClick={() => deleteShop(String(s._id))}>
                          حذف
                        </button>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
          <div className="pager">
            <button type="button" className="btn" disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>
              السابق
            </button>
            <span className="muted">
              صفحة {page} / {totalPages}
            </span>
            <button type="button" className="btn" disabled={page >= totalPages} onClick={() => setPage((p) => p + 1)}>
              التالي
            </button>
          </div>
        </>
      ) : null}

      {modal === 'create' || modal === 'edit' ? (
        <div className="modal-backdrop" role="presentation" onClick={() => setModal(null)}>
          <div className="modal" role="dialog" onClick={(ev) => ev.stopPropagation()} style={{ maxWidth: 560 }}>
            <h3>{modal === 'create' ? 'محل جديد' : 'تعديل محل'}</h3>
            <form onSubmit={submitShop}>
              <div className="field">
                <label>الاسم</label>
                <input className="input" value={name} onChange={(e) => setName(e.target.value)} required />
              </div>
              <div className="field">
                <label>الوصف</label>
                <textarea className="textarea" value={description} onChange={(e) => setDescription(e.target.value)} />
              </div>
              <div className="field">
                <label>موقع المحل على الخريطة</label>
                <p className="muted" style={{ marginTop: 0 }}>
                  انقر على الخريطة أو اسحب العلامة لتحديد الموقع.
                </p>
                <ShopLocationMap key={modal + (editId || 'new')} lat={lat} lng={lng} onChange={setLocationFromMap} height={260} />
                <p className="muted" dir="ltr" style={{ fontSize: '0.85rem', marginBottom: 0 }}>
                  lat: {lat.toFixed(6)} — lng: {lng.toFixed(6)}
                </p>
              </div>

              {modal === 'create' ? (
                <>
                  <h4 style={{ marginBottom: '0.5rem' }}>حساب مالك المحل</h4>
                  <p className="muted" style={{ marginTop: 0 }}>
                    أدخل رقم الهاتف (١١ رقماً). إن كان الرقم غير مسجّل يجب إدخال كلمة مرور لإنشاء حساب صاحب المحل. إن كان مسجّلاً يُربط
                    المحل به ويُضاف دور «محل» عند الحاجة دون تغيير كلمة المرور.
                  </p>
                  <div className="field">
                    <label>هاتف المالك</label>
                    <input
                      className="input"
                      dir="ltr"
                      style={{ textAlign: 'left' }}
                      value={ownerPhone}
                      onChange={(e) => setOwnerPhone(e.target.value)}
                      placeholder="07XXXXXXXXX"
                      required
                    />
                  </div>
                  <div className="field">
                    <label>كلمة مرور الحساب (عند رقم جديد — ٨ أحرف على الأقل)</label>
                    <input
                      className="input"
                      type="password"
                      value={ownerPassword}
                      onChange={(e) => setOwnerPassword(e.target.value)}
                      autoComplete="new-password"
                    />
                  </div>
                  <div className="field">
                    <label>اسم المالك (يُستخدم عند إنشاء حساب جديد)</label>
                    <input className="input" value={ownerName} onChange={(e) => setOwnerName(e.target.value)} placeholder="اسم صاحب المحل" />
                  </div>
                  <div className="field">
                    <label>محافظة المالك</label>
                    <select className="select" value={ownerGovernorateId} onChange={(e) => setOwnerGovernorateId(e.target.value)}>
                      {govs.map((g) => (
                        <option key={g.id} value={g.id}>
                          {g.nameAr}
                        </option>
                      ))}
                    </select>
                  </div>
                </>
              ) : null}

              <div className="row">
                <div className="field" style={{ flex: 1 }}>
                  <label>فتح من</label>
                  <input className="input" value={openFrom} onChange={(e) => setOpenFrom(e.target.value)} />
                </div>
                <div className="field" style={{ flex: 1 }}>
                  <label>إلى</label>
                  <input className="input" value={openTo} onChange={(e) => setOpenTo(e.target.value)} />
                </div>
              </div>
              <div className="field">
                <label>صورة (اختياري)</label>
                <input type="file" accept="image/jpeg,image/png,image/webp" onChange={(e) => setImageFile(e.target.files?.[0] ?? null)} />
              </div>
              <label className="muted" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <input type="checkbox" checked={isOpen} onChange={(e) => setIsOpen(e.target.checked)} /> مفتوح
              </label>
              <label className="muted" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <input type="checkbox" checked={isHidden} onChange={(e) => setIsHidden(e.target.checked)} /> مخفي
              </label>
              {modal === 'edit' ? (
                <label className="muted" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <input type="checkbox" checked={isActive} onChange={(e) => setIsActive(e.target.checked)} /> نشط
                </label>
              ) : null}
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

      {modal === 'reorder' ? (
        <div className="modal-backdrop" onClick={() => setModal(null)} role="presentation">
          <div className="modal" onClick={(e) => e.stopPropagation()} role="dialog">
            <h3>ترتيب المحلات</h3>
            <p className="muted">أدخل معرفات المحلات بالترتيب المطلوب، مفصولة بمسافة أو فاصلة.</p>
            <form onSubmit={submitReorder}>
              <textarea className="textarea" value={reorderText} onChange={(e) => setReorderText(e.target.value)} placeholder="id1 id2 id3" />
              <div style={{ marginTop: '1rem', display: 'flex', gap: 8 }}>
                <button type="submit" className="btn btn-primary">
                  تطبيق
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
