-- Sirius Edu v4: Structured Lessons Migration
-- Adds lesson_chapters, chapter_activities, student_progress tables

-- Capítulos de una lección (ordenados)
CREATE TABLE IF NOT EXISTS lesson_chapters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
    chapter_number INT NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(lesson_id, chapter_number)
);

-- Actividades de un capítulo (misiones + tests)
CREATE TABLE IF NOT EXISTS chapter_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chapter_id UUID REFERENCES lesson_chapters(id) ON DELETE CASCADE,
    lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
    activity_number INT NOT NULL,
    activity_type TEXT NOT NULL CHECK (activity_type IN ('mission', 'test')),
    title TEXT NOT NULL,
    data JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(chapter_id, activity_number)
);

-- Progreso del alumno por lección
CREATE TABLE IF NOT EXISTS student_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES roster(id) ON DELETE CASCADE,
    lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
    last_completed_chapter INT DEFAULT 0,
    last_completed_activity INT DEFAULT 0,
    started_at TIMESTAMPTZ DEFAULT now(),
    completed_at TIMESTAMPTZ,
    UNIQUE(student_id, lesson_id)
);

-- Agregar total_chapters a lessons
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS total_chapters INT DEFAULT 0;

-- Agregar activity_id y activity_type a submissions
ALTER TABLE submissions ADD COLUMN IF NOT EXISTS activity_id UUID;
ALTER TABLE submissions ADD COLUMN IF NOT EXISTS activity_type TEXT;

-- RLS
ALTER TABLE lesson_chapters ENABLE ROW LEVEL SECURITY;
ALTER TABLE chapter_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Gateway full access" ON lesson_chapters FOR ALL USING (true);
CREATE POLICY "Gateway full access" ON chapter_activities FOR ALL USING (true);
CREATE POLICY "Gateway full access" ON student_progress FOR ALL USING (true);

-- Indices
CREATE INDEX IF NOT EXISTS idx_chapters_lesson ON lesson_chapters(lesson_id);
CREATE INDEX IF NOT EXISTS idx_activities_chapter ON chapter_activities(chapter_id);
CREATE INDEX IF NOT EXISTS idx_activities_lesson ON chapter_activities(lesson_id);
CREATE INDEX IF NOT EXISTS idx_progress_student ON student_progress(student_id);
CREATE INDEX IF NOT EXISTS idx_progress_lesson ON student_progress(lesson_id);
