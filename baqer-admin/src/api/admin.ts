import { apiFetch } from '../lib/api'

export type Paginated<T> = {
  items: T[]
  pagination: { page: number; limit: number; total: number }
}

export type AdminSettings = {
  deliveryEnabled: boolean
  deliveryPauseReason: string
  globalDeliveryFee: number
  useDashboardDeliveryFee?: boolean
  platformSettingsSource?: string
  facebookUrl: string
  instagramUrl: string
  supportPhone: string
  aboutUs: string
}

export const adminApi = {
  settings: {
    get: () => apiFetch<AdminSettings>('/api/admin/settings'),
    patch: (body: Partial<AdminSettings>) =>
      apiFetch<AdminSettings>('/api/admin/settings', { method: 'PATCH', body: JSON.stringify(body) }),
  },
  stats: () => apiFetch<Record<string, unknown>>('/api/admin/stats'),
  ordersStats: (q?: Record<string, string>) => {
    const sp = q ? `?${new URLSearchParams(q).toString()}` : ''
    return apiFetch<unknown>(`/api/admin/orders/stats${sp}`)
  },
  users: {
    list: (q: Record<string, string | number | boolean | undefined>) => {
      const sp = new URLSearchParams()
      Object.entries(q).forEach(([k, v]) => {
        if (v !== undefined && v !== '') sp.set(k, String(v))
      })
      return apiFetch<Paginated<Record<string, unknown>>>(`/api/admin/users?${sp}`)
    },
    get: (id: string) => apiFetch<Record<string, unknown>>(`/api/admin/users/${id}`),
    create: (body: Record<string, unknown>) =>
      apiFetch<Record<string, unknown>>('/api/admin/users', { method: 'POST', body: JSON.stringify(body) }),
    patch: (id: string, body: Record<string, unknown>) =>
      apiFetch<Record<string, unknown>>(`/api/admin/users/${id}`, { method: 'PATCH', body: JSON.stringify(body) }),
    setActive: (id: string, isActive: boolean) =>
      apiFetch<Record<string, unknown>>(`/api/admin/users/${id}/active`, {
        method: 'PATCH',
        body: JSON.stringify({ isActive }),
      }),
    remove: (id: string) => apiFetch<{ message: string }>(`/api/admin/users/${id}`, { method: 'DELETE' }),
  },
  shops: {
    list: (q: Record<string, string | number | boolean | undefined>) => {
      const sp = new URLSearchParams()
      Object.entries(q).forEach(([k, v]) => {
        if (v !== undefined && v !== '') sp.set(k, String(v))
      })
      return apiFetch<Paginated<Record<string, unknown>>>(`/api/admin/shops?${sp}`)
    },
    create: (form: FormData) =>
      apiFetch<Record<string, unknown>>('/api/admin/shops', { method: 'POST', body: form }),
    patch: (id: string, form: FormData) =>
      apiFetch<Record<string, unknown>>(`/api/admin/shops/${id}`, { method: 'PATCH', body: form }),
    remove: (id: string) => apiFetch<{ message: string }>(`/api/admin/shops/${id}`, { method: 'DELETE' }),
    reorder: (shopIds: string[]) =>
      apiFetch<unknown>('/api/admin/shops/reorder', {
        method: 'POST',
        body: JSON.stringify({ shopIds }),
      }),
    bulkOpenHours: (body: Record<string, unknown>) =>
      apiFetch<unknown>('/api/admin/shops/bulk-open-hours', { method: 'PATCH', body: JSON.stringify(body) }),
  },
  orders: {
    list: (q: Record<string, string | number | boolean | undefined>) => {
      const sp = new URLSearchParams()
      Object.entries(q).forEach(([k, v]) => {
        if (v !== undefined && v !== '') sp.set(k, String(v))
      })
      return apiFetch<Paginated<Record<string, unknown>>>(`/api/admin/orders?${sp}`)
    },
    get: (id: string) => apiFetch<Record<string, unknown>>(`/api/admin/orders/${id}`),
    patchStatus: (id: string, body: Record<string, unknown>) =>
      apiFetch<Record<string, unknown>>(`/api/admin/orders/${id}/status`, {
        method: 'PATCH',
        body: JSON.stringify(body),
      }),
    remove: (id: string) => apiFetch<{ message: string }>(`/api/admin/orders/${id}`, { method: 'DELETE' }),
    deliverStale: () =>
      apiFetch<{ updatedCount: number }>('/api/admin/orders/deliver-stale-on-the-way-silent', { method: 'POST' }),
  },
  products: {
    list: (q: Record<string, string | number | boolean | undefined>) => {
      const sp = new URLSearchParams()
      Object.entries(q).forEach(([k, v]) => {
        if (v !== undefined && v !== '') sp.set(k, String(v))
      })
      return apiFetch<Paginated<Record<string, unknown>>>(`/api/admin/products?${sp}`)
    },
    create: (shopId: string, form: FormData) =>
      apiFetch<Record<string, unknown>>(`/api/shops/${shopId}/products`, {
        method: 'POST',
        body: form,
      }),
  },
  categories: {
    list: () => apiFetch<Record<string, unknown>[]>('/api/admin/categories'),
    create: (form: FormData) =>
      apiFetch<Record<string, unknown>>('/api/admin/categories', { method: 'POST', body: form }),
    patch: (id: string, body: Record<string, unknown> | FormData) =>
      apiFetch<Record<string, unknown>>(`/api/admin/categories/${id}`, {
        method: 'PATCH',
        body: body instanceof FormData ? body : JSON.stringify(body),
      }),
    remove: (id: string) => apiFetch<unknown>(`/api/admin/categories/${id}`, { method: 'DELETE' }),
    reorder: (orderedIds: string[]) =>
      apiFetch<unknown>('/api/admin/categories/reorder', {
        method: 'PATCH',
        body: JSON.stringify({ orderedIds }),
      }),
  },
  productTaxonomy: {
    list: () =>
      apiFetch<{
        categories: Record<string, unknown>[]
        subcategories: Record<string, unknown>[]
        brands: Record<string, unknown>[]
      }>('/api/admin/product-taxonomy'),
    createSubcategory: (body: Record<string, unknown>) =>
      apiFetch<Record<string, unknown>>('/api/admin/product-subcategories', {
        method: 'POST',
        body: JSON.stringify(body),
      }),
    patchSubcategory: (id: string, body: Record<string, unknown>) =>
      apiFetch<Record<string, unknown>>(`/api/admin/product-subcategories/${id}`, {
        method: 'PATCH',
        body: JSON.stringify(body),
      }),
    removeSubcategory: (id: string) => apiFetch<unknown>(`/api/admin/product-subcategories/${id}`, { method: 'DELETE' }),
    createBrand: (form: FormData) =>
      apiFetch<Record<string, unknown>>('/api/admin/brands', { method: 'POST', body: form }),
    patchBrand: (id: string, body: Record<string, unknown> | FormData) =>
      apiFetch<Record<string, unknown>>(`/api/admin/brands/${id}`, {
        method: 'PATCH',
        body: body instanceof FormData ? body : JSON.stringify(body),
      }),
    removeBrand: (id: string) => apiFetch<unknown>(`/api/admin/brands/${id}`, { method: 'DELETE' }),
  },
  discountCodes: {
    list: () => apiFetch<Record<string, unknown>[]>('/api/admin/discount-codes'),
    create: (body: Record<string, unknown>) =>
      apiFetch<Record<string, unknown>>('/api/admin/discount-codes', {
        method: 'POST',
        body: JSON.stringify(body),
      }),
    patch: (id: string, body: Record<string, unknown>) =>
      apiFetch<Record<string, unknown>>(`/api/admin/discount-codes/${id}`, {
        method: 'PATCH',
        body: JSON.stringify(body),
      }),
    remove: (id: string) => apiFetch<unknown>(`/api/admin/discount-codes/${id}`, { method: 'DELETE' }),
  },
  banners: {
    list: () => apiFetch<Record<string, unknown>[]>('/api/admin/banners'),
    create: (form: FormData) =>
      apiFetch<Record<string, unknown>>('/api/admin/banners', { method: 'POST', body: form }),
    patch: (id: string, form: FormData) =>
      apiFetch<Record<string, unknown>>(`/api/admin/banners/${id}`, { method: 'PATCH', body: form }),
    remove: (id: string) => apiFetch<unknown>(`/api/admin/banners/${id}`, { method: 'DELETE' }),
  },
  notifications: {
    broadcast: (body: {
      title: string
      body: string
      type: 'product' | 'store'
      productId?: string
      shopId?: string
    }) =>
      apiFetch<Record<string, unknown>>('/api/admin/notifications/broadcast', {
        method: 'POST',
        body: JSON.stringify(body),
      }),
  },
}

export async function fetchGovernorates() {
  return apiFetch<{ id: string; nameAr: string }[]>('/api/governorates')
}
