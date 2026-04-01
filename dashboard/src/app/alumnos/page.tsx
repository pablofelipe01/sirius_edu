import { supabase } from '@/lib/supabase'
import Link from 'next/link'
import type { RosterUser } from '@/lib/types'

export const dynamic = 'force-dynamic'

export default async function AlumnosPage() {
  const schoolId = process.env.SCHOOL_ID || 'a0000000-0000-0000-0000-000000000001'

  const { data: students } = await supabase
    .from('roster')
    .select('*')
    .eq('school_id', schoolId)
    .eq('role', 'student')
    .eq('is_active', true)
    .order('grade')
    .order('name')

  return (
    <div>
      <h1 className="text-2xl font-bold text-green-500 mb-6">Alumnos</h1>

      {students && students.length > 0 ? (
        <div className="bg-white rounded-xl border border-gray-100 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50">
              <tr>
                <th className="text-left px-4 py-3 text-gray-600 font-medium">Nombre</th>
                <th className="text-left px-4 py-3 text-gray-600 font-medium">Grado</th>
                <th className="text-left px-4 py-3 text-gray-600 font-medium">Nodo</th>
                <th className="text-left px-4 py-3 text-gray-600 font-medium"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {students.map((s: RosterUser) => (
                <tr key={s.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 font-medium text-gray-800">{s.name}</td>
                  <td className="px-4 py-3 text-gray-500">{s.grade} Grado</td>
                  <td className="px-4 py-3 text-gray-400 font-mono text-xs">{s.node_hex || '-'}</td>
                  <td className="px-4 py-3">
                    <Link href={`/alumnos/${s.id}`} className="text-blue-600 hover:underline text-xs">
                      Ver perfil
                    </Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <div className="text-center py-12 text-gray-400">
          <p className="text-4xl mb-3">👩‍🎓</p>
          <p>No hay alumnos registrados</p>
        </div>
      )}
    </div>
  )
}
