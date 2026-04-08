-- Sirius Edu: add foreign key from submissions.activity_id to chapter_activities.id
-- This enables Supabase REST joins (chapter_activities) on submissions queries.

ALTER TABLE submissions
  DROP CONSTRAINT IF EXISTS submissions_activity_id_fkey;

ALTER TABLE submissions
  ADD CONSTRAINT submissions_activity_id_fkey
  FOREIGN KEY (activity_id) REFERENCES chapter_activities(id) ON DELETE SET NULL;

-- Reload PostgREST schema cache so the new relationship is recognized
NOTIFY pgrst, 'reload schema';
