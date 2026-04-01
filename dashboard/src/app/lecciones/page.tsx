import { supabase } from '@/lib/supabase'
import LessonCard from '@/components/LessonCard'
import Link from 'next/link'
import type { Lesson } from '@/lib/types'

export const dynamic = 'force-dynamic'

export default async function LeccionesPage() {
  const schoolId = process.env.SCHOOL_ID || 'a0000000-0000-0000-0000-000000000001'

  const { data: lessons } = await supabase
    .from('lessons')
    .select('*')
    .eq('school_id', schoolId)
    .order('week_number', { ascending: false })
    .order('created_at', { ascending: false })

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-800">Lecciones</h1>
        <Link href="/lecciones/nueva"
          className="bg-green-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-green-700 transition-colors">
          + Nueva Leccion
        </Link>
      </div>

      {lessons && lessons.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {lessons.map((lesson: Lesson) => (
            <LessonCard key={lesson.id} lesson={lesson} />
          ))}
        </div>
      ) : (
        <div className="text-center py-12 text-gray-400">
          <p className="text-4xl mb-3">📖</p>
          <p>No hay lecciones creadas</p>
          <Link href="/lecciones/nueva" className="text-green-600 underline text-sm mt-2 inline-block">
            Crear la primera leccion
          </Link>
        </div>
      )}
    </div>
  )
}
