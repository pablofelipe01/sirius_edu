import Anthropic from '@anthropic-ai/sdk'
import { NextRequest, NextResponse } from 'next/server'

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY })

export async function POST(req: NextRequest) {
  const { subject, grade, topic } = await req.json()

  const subjectNames: Record<string, string> = {
    ciencias_naturales: 'Ciencias Naturales',
    matematicas: 'Matematicas',
    lenguaje: 'Lenguaje',
    ciencias_sociales: 'Ciencias Sociales',
  }

  const message = await anthropic.messages.create({
    model: 'claude-sonnet-4-20250514',
    max_tokens: 1000,
    messages: [{
      role: 'user',
      content: `Eres un asistente educativo para profesores rurales de Colombia.
Genera el contenido de una leccion de ${subjectNames[subject] || subject} para grado ${grade} de primaria.
${topic ? `Tema: ${topic}` : 'Tema libre apropiado para el grado.'}

Usa ejemplos del contexto rural colombiano (fincas, animales, cultivos, rios, veredas).
Lenguaje simple y claro para ninos.
Incluye una actividad practica que puedan hacer en casa.
Maximo 500 palabras.`
    }]
  })

  const suggestion = message.content[0].type === 'text' ? message.content[0].text : ''
  return NextResponse.json({ suggestion })
}
