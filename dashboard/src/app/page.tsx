import { supabase } from '@/lib/supabase'
import StatCard from '@/components/StatCard'

export const dynamic = 'force-dynamic'

export default async function DashboardPage() {
  const schoolId = process.env.SCHOOL_ID || 'a0000000-0000-0000-0000-000000000001'

  const [studentsRes, lessonsRes, questionsRes] = await Promise.all([
    supabase.from('roster').select('id').eq('school_id', schoolId).eq('role', 'student').eq('is_active', true),
    supabase.from('lessons').select('id').eq('school_id', schoolId).eq('is_active', true),
    supabase.from('student_questions').select('id').eq('school_id', schoolId).is('teacher_response', null),
  ])

  return (
    <div>
      <h1 className="text-2xl font-bold text-green-500 mb-6">Dashboard</h1>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <StatCard icon="👩‍🎓" value={studentsRes.data?.length || 0} label="Alumnos registrados" color="green" />
        <StatCard icon="📖" value={lessonsRes.data?.length || 0} label="Lecciones activas" color="blue" />
        <StatCard icon="❓" value={questionsRes.data?.length || 0} label="Preguntas sin responder" color="orange" />
        <StatCard icon="📝" value="--" label="Entregas recientes" color="purple" />
      </div>

      <div className="bg-white rounded-xl border border-gray-100 p-5">
        <h2 className="font-semibold text-gray-800 mb-4">Bienvenido al Panel del Profesor</h2>
        <p className="text-gray-500 text-sm">
          Desde aqui puedes crear lecciones semanales, revisar tareas, ver el progreso de tus alumnos
          y responder sus preguntas. Todo lo que crees aqui estara disponible para tus alumnos
          a traves de la red mesh LoRa.
        </p>
      </div>
    </div>
  )
}
