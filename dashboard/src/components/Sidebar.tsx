'use client'
import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'

const nav = [
  { href: '/', label: 'Dashboard', icon: '📊' },
  { href: '/lecciones', label: 'Lecciones', icon: '📖' },
  { href: '/alumnos', label: 'Alumnos', icon: '👩‍🎓' },
  { href: '/entregas', label: 'Entregas', icon: '✅' },
  { href: '/preguntas', label: 'Preguntas', icon: '❓' },
  { href: '/asistente', label: 'Asistente IA', icon: '🤖' },
]

export default function Sidebar({ teacherName, schoolName }: { teacherName?: string; schoolName?: string }) {
  const pathname = usePathname()
  const router = useRouter()

  async function logout() {
    await fetch('/api/auth/logout', { method: 'POST' })
    router.push('/login')
    router.refresh()
  }

  return (
    <aside className="w-64 bg-white border-r border-gray-200 min-h-screen p-4 hidden md:flex md:flex-col">
      <div className="mb-6">
        <h1 className="text-xl font-bold text-green-600">Sirius Edu</h1>
        {schoolName && <p className="text-xs text-gray-500 mt-0.5">{schoolName}</p>}
      </div>

      <nav className="space-y-1 flex-1">
        {nav.map(({ href, label, icon }) => {
          const active = pathname === href || (href !== '/' && pathname.startsWith(href))
          return (
            <Link key={href} href={href}
              className={`flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors
                ${active ? 'bg-green-50 text-green-700' : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'}`}>
              <span className="text-lg">{icon}</span>
              {label}
            </Link>
          )
        })}
      </nav>

      {teacherName && (
        <div className="mt-4 pt-4 border-t border-gray-100">
          <div className="px-3 py-2">
            <p className="text-xs text-gray-400">Conectado como</p>
            <p className="text-sm font-medium text-gray-700 truncate">{teacherName}</p>
          </div>
          <button onClick={logout}
            className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium text-gray-500 hover:bg-red-50 hover:text-red-600 transition-colors">
            <span>🚪</span>
            Salir
          </button>
        </div>
      )}
    </aside>
  )
}
