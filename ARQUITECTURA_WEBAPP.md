# Arquitectura de la Web App — Sirius Edu (Panel del Profesor)

> Documento de referencia para **entender** la web app actual y **replicarla** en un nuevo
> escenario educativo: una **biblioteca digital** con conectividad total, sin red mesh LoRa.
>
> El proyecto tiene 2 piezas independientes: una **app Flutter** (cliente del alumno, que vive
> en la red mesh) y una **web app** (panel del profesor). **Este documento solo describe la web app.**

---

## 1. Resumen ejecutivo

La web app es el **panel de administración del profesor**: un dashboard donde el docente
crea lecciones, revisa entregas de los alumnos, responde preguntas y usa un asistente de IA.

Es una aplicación **Next.js (App Router) full-stack**: el mismo proyecto sirve el frontend
(React) y el backend (API Routes). No hay servidor aparte. Los datos viven en **Supabase**
(Postgres gestionado) y la IA es **Claude** vía el SDK de Anthropic.

```
┌──────────────────────────────────────────────────────────┐
│                     NAVEGADOR (Profesor)                   │
│   React 19 + Tailwind 4  (Server Components + Client)      │
└───────────────┬───────────────────────────┬───────────────┘
                │ HTTP                        │ HTTP
                ▼                             ▼
┌──────────────────────────────────────────────────────────┐
│              NEXT.JS 16 (App Router) — un solo deploy      │
│                                                            │
│  middleware.ts ── verifica cookie de sesión (JWT) en TODO  │
│                                                            │
│  /app/*           páginas (Server Components)              │
│  /app/api/auth/*  login / logout / me                      │
│  /app/api/ai/*    chat, generate-lesson, lesson-wizard     │
└───────┬───────────────────────────────┬──────────────────┘
        │ supabase-js                     │ Anthropic SDK
        ▼                                 ▼
┌────────────────────┐          ┌────────────────────────┐
│   SUPABASE (Postgres)│          │   CLAUDE (Anthropic API) │
│   roster, lessons,   │          │   claude-sonnet-4        │
│   chapters, ...      │          │                          │
└────────────────────┘          └────────────────────────┘
```

---

## 2. Stack tecnológico

| Capa | Tecnología | Versión | Rol |
|------|-----------|---------|-----|
| Framework | **Next.js** (App Router) | 16.2 | Frontend + backend en un solo proyecto |
| UI | **React** | 19.2 | Componentes |
| Estilos | **Tailwind CSS** | 4 | Utilidades CSS, sin CSS-in-JS |
| Lenguaje | **TypeScript** | 5 | Tipado en todo el proyecto |
| Base de datos | **Supabase** (`@supabase/supabase-js`) | 2.x | Postgres + REST autogenerada + RLS |
| IA | **Anthropic SDK** (`@anthropic-ai/sdk`) | 0.81 | Generación de lecciones y chat |
| Auth | **jose** (JWT) | 6.x | Sesión propia firmada (no usa Supabase Auth) |
| Parsing | **pdf-parse** | 2.x | Extrae texto de PDFs del temario |

> **Nota clave:** la app **no usa Supabase Auth**. La autenticación es propia (JWT en cookie
> httpOnly). Supabase se usa solo como base de datos.

---

## 3. Estructura de carpetas (`dashboard/`)

```
dashboard/
├── package.json
├── next.config.ts
└── src/
    ├── middleware.ts          ← guardia de auth para TODAS las rutas
    ├── lib/
    │   ├── supabase.ts        ← cliente Supabase (anon key, navegador/servidor)
    │   ├── session.ts         ← crear/verificar JWT, leer cookie
    │   └── types.ts           ← interfaces TypeScript del dominio
    ├── components/
    │   ├── Sidebar.tsx        ← navegación + logout (Client Component)
    │   ├── StatCard.tsx       ← tarjeta de métrica
    │   └── LessonCard.tsx
    └── app/
        ├── layout.tsx         ← layout raíz: pinta Sidebar si hay sesión
        ├── page.tsx           ← Dashboard (home, métricas)
        ├── globals.css        ← Tailwind + variables de tema
        ├── login/
        │   ├── layout.tsx
        │   └── page.tsx       ← formulario de login (Client Component)
        ├── lecciones/
        │   ├── page.tsx       ← lista de lecciones
        │   ├── nueva/page.tsx ← crear lección (PDF / wizard IA / manual)
        │   └── [id]/page.tsx  ← detalle/edición
        ├── alumnos/
        │   ├── page.tsx
        │   └── [id]/page.tsx
        ├── entregas/page.tsx   ← submissions de alumnos
        ├── preguntas/page.tsx  ← preguntas de alumnos al profesor
        ├── asistente/page.tsx  ← chat con IA
        └── api/
            ├── auth/{login,logout,me}/route.ts
            └── ai/{chat,generate-lesson,lesson-wizard}/route.ts
```

**Convención del App Router:** cada carpeta bajo `app/` es una ruta. `page.tsx` = página,
`route.ts` = endpoint de API, `layout.tsx` = envoltorio compartido, `[id]` = ruta dinámica.

---

## 4. Los 4 pilares de la arquitectura

### 4.1 Autenticación (sesión propia con JWT)

No usa proveedores externos. El flujo es:

1. **Login** (`/api/auth/login/route.ts`): el profesor envía `node_hex` + `pin`. El servidor
   busca el usuario en la tabla `roster` con la **service key** de Supabase (para saltar RLS),
   compara el PIN en texto plano, y si todo cuadra firma un **JWT** con `jose`.
2. El JWT se guarda en una **cookie httpOnly** (`sirius_session`), no accesible desde JS del
   navegador. Dura 7 días.
3. **`middleware.ts`** intercepta TODAS las peticiones: si no hay cookie válida, redirige a
   `/login` (páginas) o devuelve 401 (rutas `/api`). Rutas públicas: `/login`, `/api/auth/login`,
   `/api/auth/logout`.
4. En Server Components y API routes, `getSession()` lee la cookie y devuelve `{ teacher_id,
   teacher_name, school_id, school_name }`. **El `school_id` de la sesión es la clave de
   aislamiento de datos**: cada query filtra por la escuela del profesor.

```ts
// session.ts (esencia)
const SECRET = new TextEncoder().encode(process.env.SESSION_SECRET || '...')
createSession(data)  → SignJWT(...).setExpirationTime('7d').sign(SECRET)
verifySession(token) → jwtVerify(token, SECRET) → payload | null
getSession()         → lee cookie 'sirius_session' → verifySession
```

> ⚠️ **Deudas de seguridad heredadas que NO debes copiar tal cual:** el PIN se guarda y compara
> en texto plano; el `SESSION_SECRET` tiene un fallback hardcodeado; se usa la `anon key` para
> queries con RLS en modo `USING (true)` (todo abierto). Ver §8 para cómo endurecerlo en la
> biblioteca.

### 4.2 Datos (Supabase como backend)

Un único cliente (`lib/supabase.ts`) creado con la URL y la **anon key**. Las páginas (Server
Components) y las API routes hacen queries directamente con la API fluida de `supabase-js`:

```ts
const { data } = await supabase
  .from('roster')
  .select('id')
  .eq('school_id', schoolId)
  .eq('role', 'student')
  .eq('is_active', true)
```

Características:
- **REST autogenerada:** no se escribe SQL en la app; supabase-js genera las queries.
- **Joins por foreign key:** p.ej. `submissions` puede traer `roster(name, grade)` y
  `assignments(title, description)` en una sola query gracias a las FK (ver migración 003).
- **RLS (Row Level Security)** activado en todas las tablas, pero con política `USING (true)`
  (todo permitido) — el aislamiento real lo hace la app filtrando por `school_id`.
- **JSONB** para estructuras flexibles: el campo `data` de `chapter_activities` guarda el test
  o la misión; `curriculum.dba` y `content_axes` guardan listas/objetos.

### 4.3 IA (Claude vía Anthropic SDK)

Tres endpoints, todos con el patrón `anthropic.messages.create({ model, system, messages })`:

| Endpoint | Qué hace |
|----------|----------|
| `/api/ai/chat` | Chat libre del profesor con un asistente educativo. Mantiene historial (últimos 10 mensajes). |
| `/api/ai/generate-lesson` | Recibe un **PDF** (lo parsea con `pdf-parse`) + materia/grado/periodo, mete el **currículo oficial** desde Supabase como contexto, y pide a Claude una **lección estructurada en JSON** (capítulos + actividades). |
| `/api/ai/lesson-wizard` | Asistente **conversacional** que guía al profesor paso a paso (sugiere temas → pregunta nivel → genera el JSON de la lección). |

Patrón importante: el **system prompt** lleva todo el contexto del dominio (en el caso actual:
"texto plano, sin internet, zona rural, mesh LoRa..."). La respuesta de Claude se **parsea para
extraer el JSON** de la lección con varias estrategias de fallback (prefijo `LECCION_JSON:`,
bloque ```` ```json ````, búsqueda de `{"title"`, limpieza de comas finales).

> 🔑 Para la biblioteca, este es el punto que **más cambia**: el system prompt rural/mesh hay que
> reemplazarlo por uno de biblioteca (resúmenes, recomendaciones, búsqueda semántica, etc.).
> La **mecánica** (SDK, system prompt + messages, parseo de salida) se reutiliza igual.

### 4.4 UI (Server Components + Client Components + Tailwind)

- **`layout.tsx`** (Server): lee la sesión y decide si pinta el `Sidebar` + `main`, o solo el
  contenido (login). Idioma `es`.
- **Páginas de datos** (`page.tsx`, Server Components con `export const dynamic = 'force-dynamic'`):
  hacen las queries a Supabase **en el servidor** y renderizan HTML ya con datos. Usan
  `Promise.all` para queries en paralelo.
- **Componentes interactivos** (`'use client'`): `Sidebar`, formulario de login, modos de
  creación de lección. Usan `useState`, `useRouter`, `fetch` a las API routes.
- **Estilos:** Tailwind 4 puro (clases utilitarias), paleta verde/azul, sin librería de
  componentes. Iconos = emojis.

---

## 5. Modelo de datos (tablas Supabase)

Tablas centrales (de `lib/types.ts` y las migraciones):

| Tabla | Rol | Campos clave |
|-------|-----|--------------|
| `schools` | Escuelas/sedes | `id`, `name`, `municipality`, `gateway_node_id` |
| `roster` | Usuarios (alumnos/profesores/padres) | `id`, `school_id`, `role`, `name`, `grade`, `node_hex`, `pin`, `is_active` |
| `lessons` | Lecciones | `id`, `school_id`, `subject_code`, `grade`, `title`, `summary`, `objectives[]`, `total_chapters` |
| `lesson_chapters` | Capítulos de una lección | `lesson_id`, `chapter_number`, `title`, `content` |
| `chapter_activities` | Actividades (tests/misiones) | `chapter_id`, `activity_type`, `data` (JSONB), `activity_number` |
| `student_progress` | Progreso del alumno | `student_id`, `lesson_id`, `last_completed_chapter/activity`, `completed_at` |
| `submissions` | Entregas de actividades | `assignment_id`, `activity_id`(FK), `student_id`, `response`, `ai_feedback`, `ai_score`, `teacher_score` |
| `student_questions` | Preguntas al profesor | `student_id`, `question`, `teacher_response`, `is_read` |
| `curriculum` | Pensum oficial (MEN Colombia) | `grade`, `subject_code`, `period`, `dba`(JSONB), `topics`, `content_axes`(JSONB) |
| `ai_conversations` | Historial de chat alumno-IA | `student_id`, `question`, `ai_response` |

Relaciones: `lessons 1─N lesson_chapters 1─N chapter_activities`; todo cuelga de `school_id`;
`submissions.activity_id → chapter_activities.id` (FK para joins REST).

---

## 6. Variables de entorno

```bash
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...        # cliente público
SUPABASE_SERVICE_KEY=eyJ...                  # solo servidor (login salta RLS)
SESSION_SECRET=<32+ chars aleatorios>        # firma de JWT — ¡NO usar el fallback!
ANTHROPIC_API_KEY=sk-ant-...                 # solo servidor
```

`NEXT_PUBLIC_*` se exponen al navegador; el resto solo viven en el servidor (API routes).

---

## 7. Cómo correr / desplegar

```bash
cd dashboard
npm install
npm run dev      # desarrollo en localhost:3000
npm run build    # build de producción
npm run start    # servir el build
```

Despliegue natural: **Vercel** (Next.js es de Vercel) o cualquier host de Node. Supabase es
SaaS. Migraciones SQL en `supabase/migrations/` (aplicar con la CLI de Supabase o el editor SQL).

---

## 8. Guía para replicar como **Biblioteca Digital** (conectividad total, sin mesh)

La arquitectura se reutiliza casi entera. Lo que cambia es el **dominio** (lecciones → libros/
recursos) y que **desaparecen todas las restricciones de la mesh** (texto plano, offline,
"el niño está solo sin internet", LoRa, nodos Meshtastic).

### 8.1 Qué se conserva tal cual

- **Next.js App Router** full-stack (frontend + API en un proyecto).
- **Supabase** como base de datos + REST + RLS + JSONB.
- **Middleware** de guardia de sesión sobre todas las rutas.
- **Patrón de Server Components** que hacen queries en el servidor + Client Components para
  interacción.
- **Tailwind** para UI.
- **Anthropic SDK** para funciones de IA (la *mecánica*: system prompt + messages + parseo).

### 8.2 Qué se simplifica o elimina (gracias a tener internet siempre)

| En Sirius Edu (mesh) | En la Biblioteca (online) |
|----------------------|---------------------------|
| Login por `node_hex` (ID de nodo Meshtastic) + PIN | **Auth estándar**: email+contraseña o magic link. Recomendado: **Supabase Auth** (gratis, gestiona hashing, sesiones, OAuth). |
| PIN en texto plano | Hashing gestionado por Supabase Auth (o bcrypt si haces auth propia). |
| Contenido en **texto plano** (sin imágenes/links/markdown) | **Contenido enriquecido**: portadas, PDFs/EPUBs, imágenes, markdown, video, enlaces. |
| System prompts "rural / sin internet / niño solo" | System prompts de **biblioteca**: resúmenes, recomendaciones, búsqueda, preguntas sobre un libro. |
| `gateway_node_id`, `node_hex`, `node_id`, tabla mesh | **Se eliminan** todos los campos de red mesh. |
| Aislamiento por `school_id` filtrado en la app | RLS real de Supabase por `user_id` / `org_id` (políticas que sí restringen). |
| `student_progress` por capítulos/misiones | **Préstamos / favoritos / historial de lectura / progreso de lectura**. |
| Almacenamiento solo de texto | **Supabase Storage** (o S3) para archivos de los libros. |

### 8.3 Modelo de datos propuesto para la biblioteca

```
users           id, email, name, role (lector/bibliotecario/admin), org_id, created_at
                ← usa Supabase Auth; esta tabla es el "perfil"
collections     id, name, description, org_id          ← estanterías/colecciones
resources       id, collection_id, title, author, description, cover_url,
                file_url, file_type (pdf/epub/video/link), tags[], language,
                published_year, is_active, created_at
                ← reemplaza a "lessons"
resource_meta   id, resource_id, key, value (JSONB)    ← metadatos flexibles
loans           id, resource_id, user_id, borrowed_at, due_at, returned_at, status
favorites       id, resource_id, user_id, created_at
reading_progress id, resource_id, user_id, position, percent, updated_at
reviews         id, resource_id, user_id, rating, comment, created_at
ai_conversations id, user_id, resource_id, question, ai_response, created_at
```

Patrón a copiar de Sirius Edu: **JSONB** para metadatos variables (`resource_meta`), **FK** entre
`loans/favorites/reviews → resources` y `→ users` para joins REST, y un campo de **aislamiento
multi-tenant** (`org_id`) si habrá varias bibliotecas.

### 8.4 Endpoints de IA adaptados

Reutiliza la mecánica de `/api/ai/*`, cambiando el system prompt:

- `/api/ai/chat` → **asistente bibliotecario** ("¿qué leo si me gustó X?", dudas sobre un libro).
- `/api/ai/summarize` → recibe un PDF/EPUB (parsea con `pdf-parse`), devuelve **resumen + temas +
  nivel de lectura** (mismo patrón que `generate-lesson`, pero sin restricción de texto plano).
- `/api/ai/recommend` → toma historial/favoritos del usuario y sugiere recursos (búsqueda
  semántica con embeddings + **pgvector** de Supabase es el siguiente paso natural).
- `/api/ai/extract-metadata` → al subir un libro, autocompleta autor/año/tags/descripción.

### 8.5 Páginas (rutas) propuestas

```
/                     ← home: destacados, recién agregados, recomendados
/catalogo             ← buscador + filtros (autor, tema, tipo, idioma)
/catalogo/[id]        ← ficha del recurso: portada, descripción, leer/descargar, reseñas, IA
/lector/[id]          ← visor de PDF/EPUB con progreso de lectura
/mis-prestamos        ← préstamos activos e historial
/favoritos
/asistente            ← chat IA (igual que ahora)
/admin/recursos       ← CRUD de recursos (solo bibliotecario)  ← análogo a /lecciones/nueva
/admin/recursos/nuevo ← subir libro + IA autocompleta metadatos
/login
/api/auth/*           ← si usas Supabase Auth, casi no escribes nada aquí
/api/ai/*
```

### 8.6 Pasos concretos para arrancar la réplica

1. **Copiar el esqueleto:** `npx create-next-app` (o clonar `dashboard/` y vaciar el dominio).
   Conservar `lib/supabase.ts`, el patrón de `middleware.ts`, `globals.css`, Tailwind.
2. **Auth:** sustituir `lib/session.ts` + `/api/auth/*` por **Supabase Auth** (`@supabase/ssr`).
   Es menos código y más seguro que el JWT manual. (Si prefieres mantener el JWT propio, al
   menos hashea contraseñas y quita el fallback del secret.)
3. **Base de datos:** crear las tablas de §8.3 como migraciones en `supabase/migrations/`, con
   **RLS real** (`USING (auth.uid() = user_id)` etc.), no `USING (true)`.
4. **Storage:** activar Supabase Storage para portadas y archivos de libros.
5. **IA:** copiar un endpoint de `/api/ai/` y reescribir el system prompt para el dominio
   biblioteca. Mantener el patrón de parseo de JSON si pides salida estructurada.
6. **UI:** reaprovechar `Sidebar`, `StatCard`, el layout y las páginas de listado/detalle como
   plantillas; cambiar "Lecciones" → "Catálogo", "Alumnos" → "Lectores", etc.

### 8.7 Mejoras recomendadas para la versión online (no estaban en mesh)

- **Búsqueda semántica** con embeddings + `pgvector` (Supabase lo soporta nativo).
- **Streaming** de las respuestas de Claude (`anthropic.messages.stream`) para chat fluido.
- **Caché de prompts** de Anthropic para abaratar resúmenes repetidos.
- **Imágenes/portadas** optimizadas con `next/image`.
- **Roles y permisos** reales con RLS (lector vs. bibliotecario vs. admin).
- **Realtime** de Supabase para "disponibilidad" de un libro en préstamo.

---

## 9. Tabla rápida: archivo → responsabilidad (para copiar de referencia)

| Archivo | Patrón que enseña |
|---------|-------------------|
| `src/lib/supabase.ts` | Crear el cliente de datos una sola vez |
| `src/lib/session.ts` | Sesión JWT en cookie httpOnly (→ reemplazable por Supabase Auth) |
| `src/middleware.ts` | Guardia de auth global + rutas públicas + 401 en API |
| `src/app/layout.tsx` | Layout condicionado por sesión |
| `src/app/page.tsx` | Server Component con queries en paralelo (`Promise.all`) |
| `src/app/api/auth/login/route.ts` | Endpoint POST, service key para saltar RLS, set-cookie |
| `src/app/api/ai/generate-lesson/route.ts` | PDF→texto + contexto de BD + Claude + parseo de JSON |
| `src/app/api/ai/lesson-wizard/route.ts` | Chat IA con extracción de estructura de la respuesta |
| `src/components/Sidebar.tsx` | Client Component: navegación activa + logout vía fetch |
| `supabase/migrations/*.sql` | Tablas, RLS, índices, FK para joins REST, JSONB |

---

*Generado a partir de la revisión del código en `dashboard/` y `supabase/migrations/`.
La app Flutter (cliente del alumno en la mesh) queda fuera del alcance de este documento.*
