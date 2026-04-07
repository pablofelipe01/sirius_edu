import Anthropic from '@anthropic-ai/sdk'
import { NextRequest, NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY })

const STRUCTURED_LESSON_PROMPT = `Eres un experto en diseno curricular para escuelas rurales de Colombia.
A partir del contenido educativo proporcionado, genera una leccion estructurada en capitulos.

CONTEXTO CRITICO:
- Los alumnos reciben la leccion en su celular via red mesh LoRa (radio, sin internet).
- Todo es TEXTO PLANO. No hay imagenes, videos, links, ni formato markdown.
- El nino esta en su casa, posiblemente solo, sin profesor presente.
- Un tutor IA esta disponible para dudas.
- Zona rural colombiana: fincas, cultivos (cacao, platano, yuca, cafe), rios, montanas.

REGLAS PARA EL CONTENIDO:
- 2-5 capitulos por leccion
- Cada capitulo: 3-5 parrafos cortos, texto plano, auto-contenido
- Ejemplos concretos del entorno rural colombiano
- Vocabulario simple, oraciones cortas
- Sin markdown, sin emojis, sin listas con vinetas

REGLAS PARA ACTIVIDADES:
- Cada capitulo: 1-3 actividades (mezclar tests y misiones)
- Tests: exactamente 4 opciones (A-D), una sola correcta
- Misiones: realizables en casa sin internet ni materiales especiales
- Instrucciones paso a paso claras para un nino solo

FORMATO DE SALIDA — responde SOLO con JSON valido, sin texto adicional:
{
  "title": "titulo de la leccion",
  "summary": "resumen de 1-2 oraciones (max 200 chars)",
  "objectives": ["objetivo 1", "objetivo 2", "objetivo 3"],
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
            "instructions": "instrucciones paso a paso"
          }
        }
      ]
    }
  ]
}`

export async function POST(req: NextRequest) {
  try {
    const formData = await req.formData()
    const file = formData.get('file') as File | null
    const subject = formData.get('subject') as string || ''
    const grade = formData.get('grade') as string || ''
    const topic = formData.get('topic') as string || ''

    let sourceContent = ''
    const period = formData.get('period') as string || ''

    // Extract text from PDF if provided
    if (file && file.size > 0) {
      const buffer = Buffer.from(await file.arrayBuffer())
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const pdfParse = require('pdf-parse')
      const pdfData = await pdfParse(buffer)
      sourceContent = pdfData.text
    }

    // Fetch curriculum data from Supabase
    const subjectCode = subject.toLowerCase().replace(/ /g, '_')
    const { data: curriculumData } = await supabase
      .from('curriculum')
      .select('*')
      .eq('grade', grade)
      .eq('subject_code', subjectCode)

    let curriculumContext = ''
    if (curriculumData && curriculumData.length > 0) {
      const general = curriculumData.find((c: Record<string, unknown>) => c.period === null)
      const periodData = period ? curriculumData.find((c: Record<string, unknown>) => c.period === parseInt(period)) : null

      if (general) {
        curriculumContext += `\nCURRICULO OFICIAL (MEN Colombia) — Grado ${grade}, ${subject}:`
        if (general.dba) {
          const dbaList = general.dba as string[]
          curriculumContext += `\nDerechos Basicos de Aprendizaje (DBA):\n${dbaList.join('\n')}`
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
        if (periodData.topics) curriculumContext += `\nTemas: ${periodData.topics}`
        if (periodData.guiding_question) curriculumContext += `\nPregunta problematizadora: ${periodData.guiding_question}`
      }
    }

    // Build the user message
    let userMessage = `Materia: ${subject}\nGrado: ${grade}\n`
    if (period) {
      userMessage += `Periodo: ${period}\n`
    }
    if (topic) {
      userMessage += `Tema: ${topic}\n`
    }
    if (curriculumContext) {
      userMessage += `\n${curriculumContext}\n`
    }
    if (sourceContent) {
      userMessage += `\nContenido del temario (extraido del PDF):\n${sourceContent.substring(0, 6000)}\n`
    }
    userMessage += '\nGenera la leccion estructurada en formato JSON. Asegurate de alinear la leccion con los DBA y temas del curriculo oficial.'

    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 4000,
      system: STRUCTURED_LESSON_PROMPT,
      messages: [{ role: 'user', content: userMessage }],
    })

    const text = response.content[0].type === 'text' ? response.content[0].text : ''

    // Extract JSON from response
    let lessonData = null
    try {
      const start = text.indexOf('{')
      const end = text.lastIndexOf('}') + 1
      if (start >= 0 && end > start) {
        lessonData = JSON.parse(text.substring(start, end))
      }
    } catch {
      return NextResponse.json({ error: 'No se pudo parsear la respuesta de la IA', raw: text }, { status: 500 })
    }

    if (!lessonData || !lessonData.chapters) {
      return NextResponse.json({ error: 'La IA no genero una estructura valida', raw: text }, { status: 500 })
    }

    return NextResponse.json({ lessonData })
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Error desconocido'
    return NextResponse.json({ error: message }, { status: 500 })
  }
}
