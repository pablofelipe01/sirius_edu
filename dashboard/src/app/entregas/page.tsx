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
  chapter_activities: {
    title: string
    activity_number: number
    data: Record<string, unknown>
    lessons: { id: string; title: string } | null
    lesson_chapters: { chapter_number: number } | null
  } | null
}

interface LessonGroup {
  lessonId: string
  lessonTitle: string
  submissions: SubmissionRow[]
}

export default async function EntregasPage() {
  const { data: submissions } = await supabase
    .from('submissions')
    .select('*, roster!submissions_student_id_fkey(name, grade), chapter_activities(title, activity_number, data, lessons(id, title), lesson_chapters(chapter_number))')
    .order('submitted_at', { ascending: false })
    .limit(200)

  const items = (submissions as SubmissionRow[] | null) || []

  // Group by lesson
  const groups = new Map<string, LessonGroup>()
  for (const s of items) {
    const lessonId = s.chapter_activities?.lessons?.id || 'unknown'
    const lessonTitle = s.chapter_activities?.lessons?.title || 'Sin lección'
    if (!groups.has(lessonId)) {
      groups.set(lessonId, { lessonId, lessonTitle, submissions: [] })
    }
    groups.get(lessonId)!.submissions.push(s)
  }

  // Sort submissions within each group: by chapter, then activity number
  for (const group of groups.values()) {
    group.submissions.sort((a, b) => {
      const chA = a.chapter_activities?.lesson_chapters?.chapter_number ?? 99
      const chB = b.chapter_activities?.lesson_chapters?.chapter_number ?? 99
      if (chA !== chB) return chA - chB
      const actA = a.chapter_activities?.activity_number ?? 99
      const actB = b.chapter_activities?.activity_number ?? 99
      return actA - actB
    })
  }

  const lessonGroups = Array.from(groups.values())

  return (
    <div>
      <h1 className="text-2xl font-bold text-green-500 mb-2">Entregas de Alumnos</h1>
      <p className="text-sm text-gray-400 mb-6">{items.length} entregas en {lessonGroups.length} lecciones</p>

      {lessonGroups.length === 0 ? (
        <div className="bg-white rounded-xl border border-gray-100 p-12 text-center text-gray-400">
          <p className="text-4xl mb-3">📥</p>
          <p>Aun no hay entregas</p>
        </div>
      ) : (
        <div className="space-y-6">
          {lessonGroups.map(group => (
            <section key={group.lessonId} className="bg-white rounded-xl border border-green-200 overflow-hidden">
              <div className="bg-green-50 px-5 py-3 border-b border-green-100">
                <h2 className="font-semibold text-green-700">📖 {group.lessonTitle}</h2>
                <p className="text-xs text-green-600">{group.submissions.length} entregas</p>
              </div>
              <div className="divide-y divide-gray-100">
                {group.submissions.map(s => (
                  <SubmissionItem key={s.id} submission={s} />
                ))}
              </div>
            </section>
          ))}
        </div>
      )}
    </div>
  )
}

function SubmissionItem({ submission: s }: { submission: SubmissionRow }) {
  const isMission = s.activity_type === 'mission'
  const isTest = s.activity_type === 'test'
  const chapterNum = s.chapter_activities?.lesson_chapters?.chapter_number
  const studentName = s.roster?.name || 'Alumno'

  if (isMission) {
    return (
      <div className="px-5 py-4">
        <div className="flex items-start justify-between mb-2">
          <div className="flex-1">
            <div className="flex items-center gap-2">
              <span className="text-xs bg-orange-100 text-orange-700 px-2 py-0.5 rounded-full font-medium">
                Misión
              </span>
              {chapterNum && <span className="text-xs text-gray-400">Cap. {chapterNum}</span>}
              <span className="text-sm font-medium text-gray-700">{s.chapter_activities?.title}</span>
            </div>
            <p className="text-xs text-gray-400 mt-1">
              {studentName} • {new Date(s.submitted_at).toLocaleString('es-CO')}
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
        <div className="ml-2 mt-2 pl-3 border-l-2 border-orange-200">
          <p className="text-sm text-gray-700 whitespace-pre-wrap italic">&ldquo;{s.response}&rdquo;</p>
        </div>
        {s.ai_feedback && (
          <div className="ml-2 mt-2 bg-blue-50 rounded-lg p-2">
            <p className="text-xs text-blue-600 font-medium mb-0.5">Evaluación IA:</p>
            <p className="text-sm text-gray-700">{s.ai_feedback}</p>
          </div>
        )}
      </div>
    )
  }

  if (isTest) {
    const data = s.chapter_activities?.data || {}
    const question = (data.question || data.q || s.chapter_activities?.title || '') as string
    const correctAnswer = (data.correct_answer || data.r || '') as string
    const isCorrect = correctAnswer && s.response.toUpperCase() === correctAnswer.toUpperCase()

    return (
      <div className="px-5 py-4">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <div className="flex items-center gap-2 mb-1">
              <span className="text-xs bg-purple-100 text-purple-700 px-2 py-0.5 rounded-full font-medium">
                Test
              </span>
              {chapterNum && <span className="text-xs text-gray-400">Cap. {chapterNum}</span>}
              <span className="text-xs text-gray-400">
                {studentName} • {new Date(s.submitted_at).toLocaleString('es-CO')}
              </span>
            </div>
            <p className="text-sm text-gray-700">{question}</p>
          </div>
          <div className="flex items-center gap-2 ml-3">
            <span className="text-sm font-bold text-purple-700 bg-purple-50 px-3 py-1 rounded-full">
              {s.response}
            </span>
            {correctAnswer && (
              <span className={`text-xs px-2 py-1 rounded-full font-medium ${
                isCorrect ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
              }`}>
                {isCorrect ? '✓' : `✗ (${correctAnswer})`}
              </span>
            )}
          </div>
        </div>
      </div>
    )
  }

  return null
}
