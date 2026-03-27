# Sirius Edu — Base de Datos Airtable

## Identificadores de la Base

| Variable | Valor |
|----------|-------|
| **Base Name** | Sirius Edu - Piloto |
| **Base ID** | `appQQ3PpZD3sx9ZW4` |
| **Variable de entorno** | `AIRTABLE_EDU_BASE_ID=appQQ3PpZD3sx9ZW4` |

> El token de API (`AIRTABLE_API_TOKEN`) es el mismo que el de Porteria — es por cuenta de Airtable, no por base.

---

## Tabla 1: Estudiantes

**Table ID:** `tblAaP1Cd1mxcWRWs`

| Field ID | Nombre | Tipo |
|----------|--------|------|
| `fldW5j5EskDWjhino` | ID | Single line text *(primary)* |
| `fldxQ9xtd8ZkM42Dr` | Nombre | Single line text |
| `fldH5SNgOqERYbY4p` | Grado | Single select — `1, 2, 3, 4, 5` |
| `fldFx8A1XwONK4FiO` | Node ID | Single line text |
| `flds7RUo95O2OQ23j` | Nivel por Materia | Long text (JSON auto-generado por IA) |
| `fldfvJHQ6mQ4NhWdN` | Notas del Profesor | Long text (JSON array, privado) |
| `fldmdacY6zhNZadQz` | Mensaje para Padre | Single line text (visible para padres) |
| `fldcGtiEwqgBcj4b4` | Fecha Registro | Date (YYYY-MM-DD) |

---

## Tabla 2: Lecciones

**Table ID:** `tblY7EfPhTtczCSwD`

| Field ID | Nombre | Tipo |
|----------|--------|------|
| `fldgMqa0CnoPoPyfI` | ID | Single line text *(primary)* |
| `fldQucc1otfS0wmB5` | Materia | Single select — `ciencias_naturales, matematicas, lenguaje, ciencias_sociales` |
| `fldghn5QfZaGxWbcP` | Grado | Single select — `1, 2, 3, 4, 5` |
| `fld8RxawIm4Ry6fKV` | Titulo | Single line text |
| `fld1gQfdstZjZhXYD` | Resumen | Long text (< 200 chars) |
| `fldbNYqPPtmFmAfH1` | Contenido | Long text |
| `fld4r3ibgM1o3q3rO` | Activa | Checkbox (solo una activa por grado) |
| `fldFe1F1oy4FQK0jq` | Profesor Node | Single line text |
| `fld7dKzbHkZO1tgx2` | Fecha | Date (YYYY-MM-DD) |

---

## Tabla 3: Tareas

**Table ID:** `tblayZBVzJZYeXpKB`

| Field ID | Nombre | Tipo |
|----------|--------|------|
| `fldaRPrQIplWFZ3b8` | ID | Single line text *(primary)* |
| `fldE5TQIWpvGd79wL` | Leccion | Link to Lecciones |
| `fldnpCLmSqX0dOVwt` | Estudiante | Link to Estudiantes — NULL = toda la clase |
| `fldUYnouS5p3P0PVb` | Descripcion | Long text |
| `fldWFyu7ZB7oxAlEb` | Fecha Limite | Date (YYYY-MM-DD) |
| `fldFlqvwS7CdzBdQ4` | Estado | Single select — `Pendiente, Entregada, Evaluada IA, Evaluada Final` |

---

## Tabla 4: Entregas

**Table ID:** `tblMRgI60MdSMe4qq`

| Field ID | Nombre | Tipo |
|----------|--------|------|
| `fldAuJAaasRYjkAla` | ID | Single line text *(primary)* |
| `fldhyebdf6lEBkhYd` | Tarea | Link to Tareas |
| `fldcOjtL0ctKjSD74` | Estudiante | Link to Estudiantes |
| `fldCg6mEqp5igXWtQ` | Respuesta | Long text |
| `fldoiQ6JS726F0zp6` | Fecha Entrega | Date (YYYY-MM-DD) |
| `fldbfL9abXKUUryhr` | Feedback IA | Long text |
| `fldjTBJDGXoEGddbJ` | Puntaje IA | Number (decimal, 0.0 – 10.0) |
| `fldi1c5WtYswSFl8q` | Criterio Profesor | Long text |
| `fldXHcbEIds59dLCh` | Nota Final | Single line text |

---

## Tabla 5: Conversaciones IA

**Table ID:** `tblduhargWkpksTBL`

| Field ID | Nombre | Tipo |
|----------|--------|------|
| `fldfRLIPQuezAaI1r` | ID | Single line text *(primary)* |
| `fldhQg87bhxNvzGV6` | Estudiante | Link to Estudiantes |
| `fldSekd96NcqfYf9W` | Materia | Single line text |
| `fldJ3CIBWt4yRsLi9` | Pregunta | Long text |
| `fldqv77AUpKtzuRsu` | Respuesta IA | Long text |
| `fldZ8hBmr8bxIQRip` | Modelo | Single line text |
| `fld1RzdCVRmDSQsiO` | Fecha | Date (YYYY-MM-DD) |

---

## Comparacion de bases Sirius

| Sistema | Base ID | Tabla principal |
|---------|---------|-----------------|
| Porteria | `apptwIqTras1uPNOc` | Registro Visitantes |
| **Educacion** | `appQQ3PpZD3sx9ZW4` | Estudiantes, Lecciones, Tareas, Entregas, Conversaciones IA |
