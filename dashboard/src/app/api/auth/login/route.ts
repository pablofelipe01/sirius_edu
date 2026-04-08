import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'
import { createSession, COOKIE_NAME, SESSION_COOKIE_OPTIONS } from '@/lib/session'

// Use service role on the server so RLS doesn't block lookups during auth
const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
)

export async function POST(req: NextRequest) {
  try {
    const { node_hex, pin } = await req.json()

    if (!node_hex || !pin) {
      return NextResponse.json({ error: 'Node ID y PIN son obligatorios' }, { status: 400 })
    }

    // Normalize node_hex (accept !abcd1234 or abcd1234)
    const normalized = node_hex.startsWith('!') ? node_hex : `!${node_hex}`

    // Look up teacher by node_hex
    const { data: user, error } = await supabase
      .from('roster')
      .select('id, name, role, school_id, pin, is_active')
      .eq('node_hex', normalized)
      .eq('role', 'teacher')
      .maybeSingle()

    if (error || !user) {
      return NextResponse.json({ error: 'Profesor no encontrado' }, { status: 401 })
    }

    if (!user.is_active) {
      return NextResponse.json({ error: 'Cuenta inactiva' }, { status: 401 })
    }

    if (user.pin !== pin) {
      return NextResponse.json({ error: 'PIN incorrecto' }, { status: 401 })
    }

    // Get school name (optional, for display)
    const { data: school } = await supabase
      .from('schools')
      .select('name')
      .eq('id', user.school_id)
      .maybeSingle()

    const token = await createSession({
      teacher_id: user.id,
      teacher_name: user.name,
      school_id: user.school_id,
      school_name: school?.name,
    })

    const res = NextResponse.json({
      success: true,
      teacher: { id: user.id, name: user.name },
      school: { id: user.school_id, name: school?.name },
    })
    res.cookies.set(COOKIE_NAME, token, SESSION_COOKIE_OPTIONS)
    return res
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Error desconocido'
    return NextResponse.json({ error: message }, { status: 500 })
  }
}
