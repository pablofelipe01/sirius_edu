import type { Lesson } from '@/lib/types'

const subjectColors: Record<string, string> = {
  ciencias_naturales: 'bg-green-100 text-green-700',
  matematicas: 'bg-blue-100 text-blue-700',
  lenguaje: 'bg-orange-100 text-orange-700',
  ciencias_sociales: 'bg-purple-100 text-purple-700',
}

const subjectNames: Record<string, string> = {
  ciencias_naturales: 'Ciencias Naturales',
  matematicas: 'Matematicas',
  lenguaje: 'Lenguaje',
  ciencias_sociales: 'Ciencias Sociales',
}

export default function LessonCard({ lesson }: { lesson: Lesson }) {
  const badgeClass = subjectColors[lesson.subject_code] || 'bg-gray-100 text-green-400'
  const subjectName = subjectNames[lesson.subject_code] || lesson.subject_code

  return (
    <div className="bg-white rounded-xl border border-gray-100 p-5 hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between mb-3">
        <div>
          <span className={`text-xs font-medium px-2 py-1 rounded-full ${badgeClass}`}>
            {subjectName}
          </span>
          <span className="text-xs text-gray-400 ml-2">Grado {lesson.grade} - Semana {lesson.week_number}</span>
        </div>
        {lesson.is_active && (
          <span className="text-xs bg-green-100 text-green-700 px-2 py-1 rounded-full">Activa</span>
        )}
      </div>
      <h3 className="font-semibold text-gray-800 mb-1">{lesson.title}</h3>
      <p className="text-sm text-gray-500 line-clamp-2">{lesson.summary}</p>
    </div>
  )
}
