'use client'
import { useState } from 'react'
import { supabase } from '@/lib/supabase'
import { useRouter } from 'next/navigation'
import type { StructuredLesson, TestData, MissionData } from '@/lib/types'

const subjects = [
  { code: 'ciencias_naturales', name: 'Ciencias Naturales' },
  { code: 'matematicas', name: 'Matematicas' },
  { code: 'lenguaje', name: 'Lenguaje' },
  { code: 'ciencias_sociales', name: 'Ciencias Sociales' },
]

function Field({ id, label, children }: { id: string; label: string; children: (id: string) => React.ReactNode }) {
  return (
    <div>
      <label htmlFor={id} className="block text-sm font-medium text-green-400 mb-1">{label}</label>
      {children(id)}
    </div>
  )
}

export default function NuevaLeccionPage() {
  const [mode, setMode] = useState<'choose' | 'pdf' | 'wizard' | 'manual'>('choose')

  return (
    <div>
      <h1 className="text-2xl font-bold text-green-500 mb-6">Nueva Leccion</h1>

      {mode === 'choose' && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 max-w-3xl">
          <button type="button" onClick={() => setMode('pdf')}
            className="bg-white rounded-xl border-2 border-blue-200 p-6 text-left hover:border-blue-400 hover:shadow-md transition-all">
            <span className="text-3xl block mb-3">📄</span>
            <span className="font-semibold text-blue-600 block mb-1">Desde PDF + IA</span>
            <span className="text-sm text-gray-500">Sube un PDF del temario y la IA genera la leccion estructurada</span>
          </button>
          <button type="button" onClick={() => setMode('wizard')}
            className="bg-white rounded-xl border-2 border-green-200 p-6 text-left hover:border-green-400 hover:shadow-md transition-all">
            <span className="text-3xl block mb-3">🤖</span>
            <span className="font-semibold text-green-600 block mb-1">Con asistente IA</span>
            <span className="text-sm text-gray-500">Te guio paso a paso para crear la leccion</span>
          </button>
          <button type="button" onClick={() => setMode('manual')}
            className="bg-white rounded-xl border-2 border-gray-200 p-6 text-left hover:border-gray-400 hover:shadow-md transition-all">
            <span className="text-3xl block mb-3">✏️</span>
            <span className="font-semibold text-gray-700 block mb-1">Manual</span>
            <span className="text-sm text-gray-500">Ya se que quiero poner</span>
          </button>
        </div>
      )}

      {mode === 'pdf' && <PdfMode onBack={() => setMode('choose')} />}
      {mode === 'wizard' && <WizardMode onBack={() => setMode('choose')} />}
      {mode === 'manual' && <ManualMode onBack={() => setMode('choose')} />}
    </div>
  )
}

// ============================================================
// MODO PDF — Upload PDF + IA genera leccion estructurada
// ============================================================

function PdfMode({ onBack }: { onBack: () => void }) {
  const [subject, setSubject] = useState('ciencias_naturales')
  const [grade, setGrade] = useState('2')
  const [weekNumber, setWeekNumber] = useState(1)
  const [topic, setTopic] = useState('')
  const [period, setPeriod] = useState('1')
  const [file, setFile] = useState<File | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [lessonData, setLessonData] = useState<StructuredLesson | null>(null)

  async function generate() {
    if (!file && !topic) { setError('Sube un PDF o escribe un tema'); return }
    setLoading(true)
    setError('')
    const formData = new FormData()
    if (file) formData.append('file', file)
    formData.append('subject', subjects.find(s => s.code === subject)?.name || subject)
    formData.append('grade', grade)
    formData.append('topic', topic)
    formData.append('period', period)
    try {
      const res = await fetch('/api/ai/generate-lesson', { method: 'POST', body: formData })
      const data = await res.json()
      if (data.error) { setError(data.error); setLoading(false); return }
      setLessonData(data.lessonData)
    } catch (e) {
      setError('Error de conexion')
    }
    setLoading(false)
  }

  if (lessonData) {
    return <LessonReviewEditor
      lessonData={lessonData}
      setLessonData={setLessonData}
      subject={subject}
      grade={grade}
      weekNumber={weekNumber}
      onBack={() => setLessonData(null)}
    />
  }

  return (
    <div className="max-w-lg">
      <button type="button" onClick={onBack} className="text-sm text-gray-400 hover:text-gray-600 mb-4">&larr; Volver</button>
      <div className="bg-white rounded-xl border border-blue-100 p-5 space-y-4">
        <p className="text-blue-600 font-medium">Sube un PDF del temario y la IA generara la leccion:</p>
        <div className="grid grid-cols-2 gap-4">
          <Field id="pdf-subject" label="Materia">
            {(id) => <select id={id} value={subject} onChange={e => setSubject(e.target.value)}
              className="w-full border rounded-lg px-3 py-2 text-sm">
              {subjects.map(s => <option key={s.code} value={s.code}>{s.name}</option>)}
            </select>}
          </Field>
          <Field id="pdf-grade" label="Grado">
            {(id) => <select id={id} value={grade} onChange={e => setGrade(e.target.value)}
              className="w-full border rounded-lg px-3 py-2 text-sm">
              {[1,2,3,4,5].map(g => <option key={g} value={String(g)}>{g} Grado</option>)}
            </select>}
          </Field>
        </div>
        <div className="grid grid-cols-2 gap-4">
          <Field id="pdf-period" label="Periodo">
            {(id) => <select id={id} value={period} onChange={e => setPeriod(e.target.value)}
              className="w-full border rounded-lg px-3 py-2 text-sm">
              {[1,2,3,4].map(p => <option key={p} value={String(p)}>Periodo {p}</option>)}
            </select>}
          </Field>
          <Field id="pdf-week" label="Semana">
            {(id) => <input id={id} type="number" value={weekNumber} onChange={e => setWeekNumber(Number(e.target.value))}
              className="w-full border rounded-lg px-3 py-2 text-sm" min={1} max={52} />}
          </Field>
        </div>
        <Field id="pdf-topic" label="Tema (opcional si subes PDF)">
          {(id) => <input id={id} value={topic} onChange={e => setTopic(e.target.value)}
            className="w-full border rounded-lg px-3 py-2 text-sm" placeholder="Ej: Los seres vivos" />}
        </Field>
        <div>
          <label htmlFor="pdf-file" className="block text-sm font-medium text-green-400 mb-1">PDF del temario</label>
          <input id="pdf-file" type="file" accept=".pdf"
            onChange={e => setFile(e.target.files?.[0] || null)}
            className="w-full border rounded-lg px-3 py-2 text-sm" />
        </div>
        {error && <p className="text-red-500 text-sm">{error}</p>}
        <button type="button" onClick={generate} disabled={loading}
          className="w-full bg-blue-600 text-white py-3 rounded-lg font-medium hover:bg-blue-700 disabled:opacity-50">
          {loading ? 'Generando leccion con IA...' : 'Generar leccion'}
        </button>
        {loading && <p className="text-center text-sm text-gray-400">Esto puede tomar 15-30 segundos...</p>}
      </div>
    </div>
  )
}

// ============================================================
// MODO WIZARD — Conversacion con IA (actualizado para estructura)
// ============================================================

function WizardMode({ onBack }: { onBack: () => void }) {
  const [step, setStep] = useState<'select' | 'chat' | 'review'>('select')
  const [subject, setSubject] = useState('ciencias_naturales')
  const [grade, setGrade] = useState('2')
  const [weekNumber, setWeekNumber] = useState(1)
  const [messages, setMessages] = useState<{ role: 'user' | 'assistant'; content: string }[]>([])
  const [input, setInput] = useState('')
  const [loading, setLoading] = useState(false)
  const [lessonData, setLessonData] = useState<StructuredLesson | null>(null)

  const subjectName = subjects.find(s => s.code === subject)?.name || subject

  async function startWizard() {
    const firstMessage = `Quiero crear una leccion de ${subjectName} para grado ${grade}. Sugiereme 5 temas apropiados.`
    setMessages([{ role: 'user', content: firstMessage }])
    setStep('chat')
    setLoading(true)
    const res = await fetch('/api/ai/lesson-wizard', {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
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
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ messages: newMessages }),
    })
    const data = await res.json()
    setMessages(prev => [...prev, { role: 'assistant' as const, content: data.response }])
    if (data.lessonData) { setLessonData(data.lessonData); setStep('review') }
    setLoading(false)
  }

  if (step === 'select') {
    return (
      <div className="max-w-md">
        <button type="button" onClick={onBack} className="text-sm text-gray-400 hover:text-gray-600 mb-4">&larr; Volver</button>
        <div className="bg-white rounded-xl border border-gray-100 p-5 space-y-4">
          <p className="text-green-600 font-medium">Selecciona materia y grado:</p>
          <Field id="wz-subject" label="Materia">
            {(id) => <select id={id} value={subject} onChange={e => setSubject(e.target.value)}
              className="w-full border rounded-lg px-3 py-2 text-sm">
              {subjects.map(s => <option key={s.code} value={s.code}>{s.name}</option>)}
            </select>}
          </Field>
          <div className="grid grid-cols-2 gap-4">
            <Field id="wz-grade" label="Grado">
              {(id) => <select id={id} value={grade} onChange={e => setGrade(e.target.value)}
                className="w-full border rounded-lg px-3 py-2 text-sm">
                {[1,2,3,4,5].map(g => <option key={g} value={String(g)}>{g} Grado</option>)}
              </select>}
            </Field>
            <Field id="wz-week" label="Semana">
              {(id) => <input id={id} type="number" value={weekNumber} onChange={e => setWeekNumber(Number(e.target.value))}
                className="w-full border rounded-lg px-3 py-2 text-sm" min={1} max={52} />}
            </Field>
          </div>
          <button type="button" onClick={startWizard}
            className="w-full bg-green-600 text-white py-3 rounded-lg font-medium hover:bg-green-700">
            Iniciar asistente
          </button>
        </div>
      </div>
    )
  }

  if (step === 'chat') {
    return (
      <div className="max-w-2xl flex flex-col h-[calc(100vh-8rem)]">
        <div className="flex items-center gap-3 mb-4">
          <button type="button" onClick={onBack} className="text-sm text-gray-400 hover:text-gray-600">&larr;</button>
          <span className="text-sm bg-green-100 text-green-700 px-2 py-1 rounded-full">{subjectName}</span>
          <span className="text-sm bg-blue-100 text-blue-700 px-2 py-1 rounded-full">Grado {grade}</span>
        </div>
        <div className="flex-1 overflow-y-auto space-y-3 mb-4">
          {messages.map((m, i) => (
            <div key={i} className={`flex ${m.role === 'user' ? 'justify-end' : 'justify-start'}`}>
              <div className={`max-w-[80%] px-4 py-3 rounded-2xl text-sm whitespace-pre-wrap
                ${m.role === 'user' ? 'bg-green-100 text-green-900 rounded-br-md' : 'bg-blue-50 text-gray-800 rounded-bl-md'}`}>
                {m.content}
              </div>
            </div>
          ))}
          {loading && (
            <div className="flex justify-start">
              <div className="bg-blue-50 text-gray-400 px-4 py-3 rounded-2xl rounded-bl-md text-sm italic">Pensando...</div>
            </div>
          )}
        </div>
        <div className="flex gap-2">
          <input id="wz-chat-input" value={input} onChange={e => setInput(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && sendMessage()}
            placeholder="Escribe tu respuesta..." aria-label="Mensaje al asistente"
            className="flex-1 border rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-green-500"
            disabled={loading} />
          <button type="button" onClick={() => sendMessage()} disabled={loading || !input.trim()}
            className="bg-green-600 text-white px-6 py-3 rounded-xl hover:bg-green-700 disabled:opacity-50">Enviar</button>
        </div>
      </div>
    )
  }

  if (step === 'review' && lessonData) {
    return <LessonReviewEditor
      lessonData={lessonData}
      setLessonData={setLessonData}
      subject={subject}
      grade={grade}
      weekNumber={weekNumber}
      onBack={() => setStep('chat')}
    />
  }
  return null
}

// ============================================================
// MODO MANUAL (simplificado — usa el review editor)
// ============================================================

function ManualMode({ onBack }: { onBack: () => void }) {
  const emptyLesson: StructuredLesson = {
    title: '', summary: '', objectives: [],
    chapters: [{
      title: 'Capitulo 1',
      content: '',
      activities: [{
        type: 'test', title: 'Pregunta de repaso',
        data: { question: '', options: [
          { label: 'A', text: '' }, { label: 'B', text: '' },
          { label: 'C', text: '' }, { label: 'D', text: '' },
        ], correct_answer: 'A' } as TestData,
      }],
    }],
  }
  const [lessonData, setLessonData] = useState<StructuredLesson>(emptyLesson)
  const [subject, setSubject] = useState('ciencias_naturales')
  const [grade, setGrade] = useState('2')
  const [weekNumber, setWeekNumber] = useState(1)

  return (
    <div>
      <button type="button" onClick={onBack} className="text-sm text-gray-400 hover:text-gray-600 mb-4">&larr; Volver</button>
      <div className="max-w-md mb-4 grid grid-cols-3 gap-3">
        <Field id="man-subject" label="Materia">
          {(id) => <select id={id} value={subject} onChange={e => setSubject(e.target.value)}
            className="w-full border rounded-lg px-3 py-2 text-sm">
            {subjects.map(s => <option key={s.code} value={s.code}>{s.name}</option>)}
          </select>}
        </Field>
        <Field id="man-grade" label="Grado">
          {(id) => <select id={id} value={grade} onChange={e => setGrade(e.target.value)}
            className="w-full border rounded-lg px-3 py-2 text-sm">
            {[1,2,3,4,5].map(g => <option key={g} value={String(g)}>{g} Grado</option>)}
          </select>}
        </Field>
        <Field id="man-week" label="Semana">
          {(id) => <input id={id} type="number" value={weekNumber} onChange={e => setWeekNumber(Number(e.target.value))}
            className="w-full border rounded-lg px-3 py-2 text-sm" min={1} max={52} />}
        </Field>
      </div>
      <LessonReviewEditor
        lessonData={lessonData}
        setLessonData={setLessonData}
        subject={subject}
        grade={grade}
        weekNumber={weekNumber}
        onBack={onBack}
      />
    </div>
  )
}

// ============================================================
// REVIEW EDITOR — Componente reutilizable para editar leccion estructurada
// ============================================================

function LessonReviewEditor({
  lessonData, setLessonData, subject, grade, weekNumber, onBack,
}: {
  lessonData: StructuredLesson
  setLessonData: (data: StructuredLesson) => void
  subject: string; grade: string; weekNumber: number
  onBack: () => void
}) {
  const router = useRouter()
  const [saving, setSaving] = useState(false)

  const updateChapter = (ci: number, field: string, value: string) => {
    const chapters = [...lessonData.chapters]
    chapters[ci] = { ...chapters[ci], [field]: value }
    setLessonData({ ...lessonData, chapters })
  }

  const addChapter = () => {
    setLessonData({
      ...lessonData,
      chapters: [...lessonData.chapters, { title: `Capitulo ${lessonData.chapters.length + 1}`, content: '', activities: [] }],
    })
  }

  const removeChapter = (ci: number) => {
    if (lessonData.chapters.length <= 1) return
    setLessonData({ ...lessonData, chapters: lessonData.chapters.filter((_, i) => i !== ci) })
  }

  const updateActivity = (ci: number, ai: number, updates: Record<string, unknown>) => {
    const chapters = [...lessonData.chapters]
    const activities = [...chapters[ci].activities]
    activities[ai] = { ...activities[ai], ...updates }
    chapters[ci] = { ...chapters[ci], activities }
    setLessonData({ ...lessonData, chapters })
  }

  const addActivity = (ci: number, type: 'test' | 'mission') => {
    const chapters = [...lessonData.chapters]
    const newActivity = type === 'test'
      ? { type: 'test' as const, title: 'Pregunta de repaso', data: { question: '', options: [
          { label: 'A', text: '' }, { label: 'B', text: '' },
          { label: 'C', text: '' }, { label: 'D', text: '' },
        ], correct_answer: 'A' } as TestData }
      : { type: 'mission' as const, title: 'Mision practica', data: { description: '', instructions: '' } as MissionData }
    chapters[ci] = { ...chapters[ci], activities: [...chapters[ci].activities, newActivity] }
    setLessonData({ ...lessonData, chapters })
  }

  const removeActivity = (ci: number, ai: number) => {
    const chapters = [...lessonData.chapters]
    chapters[ci] = { ...chapters[ci], activities: chapters[ci].activities.filter((_, i) => i !== ai) }
    setLessonData({ ...lessonData, chapters })
  }

  async function save() {
    if (!lessonData.title) { alert('Falta el titulo'); return }
    if (lessonData.chapters.length === 0) { alert('Agrega al menos un capitulo'); return }
    setSaving(true)
    const schoolId = process.env.NEXT_PUBLIC_SCHOOL_ID || 'a0000000-0000-0000-0000-000000000001'

    // 1. Create lesson
    const content = lessonData.chapters.map(c => c.content).join('\n\n')
    const { data: lesson, error } = await supabase.from('lessons').insert({
      school_id: schoolId, subject_code: subject, grade, week_number: weekNumber,
      title: lessonData.title, summary: lessonData.summary || content.substring(0, 200),
      content, objectives: lessonData.objectives, is_active: true,
      total_chapters: lessonData.chapters.length,
    }).select().single()

    if (error || !lesson) { setSaving(false); alert('Error: ' + (error?.message || 'desconocido')); return }

    // 2. Create chapters + activities
    for (let ci = 0; ci < lessonData.chapters.length; ci++) {
      const ch = lessonData.chapters[ci]
      const { data: chapter, error: chError } = await supabase.from('lesson_chapters').insert({
        lesson_id: lesson.id, chapter_number: ci + 1, title: ch.title, content: ch.content,
      }).select().single()

      if (chError || !chapter) { console.error('Chapter error:', chError); continue }

      for (let ai = 0; ai < ch.activities.length; ai++) {
        const act = ch.activities[ai]
        await supabase.from('chapter_activities').insert({
          chapter_id: chapter.id, lesson_id: lesson.id,
          activity_number: ai + 1, activity_type: act.type,
          title: act.title, data: act.data,
        })
      }
    }

    setSaving(false)
    router.push('/lecciones')
  }

  return (
    <div className="max-w-3xl">
      <button type="button" onClick={onBack} className="text-sm text-gray-400 hover:text-gray-600 mb-4">&larr; Volver</button>

      {/* Metadata */}
      <div className="bg-white rounded-xl border border-green-200 p-5 mb-4 space-y-3">
        <h2 className="text-lg font-semibold text-green-600">Leccion</h2>
        <Field id="rv-title" label="Titulo">
          {(id) => <input id={id} value={lessonData.title} onChange={e => setLessonData({ ...lessonData, title: e.target.value })}
            className="w-full border rounded-lg px-3 py-2 text-sm" />}
        </Field>
        <Field id="rv-summary" label="Resumen">
          {(id) => <textarea id={id} value={lessonData.summary} onChange={e => setLessonData({ ...lessonData, summary: e.target.value })}
            className="w-full border rounded-lg px-3 py-2 text-sm" rows={2} />}
        </Field>
        <Field id="rv-objectives" label="Objetivos (uno por linea)">
          {(id) => <textarea id={id} value={lessonData.objectives.join('\n')}
            onChange={e => setLessonData({ ...lessonData, objectives: e.target.value.split('\n').filter(Boolean) })}
            className="w-full border rounded-lg px-3 py-2 text-sm" rows={3} />}
        </Field>
      </div>

      {/* Chapters */}
      {lessonData.chapters.map((ch, ci) => (
        <div key={ci} className="bg-white rounded-xl border border-blue-200 p-5 mb-4">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-md font-semibold text-blue-600">Capitulo {ci + 1}</h3>
            {lessonData.chapters.length > 1 && (
              <button type="button" onClick={() => removeChapter(ci)} className="text-xs text-red-400 hover:text-red-600">Eliminar</button>
            )}
          </div>
          <div className="space-y-3">
            <Field id={`ch-${ci}-title`} label="Titulo del capitulo">
              {(id) => <input id={id} value={ch.title} onChange={e => updateChapter(ci, 'title', e.target.value)}
                className="w-full border rounded-lg px-3 py-2 text-sm" />}
            </Field>
            <Field id={`ch-${ci}-content`} label="Contenido">
              {(id) => <textarea id={id} value={ch.content} onChange={e => updateChapter(ci, 'content', e.target.value)}
                className="w-full border rounded-lg px-3 py-2 text-sm" rows={6} />}
            </Field>

            {/* Activities */}
            {ch.activities.map((act, ai) => (
              <div key={ai} className={`rounded-lg border p-4 ${act.type === 'test' ? 'border-purple-200 bg-purple-50/30' : 'border-orange-200 bg-orange-50/30'}`}>
                <div className="flex items-center justify-between mb-2">
                  <span className={`text-xs font-medium px-2 py-1 rounded-full ${act.type === 'test' ? 'bg-purple-100 text-purple-700' : 'bg-orange-100 text-orange-700'}`}>
                    {act.type === 'test' ? 'Test' : 'Mision'}
                  </span>
                  <button type="button" onClick={() => removeActivity(ci, ai)} className="text-xs text-red-400 hover:text-red-600">Eliminar</button>
                </div>
                <Field id={`act-${ci}-${ai}-title`} label="Titulo">
                  {(id) => <input id={id} value={act.title} onChange={e => updateActivity(ci, ai, { title: e.target.value })}
                    className="w-full border rounded-lg px-3 py-2 text-sm" />}
                </Field>

                {act.type === 'test' && (() => {
                  const testData = act.data as TestData
                  return (
                    <div className="mt-2 space-y-2">
                      <Field id={`test-${ci}-${ai}-q`} label="Pregunta">
                        {(id) => <input id={id} value={testData.question}
                          onChange={e => updateActivity(ci, ai, { data: { ...testData, question: e.target.value } })}
                          className="w-full border rounded-lg px-3 py-2 text-sm" />}
                      </Field>
                      {testData.options.map((opt, oi) => (
                        <div key={oi} className="flex items-center gap-2">
                          <span className="font-bold text-sm w-6">{opt.label})</span>
                          <input value={opt.text}
                            onChange={e => {
                              const newOptions = [...testData.options]
                              newOptions[oi] = { ...opt, text: e.target.value }
                              updateActivity(ci, ai, { data: { ...testData, options: newOptions } })
                            }}
                            className="flex-1 border rounded-lg px-3 py-1 text-sm" aria-label={`Opcion ${opt.label}`} />
                          <input type="radio" name={`correct-${ci}-${ai}`}
                            checked={testData.correct_answer === opt.label}
                            onChange={() => updateActivity(ci, ai, { data: { ...testData, correct_answer: opt.label } })}
                            aria-label={`${opt.label} es correcta`} />
                        </div>
                      ))}
                      <p className="text-xs text-gray-400">Selecciona el radio de la respuesta correcta</p>
                    </div>
                  )
                })()}

                {act.type === 'mission' && (() => {
                  const missionData = act.data as MissionData
                  return (
                    <div className="mt-2 space-y-2">
                      <Field id={`mis-${ci}-${ai}-desc`} label="Descripcion">
                        {(id) => <textarea id={id} value={missionData.description}
                          onChange={e => updateActivity(ci, ai, { data: { ...missionData, description: e.target.value } })}
                          className="w-full border rounded-lg px-3 py-2 text-sm" rows={2} />}
                      </Field>
                      <Field id={`mis-${ci}-${ai}-inst`} label="Instrucciones paso a paso">
                        {(id) => <textarea id={id} value={missionData.instructions}
                          onChange={e => updateActivity(ci, ai, { data: { ...missionData, instructions: e.target.value } })}
                          className="w-full border rounded-lg px-3 py-2 text-sm" rows={3} />}
                      </Field>
                    </div>
                  )
                })()}
              </div>
            ))}

            <div className="flex gap-2">
              <button type="button" onClick={() => addActivity(ci, 'test')}
                className="text-xs bg-purple-50 text-purple-600 px-3 py-1 rounded-full hover:bg-purple-100">+ Test</button>
              <button type="button" onClick={() => addActivity(ci, 'mission')}
                className="text-xs bg-orange-50 text-orange-600 px-3 py-1 rounded-full hover:bg-orange-100">+ Mision</button>
            </div>
          </div>
        </div>
      ))}

      <button type="button" onClick={addChapter}
        className="w-full border-2 border-dashed border-blue-200 text-blue-400 py-3 rounded-xl hover:border-blue-400 hover:text-blue-600 mb-4">
        + Agregar capitulo
      </button>

      <button type="button" onClick={save} disabled={saving}
        className="w-full bg-green-600 text-white py-3 rounded-lg font-medium hover:bg-green-700 disabled:opacity-50">
        {saving ? 'Guardando...' : 'Guardar leccion'}
      </button>
    </div>
  )
}
