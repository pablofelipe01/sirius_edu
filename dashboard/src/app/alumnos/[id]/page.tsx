import { supabase } from '@/lib/supabase'
import Link from 'next/link'

export const dynamic = 'force-dynamic'

export default async function AlumnoPerfilPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params

  const [studentRes, conversationsRes, questionsRes, submissionsRes] = await Promise.all([
    supabase.from('roster').select('*').eq('id', id).single(),
    supabase.from('ai_conversations').select('*').eq('student_id', id).order('created_at', { ascending: false }).limit(20),
    supabase.from('student_questions').select('*').eq('student_id', id).order('created_at', { ascending: false }).limit(10),
    supabase.from('submissions').select('*, assignments(title)').eq('student_id', id).order('submitted_at', { ascending: false }).limit(10),
  ])

  const student = studentRes.data
  if (!student) return <p className="text-gray-400">Alumno no encontrado</p>

  return (
    <div>
      <Link href="/alumnos" className="text-sm text-gray-400 hover:text-gray-600 mb-4 inline-block">&larr; Volver</Link>

      <div className="flex items-center gap-4 mb-6">
        <div className="w-14 h-14 rounded-full bg-green-100 flex items-center justify-center text-2xl">👩‍🎓</div>
        <div>
          <h1 className="text-2xl font-bold text-gray-800">{student.name}</h1>
          <p className="text-gray-500">Grado {student.grade} - Nodo {student.node_hex || '-'}</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Entregas */}
        <div className="bg-white rounded-xl border border-gray-100 p-5">
          <h2 className="font-semibold text-gray-800 mb-3">Entregas ({submissionsRes.data?.length || 0})</h2>
          {submissionsRes.data?.map((s: Record<string, unknown>) => (
            <div key={s.id as string} className="border-b border-gray-50 py-2 last:border-0">
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-700">{(s.assignments as Record<string, string>)?.title || 'Tarea'}</span>
                {s.ai_score != null && (
                  <span className="text-xs bg-green-100 text-green-700 px-2 py-0.5 rounded-full">
                    {Number(s.ai_score).toFixed(1)}/10
                  </span>
                )}
              </div>
              <p className="text-xs text-gray-400">{new Date(s.submitted_at as string).toLocaleDateString('es-CO')}</p>
            </div>
          ))}
          {!submissionsRes.data?.length && <p className="text-sm text-gray-400">Sin entregas</p>}
        </div>

        {/* Preguntas al profesor */}
        <div className="bg-white rounded-xl border border-gray-100 p-5">
          <h2 className="font-semibold text-gray-800 mb-3">Preguntas al profesor ({questionsRes.data?.length || 0})</h2>
          {questionsRes.data?.map((q: Record<string, unknown>) => (
            <div key={q.id as string} className="border-b border-gray-50 py-2 last:border-0">
              <p className="text-sm text-gray-700">{q.question as string}</p>
              {q.teacher_response ? (
                <p className="text-xs text-green-600 mt-1">{q.teacher_response as string}</p>
              ) : (
                <p className="text-xs text-orange-500 mt-1">Sin respuesta</p>
              )}
            </div>
          ))}
          {!questionsRes.data?.length && <p className="text-sm text-gray-400">Sin preguntas</p>}
        </div>

        {/* Conversaciones IA */}
        <div className="bg-white rounded-xl border border-gray-100 p-5 md:col-span-2">
          <h2 className="font-semibold text-gray-800 mb-3">Conversaciones con tutor IA ({conversationsRes.data?.length || 0})</h2>
          {conversationsRes.data?.map((c: Record<string, unknown>) => (
            <div key={c.id as string} className="border-b border-gray-50 py-3 last:border-0">
              <p className="text-sm font-medium text-gray-700">{c.question as string}</p>
              <p className="text-sm text-gray-500 mt-1">{(c.ai_response as string)?.substring(0, 200)}...</p>
              <p className="text-xs text-gray-300 mt-1">{new Date(c.created_at as string).toLocaleDateString('es-CO')} - {c.ai_model as string}</p>
            </div>
          ))}
          {!conversationsRes.data?.length && <p className="text-sm text-gray-400">Sin conversaciones</p>}
        </div>
      </div>
    </div>
  )
}
