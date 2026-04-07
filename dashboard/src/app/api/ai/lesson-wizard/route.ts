import Anthropic from '@anthropic-ai/sdk'
import { NextRequest, NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY })

const SYSTEM_PROMPT = `Eres un asistente educativo experto que ayuda a profesores rurales de Colombia a crear lecciones estructuradas para primaria.

CONTEXTO CRITICO — EL SISTEMA DE ENTREGA:
- Los alumnos reciben la leccion en su celular/tableta a traves de una red mesh LoRa (radio de largo alcance, sin internet).
- La leccion llega como TEXTO PLANO por capitulos. No hay imagenes, videos, links ni formato especial.
- Los ninos completan la leccion capitulo por capitulo, con actividades (tests y misiones) integradas.
- Un tutor IA esta disponible 24/7 para responder dudas del alumno sobre la leccion.
- El profesor NO esta presente. El nino esta en su casa, posiblemente solo.

ESTRUCTURA DE LA LECCION:
- 2-5 capitulos por leccion
- Cada capitulo: 3-5 parrafos cortos de contenido (texto plano, sin markdown)
- Cada capitulo: 1-3 actividades mezclando tests (opcion multiple A-D) y misiones (tareas practicas)
- Tests: evaluacion inmediata en el dispositivo (sin internet)
- Misiones: el alumno escribe una respuesta corta que se evalua por IA

REGLAS DEL CONTENIDO:
- Auto-contenido: el nino debe poder entenderlo sin ayuda de un adulto
- Vocabulario simple, oraciones cortas, ejemplos del entorno rural colombiano
- Fincas, animales, cultivos (cacao, platano, yuca, cafe), rios, montanas, veredas
- Sin formato markdown, sin negritas, sin listas con vinetas — solo texto plano

REGLAS DE ACTIVIDADES:
- Tests: exactamente 4 opciones (A-D), una sola correcta
- Misiones: realizables en casa sin materiales especiales ni internet
- Instrucciones paso a paso claras (el nino esta solo)

TU PROCESO:
1. Cuando el profesor selecciona materia, grado y periodo, usa el CURRICULO OFICIAL proporcionado para sugerir 5 temas apropiados del periodo. Numera los temas 1-5 y da una descripcion corta de cada uno basada en los DBA y contenidos del curriculo.

2. Cuando el profesor elige un tema, hazle 2 preguntas breves para personalizar:
   - Que tanto saben los ninos sobre este tema? (para calibrar el nivel)
   - Que recursos naturales o del entorno tienen cerca? (para usar como ejemplos)

3. Con las respuestas, genera la leccion completa en formato JSON asi:
LECCION_JSON:
{
  "title": "titulo de la leccion",
  "summary": "resumen de 1-2 oraciones (maximo 200 caracteres)",
  "objectives": ["objetivo 1 (alineado al DBA)", "objetivo 2", "objetivo 3"],
  "chapters": [
    {
      "title": "titulo del capitulo",
      "content": "texto plano del capitulo, 3-5 parrafos separados por doble salto de linea",
      "activities": [
        {
          "type": "test",
          "title": "pregunta de repaso",
          "data": {
            "question": "la pregunta",
            "options": [
              {"label": "A", "text": "opcion 1"},
              {"label": "B", "text": "opcion 2"},
              {"label": "C", "text": "opcion 3"},
              {"label": "D", "text": "opcion 4"}
            ],
            "correct_answer": "B"
          }
        },
        {
          "type": "mission",
          "title": "actividad practica",
          "data": {
            "description": "que debe hacer el alumno (1-2 oraciones)",
            "instructions": "instrucciones paso a paso que un nino solo en su casa pueda seguir"
          }
        }
      ]
    }
  ]
}

IMPORTANTE:
- Solo genera el JSON cuando tengas suficiente informacion (despues del paso 3)
- Alinea los objetivos y contenido con los DBA del curriculo oficial
- Responde de forma conversacional y amigable, como un colega profesor
- NO preguntes cuanto dura la leccion — no es presencial`

export async function POST(req: NextRequest) {
  const { messages, grade, subject_code, period } = await req.json()

  // Fetch curriculum context from Supabase
  let curriculumContext = ''
  if (grade && subject_code) {
    const { data: curriculumData } = await supabase
      .from('curriculum')
      .select('*')
      .eq('grade', grade)
      .eq('subject_code', subject_code)

    if (curriculumData && curriculumData.length > 0) {
      const general = curriculumData.find((c: Record<string, unknown>) => c.period === null)
      const periodData = period ? curriculumData.find((c: Record<string, unknown>) => c.period === parseInt(period)) : null

      if (general) {
        curriculumContext += `\n\nCURRICULO OFICIAL (MEN Colombia) — Grado ${grade}, ${subject_code}:`
        if (general.dba) {
          const dbaList = general.dba as string[]
          curriculumContext += `\nDBA:\n${dbaList.join('\n')}`
        }
        if (general.competencies) {
          curriculumContext += `\nCompetencias: ${general.competencies}`
        }
        if (general.content_axes) {
          const axes = general.content_axes as Array<{eje: string, contenido: string}>
          curriculumContext += `\nEjes tematicos:`
          for (const axis of axes) {
            curriculumContext += `\n- ${axis.eje}: ${axis.contenido}`
          }
        }
      }
      if (periodData) {
        curriculumContext += `\n\nPERIODO ${period}:`
        if (periodData.topics) curriculumContext += `\nTemas del periodo: ${periodData.topics}`
        if (periodData.guiding_question) curriculumContext += `\nPregunta problematizadora: ${periodData.guiding_question}`
      }
    }
  }

  const systemPrompt = SYSTEM_PROMPT + curriculumContext

  const response = await anthropic.messages.create({
    model: 'claude-sonnet-4-20250514',
    max_tokens: 4000,
    system: systemPrompt,
    messages: messages.map((m: { role: string; content: string }) => ({
      role: m.role as 'user' | 'assistant',
      content: m.content,
    })),
  })

  const text = response.content[0].type === 'text' ? response.content[0].text : ''

  // Detect structured lesson JSON — multiple strategies
  let lessonData = null
  let jsonText = ''

  // Strategy 1: LECCION_JSON: prefix
  const prefixMatch = text.match(/LECCION_JSON:\s*(\{[\s\S]*\})/m)
  if (prefixMatch) {
    jsonText = prefixMatch[1]
  }

  // Strategy 2: JSON in code block ```json ... ```
  if (!jsonText) {
    const codeBlockMatch = text.match(/```(?:json)?\s*(\{[\s\S]*?\})\s*```/m)
    if (codeBlockMatch) {
      jsonText = codeBlockMatch[1]
    }
  }

  // Strategy 3: Find JSON with "chapters" key
  if (!jsonText) {
    const start = text.indexOf('{"title"')
    if (start === -1) {
      const altStart = text.indexOf('{\n')
      if (altStart >= 0) {
        const end = text.lastIndexOf('}') + 1
        if (end > altStart) jsonText = text.substring(altStart, end)
      }
    } else {
      const end = text.lastIndexOf('}') + 1
      if (end > start) jsonText = text.substring(start, end)
    }
  }

  // Try to parse
  if (jsonText) {
    try {
      const parsed = JSON.parse(jsonText)
      if (parsed.title && (parsed.chapters || parsed.content)) {
        lessonData = parsed
      }
    } catch {
      // Try cleaning common issues
      try {
        const cleaned = jsonText.replace(/,\s*}/g, '}').replace(/,\s*]/g, ']')
        const parsed = JSON.parse(cleaned)
        if (parsed.title) lessonData = parsed
      } catch { /* ignore */ }
    }
  }

  // Clean the response text (remove the JSON part)
  let cleanResponse = text
  if (lessonData) {
    cleanResponse = text
      .replace(/LECCION_JSON:\s*\{[\s\S]*\}/m, '')
      .replace(/```(?:json)?\s*\{[\s\S]*?\}\s*```/m, '')
      .trim()
    if (!cleanResponse) cleanResponse = 'Leccion generada. Revisa y edita antes de guardar.'
  }

  return NextResponse.json({
    response: cleanResponse,
    lessonData,
  })
}
