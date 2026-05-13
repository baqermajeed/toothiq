import { useEffect, useState, type FormEvent } from 'react'
import { ApiError } from '../lib/api'
import { adminApi, type AdminSettings } from '../api/admin'

export function SettingsPage() {
  const [data, setData] = useState<AdminSettings | null>(null)
  const [err, setErr] = useState('')
  const [msg, setMsg] = useState('')

  useEffect(() => {
    let c = false
    ;(async () => {
      try {
        const s = await adminApi.settings.get()
        if (!c)
          setData({
            ...s,
            globalDeliveryFee: typeof s.globalDeliveryFee === 'number' ? s.globalDeliveryFee : 0,
            useDashboardDeliveryFee: !!s.useDashboardDeliveryFee,
            facebookUrl: String(s.facebookUrl ?? ''),
            instagramUrl: String(s.instagramUrl ?? ''),
            supportPhone: String(s.supportPhone ?? ''),
            aboutUs: String(s.aboutUs ?? ''),
          })
      } catch (e) {
        if (!c) setErr(e instanceof ApiError ? e.message : 'فشل')
      }
    })()
    return () => {
      c = true
    }
  }, [])

  async function onSave(e: FormEvent) {
    e.preventDefault()
    if (!data) return
    setErr('')
    setMsg('')
    try {
      const patch: Partial<AdminSettings> = {
        deliveryEnabled: data.deliveryEnabled,
        deliveryPauseReason: data.deliveryPauseReason,
        globalDeliveryFee: data.globalDeliveryFee,
        facebookUrl: data.facebookUrl,
        instagramUrl: data.instagramUrl,
        supportPhone: data.supportPhone,
        aboutUs: data.aboutUs,
      }
      const s = await adminApi.settings.patch(patch)
      setData({
        ...s,
        globalDeliveryFee: typeof s.globalDeliveryFee === 'number' ? s.globalDeliveryFee : 0,
        useDashboardDeliveryFee: !!s.useDashboardDeliveryFee,
        facebookUrl: String(s.facebookUrl ?? ''),
        instagramUrl: String(s.instagramUrl ?? ''),
        supportPhone: String(s.supportPhone ?? ''),
        aboutUs: String(s.aboutUs ?? ''),
      })
      setMsg('تم الحفظ')
    } catch (ex) {
      setErr(ex instanceof ApiError ? ex.message : 'فشل')
    }
  }

  if (!data && !err) return <p className="muted">جاري التحميل…</p>

  return (
    <div>
      <h1 style={{ marginTop: 0 }}>إعدادات المنصة</h1>
      {err ? <div className="alert alert-error">{err}</div> : null}
      {msg ? <div className="alert alert-success">{msg}</div> : null}
      {data ? (
        <form className="card" onSubmit={onSave}>
          <h2 style={{ marginTop: 0, fontSize: '1.1rem' }}>التوصيل</h2>
          <p className="muted" style={{ marginTop: 0 }}>
            رسوم التوصيل الموحّدة تُطبَّق على الطلبات الجديدة. يمكنك تعديلها من هنا في أي وقت؛ إذا كان مصدر الإعدادات{' '}
            <code dir="ltr">env</code> فستُستخدم قيمة البيئة حتى تحفظ الرسوم من لوحة الإدارة، وبعدها تُستخدم القيمة
            المحفوظة في قاعدة البيانات.
          </p>
          <label className="muted" style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
            <input
              type="checkbox"
              checked={data.deliveryEnabled}
              onChange={(e) => setData({ ...data, deliveryEnabled: e.target.checked })}
            />
            التوصيل مفعّل (deliveryEnabled)
          </label>
          <div className="field">
            <label>سبب إيقاف التوصيل (نص للمستخدم)</label>
            <textarea
              className="textarea"
              value={data.deliveryPauseReason}
              onChange={(e) => setData({ ...data, deliveryPauseReason: e.target.value })}
            />
          </div>
          <div className="field">
            <label>رسوم التوصيل الموحّدة (لجميع الطلبات)</label>
            {data.platformSettingsSource === 'env' && !data.useDashboardDeliveryFee ? (
              <p className="muted" style={{ marginTop: 0 }}>
                القيمة الحالية من البيئة أو الافتراضي: <strong dir="ltr">{data.globalDeliveryFee ?? 0}</strong> — بعد
                الضغط على «حفظ» تُثبَّت الرسوم من لوحة الإدارة.
              </p>
            ) : null}
            {data.platformSettingsSource === 'env' && data.useDashboardDeliveryFee ? (
              <p className="muted" style={{ marginTop: 0 }}>
                الرسوم المحفوظة من لوحة الإدارة تتجاوز <code dir="ltr">PLATFORM_GLOBAL_DELIVERY_FEE</code> في البيئة.
              </p>
            ) : null}
            <input
              className="input"
              type="number"
              min={0}
              step={100}
              dir="ltr"
              style={{ textAlign: 'left' }}
              value={data.globalDeliveryFee ?? 0}
              onChange={(e) => setData({ ...data, globalDeliveryFee: Number(e.target.value) || 0 })}
            />
          </div>

          <hr style={{ margin: '24px 0', border: 'none', borderTop: '1px solid var(--border, #ddd)' }} />

          <h2 style={{ marginTop: 0, fontSize: '1.1rem' }}>التواصل مع المنصة</h2>
          <p className="muted" style={{ marginTop: 0 }}>
            رقم دعم واحد لجميع المناطق (لا يوجد تقسيم حسب المحافظة في الواجهة).
          </p>
          <div className="field">
            <label>رقم الدعم</label>
            <input
              className="input"
              dir="ltr"
              style={{ textAlign: 'left' }}
              value={data.supportPhone}
              onChange={(e) => setData({ ...data, supportPhone: e.target.value })}
              placeholder="+964..."
            />
          </div>
          <div className="field">
            <label>رابط فيسبوك</label>
            <input
              className="input"
              dir="ltr"
              style={{ textAlign: 'left' }}
              value={data.facebookUrl}
              onChange={(e) => setData({ ...data, facebookUrl: e.target.value })}
            />
          </div>
          <div className="field">
            <label>رابط إنستغرام</label>
            <input
              className="input"
              dir="ltr"
              style={{ textAlign: 'left' }}
              value={data.instagramUrl}
              onChange={(e) => setData({ ...data, instagramUrl: e.target.value })}
            />
          </div>

          <hr style={{ margin: '24px 0', border: 'none', borderTop: '1px solid var(--border, #ddd)' }} />

          <h2 style={{ marginTop: 0, fontSize: '1.1rem' }}>من نحن</h2>
          <p className="muted" style={{ marginTop: 0 }}>
            النص الذي يظهر في التطبيق في صفحة «من نحن» (يمكن استخدام أسطر متعددة).
          </p>
          <div className="field">
            <label>المحتوى</label>
            <textarea
              className="textarea"
              rows={10}
              value={data.aboutUs}
              onChange={(e) => setData({ ...data, aboutUs: e.target.value })}
              placeholder="اكتب نبذة عن المنصة..."
            />
          </div>

          <button type="submit" className="btn btn-primary">
            حفظ
          </button>
        </form>
      ) : null}
    </div>
  )
}
