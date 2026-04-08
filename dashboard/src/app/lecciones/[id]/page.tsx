import { supabase } from '@/lib/supabase'
import { getSession } from '@/lib/session'
import { redirect } from 'next/navigation'
import Link from 'next/link'

export const dynamic = 'force-dynamic'

interface Chapter {
  id: string
  chapter_number: number
  title: string
  content: string
}

interface Activity {
  id: string
  chapter_id: string
  activity_number: number
  activity_type: 'mission' | 'test'
  title: string
  data: Record<string, unknown>
}

export default async function LessonDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const session = await getSession()
  const schoolId = session!.school_id

  const { data: lesson } = await supabase
    .from('lessons')
    .select('*')
    .eq('id', id)
    .single()

  if (!lesson) return <p className="text-gray-400">Leccion no encontrada</p>
  if (lesson.school_id !== schoolId) redirect('/lecciones')

  const { data: chapters } = await supabase
    .from('lesson_chapters')
    .select('*')
    .eq('lesson_id', id)
    .order('chapter_number')

  const { data: activities } = await supabase
    .from('chapter_activities')
    .select('*')
    .eq('lesson_id', id)
    .order('activity_number')

  const chs = (chapters as Chapter[] | null) || []
  const acts = (activities as Activity[] | null) || []

  return (
    <div className="max-w-3xl">
      <Link href="/lecciones" className="text-sm text-gray-400 hover:text-gray-600 mb-4 inline-block">&larr; Volver</Link>

      <div className="bg-white rounded-xl border border-green-200 p-5 mb-6">
        <div className="flex items-start justify-between mb-2">
          <div>
            <h1 className="text-2xl font-bold text-green-600">{lesson.title}</h1>
            <p className="text-sm text-gray-500 mt-1">
              {lesson.subject_code} - Grado {lesson.grade} - Semana {lesson.week_number}
            </p>
          </div>
          <span className={`text-xs px-2 py-1 rounded-full ${lesson.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
            {lesson.is_active ? 'Activa' : 'Inactiva'}
          </span>
        </div>
        {lesson.summary && <p className="text-gray-600 mt-2">{lesson.summary}</p>}
        {lesson.objectives?.length > 0 && (
          <div className="mt-4">
            <p className="text-xs font-semibold text-gray-500 uppercase">Objetivos</p>
            <ul className="text-sm text-gray-600 mt-1 list-disc list-inside">
              {lesson.objectives.map((o: string, i: number) => <li key={i}>{o}</li>)}
            </ul>
          </div>
        )}
      </div>

      <h2 className="text-lg font-semibold text-gray-700 mb-3">Capitulos ({chs.length})</h2>
      {chs.map(ch => {
        const chapterActs = acts.filter(a => a.chapter_id === ch.id)
        return (
          <div key={ch.id} className="bg-white rounded-xl border border-blue-100 p-5 mb-4">
            <h3 className="font-semibold text-blue-600 mb-2">
              Capitulo {ch.chapter_number}: {ch.title}
            </h3>
            <p className="text-sm text-gray-600 whitespace-pre-wrap mb-3">{ch.content}</p>

            {chapterActs.length > 0 && (
              <div className="mt-3 space-y-2">
                <p className="text-xs font-semibold text-gray-500 uppercase">Actividades</p>
                {chapterActs.map(a => (
                  <div key={a.id} className={`rounded-lg p-3 ${a.activity_type === 'test' ? 'bg-purple-50' : 'bg-orange-50'}`}>
                    <div className="flex items-center gap-2 mb-1">
                      <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${a.activity_type === 'test' ? 'bg-purple-100 text-purple-700' : 'bg-orange-100 text-orange-700'}`}>
                        {a.activity_type === 'test' ? 'Test' : 'Mision'}
                      </span>
                      <span className="text-sm font-medium text-gray-700">{a.title}</span>
                    </div>
                    {a.activity_type === 'test' && (
                      <div className="text-xs text-gray-600 mt-1">
                        <p className="font-medium">{(a.data.question || a.data.q) as string}</p>
                        <p className="text-gray-400 mt-1">Respuesta correcta: {(a.data.correct_answer || a.data.r) as string}</p>
                      </div>
                    )}
                    {a.activity_type === 'mission' && (
                      <p className="text-xs text-gray-600 mt-1">{(a.data.description || a.data.d) as string}</p>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>
        )
      })}

      {chs.length === 0 && (
        <p className="text-sm text-gray-400">Esta leccion no tiene capitulos estructurados.</p>
      )}
    </div>
  )
}
