import { cookies } from 'next/headers'
import { SignJWT, jwtVerify } from 'jose'

const SECRET = new TextEncoder().encode(
  process.env.SESSION_SECRET || 'dev-secret-change-in-production-please-32chars'
)

export const COOKIE_NAME = 'sirius_session'
const SESSION_MAX_AGE = 60 * 60 * 24 * 7 // 7 days

export interface Session {
  teacher_id: string
  teacher_name: string
  school_id: string
  school_name?: string
}

export async function createSession(data: Session): Promise<string> {
  return await new SignJWT({ ...data })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('7d')
    .sign(SECRET)
}

export async function verifySession(token: string): Promise<Session | null> {
  try {
    const { payload } = await jwtVerify(token, SECRET)
    return {
      teacher_id: payload.teacher_id as string,
      teacher_name: payload.teacher_name as string,
      school_id: payload.school_id as string,
      school_name: payload.school_name as string | undefined,
    }
  } catch {
    return null
  }
}

/// Get session from cookies (server components / API routes)
export async function getSession(): Promise<Session | null> {
  const cookieStore = await cookies()
  const token = cookieStore.get(COOKIE_NAME)?.value
  if (!token) return null
  return verifySession(token)
}

export const SESSION_COOKIE_OPTIONS = {
  httpOnly: true,
  secure: process.env.NODE_ENV === 'production',
  sameSite: 'lax' as const,
  path: '/',
  maxAge: SESSION_MAX_AGE,
}
