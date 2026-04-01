'use client'
import { useState } from 'react'

interface Message {
  role: 'user' | 'assistant'
  content: string
}

const suggestions = [
  'Sugerir leccion de ciencias naturales para grado 2',
  'Como puedo explicar fracciones a ninos de 8 anos?',
  'Actividad practica de lenguaje para grado 3',
  'Como evaluar comprension lectora en primaria?',
]

export default function AsistentePage() {
  const [messages, setMessages] = useState<Message[]>([
    { role: 'assistant', content: 'Hola profesor. Soy tu asistente educativo. Puedo ayudarte con sugerencias de lecciones, como explicar temas, estrategias de evaluacion y mas. Preguntame lo que necesites.' }
  ])
  const [input, setInput] = useState('')
  const [loading, setLoading] = useState(false)

  async function send(text?: string) {
    const msg = text || input.trim()
    if (!msg) return

    const newMessages = [...messages, { role: 'user' as const, content: msg }]
    setMessages(newMessages)
    setInput('')
    setLoading(true)

    try {
      const res = await fetch('/api/ai/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: msg, history: newMessages.slice(-10) }),
      })
      const data = await res.json()
      setMessages([...newMessages, { role: 'assistant', content: data.response || 'No pude responder.' }])
    } catch {
      setMessages([...newMessages, { role: 'assistant', content: 'Error de conexion.' }])
    }
    setLoading(false)
  }

  return (
    <div className="flex flex-col h-[calc(100vh-4rem)]">
      <h1 className="text-2xl font-bold text-green-500 mb-4">Asistente IA</h1>

      <div className="flex gap-2 mb-4 overflow-x-auto">
        {suggestions.map(s => (
          <button key={s} onClick={() => send(s)}
            className="whitespace-nowrap text-xs bg-blue-50 text-blue-600 px-3 py-1.5 rounded-full hover:bg-blue-100 transition-colors">
            {s}
          </button>
        ))}
      </div>

      <div className="flex-1 overflow-y-auto space-y-3 mb-4">
        {messages.map((m, i) => (
          <div key={i} className={`flex ${m.role === 'user' ? 'justify-end' : 'justify-start'}`}>
            <div className={`max-w-[75%] px-4 py-3 rounded-2xl text-sm whitespace-pre-wrap
              ${m.role === 'user' ? 'bg-green-100 text-green-900 rounded-br-md' : 'bg-blue-50 text-gray-800 rounded-bl-md'}`}>
              {m.content}
            </div>
          </div>
        ))}
        {loading && (
          <div className="flex justify-start">
            <div className="bg-blue-50 text-gray-400 px-4 py-3 rounded-2xl rounded-bl-md text-sm italic">
              Escribiendo...
            </div>
          </div>
        )}
      </div>

      <div className="flex gap-2">
        <input value={input} onChange={e => setInput(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && send()}
          placeholder="Pregunta al asistente..."
          className="flex-1 border rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-green-500"
          disabled={loading} />
        <button onClick={() => send()} disabled={loading || !input.trim()}
          className="bg-green-600 text-white px-6 py-3 rounded-xl hover:bg-green-700 disabled:opacity-50 transition-colors">
          Enviar
        </button>
      </div>
    </div>
  )
}
