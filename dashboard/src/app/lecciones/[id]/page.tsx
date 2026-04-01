'use client'
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { useRouter, useParams } from 'next/navigation'
import type { Lesson, Assignment } from '@/lib/types'

const subjects = [
  { code: 'ciencias_naturales', name: 'Ciencias Naturales' },
  { code: 'matematicas', name: 'Matematicas' },
  { code: 'lenguaje', name: 'Lenguaje' },
  { code: 'ciencias_sociales', name: 'Ciencias Sociales' },
]

export default function EditLessonPage() {
  const router = useRouter()
  const params = useParams()
  const id = params.id as string

  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [lesson, setLesson] = useState<Lesson | null>(null)
  const [assignments, setAssignments] = useState<Assignment[]>([])

  const [form, setForm] = useState({
    subject_code: '', grade: '', week_number: 0,
    title: '', summary: '', content: '', objectives: '',
    is_active: true,
  })

  useEffect(() => {
    loadLesson()
  }, [id])

  async function loadLesson() {
    const { data: lessonData } = await supabase.from('lessons').select('*').eq('id', id).single()
    const { data: assignmentData } = await supabase.from('assignments').select('*').eq('lesson_id', id)

    if (lessonData) {
      setLesson(lessonData as Lesson)
      setForm({
        subject_code: lessonData.subject_code || '',
        grade: lessonData.grade || '',
        week_number: lessonData.week_number || 0,
        title: lessonData.title || '',
        summary: lessonData.summary || '',
        content: lessonData.content || '',
        objectives: (lessonData.objectives || []).join('\n'),
        is_active: lessonData.is_active ?? true,
      })
    }
    if (assignmentData) setAssignments(assignmentData as Assignment[])
    setLoading(false)
  }

  const update = (field: string, value: string | number | boolean) => setForm(f => ({ ...f, [field]: value }))

  async function save() {
    if (!form.title || !form.content) return alert('Completa titulo y contenido')
    setSaving(true)

    const { error } = await supabase.from('lessons').update({
      subject_code: form.subject_code,
      grade: form.grade,
      week_number: form.week_number,
      title: form.title,
      summary: form.summary || form.content.substring(0, 200),
      content: form.content,
      objectives: form.objectives.split('\n').filter(Boolean),
      is_active: form.is_active,
      updated_at: new Date().toISOString(),
    }).eq('id', id)

    setSaving(false)
    if (error) {
      alert('Error: ' + error.message)
    } else {
      router.push('/lecciones')
    }
  }

  async function deleteLesson() {
    const confirm = window.confirm('Eliminar esta leccion y sus tareas?')
    if (!confirm) return

    await supabase.from('assignments').delete().eq('lesson_id', id)
    await supabase.from('lessons').delete().eq('id', id)
    router.push('/lecciones')
  }

  if (loading) return <p className="text-gray-400">Cargando...</p>
  if (!lesson) return <p className="text-gray-400">Leccion no encontrada</p>

  return (
    <div className="max-w-2xl">
      <button onClick={() => router.push('/lecciones')} className="text-sm text-gray-400 hover:text-gray-600 mb-4">
        &larr; Volver a lecciones
      </button>

      <h1 className="text-2xl font-bold text-green-500 mb-6">Editar Leccion</h1>

      <div className="space-y-4">
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-green-400 mb-1">Materia</label>
            <select value={form.subject_code} onChange={e => update('subject_code', e.target.value)}
              className="w-full border rounded-lg px-3 py-2 text-sm">
              {subjects.map(s => <option key={s.code} value={s.code}>{s.name}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-green-400 mb-1">Grado</label>
            <select value={form.grade} onChange={e => update('grade', e.target.value)}
              className="w-full border rounded-lg px-3 py-2 text-sm">
              {[1,2,3,4,5].map(g => <option key={g} value={String(g)}>{g} Grado</option>)}
            </select>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-green-400 mb-1">Semana</label>
            <input type="number" value={form.week_number} onChange={e => update('week_number', Number(e.target.value))}
              className="w-full border rounded-lg px-3 py-2 text-sm" min={1} max={52} />
          </div>
          <div>
            <label className="block text-sm font-medium text-green-400 mb-1">Estado</label>
            <select value={form.is_active ? 'true' : 'false'}
              onChange={e => update('is_active', e.target.value === 'true')}
              className="w-full border rounded-lg px-3 py-2 text-sm">
              <option value="true">Activa</option>
              <option value="false">Inactiva</option>
            </select>
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-green-400 mb-1">Titulo</label>
          <input value={form.title} onChange={e => update('title', e.target.value)}
            className="w-full border rounded-lg px-3 py-2 text-sm" />
        </div>

        <div>
          <label className="block text-sm font-medium text-green-400 mb-1">Resumen</label>
          <textarea value={form.summary} onChange={e => update('summary', e.target.value)}
            className="w-full border rounded-lg px-3 py-2 text-sm" rows={2} maxLength={200} />
          <p className="text-xs text-gray-400 text-right">{form.summary.length}/200</p>
        </div>

        <div>
          <label className="block text-sm font-medium text-green-400 mb-1">Contenido</label>
          <textarea value={form.content} onChange={e => update('content', e.target.value)}
            className="w-full border rounded-lg px-3 py-2 text-sm" rows={12} />
        </div>

        <div>
          <label className="block text-sm font-medium text-green-400 mb-1">Objetivos (uno por linea)</label>
          <textarea value={form.objectives} onChange={e => update('objectives', e.target.value)}
            className="w-full border rounded-lg px-3 py-2 text-sm" rows={3} />
        </div>

        {/* Tareas vinculadas */}
        {assignments.length > 0 && (
          <div className="border-t border-gray-200 pt-4">
            <h2 className="text-lg font-semibold text-green-500 mb-3">Tareas vinculadas</h2>
            {assignments.map(a => (
              <div key={a.id} className="bg-gray-50 rounded-lg p-3 mb-2">
                <p className="font-medium text-sm text-gray-800">{a.title}</p>
                <p className="text-xs text-gray-500">{a.description}</p>
              </div>
            ))}
          </div>
        )}

        <div className="flex gap-3">
          <button type="button" onClick={save} disabled={saving}
            className="flex-1 bg-green-600 text-white py-3 rounded-lg font-medium hover:bg-green-700 disabled:opacity-50 transition-colors">
            {saving ? 'Guardando...' : 'Guardar cambios'}
          </button>
          <button type="button" onClick={deleteLesson}
            className="px-6 py-3 rounded-lg font-medium text-red-600 border border-red-200 hover:bg-red-50 transition-colors">
            Eliminar
          </button>
        </div>
      </div>
    </div>
  )
}
