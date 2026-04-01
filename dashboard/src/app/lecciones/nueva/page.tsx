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

interface LessonData {
  title: string; summary: string; content: string; objectives: string[];
  task_title: string; task_description: string; task_instructions: string;
}

export default function NuevaLeccionPage() {
  const [mode, setMode] = useState<'choose' | 'wizard' | 'manual'>('choose')

  return (
    <div>
      <h1 className="text-2xl font-bold text-green-500 mb-6">Nueva Leccion</h1>

      {mode === 'choose' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 max-w-xl">
          <button onClick={() => setMode('wizard')}
            className="bg-white rounded-xl border-2 border-green-200 p-6 text-left hover:border-green-400 hover:shadow-md transition-all">
            <span className="text-3xl block mb-3">🤖</span>
            <span className="font-semibold text-green-600 block mb-1">Con ayuda del asistente</span>
            <span className="text-sm text-gray-500">Te guio paso a paso para crear la mejor leccion</span>
          </button>
          <button onClick={() => setMode('manual')}
            className="bg-white rounded-xl border-2 border-gray-200 p-6 text-left hover:border-gray-400 hover:shadow-md transition-all">
            <span className="text-3xl block mb-3">✏️</span>
            <span className="font-semibold text-gray-700 block mb-1">Manual</span>
            <span className="text-sm text-gray-500">Ya se que quiero poner</span>
          </button>
        </div>
      )}

      {mode === 'wizard' && <WizardMode onBack={() => setMode('choose')} />}
      {mode === 'manual' && <ManualMode onBack={() => setMode('choose')} />}
    </div>
  )
}

// ============================================================
// MODO WIZARD — Asistente IA paso a paso
// ============================================================

function WizardMode({ onBack }: { onBack: () => void }) {
  const router = useRouter()
  const [step, setStep] = useState<'select' | 'chat' | 'review'>('select')
  const [subject, setSubject] = useState('ciencias_naturales')
  const [grade, setGrade] = useState('2')
  const [weekNumber, setWeekNumber] = useState(1)
  const [messages, setMessages] = useState<{ role: 'user' | 'assistant'; content: string }[]>([])
  const [input, setInput] = useState('')
  const [loading, setLoading] = useState(false)
  const [lessonData, setLessonData] = useState<LessonData | null>(null)
  const [saving, setSaving] = useState(false)

  const subjectName = subjects.find(s => s.code === subject)?.name || subject

  async function startWizard() {
    const firstMessage = `Quiero crear una leccion de ${subjectName} para grado ${grade} (ninos de ${
      grade === '1' ? '6-7' : grade === '2' ? '7-8' : grade === '3' ? '8-9' : grade === '4' ? '9-10' : '10-11'
    } anos). Sugiereme 5 temas apropiados.`

    setMessages([{ role: 'user', content: firstMessage }])
    setStep('chat')
    setLoading(true)

    const res = await fetch('/api/ai/lesson-wizard', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ messages: [{ role: 'user', content: firstMessage }] }),
    })
    const data = await res.json()

    setMessages(prev => [...prev, { role: 'assistant', content: data.response }])
    if (data.lessonData) setLessonData(data.lessonData)
    setLoading(false)
  }

  async function sendMessage(text?: string) {
    const msg = text || input.trim()
    if (!msg) return

    const newMessages = [...messages, { role: 'user' as const, content: msg }]
    setMessages(newMessages)
    setInput('')
    setLoading(true)

    const res = await fetch('/api/ai/lesson-wizard', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ messages: newMessages }),
    })
    const data = await res.json()

    setMessages(prev => [...prev, { role: 'assistant' as const, content: data.response }])
    if (data.lessonData) {
      setLessonData(data.lessonData)
      setStep('review')
    }
    setLoading(false)
  }

  async function saveLesson() {
    if (!lessonData) return
    setSaving(true)
    const schoolId = process.env.NEXT_PUBLIC_SCHOOL_ID || 'a0000000-0000-0000-0000-000000000001'

    const { data: lesson, error } = await supabase.from('lessons').insert({
      school_id: schoolId, subject_code: subject, grade, week_number: weekNumber,
      title: lessonData.title,
      summary: lessonData.summary || lessonData.content.substring(0, 200),
      content: lessonData.content,
      objectives: lessonData.objectives,
      is_active: true,
    }).select().single()

    if (error) { setSaving(false); alert('Error: ' + error.message); return }

    if (lessonData.task_title && lessonData.task_description && lesson) {
      await supabase.from('assignments').insert({
        lesson_id: lesson.id, school_id: schoolId, grade,
        title: lessonData.task_title,
        description: lessonData.task_description,
        instructions: lessonData.task_instructions || null,
        is_active: true,
      })
    }

    setSaving(false)
    router.push('/lecciones')
  }

  // --- Step: Seleccionar materia y grado ---
  if (step === 'select') {
    return (
      <div className="max-w-md">
        <button onClick={onBack} className="text-sm text-gray-400 hover:text-gray-600 mb-4">&larr; Volver</button>

        <div className="bg-white rounded-xl border border-gray-100 p-5 space-y-4">
          <p className="text-green-600 font-medium">Primero, selecciona la materia y el grado:</p>

          <div>
            <label className="block text-sm font-medium text-green-400 mb-1">Materia</label>
            <select value={subject} onChange={e => setSubject(e.target.value)}
              className="w-full border rounded-lg px-3 py-2 text-sm">
              {subjects.map(s => <option key={s.code} value={s.code}>{s.name}</option>)}
            </select>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-green-400 mb-1">Grado</label>
              <select value={grade} onChange={e => setGrade(e.target.value)}
                className="w-full border rounded-lg px-3 py-2 text-sm">
                {[1,2,3,4,5].map(g => <option key={g} value={String(g)}>{g} Grado</option>)}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-green-400 mb-1">Semana</label>
              <input type="number" value={weekNumber} onChange={e => setWeekNumber(Number(e.target.value))}
                className="w-full border rounded-lg px-3 py-2 text-sm" min={1} max={52} />
            </div>
          </div>

          <button onClick={startWizard}
            className="w-full bg-green-600 text-white py-3 rounded-lg font-medium hover:bg-green-700 transition-colors">
            🤖 Iniciar asistente
          </button>
        </div>
      </div>
    )
  }

  // --- Step: Chat con IA ---
  if (step === 'chat') {
    return (
      <div className="max-w-2xl flex flex-col h-[calc(100vh-8rem)]">
        <div className="flex items-center gap-3 mb-4">
          <button onClick={onBack} className="text-sm text-gray-400 hover:text-gray-600">&larr;</button>
          <span className="text-sm bg-green-100 text-green-700 px-2 py-1 rounded-full">{subjectName}</span>
          <span className="text-sm bg-blue-100 text-blue-700 px-2 py-1 rounded-full">Grado {grade}</span>
        </div>

        <div className="flex-1 overflow-y-auto space-y-3 mb-4">
          {messages.map((m, i) => (
            <div key={i} className={`flex ${m.role === 'user' ? 'justify-end' : 'justify-start'}`}>
              <div className={`max-w-[80%] px-4 py-3 rounded-2xl text-sm whitespace-pre-wrap
                ${m.role === 'user'
                  ? 'bg-green-100 text-green-900 rounded-br-md'
                  : 'bg-blue-50 text-gray-800 rounded-bl-md'}`}>
                {m.content}
              </div>
            </div>
          ))}
          {loading && (
            <div className="flex justify-start">
              <div className="bg-blue-50 text-gray-400 px-4 py-3 rounded-2xl rounded-bl-md text-sm italic">
                Pensando...
              </div>
            </div>
          )}
        </div>

        <div className="flex gap-2">
          <input value={input} onChange={e => setInput(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && sendMessage()}
            placeholder="Escribe tu respuesta..."
            className="flex-1 border rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-green-500"
            disabled={loading} />
          <button onClick={() => sendMessage()} disabled={loading || !input.trim()}
            className="bg-green-600 text-white px-6 py-3 rounded-xl hover:bg-green-700 disabled:opacity-50">
            Enviar
          </button>
        </div>
      </div>
    )
  }

  // --- Step: Revisar y guardar ---
  if (step === 'review' && lessonData) {
    return (
      <div className="max-w-2xl">
        <button onClick={() => setStep('chat')} className="text-sm text-gray-400 hover:text-gray-600 mb-4">
          &larr; Volver al chat
        </button>

        <div className="bg-white rounded-xl border border-green-200 p-5 mb-4">
          <h2 className="text-lg font-semibold text-green-600 mb-1">Leccion generada</h2>
          <p className="text-xs text-gray-400 mb-4">{subjectName} - Grado {grade} - Semana {weekNumber}</p>

          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-green-400 mb-1">Titulo</label>
              <input value={lessonData.title}
                onChange={e => setLessonData({ ...lessonData, title: e.target.value })}
                className="w-full border rounded-lg px-3 py-2 text-sm" />
            </div>

            <div>
              <label className="block text-sm font-medium text-green-400 mb-1">Resumen</label>
              <textarea value={lessonData.summary}
                onChange={e => setLessonData({ ...lessonData, summary: e.target.value })}
                className="w-full border rounded-lg px-3 py-2 text-sm" rows={2} />
            </div>

            <div>
              <label className="block text-sm font-medium text-green-400 mb-1">Contenido</label>
              <textarea value={lessonData.content}
                onChange={e => setLessonData({ ...lessonData, content: e.target.value })}
                className="w-full border rounded-lg px-3 py-2 text-sm" rows={10} />
            </div>

            <div>
              <label className="block text-sm font-medium text-green-400 mb-1">Objetivos</label>
              <textarea value={lessonData.objectives.join('\n')}
                onChange={e => setLessonData({ ...lessonData, objectives: e.target.value.split('\n').filter(Boolean) })}
                className="w-full border rounded-lg px-3 py-2 text-sm" rows={3} />
            </div>
          </div>
        </div>

        {lessonData.task_title && (
          <div className="bg-white rounded-xl border border-blue-200 p-5 mb-4">
            <h2 className="text-lg font-semibold text-blue-600 mb-3">Tarea</h2>
            <div className="space-y-3">
              <div>
                <label className="block text-sm font-medium text-green-400 mb-1">Titulo</label>
                <input value={lessonData.task_title}
                  onChange={e => setLessonData({ ...lessonData, task_title: e.target.value })}
                  className="w-full border rounded-lg px-3 py-2 text-sm" />
              </div>
              <div>
                <label className="block text-sm font-medium text-green-400 mb-1">Descripcion</label>
                <textarea value={lessonData.task_description}
                  onChange={e => setLessonData({ ...lessonData, task_description: e.target.value })}
                  className="w-full border rounded-lg px-3 py-2 text-sm" rows={2} />
              </div>
              <div>
                <label className="block text-sm font-medium text-green-400 mb-1">Instrucciones</label>
                <textarea value={lessonData.task_instructions}
                  onChange={e => setLessonData({ ...lessonData, task_instructions: e.target.value })}
                  className="w-full border rounded-lg px-3 py-2 text-sm" rows={3} />
              </div>
            </div>
          </div>
        )}

        <button type="button" onClick={saveLesson} disabled={saving}
          className="w-full bg-green-600 text-white py-3 rounded-lg font-medium hover:bg-green-700 disabled:opacity-50 transition-colors">
          {saving ? 'Guardando...' : 'Guardar leccion y tarea'}
        </button>
      </div>
    )
  }

  return null
}

// ============================================================
// MODO MANUAL — Formulario directo
// ============================================================

function ManualMode({ onBack }: { onBack: () => void }) {
  const router = useRouter()
  const [saving, setSaving] = useState(false)
  const [aiLoading, setAiLoading] = useState(false)
  const [form, setForm] = useState({
    subject_code: 'ciencias_naturales', grade: '2', week_number: 1,
    title: '', summary: '', content: '', objectives: '',
    task_title: '', task_description: '', task_instructions: '',
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
      if (data.suggestion) update('content', data.suggestion)
    } catch (e) { console.error(e) }
    setAiLoading(false)
  }

  const save = async () => {
    if (!form.title || !form.content) return alert('Completa titulo y contenido')
    setSaving(true)
    const schoolId = process.env.NEXT_PUBLIC_SCHOOL_ID || 'a0000000-0000-0000-0000-000000000001'

    const { data: lesson, error } = await supabase.from('lessons').insert({
      school_id: schoolId, subject_code: form.subject_code, grade: form.grade,
      week_number: form.week_number, title: form.title,
      summary: form.summary || form.content.substring(0, 200),
      content: form.content,
      objectives: form.objectives.split('\n').filter(Boolean),
      is_active: true,
    }).select().single()

    if (error) { setSaving(false); alert('Error: ' + error.message); return }

    if (form.task_title && form.task_description && lesson) {
      await supabase.from('assignments').insert({
        lesson_id: lesson.id, school_id: schoolId, grade: form.grade,
        title: form.task_title, description: form.task_description,
        instructions: form.task_instructions || null, is_active: true,
      })
    }

    setSaving(false)
    router.push('/lecciones')
  }

  return (
    <div className="max-w-2xl">
      <button onClick={onBack} className="text-sm text-gray-400 hover:text-gray-600 mb-4">&larr; Volver</button>

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
            <label className="block text-sm font-medium text-green-400 mb-1">Titulo</label>
            <input value={form.title} onChange={e => update('title', e.target.value)}
              className="w-full border rounded-lg px-3 py-2 text-sm" placeholder="Ej: Los Seres Vivos" />
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-green-400 mb-1">Resumen (corto, para la app)</label>
          <textarea value={form.summary} onChange={e => update('summary', e.target.value)}
            className="w-full border rounded-lg px-3 py-2 text-sm" rows={2} maxLength={200}
            placeholder="Resumen de 1-2 oraciones..." />
          <p className="text-xs text-gray-400 text-right">{form.summary.length}/200</p>
        </div>

        <div>
          <div className="flex items-center justify-between mb-1">
            <label className="block text-sm font-medium text-green-400">Contenido de la leccion</label>
            <button type="button" onClick={askAI} disabled={aiLoading}
              className="text-xs bg-blue-50 text-blue-600 px-3 py-1 rounded-full hover:bg-blue-100 disabled:opacity-50">
              {aiLoading ? 'Generando...' : '🤖 Sugerencia IA'}
            </button>
          </div>
          <textarea value={form.content} onChange={e => update('content', e.target.value)}
            className="w-full border rounded-lg px-3 py-2 text-sm" rows={10}
            placeholder="Escribe el contenido completo de la leccion..." />
        </div>

        <div>
          <label className="block text-sm font-medium text-green-400 mb-1">Objetivos (uno por linea)</label>
          <textarea value={form.objectives} onChange={e => update('objectives', e.target.value)}
            className="w-full border rounded-lg px-3 py-2 text-sm" rows={3}
            placeholder="Identificar seres vivos&#10;Describir caracteristicas&#10;Clasificar elementos" />
        </div>

        <div className="border-t border-gray-200 pt-4 mt-2">
          <h2 className="text-lg font-semibold text-green-500 mb-3">Tarea para los alumnos (opcional)</h2>
          <div className="space-y-3">
            <div>
              <label className="block text-sm font-medium text-green-400 mb-1">Titulo de la tarea</label>
              <input value={form.task_title} onChange={e => update('task_title', e.target.value)}
                className="w-full border rounded-lg px-3 py-2 text-sm"
                placeholder="Ej: Observar seres vivos cerca de casa" />
            </div>
            <div>
              <label className="block text-sm font-medium text-green-400 mb-1">Descripcion</label>
              <textarea value={form.task_description} onChange={e => update('task_description', e.target.value)}
                className="w-full border rounded-lg px-3 py-2 text-sm" rows={3}
                placeholder="Ej: Observa 3 seres vivos cerca de tu casa y describelos" />
            </div>
            <div>
              <label className="block text-sm font-medium text-green-400 mb-1">Instrucciones detalladas (opcional)</label>
              <textarea value={form.task_instructions} onChange={e => update('task_instructions', e.target.value)}
                className="w-full border rounded-lg px-3 py-2 text-sm" rows={3}
                placeholder="Pasos detallados para completar la tarea..." />
            </div>
          </div>
        </div>

        <button type="button" onClick={save} disabled={saving}
          className="w-full bg-green-600 text-white py-3 rounded-lg font-medium hover:bg-green-700 disabled:opacity-50 transition-colors">
          {saving ? 'Guardando...' : form.task_title ? 'Guardar leccion + tarea' : 'Guardar leccion'}
        </button>
      </div>
    </div>
  )
}
