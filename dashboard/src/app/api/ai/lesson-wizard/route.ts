import Anthropic from '@anthropic-ai/sdk'
import { NextRequest, NextResponse } from 'next/server'

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY })

const SYSTEM_PROMPT = `Eres un asistente educativo experto que ayuda a profesores rurales de Colombia a crear lecciones para primaria.

CONTEXTO:
- Los alumnos son ninos de zonas rurales (veredas, fincas, campo)
- Edad: 6-12 anos segun el grado
- La leccion se envia por radio LoRa (texto plano, sin imagenes, sin formato especial)
- Usa ejemplos del campo: cultivos, animales, rios, montanas, la finca, la vereda
- Lenguaje simple, oraciones cortas, sin tecnicismos innecesarios

TU PROCESO:
1. Cuando el profesor selecciona materia y grado, sugiere 5 temas del curriculo colombiano (MEN) apropiados para ese grado. Numera los temas 1-5 y da una descripcion corta de cada uno.

2. Cuando el profesor elige un tema, hazle 2-3 preguntas breves para personalizar la leccion:
   - Que tanto saben los ninos sobre este tema?
   - Tienen acceso a algun recurso natural cercano? (rio, bosque, huerta)
   - Cuanto tiempo tienen para la leccion?

3. Con las respuestas, genera la leccion completa en formato JSON asi:
LECCION_JSON:
{
  "title": "titulo de la leccion",
  "summary": "resumen de 1-2 oraciones (maximo 200 caracteres)",
  "content": "contenido completo de la leccion, 3-5 parrafos cortos, con ejemplos rurales",
  "objectives": ["objetivo 1", "objetivo 2", "objetivo 3"],
  "task_title": "titulo de la tarea",
  "task_description": "que debe hacer el alumno (1-2 oraciones)",
  "task_instructions": "instrucciones paso a paso claras y sencillas"
}

IMPORTANTE:
- Solo genera el JSON cuando tengas suficiente informacion (despues del paso 3)
- El contenido debe ser apropiado para el grado especifico
- Las tareas deben ser realizables en casa sin internet ni materiales especiales
- Todo en espanol colombiano simple
- Responde de forma conversacional y amigable, como un colega profesor`

export async function POST(req: NextRequest) {
  const { messages } = await req.json()

  const response = await anthropic.messages.create({
    model: 'claude-sonnet-4-20250514',
    max_tokens: 1500,
    system: SYSTEM_PROMPT,
    messages: messages.map((m: { role: string; content: string }) => ({
      role: m.role as 'user' | 'assistant',
      content: m.content,
    })),
  })

  const text = response.content[0].type === 'text' ? response.content[0].text : ''

  // Detectar si la respuesta contiene JSON de leccion
  let lessonData = null
  const jsonMatch = text.match(/LECCION_JSON:\s*(\{[\s\S]*\})/m)
  if (jsonMatch) {
    try {
      lessonData = JSON.parse(jsonMatch[1])
    } catch {
      // Intentar extraer JSON de otra forma
      const start = text.lastIndexOf('{')
      const end = text.lastIndexOf('}') + 1
      if (start >= 0 && end > start) {
        try { lessonData = JSON.parse(text.substring(start, end)) } catch { /* ignore */ }
      }
    }
  }

  return NextResponse.json({
    response: text.replace(/LECCION_JSON:\s*\{[\s\S]*\}/m, '').trim(),
    lessonData,
  })
}
