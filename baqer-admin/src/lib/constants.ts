export const TOKEN_KEY = 'baqer_admin_token'
export const USER_KEY = 'baqer_admin_user'

export const ROLES = ['customer', 'shop', 'driver', 'admin'] as const

export const ORDER_STATUS = {
  pending: 'قيد الانتظار',
  accepted: 'مقبول',
  preparing: 'قيد التحضير',
  on_the_way: 'في الطريق',
  delivered: 'تم التسليم',
  canceled: 'ملغي',
  postponed: 'مؤجل',
} as const

export type OrderStatusKey = keyof typeof ORDER_STATUS
