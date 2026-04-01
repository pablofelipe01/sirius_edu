'use client'
import { useState } from 'react'
import { supabase } from '@/lib/supabase'
import { useRouter } from 'next/navigation'

const subjects = [
  { code: 'ciencias_naturales', name: 'Ciencias Naturales' },
  { code: 'matematicas', name: 'Matematicas' },
  { code: 'lenguaje', name: 'Lenguaje' },
  { code: 'ciencias_sociales', name: 'Ciencias Sociales' },
]

export default function NuevaLeccionPage() {
  const router = useRouter()
  const [saving, setSaving] = useState(false)
  const [aiLoading, setAiLoading] = useState(false)
  const [form, setForm] = useState({
    subject_code: 'ciencias_naturales', grade: '2', week_number: 1,
    title: '', summary: '', content: '', objectives: '',
  })

  const update = (field: string, value: string | number) => setForm(f => ({ ...f, [field]: value }))

  const askAI = async () => {
    setAiLoading(true)
    try {
      const res = await fetch('/api/ai/suggest', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ subject: form.subject_code, grade: form.grade, topic: form.title || 'tema libre' }),
      })
      const data = await res.json()
      if (data.suggestion) {
        update('content', data.suggestion)
      }
    } catch (e) {
      console.error(e)
    }
    setAiLoading(false)
  }

  const save = async () => {
    if (!form.title || !form.content) return alert('Completa titulo y contenido')
    setSaving(true)
    const schoolId = process.env.NEXT_PUBLIC_SCHOOL_ID || 'a0000000-0000-0000-0000-000000000001'

    const { error } = await supabase.from('lessons').insert({
      school_id: schoolId,
      subject_code: form.subject_code,
      grade: form.grade,
      week_number: form.week_number,
      title: form.title,
      summary: form.summary || form.content.substring(0, 200),
      content: form.content,
      objectives: form.objectives.split('\n').filter(Boolean),
      is_active: true,
    })

    setSaving(false)
    if (error) {
      alert('Error al guardar: ' + error.message)
    } else {
      router.push('/lecciones')
    }
  }

  return (
    <div className="max-w-2xl">
      <h1 className="text-2xl font-bold text-gray-800 mb-6">Nueva Leccion</h1>

      <div className="space-y-4">
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Materia</label>
            <select value={form.subject_code} onChange={e => update('subject_code', e.target.value)}
              className="w-full border rounded-lg px-3 py-2 text-sm">
              {subjects.map(s => <option key={s.code} value={s.code}>{s.name}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Grado</label>
            <select value={form.grade} onChange={e => update('grade', e.target.value)}
              className="w-full border rounded-lg px-3 py-2 text-sm">
              {[1,2,3,4,5].map(g => <option key={g} value={String(g)}>{g} Grado</option>)}
            </select>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Semana</label>
            <input type="number" value={form.week_number} onChange={e => update('week_number', Number(e.target.value))}
              className="w-full border rounded-lg px-3 py-2 text-sm" min={1} max={52} />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Titulo</label>
            <input value={form.title} onChange={e => update('title', e.target.value)}
              className="w-full border rounded-lg px-3 py-2 text-sm" placeholder="Ej: Los Seres Vivos" />
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Resumen (corto, para la app)</label>
          <textarea value={form.summary} onChange={e => update('summary', e.target.value)}
            className="w-full border rounded-lg px-3 py-2 text-sm" rows={2} maxLength={200}
            placeholder="Resumen de 1-2 oraciones..." />
          <p className="text-xs text-gray-400 text-right">{form.summary.length}/200</p>
        </div>

        <div>
          <div className="flex items-center justify-between mb-1">
            <label className="block text-sm font-medium text-gray-700">Contenido de la leccion</label>
            <button onClick={askAI} disabled={aiLoading}
              className="text-xs bg-blue-50 text-blue-600 px-3 py-1 rounded-full hover:bg-blue-100 disabled:opacity-50">
              {aiLoading ? 'Generando...' : '🤖 Sugerencia IA'}
            </button>
          </div>
          <textarea value={form.content} onChange={e => update('content', e.target.value)}
            className="w-full border rounded-lg px-3 py-2 text-sm" rows={10}
            placeholder="Escribe el contenido completo de la leccion..." />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Objetivos (uno por linea)</label>
          <textarea value={form.objectives} onChange={e => update('objectives', e.target.value)}
            className="w-full border rounded-lg px-3 py-2 text-sm" rows={3}
            placeholder="Identificar seres vivos&#10;Describir caracteristicas&#10;Clasificar elementos" />
        </div>

        <button onClick={save} disabled={saving}
          className="w-full bg-green-600 text-white py-3 rounded-lg font-medium hover:bg-green-700 disabled:opacity-50 transition-colors">
          {saving ? 'Guardando...' : 'Guardar leccion'}
        </button>
      </div>
    </div>
  )
}
