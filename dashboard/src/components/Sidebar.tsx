'use client'
import Link from 'next/link'
import { usePathname } from 'next/navigation'

const nav = [
  { href: '/', label: 'Dashboard', icon: '📊' },
  { href: '/lecciones', label: 'Lecciones', icon: '📖' },
  { href: '/tareas', label: 'Tareas', icon: '📝' },
  { href: '/alumnos', label: 'Alumnos', icon: '👩‍🎓' },
  { href: '/preguntas', label: 'Preguntas', icon: '❓' },
  { href: '/asistente', label: 'Asistente IA', icon: '🤖' },
]

export default function Sidebar() {
  const pathname = usePathname()

  return (
    <aside className="w-64 bg-white border-r border-gray-200 min-h-screen p-4 hidden md:block">
      <div className="mb-8">
        <h1 className="text-xl font-bold text-green-600">Sirius Edu</h1>
        <p className="text-xs text-gray-400">Panel del Profesor</p>
      </div>
      <nav className="space-y-1">
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
    </aside>
  )
}
