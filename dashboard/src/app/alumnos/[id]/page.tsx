import { supabase } from '@/lib/supabase'
import Link from 'next/link'

export const dynamic = 'force-dynamic'

interface SubmissionRow {
  id: string
  activity_id: string | null
  activity_type: string | null
  response: string
  ai_score: number | null
  ai_feedback: string | null
  submitted_at: string
  chapter_activities: {
    title: string
    activity_type: string
    lessons: { title: string } | null
  } | null
}

interface QuestionRow {
  id: string
  question: string
  teacher_response: string | null
}

interface ConversationRow {
  id: string
  question: string
  ai_response: string
  ai_model: string
  created_at: string
}

export default async function AlumnoPerfilPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params

  const [studentRes, conversationsRes, questionsRes, submissionsRes] = await Promise.all([
    supabase.from('roster').select('*').eq('id', id).single(),
    supabase.from('ai_conversations').select('*').eq('student_id', id).order('created_at', { ascending: false }).limit(20),
    supabase.from('student_questions').select('*').eq('student_id', id).order('created_at', { ascending: false }).limit(10),
    supabase
      .from('submissions')
      .select('*, chapter_activities(title, activity_type, lessons(title))')
      .eq('student_id', id)
      .order('submitted_at', { ascending: false })
      .limit(20),
  ])

  const student = studentRes.data
  if (!student) return <p className="text-gray-400">Alumno no encontrado</p>

  const submissions = (submissionsRes.data as SubmissionRow[] | null) || []
  const missions = submissions.filter(s => s.activity_type === 'mission')
  const tests = submissions.filter(s => s.activity_type === 'test')
  const questions = (questionsRes.data as QuestionRow[] | null) || []
  const conversations = (conversationsRes.data as ConversationRow[] | null) || []

  return (
    <div>
      <Link href="/alumnos" className="text-sm text-gray-400 hover:text-gray-600 mb-4 inline-block">&larr; Volver</Link>

      <div className="flex items-center gap-4 mb-6">
        <div className="w-14 h-14 rounded-full bg-green-100 flex items-center justify-center text-2xl">👩‍🎓</div>
        <div>
          <h1 className="text-2xl font-bold text-green-500">{student.name}</h1>
          <p className="text-gray-500">Grado {student.grade} - Nodo {student.node_hex || '-'}</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Misiones */}
        <div className="bg-white rounded-xl border border-orange-100 p-5">
          <h2 className="font-semibold text-orange-600 mb-3">Misiones ({missions.length})</h2>
          {missions.length > 0 ? missions.map(s => (
            <div key={s.id} className="border-b border-gray-50 py-3 last:border-0">
              <div className="flex items-center justify-between mb-1">
                <span className="text-sm font-medium text-gray-800">
                  {s.chapter_activities?.title || 'Mision'}
                </span>
                {s.ai_score != null && (
                  <span className={`text-xs px-2 py-0.5 rounded-full font-bold ${
                    s.ai_score >= 7 ? 'bg-green-100 text-green-700' :
                    s.ai_score >= 5 ? 'bg-yellow-100 text-yellow-700' : 'bg-red-100 text-red-700'
                  }`}>
                    {Number(s.ai_score).toFixed(1)}/10
                  </span>
                )}
              </div>
              {s.chapter_activities?.lessons?.title && (
                <p className="text-xs text-gray-400 mb-1">Leccion: {s.chapter_activities.lessons.title}</p>
              )}
              <p className="text-sm text-gray-600 mt-1 italic">&ldquo;{s.response}&rdquo;</p>
              {s.ai_feedback && (
                <p className="text-xs text-blue-500 mt-1">{s.ai_feedback}</p>
              )}
              <p className="text-xs text-gray-300 mt-1">{new Date(s.submitted_at).toLocaleString('es-CO')}</p>
            </div>
          )) : <p className="text-sm text-gray-400">Sin misiones entregadas</p>}
        </div>

        {/* Tests */}
        <div className="bg-white rounded-xl border border-purple-100 p-5">
          <h2 className="font-semibold text-purple-600 mb-3">Tests ({tests.length})</h2>
          {tests.length > 0 ? tests.map(s => (
            <div key={s.id} className="border-b border-gray-50 py-2 last:border-0">
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium text-gray-800">
                  {s.chapter_activities?.title || 'Test'}
                </span>
                <span className="text-xs bg-purple-50 text-purple-700 px-2 py-0.5 rounded-full font-bold">
                  {s.response}
                </span>
              </div>
              {s.chapter_activities?.lessons?.title && (
                <p className="text-xs text-gray-400">Leccion: {s.chapter_activities.lessons.title}</p>
              )}
              <p className="text-xs text-gray-300">{new Date(s.submitted_at).toLocaleString('es-CO')}</p>
            </div>
          )) : <p className="text-sm text-gray-400">Sin tests respondidos</p>}
        </div>

        {/* Preguntas al profesor */}
        <div className="bg-white rounded-xl border border-gray-100 p-5">
          <h2 className="font-semibold text-gray-800 mb-3">Preguntas al profesor ({questions.length})</h2>
          {questions.map(q => (
            <div key={q.id} className="border-b border-gray-50 py-2 last:border-0">
              <p className="text-sm text-gray-700">{q.question}</p>
              {q.teacher_response ? (
                <p className="text-xs text-green-600 mt-1">{q.teacher_response}</p>
              ) : (
                <p className="text-xs text-orange-500 mt-1">Sin respuesta</p>
              )}
            </div>
          ))}
          {!questions.length && <p className="text-sm text-gray-400">Sin preguntas</p>}
        </div>

        {/* Conversaciones IA */}
        <div className="bg-white rounded-xl border border-gray-100 p-5">
          <h2 className="font-semibold text-gray-800 mb-3">Tutor IA ({conversations.length})</h2>
          {conversations.map(c => (
            <div key={c.id} className="border-b border-gray-50 py-3 last:border-0">
              <p className="text-sm font-medium text-gray-700">{c.question}</p>
              <p className="text-sm text-gray-500 mt-1">{c.ai_response?.substring(0, 200)}...</p>
              <p className="text-xs text-gray-300 mt-1">{new Date(c.created_at).toLocaleDateString('es-CO')}</p>
            </div>
          ))}
          {!conversations.length && <p className="text-sm text-gray-400">Sin conversaciones</p>}
        </div>
      </div>
    </div>
  )
}
