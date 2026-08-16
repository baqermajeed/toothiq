import { useCallback, useEffect, useState, type FormEvent } from 'react'
import { ApiError, assetUrl } from '../lib/api'
import { adminApi, type Paginated } from '../api/admin'

export function ProductsPage() {
  const [data, setData] = useState<Paginated<Record<string, unknown>> | null>(null)
  const [shops, setShops] = useState<Record<string, unknown>[]>([])
  const [categories, setCategories] = useState<Record<string, unknown>[]>([])
  const [subcategories, setSubcategories] = useState<Record<string, unknown>[]>([])
  const [brands, setBrands] = useState<Record<string, unknown>[]>([])
  const [page, setPage] = useState(1)
  const [limit, setLimit] = useState(30)
  const [shopId, setShopId] = useState('')
  const [q, setQ] = useState('')
  const [categoryId, setCategoryId] = useState('')
  const [subcategoryId, setSubcategoryId] = useState('')
  const [brandId, setBrandId] = useState('')
  const [price, setPrice] = useState('')
  const [minPrice, setMinPrice] = useState('')
  const [maxPrice, setMaxPrice] = useState('')
  const [expiryDate, setExpiryDate] = useState('')
  const [expiryDateFrom, setExpiryDateFrom] = useState('')
  const [expiryDateTo, setExpiryDateTo] = useState('')
  const [missingImageOnly, setMissingImageOnly] = useState(false)
  const [hasOffer, setHasOffer] = useState(false)
  const [err, setErr] = useState('')
  const [msg, setMsg] = useState('')
  const [loading, setLoading] = useState(true)
  const [showCreate, setShowCreate] = useState(false)
  const [newShopId, setNewShopId] = useState('')
  const [newName, setNewName] = useState('')
  const [newDescription, setNewDescription] = useState('')
  const [newPrice, setNewPrice] = useState('')
  const [newOfferPrice, setNewOfferPrice] = useState('')
  const [newOfferEndsAt, setNewOfferEndsAt] = useState('')
  const [newCategoryId, setNewCategoryId] = useState('')
  const [newSubcategoryId, setNewSubcategoryId] = useState('')
  const [newBrandId, setNewBrandId] = useState('')
  const [newProductionDate, setNewProductionDate] = useState('')
  const [newExpiryDate, setNewExpiryDate] = useState('')
  const [newImageFiles, setNewImageFiles] = useState<File[]>([])
  const [editing, setEditing] = useState<Record<string, unknown> | null>(null)
  const [editName, setEditName] = useState('')
  const [editPrice, setEditPrice] = useState('')
  const [editOfferPrice, setEditOfferPrice] = useState('')
  const [editOfferEndsAt, setEditOfferEndsAt] = useState('')

  const load = useCallback(async () => {
    setErr('')
    setMsg('')
    setLoading(true)
    try {
      const res = await adminApi.products.list({
        page,
        limit,
        shopId: shopId.trim() || undefined,
        q: q.trim() || undefined,
        categoryId: categoryId || undefined,
        subcategoryId: subcategoryId || undefined,
        brandId: brandId || undefined,
        price: price.trim() || undefined,
        minPrice: minPrice.trim() || undefined,
        maxPrice: maxPrice.trim() || undefined,
        expiryDate: expiryDate || undefined,
        expiryDateFrom: expiryDateFrom || undefined,
        expiryDateTo: expiryDateTo || undefined,
        missingImageOnly: missingImageOnly || undefined,
        hasOffer: hasOffer || undefined,
      })
      setData(res)
    } catch (e) {
      setErr(e instanceof ApiError ? e.message : 'فشل التحميل')
    } finally {
      setLoading(false)
    }
  }, [page, limit, shopId, q, categoryId, subcategoryId, brandId, price, minPrice, maxPrice, expiryDate, expiryDateFrom, expiryDateTo, missingImageOnly, hasOffer])

  useEffect(() => {
    void load()
  }, [load])

  useEffect(() => {
    void adminApi.shops
      .list({ page: 1, limit: 500 })
      .then((x) => {
        setShops(x.items)
      })
      .catch(() => {})
  }, [])

  useEffect(() => {
    void adminApi.productTaxonomy
      .list()
      .then((x) => {
        setCategories(x.categories)
        setSubcategories(x.subcategories)
        setBrands(x.brands)
      })
      .catch(() => {})
  }, [])

  async function createProduct(e: FormEvent) {
    e.preventDefault()
    setErr('')
    setMsg('')
    const sid = newShopId.trim()
    if (!sid) {
      setErr('معرّف المحل مطلوب')
      return
    }
    if ((newSubcategoryId || newBrandId) && !newCategoryId) {
      setErr('يجب اختيار التصنيف الرئيسي عند ربط المنتج بتصنيف فرعي أو براند')
      return
    }
    const fd = new FormData()
    fd.append('name', newName)
    fd.append('description', newDescription)
    fd.append('price', newPrice)
    if (newOfferPrice.trim()) {
      const offerNum = Number(newOfferPrice.trim())
      const priceNum = Number(newPrice)
      if (!Number.isFinite(offerNum) || offerNum <= 0) {
        setErr('سعر العرض يجب أن يكون أكبر من صفر')
        return
      }
      if (Number.isFinite(priceNum) && offerNum >= priceNum) {
        setErr('سعر العرض يجب أن يكون أقل من السعر الأصلي')
        return
      }
      fd.append('offerPrice', newOfferPrice.trim())
    }
    if (newOfferEndsAt) fd.append('offerEndsAt', new Date(newOfferEndsAt).toISOString())
    if (newCategoryId) fd.append('categoryId', newCategoryId)
    if (newSubcategoryId) fd.append('subcategoryId', newSubcategoryId)
    if (newBrandId) fd.append('brandId', newBrandId)
    if (newProductionDate) fd.append('productionDate', newProductionDate)
    if (newExpiryDate) fd.append('expiryDate', newExpiryDate)
    for (const f of newImageFiles) {
      fd.append('images', f)
    }
    try {
      await adminApi.products.create(sid, fd)
      setMsg('تمت إضافة المنتج')
      setShowCreate(false)
      setNewName('')
      setNewDescription('')
      setNewPrice('')
      setNewOfferPrice('')
      setNewOfferEndsAt('')
      setNewCategoryId('')
      setNewSubcategoryId('')
      setNewBrandId('')
      setNewProductionDate('')
      setNewExpiryDate('')
      setNewImageFiles([])
      if (!shopId) setShopId(sid)
      setPage(1)
      void load()
    } catch (e) {
      setErr(e instanceof ApiError ? e.message : 'فشل إضافة المنتج')
    }
  }

  function toDateInput(value: unknown) {
    if (!value) return ''
    const d = new Date(String(value))
    if (Number.isNaN(d.getTime())) return ''
    return d.toISOString().slice(0, 10)
  }

  function openEdit(p: Record<string, unknown>) {
    setErr('')
    setMsg('')
    setEditing(p)
    setEditName(String(p.name ?? ''))
    setEditPrice(p.price != null ? String(p.price) : '')
    setEditOfferPrice(p.offerPrice != null && p.offerPrice !== '' ? String(p.offerPrice) : '')
    setEditOfferEndsAt(toDateInput(p.offerEndsAt))
  }

  async function saveEdit(e: FormEvent) {
    e.preventDefault()
    if (!editing) return
    setErr('')
    setMsg('')
    const sid = String(editing.shopId ?? '').trim()
    const pid = String(editing._id ?? editing.id ?? '').trim()
    if (!sid || !pid) {
      setErr('تعذر تحديد المنتج')
      return
    }
    const priceNum = Number(editPrice)
    if (!Number.isFinite(priceNum) || priceNum < 0) {
      setErr('السعر غير صالح')
      return
    }
    const offerRaw = editOfferPrice.trim()
    let offerPrice: number | null = null
    if (offerRaw) {
      const offerNum = Number(offerRaw)
      if (!Number.isFinite(offerNum) || offerNum <= 0) {
        setErr('سعر العرض يجب أن يكون أكبر من صفر')
        return
      }
      if (offerNum >= priceNum) {
        setErr('سعر العرض يجب أن يكون أقل من السعر الأصلي')
        return
      }
      offerPrice = offerNum
    }
    try {
      await adminApi.products.patch(sid, pid, {
        name: editName.trim(),
        price: priceNum,
        offerPrice,
        offerEndsAt: editOfferEndsAt ? new Date(editOfferEndsAt).toISOString() : null,
      })
      setMsg('تم تحديث المنتج')
      setEditing(null)
      void load()
    } catch (e) {
      setErr(e instanceof ApiError ? e.message : 'فشل تحديث المنتج')
    }
  }

  const totalPages = data ? Math.max(1, Math.ceil(data.pagination.total / data.pagination.limit)) : 1

  return (
    <div>
      <h1 style={{ marginTop: 0 }}>المنتجات (عرض أدمن)</h1>
      <div className="row" style={{ marginBottom: '1rem' }}>
        <button type="button" className="btn btn-primary" onClick={() => setShowCreate(true)}>
          + إضافة منتج
        </button>
      </div>
      <div className="card">
        <div className="row">
          <div className="field" style={{ minWidth: 220, marginBottom: 0 }}>
            <label>المحل</label>
            <select className="select" value={shopId} onChange={(e) => setShopId(e.target.value)}>
              <option value="">الكل</option>
              {shops.map((s) => (
                <option key={String(s._id)} value={String(s._id)}>
                  {String(s.name ?? '')}
                </option>
              ))}
            </select>
          </div>
          <div className="field" style={{ flex: 1, minWidth: 200, marginBottom: 0 }}>
            <label>بحث نصي</label>
            <input className="input" value={q} onChange={(e) => setQ(e.target.value)} />
          </div>
          <div className="field" style={{ minWidth: 200, marginBottom: 0 }}>
            <label>تصنيف رئيسي</label>
            <select className="select" value={categoryId} onChange={(e) => setCategoryId(e.target.value)}>
              <option value="">الكل</option>
              {categories.map((c) => (
                <option key={String(c.id ?? c._id)} value={String(c.id ?? c._id)}>
                  {String(c.nameAr ?? '')}
                </option>
              ))}
            </select>
          </div>
          <div className="field" style={{ minWidth: 200, marginBottom: 0 }}>
            <label>تصنيف فرعي</label>
            <select className="select" value={subcategoryId} onChange={(e) => setSubcategoryId(e.target.value)}>
              <option value="">الكل</option>
              {subcategories
                .filter((s) => !categoryId || String(s.categoryId) === categoryId)
                .map((s) => (
                  <option key={String(s._id)} value={String(s._id)}>
                    {String(s.nameAr ?? '')}
                  </option>
                ))}
            </select>
          </div>
          <div className="field" style={{ minWidth: 200, marginBottom: 0 }}>
            <label>براند</label>
            <select className="select" value={brandId} onChange={(e) => setBrandId(e.target.value)}>
              <option value="">الكل</option>
              {brands
                .filter((b) => !categoryId || String(b.categoryId) === categoryId)
                .map((b) => (
                  <option key={String(b._id)} value={String(b._id)}>
                    {String(b.nameAr ?? '')}
                  </option>
                ))}
            </select>
          </div>
          <div className="field" style={{ minWidth: 180, marginBottom: 0 }}>
            <label>سعر يساوي</label>
            <input className="input" type="number" min="0" step="any" value={price} onChange={(e) => setPrice(e.target.value)} />
          </div>
          <div className="field" style={{ minWidth: 180, marginBottom: 0 }}>
            <label>من سعر</label>
            <input className="input" type="number" min="0" step="any" value={minPrice} onChange={(e) => setMinPrice(e.target.value)} />
          </div>
          <div className="field" style={{ minWidth: 180, marginBottom: 0 }}>
            <label>إلى سعر</label>
            <input className="input" type="number" min="0" step="any" value={maxPrice} onChange={(e) => setMaxPrice(e.target.value)} />
          </div>
          <div className="field" style={{ minWidth: 180, marginBottom: 0 }}>
            <label>تاريخ انتهاء (يوم محدد)</label>
            <input className="input" type="date" value={expiryDate} onChange={(e) => setExpiryDate(e.target.value)} />
          </div>
          <div className="field" style={{ minWidth: 180, marginBottom: 0 }}>
            <label>انتهاء من تاريخ</label>
            <input className="input" type="date" value={expiryDateFrom} onChange={(e) => setExpiryDateFrom(e.target.value)} />
          </div>
          <div className="field" style={{ minWidth: 180, marginBottom: 0 }}>
            <label>انتهاء إلى تاريخ</label>
            <input className="input" type="date" value={expiryDateTo} onChange={(e) => setExpiryDateTo(e.target.value)} />
          </div>
          <div className="field" style={{ minWidth: 120, marginBottom: 0 }}>
            <label>عدد/صفحة</label>
            <select className="select" value={String(limit)} onChange={(e) => setLimit(Number(e.target.value) || 30)}>
              <option value="20">20</option>
              <option value="30">30</option>
              <option value="50">50</option>
              <option value="100">100</option>
            </select>
          </div>
          <label className="muted" style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
            <input type="checkbox" checked={missingImageOnly} onChange={(e) => setMissingImageOnly(e.target.checked)} />
            بدون صورة فقط
          </label>
          <label className="muted" style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
            <input type="checkbox" checked={hasOffer} onChange={(e) => setHasOffer(e.target.checked)} />
            عروض فقط
          </label>
          <button type="button" className="btn btn-primary" onClick={() => setPage(1)}>
            تطبيق
          </button>
          <button
            type="button"
            className="btn"
            onClick={() => {
              setShopId('')
              setQ('')
              setCategoryId('')
              setSubcategoryId('')
              setBrandId('')
              setPrice('')
              setMinPrice('')
              setMaxPrice('')
              setExpiryDate('')
              setExpiryDateFrom('')
              setExpiryDateTo('')
              setMissingImageOnly(false)
              setHasOffer(false)
              setPage(1)
            }}
          >
            تصفير الفلاتر
          </button>
        </div>
      </div>
      {err ? <div className="alert alert-error">{err}</div> : null}
      {msg ? <div className="alert alert-success">{msg}</div> : null}
      {loading ? <p className="muted">جاري التحميل…</p> : null}
      {!loading && data ? (
        <>
          <div className="table-wrap">
            <table className="data">
              <thead>
                <tr>
                  <th>صورة</th>
                  <th>الاسم</th>
                  <th>السعر</th>
                  <th>العرض</th>
                  <th>المحل</th>
                  <th>متاح</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {data.items.map((p) => {
                  const img = p.image as string | undefined
                  const shop = p.shopId as Record<string, unknown> | string | undefined
                  const shopLabel =
                    typeof shop === 'object' && shop && 'name' in shop
                      ? String(shop.name)
                      : typeof shop === 'string'
                        ? shop
                        : ''
                  return (
                    <tr key={String(p._id)}>
                      <td>{img ? <img className="thumb" src={assetUrl(img)} alt="" /> : '—'}</td>
                      <td>{String(p.name ?? '')}</td>
                      <td>{String(p.price ?? '')}</td>
                      <td>
                        {p.isOnOffer
                          ? String(p.offerPrice ?? '')
                          : p.offerPrice
                            ? `${String(p.offerPrice)} (منتهي)`
                            : '—'}
                      </td>
                      <td>{String(p.shopName ?? shopLabel)}</td>
                      <td>{p.isAvailable !== false ? 'نعم' : 'لا'}</td>
                      <td>
                        <button type="button" className="btn" onClick={() => openEdit(p)}>
                          تعديل
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
              {page} / {totalPages}
            </span>
            <button type="button" className="btn" disabled={page >= totalPages} onClick={() => setPage((p) => p + 1)}>
              التالي
            </button>
          </div>
        </>
      ) : null}
      {showCreate ? (
        <div className="modal-backdrop" onClick={() => setShowCreate(false)} role="presentation">
          <div className="modal" role="dialog" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 560 }}>
            <h3>إضافة منتج (أدمن)</h3>
            <form onSubmit={createProduct}>
              <div className="field">
                <label>المحل</label>
                <select className="select" value={newShopId} onChange={(e) => setNewShopId(e.target.value)} required>
                  <option value="">اختر محلًا</option>
                  {shops.map((s) => (
                    <option key={String(s._id)} value={String(s._id)}>
                      {String(s.name ?? '')}
                    </option>
                  ))}
                </select>
              </div>
              <div className="field">
                <label>اسم المنتج</label>
                <input className="input" value={newName} onChange={(e) => setNewName(e.target.value)} required />
              </div>
              <div className="field">
                <label>الوصف</label>
                <textarea className="textarea" value={newDescription} onChange={(e) => setNewDescription(e.target.value)} />
              </div>
              <div className="field">
                <label>السعر الأصلي</label>
                <input className="input" type="number" min="0" step="any" value={newPrice} onChange={(e) => setNewPrice(e.target.value)} required />
              </div>
              <div className="field">
                <label>سعر العرض (اختياري)</label>
                <input className="input" type="number" min="0" step="any" value={newOfferPrice} onChange={(e) => setNewOfferPrice(e.target.value)} />
              </div>
              <div className="field">
                <label>انتهاء العرض (اختياري)</label>
                <input className="input" type="date" value={newOfferEndsAt} onChange={(e) => setNewOfferEndsAt(e.target.value)} />
              </div>
              <div className="field">
                <label>تصنيف رئيسي</label>
                <select
                  className="select"
                  value={newCategoryId}
                  onChange={(e) => {
                    setNewCategoryId(e.target.value)
                    setNewSubcategoryId('')
                    setNewBrandId('')
                  }}
                >
                  <option value="">اختر تصنيفًا رئيسيًا</option>
                  {categories.map((c) => (
                    <option key={String(c.id ?? c._id)} value={String(c.id ?? c._id)}>
                      {String(c.nameAr ?? '')}
                    </option>
                  ))}
                </select>
              </div>
              <div className="field">
                <label>تصنيف فرعي (اختياري)</label>
                <select
                  className="select"
                  value={newSubcategoryId}
                  disabled={!newCategoryId}
                  onChange={(e) => setNewSubcategoryId(e.target.value)}
                >
                  <option value="">بدون</option>
                  {subcategories
                    .filter((s) => !newCategoryId || String(s.categoryId) === newCategoryId)
                    .map((s) => (
                      <option key={String(s._id)} value={String(s._id)}>
                        {String(s.nameAr ?? '')}
                      </option>
                    ))}
                </select>
              </div>
              <div className="field">
                <label>براند (اختياري)</label>
                <select
                  className="select"
                  value={newBrandId}
                  disabled={!newCategoryId}
                  onChange={(e) => setNewBrandId(e.target.value)}
                >
                  <option value="">بدون</option>
                  {brands
                    .filter((b) => !newCategoryId || String(b.categoryId) === newCategoryId)
                    .map((b) => (
                      <option key={String(b._id)} value={String(b._id)}>
                        {String(b.nameAr ?? '')}
                      </option>
                    ))}
                </select>
              </div>
              <div className="field">
                <label>تاريخ الإنتاج (اختياري)</label>
                <input className="input" type="date" value={newProductionDate} onChange={(e) => setNewProductionDate(e.target.value)} />
              </div>
              <div className="field">
                <label>تاريخ النفاذ (اختياري)</label>
                <input className="input" type="date" value={newExpiryDate} onChange={(e) => setNewExpiryDate(e.target.value)} />
              </div>
              <div className="field">
                <label>صور المنتج (يمكن اختيار عدة صور)</label>
                <input
                  type="file"
                  accept="image/jpeg,image/png,image/webp"
                  multiple
                  onChange={(e) => setNewImageFiles(Array.from(e.target.files || []))}
                />
              </div>
              <div style={{ marginTop: '1rem', display: 'flex', gap: 8 }}>
                <button type="submit" className="btn btn-primary">
                  حفظ
                </button>
                <button type="button" className="btn" onClick={() => setShowCreate(false)}>
                  إلغاء
                </button>
              </div>
            </form>
          </div>
        </div>
      ) : null}
      {editing ? (
        <div className="modal-backdrop" onClick={() => setEditing(null)} role="presentation">
          <div className="modal" role="dialog" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 560 }}>
            <h3>تعديل المنتج</h3>
            <form onSubmit={saveEdit}>
              <div className="field">
                <label>اسم المنتج</label>
                <input className="input" value={editName} onChange={(e) => setEditName(e.target.value)} required />
              </div>
              <div className="field">
                <label>السعر الأصلي</label>
                <input
                  className="input"
                  type="number"
                  min="0"
                  step="any"
                  value={editPrice}
                  onChange={(e) => setEditPrice(e.target.value)}
                  required
                />
              </div>
              <div className="field">
                <label>سعر العرض (اختياري — اتركه فارغاً لإزالة العرض)</label>
                <input
                  className="input"
                  type="number"
                  min="0"
                  step="any"
                  value={editOfferPrice}
                  onChange={(e) => setEditOfferPrice(e.target.value)}
                />
              </div>
              <div className="field">
                <label>انتهاء العرض (اختياري)</label>
                <input
                  className="input"
                  type="date"
                  value={editOfferEndsAt}
                  onChange={(e) => setEditOfferEndsAt(e.target.value)}
                />
              </div>
              <div style={{ marginTop: '1rem', display: 'flex', gap: 8 }}>
                <button type="submit" className="btn btn-primary">
                  حفظ
                </button>
                <button type="button" className="btn" onClick={() => setEditing(null)}>
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
