export const ORDER_STATUS = {
  pending: 'قيد الانتظار',
  accepted: 'مقبول',
  preparing: 'قيد التحضير',
  on_the_way: 'في الطريق',
  delivered: 'تم التوصيل',
  canceled: 'ملغى',
  postponed: 'مؤجل',
} as const

export type OrderStatusKey = keyof typeof ORDER_STATUS

export const ROLES = ['customer', 'shop', 'admin'] as const

export const TOKEN_KEY = 'baqer_admin_token'
export const USER_KEY = 'baqer_admin_user'
