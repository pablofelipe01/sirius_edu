import Anthropic from '@anthropic-ai/sdk'
import { NextRequest, NextResponse } from 'next/server'

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY })

export async function POST(req: NextRequest) {
  const { message, history } = await req.json()

  const messages = (history || [])
    .filter((m: { role: string }) => m.role === 'user' || m.role === 'assistant')
    .slice(-10)
    .map((m: { role: string; content: string }) => ({
      role: m.role as 'user' | 'assistant',
      content: m.content,
    }))

  if (!messages.length || messages[messages.length - 1].role !== 'user') {
    messages.push({ role: 'user' as const, content: message })
  }

  const response = await anthropic.messages.create({
    model: 'claude-sonnet-4-20250514',
    max_tokens: 800,
    system: `Eres un asistente educativo para profesores rurales de Colombia.
Ayudas a preparar lecciones, explicar temas, disenar actividades y evaluar alumnos de primaria.
Usa ejemplos del contexto rural colombiano. Responde en espanol claro y practico.`,
    messages,
  })

  const text = response.content[0].type === 'text' ? response.content[0].text : ''
  return NextResponse.json({ response: text })
}
