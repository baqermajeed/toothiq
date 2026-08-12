import { useEffect, useState, type FormEvent } from 'react'
import { ApiError } from '../lib/api'
import { assetUrl } from '../lib/api'
import { adminApi } from '../api/admin'
import {
  CategoryIconPicker,
  PRESET_BRAND_ICONS,
  iconValueToFile,
  type CategoryIconValue,
} from '../components/CategoryIconPicker'

export function CategoriesPage() {
  const [categories, setCategories] = useState<Record<string, unknown>[]>([])
  const [subcategories, setSubcategories] = useState<Record<string, unknown>[]>([])
  const [brands, setBrands] = useState<Record<string, unknown>[]>([])
  const [err, setErr] = useState('')
  const [msg, setMsg] = useState('')
  const [mainNameAr, setMainNameAr] = useState('')
  const [mainIcon, setMainIcon] = useState<CategoryIconValue | null>(null)
  const [iconError, setIconError] = useState('')
  const [mainOrder, setMainOrder] = useState('0')
  const [subcategoryCategoryId, setSubcategoryCategoryId] = useState('')
  const [subcategoryNameAr, setSubcategoryNameAr] = useState('')
  const [brandCategoryId, setBrandCategoryId] = useState('')
  const [brandNameAr, setBrandNameAr] = useState('')
  const [brandImage, setBrandImage] = useState<CategoryIconValue | null>(null)
  const [brandImageError, setBrandImageError] = useState('')

  async function load() {
    setErr('')
    try {
      const [main, taxonomy] = await Promise.all([adminApi.categories.list(), adminApi.productTaxonomy.list()])
      setCategories(main)
      setSubcategories(taxonomy.subcategories)
      setBrands(taxonomy.brands)
      if (!subcategoryCategoryId && main.length > 0) setSubcategoryCategoryId(String(main[0].id))
      if (!brandCategoryId && main.length > 0) setBrandCategoryId(String(main[0].id))
    } catch (e) {
      setErr(e instanceof ApiError ? e.message : 'فشل التحميل')
    }
  }

  useEffect(() => {
    void load()
  }, [])

  async function onCreate(e: FormEvent) {
    e.preventDefault()
    setErr('')
    setMsg('')
    setIconError('')
    if (!mainIcon) {
      setIconError('اختر أيقونة للقسم')
      return
    }
    try {
      const iconFile = await iconValueToFile(mainIcon)
      const form = new FormData()
      form.append('nameAr', mainNameAr.trim())
      form.append('order', String(Number(mainOrder) || 0))
      form.append('isActive', 'true')
      form.append('icon', iconFile)
      await adminApi.categories.create(form)
      setMainNameAr('')
      setMainIcon(null)
      setMainOrder('0')
      setMsg('تم الإنشاء')
      void load()
    } catch (ex) {
      setErr(ex instanceof ApiError ? ex.message : 'فشل')
    }
  }

  async function patchMainCategory(id: string, body: Record<string, unknown>) {
    setErr('')
    try {
      await adminApi.categories.patch(id, body)
      setMsg('تم التحديث')
      void load()
    } catch (ex) {
      setErr(ex instanceof ApiError ? ex.message : 'فشل')
    }
  }

  async function removeMainCategory(id: string) {
    if (!window.confirm('حذف الفئة؟')) return
    setErr('')
    try {
      await adminApi.categories.remove(id)
      void load()
    } catch (ex) {
      setErr(ex instanceof ApiError ? ex.message : 'فشل')
    }
  }

  async function onCreateSubcategory(e: FormEvent) {
    e.preventDefault()
    setErr('')
    try {
      await adminApi.productTaxonomy.createSubcategory({
        categoryId: subcategoryCategoryId,
        nameAr: subcategoryNameAr,
      })
      setSubcategoryNameAr('')
      setMsg('تمت إضافة التصنيف الفرعي')
      void load()
    } catch (ex) {
      setErr(ex instanceof ApiError ? ex.message : 'فشل')
    }
  }

  async function onCreateBrand(e: FormEvent) {
    e.preventDefault()
    setErr('')
    setMsg('')
    setBrandImageError('')
    if (!brandImage) {
      setBrandImageError('اختر صورة للبراند')
      return
    }
    try {
      const imageFile = await iconValueToFile(brandImage)
      const form = new FormData()
      form.append('categoryId', brandCategoryId)
      form.append('nameAr', brandNameAr.trim())
      form.append('isActive', 'true')
      form.append('image', imageFile)
      await adminApi.productTaxonomy.createBrand(form)
      setBrandNameAr('')
      setBrandImage(null)
      setMsg('تمت إضافة البراند')
      void load()
    } catch (ex) {
      setErr(ex instanceof ApiError ? ex.message : 'فشل')
    }
  }

  const categoryName = (id: unknown) => {
    const found = categories.find((c) => String(c.id) === String(id))
    return found ? String(found.nameAr ?? '') : '—'
  }

  return (
    <div>
      <h1 style={{ marginTop: 0 }}>إدارة تصنيفات المنتجات</h1>
      {err ? <div className="alert alert-error">{err}</div> : null}
      {msg ? <div className="alert alert-success">{msg}</div> : null}

      <form className="card" onSubmit={onCreate}>
        <h2>إضافة تصنيف رئيسي</h2>
        <div className="field">
          <label>الاسم بالعربية</label>
          <input className="input" value={mainNameAr} onChange={(e) => setMainNameAr(e.target.value)} required />
        </div>
        <CategoryIconPicker value={mainIcon} onChange={setMainIcon} error={iconError} />
        <div className="field">
          <label>الترتيب</label>
          <input className="input" type="number" value={mainOrder} onChange={(e) => setMainOrder(e.target.value)} />
        </div>
        <button type="submit" className="btn btn-primary">
          إضافة
        </button>
      </form>

      <form className="card" onSubmit={onCreateSubcategory}>
        <h2>إضافة تصنيف فرعي</h2>
        <div className="field">
          <label>التصنيف الرئيسي</label>
          <select className="select" value={subcategoryCategoryId} onChange={(e) => setSubcategoryCategoryId(e.target.value)} required>
            <option value="">اختر تصنيفًا رئيسيًا</option>
            {categories.map((c) => (
              <option key={String(c.id)} value={String(c.id)}>
                {String(c.nameAr ?? '')}
              </option>
            ))}
          </select>
        </div>
        <div className="field">
          <label>اسم التصنيف الفرعي</label>
          <input className="input" value={subcategoryNameAr} onChange={(e) => setSubcategoryNameAr(e.target.value)} required />
        </div>
        <button type="submit" className="btn btn-primary">
          إضافة
        </button>
      </form>

      <form className="card" onSubmit={onCreateBrand}>
        <h2>إضافة براند</h2>
        <div className="field">
          <label>التصنيف الرئيسي</label>
          <select className="select" value={brandCategoryId} onChange={(e) => setBrandCategoryId(e.target.value)} required>
            <option value="">اختر تصنيفًا رئيسيًا</option>
            {categories.map((c) => (
              <option key={String(c.id)} value={String(c.id)}>
                {String(c.nameAr ?? '')}
              </option>
            ))}
          </select>
        </div>
        <div className="field">
          <label>اسم البراند</label>
          <input className="input" value={brandNameAr} onChange={(e) => setBrandNameAr(e.target.value)} required />
        </div>
        <CategoryIconPicker
          value={brandImage}
          onChange={setBrandImage}
          error={brandImageError}
          label="صورة البراند *"
          presets={PRESET_BRAND_ICONS}
        />
        <button type="submit" className="btn btn-primary">
          إضافة
        </button>
      </form>

      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>النوع</th>
              <th>الأيقونة</th>
              <th>الاسم</th>
              <th>التصنيف الرئيسي</th>
              <th>نشط</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {categories.map((c) => (
              <tr key={String(c.id)}>
                <td>رئيسي</td>
                <td>
                  {c.icon ? (
                    <img
                      className="category-icon-cell"
                      src={assetUrl(String(c.icon))}
                      alt=""
                    />
                  ) : (
                    '—'
                  )}
                </td>
                <td>{String(c.nameAr ?? '')}</td>
                <td>—</td>
                <td>{c.isActive !== false ? 'نعم' : 'لا'}</td>
                <td>
                  <button type="button" className="btn" onClick={() => patchMainCategory(String(c.id), { isActive: c.isActive === false })}>
                    تبديل النشاط
                  </button>{' '}
                  <button type="button" className="btn btn-danger" onClick={() => removeMainCategory(String(c.id))}>
                    حذف
                  </button>
                </td>
              </tr>
            ))}
            {subcategories.map((s) => (
              <tr key={`sub-${String(s._id)}`}>
                <td>فرعي</td>
                <td>—</td>
                <td>{String(s.nameAr ?? '')}</td>
                <td>{categoryName(s.categoryId)}</td>
                <td>{s.isActive !== false ? 'نعم' : 'لا'}</td>
                <td>
                  <button
                    type="button"
                    className="btn"
                    onClick={async () => {
                      try {
                        await adminApi.productTaxonomy.patchSubcategory(String(s._id), { isActive: s.isActive === false })
                        void load()
                      } catch (e) {
                        setErr(e instanceof ApiError ? e.message : 'فشل')
                      }
                    }}
                  >
                    تبديل النشاط
                  </button>{' '}
                  <button
                    type="button"
                    className="btn btn-danger"
                    onClick={async () => {
                      if (!window.confirm('حذف التصنيف الفرعي؟')) return
                      try {
                        await adminApi.productTaxonomy.removeSubcategory(String(s._id))
                        void load()
                      } catch (e) {
                        setErr(e instanceof ApiError ? e.message : 'فشل')
                      }
                    }}
                  >
                    حذف
                  </button>
                </td>
              </tr>
            ))}
            {brands.map((b) => (
              <tr key={`brand-${String(b._id)}`}>
                <td>براند</td>
                <td>
                  {b.image ? (
                    <img
                      className="category-icon-cell"
                      src={assetUrl(String(b.image))}
                      alt=""
                    />
                  ) : (
                    '—'
                  )}
                </td>
                <td>{String(b.nameAr ?? '')}</td>
                <td>{categoryName(b.categoryId)}</td>
                <td>{b.isActive !== false ? 'نعم' : 'لا'}</td>
                <td>
                  <button
                    type="button"
                    className="btn"
                    onClick={async () => {
                      try {
                        await adminApi.productTaxonomy.patchBrand(String(b._id), { isActive: b.isActive === false })
                        void load()
                      } catch (e) {
                        setErr(e instanceof ApiError ? e.message : 'فشل')
                      }
                    }}
                  >
                    تبديل النشاط
                  </button>{' '}
                  <button
                    type="button"
                    className="btn btn-danger"
                    onClick={async () => {
                      if (!window.confirm('حذف البراند؟')) return
                      try {
                        await adminApi.productTaxonomy.removeBrand(String(b._id))
                        void load()
                      } catch (e) {
                        setErr(e instanceof ApiError ? e.message : 'فشل')
                      }
                    }}
                  >
                    حذف
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
