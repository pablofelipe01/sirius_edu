import { supabase } from '@/lib/supabase'
import type { Assignment } from '@/lib/types'

export const dynamic = 'force-dynamic'

export default async function TareasPage() {
  const schoolId = process.env.SCHOOL_ID || 'a0000000-0000-0000-0000-000000000001'

  const { data: assignments } = await supabase
    .from('assignments')
    .select('*, lessons(title, subject_code)')
    .eq('school_id', schoolId)
    .order('created_at', { ascending: false })

  return (
    <div>
      <h1 className="text-2xl font-bold text-green-500 mb-6">Tareas</h1>

      {assignments && assignments.length > 0 ? (
        <div className="space-y-3">
          {assignments.map((a: Assignment) => (
            <div key={a.id} className="bg-white rounded-xl border border-gray-100 p-5">
              <div className="flex items-start justify-between mb-2">
                <div>
                  <h3 className="font-semibold text-gray-800">{a.title}</h3>
                  <p className="text-xs text-gray-400">
                    {a.lessons?.title || 'Sin leccion'} - Grado {a.grade}
                  </p>
                </div>
                <span className={`text-xs px-2 py-1 rounded-full ${a.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                  {a.is_active ? 'Activa' : 'Cerrada'}
                </span>
              </div>
              <p className="text-sm text-gray-600 mb-2">{a.description}</p>
              {a.deadline && (
                <p className="text-xs text-orange-500">
                  Fecha limite: {new Date(a.deadline).toLocaleDateString('es-CO')}
                </p>
              )}
            </div>
          ))}
        </div>
      ) : (
        <div className="text-center py-12 text-gray-400">
          <p className="text-4xl mb-3">📝</p>
          <p>No hay tareas creadas</p>
          <p className="text-xs mt-1">Crea una leccion primero y luego agrega tareas</p>
        </div>
      )}
    </div>
  )
}
