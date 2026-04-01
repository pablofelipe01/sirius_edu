-- ============================================================
-- SIRIUS EDU — Schema Supabase
-- Sistema educativo mesh + IA para comunidades rurales
-- Supabase ES la fuente de verdad
-- ============================================================

-- Escuelas
CREATE TABLE schools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    location TEXT,
    municipality TEXT,
    department TEXT DEFAULT 'Caquetá',
    gateway_node_id TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Roster: todos los usuarios del sistema
CREATE TABLE roster (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('student', 'teacher', 'parent', 'supervisor')),
    grade TEXT DEFAULT '',
    node_id BIGINT UNIQUE,
    node_hex TEXT,
    pin TEXT,
    parent_of UUID REFERENCES roster(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Materias
CREATE TABLE subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    icon TEXT DEFAULT 'school',
    color TEXT DEFAULT '#2980B9'
);

INSERT INTO subjects (code, name, icon, color) VALUES
    ('ciencias_naturales', 'Ciencias Naturales', 'science', '#27AE60'),
    ('matematicas', 'Matemáticas', 'calculate', '#2980B9'),
    ('lenguaje', 'Lenguaje', 'menu_book', '#E67E22'),
    ('ciencias_sociales', 'Ciencias Sociales', 'public', '#8E44AD');

-- Lecciones (el profesor las crea desde el dashboard web)
CREATE TABLE lessons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    subject_code TEXT REFERENCES subjects(code),
    grade TEXT NOT NULL,
    week_number INT,
    title TEXT NOT NULL,
    summary TEXT NOT NULL,
    content TEXT NOT NULL,
    objectives TEXT[],
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES roster(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Tareas/Actividades (vinculadas a una lección)
CREATE TABLE assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    grade TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    instructions TEXT,
    deadline TIMESTAMPTZ,
    max_score NUMERIC DEFAULT 10,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Entregas de alumnos
CREATE TABLE submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id UUID REFERENCES assignments(id) ON DELETE CASCADE,
    student_id UUID REFERENCES roster(id) ON DELETE CASCADE,
    response TEXT NOT NULL,
    submitted_at TIMESTAMPTZ DEFAULT now(),
    -- Evaluación IA (automática, inmediata)
    ai_feedback TEXT,
    ai_score NUMERIC,
    ai_model TEXT,
    ai_evaluated_at TIMESTAMPTZ,
    -- Evaluación profesor (posterior, desde dashboard o mesh)
    teacher_feedback TEXT,
    teacher_score NUMERIC,
    final_grade TEXT,
    teacher_evaluated_at TIMESTAMPTZ,
    UNIQUE(assignment_id, student_id)
);

-- Conversaciones con tutor IA
CREATE TABLE ai_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES roster(id) ON DELETE CASCADE,
    school_id UUID REFERENCES schools(id),
    subject_code TEXT,
    question TEXT NOT NULL,
    ai_response TEXT NOT NULL,
    ai_model TEXT DEFAULT 'claude-sonnet-4-20250514',
    lesson_context UUID REFERENCES lessons(id),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Preguntas del alumno al profesor (van a Supabase para que el profesor las vea)
CREATE TABLE student_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES roster(id) ON DELETE CASCADE,
    school_id UUID REFERENCES schools(id),
    question TEXT NOT NULL,
    context TEXT,
    teacher_response TEXT,
    responded_by UUID REFERENCES roster(id),
    responded_at TIMESTAMPTZ,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Registro de conexiones (quién se conectó y cuándo)
CREATE TABLE connection_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES roster(id) ON DELETE CASCADE,
    school_id UUID REFERENCES schools(id),
    connected_at TIMESTAMPTZ DEFAULT now(),
    node_id BIGINT
);

-- Notas cualitativas del profesor sobre un alumno
CREATE TABLE teacher_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES roster(id) ON DELETE CASCADE,
    teacher_id UUID REFERENCES roster(id),
    note TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Nivel detectado por materia (auto-generado por IA cada N interacciones)
CREATE TABLE student_levels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES roster(id) ON DELETE CASCADE,
    subject_code TEXT REFERENCES subjects(code),
    level_description TEXT NOT NULL,
    detected_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(student_id, subject_code)
);

-- ============================================================
-- INDICES
-- ============================================================

CREATE INDEX idx_roster_school ON roster(school_id);
CREATE INDEX idx_roster_node ON roster(node_id);
CREATE INDEX idx_roster_role ON roster(role);
CREATE INDEX idx_lessons_school_grade ON lessons(school_id, grade);
CREATE INDEX idx_lessons_active ON lessons(is_active) WHERE is_active = true;
CREATE INDEX idx_assignments_grade ON assignments(grade);
CREATE INDEX idx_assignments_lesson ON assignments(lesson_id);
CREATE INDEX idx_submissions_student ON submissions(student_id);
CREATE INDEX idx_submissions_assignment ON submissions(assignment_id);
CREATE INDEX idx_ai_conversations_student ON ai_conversations(student_id);
CREATE INDEX idx_student_questions_school ON student_questions(school_id);
CREATE INDEX idx_student_questions_unread ON student_questions(is_read) WHERE is_read = false;
CREATE INDEX idx_connection_log_student ON connection_log(student_id);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE roster ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE connection_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE teacher_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_levels ENABLE ROW LEVEL SECURITY;

-- Política: el gateway (service_role) tiene acceso total
-- Los usuarios web (profesores) acceden via auth de Supabase
CREATE POLICY "Gateway full access" ON schools FOR ALL USING (true);
CREATE POLICY "Gateway full access" ON roster FOR ALL USING (true);
CREATE POLICY "Gateway full access" ON lessons FOR ALL USING (true);
CREATE POLICY "Gateway full access" ON assignments FOR ALL USING (true);
CREATE POLICY "Gateway full access" ON submissions FOR ALL USING (true);
CREATE POLICY "Gateway full access" ON ai_conversations FOR ALL USING (true);
CREATE POLICY "Gateway full access" ON student_questions FOR ALL USING (true);
CREATE POLICY "Gateway full access" ON connection_log FOR ALL USING (true);
CREATE POLICY "Gateway full access" ON teacher_notes FOR ALL USING (true);
CREATE POLICY "Gateway full access" ON student_levels FOR ALL USING (true);

-- ============================================================
-- FUNCIONES ÚTILES
-- ============================================================

-- Obtener lecciones activas por grado
CREATE OR REPLACE FUNCTION get_active_lessons(p_grade TEXT, p_school_id UUID)
RETURNS SETOF lessons AS $$
    SELECT * FROM lessons
    WHERE grade = p_grade
      AND school_id = p_school_id
      AND is_active = true
    ORDER BY week_number DESC, created_at DESC;
$$ LANGUAGE sql STABLE;

-- Obtener tareas pendientes de un alumno
CREATE OR REPLACE FUNCTION get_pending_assignments(p_student_id UUID, p_grade TEXT, p_school_id UUID)
RETURNS TABLE (
    assignment_id UUID,
    title TEXT,
    description TEXT,
    instructions TEXT,
    deadline TIMESTAMPTZ,
    max_score NUMERIC,
    lesson_title TEXT,
    subject_code TEXT,
    has_submitted BOOLEAN
) AS $$
    SELECT
        a.id,
        a.title,
        a.description,
        a.instructions,
        a.deadline,
        a.max_score,
        l.title,
        l.subject_code,
        EXISTS(SELECT 1 FROM submissions s WHERE s.assignment_id = a.id AND s.student_id = p_student_id)
    FROM assignments a
    LEFT JOIN lessons l ON a.lesson_id = l.id
    WHERE a.grade = p_grade
      AND a.school_id = p_school_id
      AND a.is_active = true
    ORDER BY a.deadline ASC NULLS LAST, a.created_at DESC;
$$ LANGUAGE sql STABLE;

-- Resumen de progreso de un alumno
CREATE OR REPLACE FUNCTION get_student_progress(p_student_id UUID)
RETURNS TABLE (
    total_assignments BIGINT,
    completed_assignments BIGINT,
    avg_ai_score NUMERIC,
    total_ai_questions BIGINT,
    pending_questions BIGINT
) AS $$
    SELECT
        (SELECT COUNT(*) FROM assignments a
         JOIN roster r ON r.id = p_student_id
         WHERE a.grade = r.grade AND a.is_active = true),
        (SELECT COUNT(*) FROM submissions WHERE student_id = p_student_id),
        (SELECT ROUND(AVG(ai_score), 1) FROM submissions WHERE student_id = p_student_id AND ai_score IS NOT NULL),
        (SELECT COUNT(*) FROM ai_conversations WHERE student_id = p_student_id),
        (SELECT COUNT(*) FROM student_questions WHERE student_id = p_student_id AND teacher_response IS NULL);
$$ LANGUAGE sql STABLE;

-- ============================================================
-- SEED DATA: Escuela piloto
-- ============================================================

INSERT INTO schools (id, name, location, municipality, department, gateway_node_id)
VALUES ('a0000000-0000-0000-0000-000000000001', 'Escuela El Cacao', 'Vereda El Cacao', 'Cartagena del Chairá', 'Caquetá', '!02e6bf50');

-- Roster piloto
INSERT INTO roster (school_id, name, role, grade, node_id, node_hex) VALUES
    ('a0000000-0000-0000-0000-000000000001', 'María García', 'student', '2', 1, '!00000001'),
    ('a0000000-0000-0000-0000-000000000001', 'Santiago López', 'student', '2', 2, '!00000002'),
    ('a0000000-0000-0000-0000-000000000001', 'Valentina Muñoz', 'student', '2', 3, '!00000003'),
    ('a0000000-0000-0000-0000-000000000001', 'Juan David Ríos', 'student', '3', 4, '!00000004'),
    ('a0000000-0000-0000-0000-000000000001', 'Camila Herrera', 'student', '3', 5, '!00000005');

INSERT INTO roster (school_id, name, role, grade, node_id, node_hex, pin) VALUES
    ('a0000000-0000-0000-0000-000000000001', 'Diana Castillo', 'teacher', '', 16, '!00000010', '2835'),
    ('a0000000-0000-0000-0000-000000000001', 'Carlos Mendoza', 'supervisor', '', 32, '!00000020', '9140');

-- Dev/test nodes
INSERT INTO roster (school_id, name, role, grade, node_id, node_hex) VALUES
    ('a0000000-0000-0000-0000-000000000001', 'Pablo (Dev)', 'student', '2', 2081597812, '!7c1a5974');
INSERT INTO roster (school_id, name, role, grade, node_id, node_hex, pin) VALUES
    ('a0000000-0000-0000-0000-000000000001', 'Nodo Prueba', 'teacher', '', 1236370724, '!49b7a524', '1234');

-- Lección de ejemplo
INSERT INTO lessons (school_id, subject_code, grade, week_number, title, summary, content, objectives, created_by)
SELECT
    'a0000000-0000-0000-0000-000000000001',
    'ciencias_naturales',
    '2',
    1,
    'Los Seres Vivos',
    'Aprendemos qué son los seres vivos y sus características principales.',
    'Los seres vivos son todos aquellos que nacen, crecen, se reproducen y mueren. En nuestra vereda podemos encontrar muchos seres vivos: las plantas de cacao, los árboles, los animales de la finca como las gallinas, los perros y las vacas, e incluso los insectos.

Características de los seres vivos:
1. Nacen: todos los seres vivos tienen un inicio de vida
2. Crecen: cambian de tamaño con el tiempo
3. Se alimentan: necesitan energía para vivir
4. Se reproducen: pueden tener hijos o crear nuevas plantas
5. Mueren: su ciclo de vida tiene un final

Actividad: Sal al patio de tu casa y observa 3 seres vivos diferentes. Dibújalos y escribe qué características tienen.',
    ARRAY['Identificar seres vivos en el entorno', 'Describir las características de los seres vivos', 'Clasificar seres vivos y no vivos'],
    r.id
FROM roster r WHERE r.name = 'Diana Castillo' LIMIT 1;

-- Tarea de ejemplo
INSERT INTO assignments (lesson_id, school_id, grade, title, description, instructions)
SELECT
    l.id,
    'a0000000-0000-0000-0000-000000000001',
    '2',
    'Observar seres vivos',
    'Observa 3 seres vivos cerca de tu casa y descríbelos.',
    'Sal al patio o al campo cerca de tu casa. Encuentra 3 seres vivos diferentes (pueden ser plantas, animales o insectos). Para cada uno escribe: su nombre, cómo se ve, y qué características de los seres vivos tiene (nace, crece, se alimenta, se reproduce).'
FROM lessons l WHERE l.title = 'Los Seres Vivos' LIMIT 1;
