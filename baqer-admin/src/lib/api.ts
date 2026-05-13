import { TOKEN_KEY, USER_KEY } from './constants'

const BASE = import.meta.env.VITE_API_BASE ?? ''

export class ApiError extends Error {
  status: number
  code: string
  constructor(status: number, code: string, message: string) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.code = code
  }
}

export function getStoredToken(): string | null {
  return localStorage.getItem(TOKEN_KEY)
}

export function setAuth(token: string, user: unknown) {
  localStorage.setItem(TOKEN_KEY, token)
  localStorage.setItem(USER_KEY, JSON.stringify(user))
}

export function clearAuth() {
  localStorage.removeItem(TOKEN_KEY)
  localStorage.removeItem(USER_KEY)
}

export function getStoredUser(): Record<string, unknown> | null {
  const raw = localStorage.getItem(USER_KEY)
  if (!raw) return null
  try {
    return JSON.parse(raw) as Record<string, unknown>
  } catch {
    return null
  }
}

function resolveUrl(path: string): string {
  if (path.startsWith('http')) return path
  return `${BASE}${path.startsWith('/') ? path : `/${path}`}`
}

export async function apiFetch<T>(path: string, init: RequestInit = {}): Promise<T> {
  const headers = new Headers(init.headers)
  const token = getStoredToken()
  if (token) headers.set('Authorization', `Bearer ${token}`)
  if (init.body && !(init.body instanceof FormData) && !headers.has('Content-Type')) {
    headers.set('Content-Type', 'application/json')
  }
  const res = await fetch(resolveUrl(path), { ...init, headers })
  let json: Record<string, unknown> = {}
  try {
    json = (await res.json()) as Record<string, unknown>
  } catch {
    /* empty */
  }
  if (!res.ok) {
    const err = json.error as { code?: string; message?: string } | undefined
    throw new ApiError(res.status, err?.code ?? 'HTTP_ERROR', err?.message ?? res.statusText)
  }
  if (json.success === false) {
    const err = json.error as { code?: string; message?: string } | undefined
    throw new ApiError(res.status, err?.code ?? 'ERROR', err?.message ?? 'Request failed')
  }
  return json.data as T
}

export async function apiLogin(phone: string, password: string) {
  const headers = new Headers({ 'Content-Type': 'application/json' })
  const res = await fetch(resolveUrl('/api/auth/login'), {
    method: 'POST',
    headers,
    body: JSON.stringify({ phone, password }),
  })
  const json = (await res.json()) as {
    success?: boolean
    data?: { user: Record<string, unknown>; accessToken: string; expiresIn?: string }
    error?: { code?: string; message?: string }
  }
  if (!res.ok || json.success === false) {
    throw new ApiError(res.status, json.error?.code ?? 'HTTP_ERROR', json.error?.message ?? 'فشل تسجيل الدخول')
  }
  if (!json.data?.accessToken) throw new ApiError(500, 'INVALID', 'استجابة غير صالحة')
  return json.data
}

export async function apiLogout() {
  try {
    await apiFetch<{ message: string }>('/api/auth/logout', { method: 'POST' })
  } catch {
    /* ignore */
  }
  clearAuth()
}

/** للصور والملفات النسبية من الخادم */
export function assetUrl(path: string | null | undefined): string {
  if (!path) return ''
  if (path.startsWith('http')) return path
  return resolveUrl(path.startsWith('/') ? path : `/${path}`)
}
