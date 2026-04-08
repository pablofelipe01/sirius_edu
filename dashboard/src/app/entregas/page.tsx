import { supabase } from '@/lib/supabase'

export const dynamic = 'force-dynamic'

interface SubmissionRow {
  id: string
  activity_id: string | null
  activity_type: string | null
  response: string
  submitted_at: string
  ai_feedback: string | null
  ai_score: number | null
  roster: { name: string; grade: string } | null
  chapter_activities: { title: string; lesson_id: string } | null
}

export default async function EntregasPage() {
  const { data: submissions } = await supabase
    .from('submissions')
    .select('*, roster!submissions_student_id_fkey(name, grade), chapter_activities(title, lesson_id)')
    .order('submitted_at', { ascending: false })
    .limit(50)

  const items = (submissions as SubmissionRow[] | null) || []
  const missions = items.filter(s => s.activity_type === 'mission' || (!s.activity_type && s.activity_id))
  const tests = items.filter(s => s.activity_type === 'test')

  return (
    <div>
      <h1 className="text-2xl font-bold text-green-500 mb-6">Entregas de Alumnos</h1>

      {/* Misiones (respuestas escritas con evaluacion IA) */}
      <section className="mb-8">
        <h2 className="text-lg font-semibold text-orange-500 mb-3">Misiones</h2>
        {missions.length > 0 ? (
          <div className="space-y-3">
            {missions.map(s => (
              <div key={s.id} className="bg-white rounded-xl border border-orange-100 p-5">
                <div className="flex items-start justify-between mb-2">
                  <div>
                    <h3 className="font-semibold text-gray-800">
                      {s.roster?.name || 'Alumno'} <span className="text-xs text-gray-400">- Grado {s.roster?.grade || '?'}</span>
                    </h3>
                    <p className="text-xs text-gray-400">
                      {s.chapter_activities?.title || 'Actividad'} - {new Date(s.submitted_at).toLocaleString('es-CO')}
                    </p>
                  </div>
                  {s.ai_score !== null && (
                    <span className={`text-sm px-3 py-1 rounded-full font-bold ${
                      s.ai_score >= 7 ? 'bg-green-100 text-green-700' :
                      s.ai_score >= 5 ? 'bg-yellow-100 text-yellow-700' : 'bg-red-100 text-red-700'
                    }`}>
                      {s.ai_score}/10
                    </span>
                  )}
                </div>
                <div className="mt-3">
                  <p className="text-xs text-gray-500 uppercase mb-1">Respuesta del alumno:</p>
                  <p className="text-sm text-gray-700 whitespace-pre-wrap">{s.response}</p>
                </div>
                {s.ai_feedback && (
                  <div className="mt-3 bg-blue-50 rounded-lg p-3">
                    <p className="text-xs text-blue-600 uppercase mb-1">Evaluacion IA:</p>
                    <p className="text-sm text-gray-700">{s.ai_feedback}</p>
                  </div>
                )}
              </div>
            ))}
          </div>
        ) : (
          <div className="bg-white rounded-xl border border-gray-100 p-8 text-center text-gray-400">
            <p className="text-3xl mb-2">📝</p>
            <p>Sin entregas de misiones todavia</p>
          </div>
        )}
      </section>

      {/* Tests (respuestas de opcion multiple) */}
      <section>
        <h2 className="text-lg font-semibold text-purple-500 mb-3">Tests respondidos</h2>
        {tests.length > 0 ? (
          <div className="space-y-2">
            {tests.map(s => (
              <div key={s.id} className="bg-white rounded-xl border border-purple-100 p-4 flex items-center justify-between">
                <div>
                  <h3 className="font-medium text-gray-800 text-sm">
                    {s.roster?.name || 'Alumno'} <span className="text-xs text-gray-400">- Grado {s.roster?.grade || '?'}</span>
                  </h3>
                  <p className="text-xs text-gray-400">
                    {s.chapter_activities?.title || 'Test'} - {new Date(s.submitted_at).toLocaleString('es-CO')}
                  </p>
                </div>
                <span className="text-sm font-bold text-purple-600 bg-purple-50 px-3 py-1 rounded-full">
                  Respuesta: {s.response}
                </span>
              </div>
            ))}
          </div>
        ) : (
          <div className="bg-white rounded-xl border border-gray-100 p-8 text-center text-gray-400">
            <p className="text-3xl mb-2">🎯</p>
            <p>Sin tests respondidos todavia</p>
          </div>
        )}
      </section>
    </div>
  )
}
