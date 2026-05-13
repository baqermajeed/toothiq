import { useEffect, useState, type FormEvent } from 'react'
import { ApiError } from '../lib/api'
import { adminApi } from '../api/admin'

export function DiscountCodesPage() {
  const [items, setItems] = useState<Record<string, unknown>[]>([])
  const [err, setErr] = useState('')
  const [msg, setMsg] = useState('')
  const [code, setCode] = useState('')
  const [discountAmount, setDiscountAmount] = useState('5000')
  const [maxUses, setMaxUses] = useState('100')
  const [expiresAt, setExpiresAt] = useState('')
  const [editAmount, setEditAmount] = useState<Record<string, string>>({})

  async function load() {
    setErr('')
    try {
      setItems(await adminApi.discountCodes.list())
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
    try {
      await adminApi.discountCodes.create({
        code: code.trim() || null,
        discountAmount: Number(discountAmount),
        maxUses: Number(maxUses),
        expiresAt: expiresAt || null,
        isActive: true,
      })
      setCode('')
      setMsg('تم الإنشاء')
      void load()
    } catch (ex) {
      setErr(ex instanceof ApiError ? ex.message : 'فشل')
    }
  }

  async function toggle(id: string, isActive: boolean) {
    setErr('')
    try {
      await adminApi.discountCodes.patch(id, { isActive: !isActive })
      void load()
    } catch (ex) {
      setErr(ex instanceof ApiError ? ex.message : 'فشل')
    }
  }

  async function saveAmount(id: string) {
    const v = editAmount[id]
    if (v == null || v === '') return
    setErr('')
    try {
      await adminApi.discountCodes.patch(id, { discountAmount: Number(v) })
      setMsg('تم التحديث')
      void load()
    } catch (ex) {
      setErr(ex instanceof ApiError ? ex.message : 'فشل')
    }
  }

  async function remove(id: string) {
    if (!window.confirm('حذف الكود؟')) return
    setErr('')
    try {
      await adminApi.discountCodes.remove(id)
      void load()
    } catch (ex) {
      setErr(ex instanceof ApiError ? ex.message : 'فشل')
    }
  }

  return (
    <div>
      <h1 style={{ marginTop: 0 }}>أكواد الخصم</h1>
      {err ? <div className="alert alert-error">{err}</div> : null}
      {msg ? <div className="alert alert-success">{msg}</div> : null}

      <form className="card" onSubmit={onCreate}>
        <h2>كود جديد</h2>
        <div className="field">
          <label>الكود (فارغ = توليد تلقائي إن وُجد في الخادم)</label>
          <input className="input" dir="ltr" value={code} onChange={(e) => setCode(e.target.value)} />
        </div>
        <div className="field">
          <label>مبلغ الخصم</label>
          <input className="input" type="number" value={discountAmount} onChange={(e) => setDiscountAmount(e.target.value)} required />
        </div>
        <div className="field">
          <label>أقصى عدد استخدامات</label>
          <input className="input" type="number" value={maxUses} onChange={(e) => setMaxUses(e.target.value)} required />
        </div>
        <div className="field">
          <label>انتهاء الصلاحية (datetime-local)</label>
          <input className="input" type="datetime-local" value={expiresAt} onChange={(e) => setExpiresAt(e.target.value)} />
        </div>
        <button type="submit" className="btn btn-primary">
          إنشاء
        </button>
      </form>

      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>الكود</th>
              <th>المبلغ</th>
              <th>الاستخدامات</th>
              <th>نشط</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {items.map((d) => {
              const id = String(d._id)
              return (
                <tr key={id}>
                  <td dir="ltr">{String(d.code ?? '')}</td>
                  <td>
                    <input
                      className="input"
                      style={{ maxWidth: 120 }}
                      dir="ltr"
                      placeholder={String(d.discountAmount ?? '')}
                      value={editAmount[id] ?? ''}
                      onChange={(e) => setEditAmount((m) => ({ ...m, [id]: e.target.value }))}
                    />
                    <button type="button" className="btn" onClick={() => saveAmount(id)}>
                      حفظ المبلغ
                    </button>
                  </td>
                  <td>
                    {String(d.usedCount ?? 0)} / {String(d.maxUses ?? '')}
                  </td>
                  <td>{d.isActive !== false ? 'نعم' : 'لا'}</td>
                  <td>
                    <button type="button" className="btn" onClick={() => toggle(id, d.isActive !== false)}>
                      تبديل
                    </button>{' '}
                    <button type="button" className="btn btn-danger" onClick={() => remove(id)}>
                      حذف
                    </button>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    </div>
  )
}
