'use client'
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import type { StudentQuestion } from '@/lib/types'

export default function PreguntasPage() {
  const [questions, setQuestions] = useState<StudentQuestion[]>([])
  const [response, setResponse] = useState<Record<string, string>>({})
  const [saving, setSaving] = useState<string | null>(null)

  useEffect(() => {
    loadQuestions()
  }, [])

  async function loadQuestions() {
    const { data } = await supabase
      .from('student_questions')
      .select('*, roster(name, grade)')
      .order('created_at', { ascending: false })
      .limit(50)
    setQuestions((data || []) as StudentQuestion[])
  }

  async function respond(questionId: string) {
    const text = response[questionId]
    if (!text) return
    setSaving(questionId)

    await supabase.from('student_questions').update({
      teacher_response: text,
      responded_at: new Date().toISOString(),
      is_read: true,
    }).eq('id', questionId)

    setSaving(null)
    setResponse(r => ({ ...r, [questionId]: '' }))
    loadQuestions()
  }

  const pending = questions.filter(q => !q.teacher_response)
  const answered = questions.filter(q => q.teacher_response)

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-800 mb-6">
        Preguntas de alumnos
        {pending.length > 0 && (
          <span className="ml-2 text-sm bg-orange-100 text-orange-700 px-2 py-1 rounded-full">
            {pending.length} sin responder
          </span>
        )}
      </h1>

      {pending.length > 0 && (
        <div className="mb-8">
          <h2 className="text-sm font-medium text-orange-600 mb-3">Pendientes</h2>
          <div className="space-y-3">
            {pending.map(q => (
              <div key={q.id} className="bg-white rounded-xl border-l-4 border-orange-400 p-4">
                <div className="flex items-center gap-2 mb-2">
                  <span className="font-medium text-gray-800">{(q.roster as Record<string, string>)?.name || 'Alumno'}</span>
                  <span className="text-xs text-gray-400">
                    Grado {(q.roster as Record<string, string>)?.grade} - {new Date(q.created_at).toLocaleDateString('es-CO')}
                  </span>
                </div>
                <p className="text-gray-700 mb-3">{q.question}</p>
                <div className="flex gap-2">
                  <input
                    value={response[q.id] || ''}
                    onChange={e => setResponse(r => ({ ...r, [q.id]: e.target.value }))}
                    placeholder="Escribe tu respuesta..."
                    className="flex-1 border rounded-lg px-3 py-2 text-sm"
                    onKeyDown={e => e.key === 'Enter' && respond(q.id)}
                  />
                  <button onClick={() => respond(q.id)} disabled={saving === q.id}
                    className="bg-green-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-green-700 disabled:opacity-50">
                    {saving === q.id ? '...' : 'Responder'}
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {answered.length > 0 && (
        <div>
          <h2 className="text-sm font-medium text-gray-400 mb-3">Respondidas</h2>
          <div className="space-y-2">
            {answered.map(q => (
              <div key={q.id} className="bg-white rounded-xl border border-gray-100 p-4 opacity-80">
                <div className="flex items-center gap-2 mb-1">
                  <span className="font-medium text-gray-700">{(q.roster as Record<string, string>)?.name}</span>
                  <span className="text-xs text-gray-400">{new Date(q.created_at).toLocaleDateString('es-CO')}</span>
                </div>
                <p className="text-gray-600 text-sm">{q.question}</p>
                <p className="text-green-700 text-sm mt-1 bg-green-50 rounded px-2 py-1">
                  {q.teacher_response}
                </p>
              </div>
            ))}
          </div>
        </div>
      )}

      {questions.length === 0 && (
        <div className="text-center py-12 text-gray-400">
          <p className="text-4xl mb-3">❓</p>
          <p>No hay preguntas de alumnos</p>
        </div>
      )}
    </div>
  )
}
