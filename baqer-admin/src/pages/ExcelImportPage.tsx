import { useEffect, useState, type FormEvent } from 'react'
import { ApiError } from '../lib/api'
import { adminApi } from '../api/admin'
import {
  SYSTEM_FIELDS,
  guessMapping,
  parseSpreadsheet,
  rowHasAnyValue,
  type SystemFieldKey,
} from '../lib/parseProductExcel'

type FailedRow = { row: number; name: string; reason: string }

const emptyMapping = {
  name: '',
  price: '',
  description: '',
  categoryName: '',
  brandName: '',
  expiryDate: '',
} satisfies Record<SystemFieldKey, string>

export function ExcelImportPage() {
  const [shops, setShops] = useState<Record<string, unknown>[]>([])
  const [sections, setSections] = useState<Record<string, unknown>[]>([])
  const [shopId, setShopId] = useState('')
  const [sectionId, setSectionId] = useState('')
  const [fileName, setFileName] = useState('')
  const [columns, setColumns] = useState<string[]>([])
  const [rows, setRows] = useState<Record<string, string>[]>([])
  const [mapping, setMapping] = useState<Record<SystemFieldKey, string>>(emptyMapping)
  const [err, setErr] = useState('')
  const [msg, setMsg] = useState('')
  const [loading, setLoading] = useState(false)
  const [failed, setFailed] = useState<FailedRow[]>([])

  useEffect(() => {
    void adminApi.shops
      .list({ page: 1, limit: 500 })
      .then((res) => setShops(res.items))
      .catch(() => {})
  }, [])

  useEffect(() => {
    setSectionId('')
    setSections([])
    if (!shopId) return
    void adminApi.products
      .shopSections(shopId)
      .then((items) => setSections(Array.isArray(items) ? items : []))
      .catch(() => setSections([]))
  }, [shopId])

  async function onFileChange(file: File | undefined) {
    setErr('')
    setMsg('')
    setFailed([])
    setFileName('')
    setColumns([])
    setRows([])
    setMapping(emptyMapping)
    if (!file) return
    try {
      const buffer = await file.arrayBuffer()
      const parsed = parseSpreadsheet(buffer)
      const filled = parsed.rows.filter(rowHasAnyValue)
      if (parsed.columns.length === 0 || filled.length === 0) {
        setErr('الملف فارغ أو لا يحتوي صفوف بيانات')
        return
      }
      setFileName(file.name)
      setColumns(parsed.columns)
      setRows(filled)
      setMapping(guessMapping(parsed.columns))
    } catch {
      setErr('تعذر قراءة ملف الأكسل. استخدم xlsx أو csv')
    }
  }

  function cell(row: Record<string, string>, field: SystemFieldKey) {
    const col = mapping[field]
    if (!col) return ''
    return row[col] ?? ''
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault()
    setErr('')
    setMsg('')
    setFailed([])
    if (!shopId) {
      setErr('اختر المتجر أولاً')
      return
    }
    if (!mapping.name || !mapping.price) {
      setErr('اربط أعمدة الاسم والسعر')
      return
    }
    if (!sectionId && !mapping.categoryName && !mapping.brandName) {
      setErr('اختر قسماً من قائمة المتجر أو اربط عمود تصنيف/براند من الملف')
      return
    }
    if (rows.length === 0) {
      setErr('ارفع ملف أكسل يحتوي منتجات')
      return
    }

    const items = rows.map((row, index) => ({
      row: index + 2,
      name: cell(row, 'name'),
      price: cell(row, 'price'),
      description: cell(row, 'description'),
      categoryName: cell(row, 'categoryName'),
      brandName: cell(row, 'brandName'),
      expiryDate: cell(row, 'expiryDate'),
    }))

    setLoading(true)
    try {
      const result = await adminApi.products.importMapped(shopId, {
        productCategoryId: sectionId || undefined,
        items,
      })
      setFailed(result.failed || [])
      setMsg(`تمت إضافة ${result.createdCount} منتج. الفاشلة: ${result.failedCount}`)
    } catch (e) {
      setErr(e instanceof ApiError ? e.message : 'فشل الاستيراد')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div>
      <h1 style={{ marginTop: 0 }}>إضافة المواد عن طريق ملف أكسل</h1>
      <p className="muted">
        اختر المتجر، ارفع الملف، اربط أعمدة الأكسل مع النظام، ثم اختر قسم المتجر أو عمود تصنيف/براند من الملف.
        الإجباري: الاسم والسعر، مع قسم أو براند.
      </p>

      {err ? <div className="alert alert-error">{err}</div> : null}
      {msg ? <div className="alert alert-success">{msg}</div> : null}

      <form className="card" onSubmit={onSubmit}>
        <div className="field">
          <label>المتجر</label>
          <select className="select" value={shopId} onChange={(e) => setShopId(e.target.value)} required>
            <option value="">اختر متجراً</option>
            {shops.map((shop) => (
              <option key={String(shop._id)} value={String(shop._id)}>
                {String(shop.name ?? '')}
              </option>
            ))}
          </select>
        </div>

        <div className="field">
          <label>ملف الأكسل (xlsx / csv)</label>
          <input
            type="file"
            accept=".xlsx,.xls,.csv,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,text/csv"
            onChange={(e) => void onFileChange(e.target.files?.[0])}
          />
          {fileName ? (
            <div className="muted" style={{ marginTop: 6 }}>
              {fileName} — {rows.length} صف
            </div>
          ) : null}
        </div>

        {columns.length > 0 ? (
          <div className="field">
            <label>ربط الأعمدة</label>
            <div className="table-wrap">
              <table className="data">
                <thead>
                  <tr>
                    <th>حقل النظام</th>
                    <th>عمود الملف</th>
                  </tr>
                </thead>
                <tbody>
                  {SYSTEM_FIELDS.map((field) => (
                    <tr key={field.key}>
                      <td>
                        {field.label}
                        {field.required ? ' *' : ''}
                      </td>
                      <td>
                        <select
                          className="select"
                          value={mapping[field.key]}
                          onChange={(e) =>
                            setMapping((prev) => ({ ...prev, [field.key]: e.target.value }))
                          }
                        >
                          <option value="">بدون</option>
                          {columns.map((col) => (
                            <option key={col} value={col}>
                              {col}
                            </option>
                          ))}
                        </select>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        ) : null}

        <div className="field">
          <label>قسم المتجر (تُضاف إليه المواد)</label>
          <select
            className="select"
            value={sectionId}
            onChange={(e) => setSectionId(e.target.value)}
            disabled={!shopId}
          >
            <option value="">بدون — استخدم التصنيف/البراند من الملف</option>
            {sections.map((section) => (
              <option key={String(section.id ?? section._id)} value={String(section.id ?? section._id)}>
                {String(section.nameAr ?? section.name ?? '')}
              </option>
            ))}
          </select>
        </div>

        <button type="submit" className="btn btn-primary" disabled={loading}>
          {loading ? 'جاري الإضافة…' : 'إضافة'}
        </button>
      </form>

      <h2>المنتجات التي لم تُضف</h2>
      {failed.length === 0 ? (
        <p className="muted">لا توجد أخطاء بعد. الصفوف الفاشلة تظهر هنا بعد الإضافة.</p>
      ) : (
        <div className="table-wrap">
          <table className="data">
            <thead>
              <tr>
                <th>رقم الصف</th>
                <th>الاسم</th>
                <th>السبب</th>
              </tr>
            </thead>
            <tbody>
              {failed.map((row) => (
                <tr key={`${row.row}-${row.name}-${row.reason}`}>
                  <td>{row.row}</td>
                  <td>{row.name || '—'}</td>
                  <td>{row.reason}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
