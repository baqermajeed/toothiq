import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import { apiLogin, apiLogout, getStoredToken, getStoredUser, setAuth } from '../lib/api'

type User = {
  _id?: string
  name?: string
  phone?: string
  roles?: string[]
}

type AuthState = {
  token: string | null
  user: User | null
  ready: boolean
  login: (phone: string, password: string) => Promise<void>
  logout: () => Promise<void>
}

const AuthContext = createContext<AuthState | null>(null)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState<string | null>(null)
  const [user, setUser] = useState<User | null>(null)
  const [ready, setReady] = useState(false)

  useEffect(() => {
    const t = getStoredToken()
    const u = getStoredUser() as User | null
    setToken(t)
    setUser(u && u._id ? u : null)
    setReady(true)
  }, [])

  const login = useCallback(async (phone: string, password: string) => {
    const data = await apiLogin(phone, password)
    setAuth(data.accessToken, data.user)
    setToken(data.accessToken)
    setUser(data.user as User)
  }, [])

  const logout = useCallback(async () => {
    await apiLogout()
    setToken(null)
    setUser(null)
  }, [])

  const value = useMemo(
    () => ({ token, user, ready, login, logout }),
    [token, user, ready, login, logout]
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth outside AuthProvider')
  return ctx
}

export function useIsAdmin() {
  const { user } = useAuth()
  return Boolean(user?.roles?.includes('admin'))
}
