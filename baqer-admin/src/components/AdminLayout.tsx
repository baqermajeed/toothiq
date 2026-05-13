import { useEffect, useState } from 'react'
import { NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

const links = [
  { to: '/', label: 'نظرة عامة', end: true },
  { to: '/users', label: 'المستخدمون' },
  { to: '/shops', label: 'المحلات' },
  { to: '/orders', label: 'الطلبات' },
  { to: '/products', label: 'المنتجات' },
  { to: '/categories', label: 'تصنيفات المنتجات' },
  { to: '/discount-codes', label: 'أكواد الخصم' },
  { to: '/banners', label: 'البانرات' },
  { to: '/settings', label: 'إعدادات المنصة' },
]

export function AdminLayout() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const [navOpen, setNavOpen] = useState(false)

  useEffect(() => {
    setNavOpen(false)
  }, [location.pathname])

  useEffect(() => {
    if (!navOpen) return
    const prev = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    return () => {
      document.body.style.overflow = prev
    }
  }, [navOpen])

  useEffect(() => {
    const mq = window.matchMedia('(min-width: 901px)')
    const onChange = () => {
      if (mq.matches) setNavOpen(false)
    }
    mq.addEventListener('change', onChange)
    return () => mq.removeEventListener('change', onChange)
  }, [])

  useEffect(() => {
    if (!navOpen) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setNavOpen(false)
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [navOpen])

  return (
    <div className={`app-shell${navOpen ? ' nav-open' : ''}`}>
      <button
        type="button"
        className="sidebar-backdrop"
        aria-label="إغلاق القائمة"
        tabIndex={navOpen ? 0 : -1}
        onClick={() => setNavOpen(false)}
      />
      <aside className="sidebar" aria-label="القائمة الرئيسية">
        <div className="sidebar-brand">
          <span>باقر داشبورد</span>
          <button
            type="button"
            className="sidebar-close btn"
            aria-label="إغلاق القائمة"
            onClick={() => setNavOpen(false)}
          >
            ×
          </button>
        </div>
        <nav id="admin-sidebar-nav">
          {links.map(({ to, label, end }) => (
            <NavLink key={to} to={to} end={end} className={({ isActive }) => `nav-link${isActive ? ' active' : ''}`}>
              {label}
            </NavLink>
          ))}
        </nav>
      </aside>
      <div className="main">
        <header className="topbar">
          <div className="topbar-start">
            <button
              type="button"
              className="menu-btn btn"
              aria-expanded={navOpen}
              aria-controls="admin-sidebar-nav"
              onClick={() => setNavOpen((o) => !o)}
            >
              القائمة
            </button>
            <span className="muted topbar-user">
              {user?.name} — {user?.phone}
            </span>
          </div>
          <button
            type="button"
            className="btn"
            onClick={async () => {
              await logout()
              navigate('/login', { replace: true })
            }}
          >
            خروج
          </button>
        </header>
        <main className="content">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
