export interface School {
  id: string; name: string; location: string; municipality: string; department: string; gateway_node_id: string;
}

export interface RosterUser {
  id: string; school_id: string; name: string; role: 'student' | 'teacher' | 'parent' | 'supervisor';
  grade: string; node_id: number | null; node_hex: string | null; pin: string | null;
  parent_of: string | null; is_active: boolean; created_at: string;
}

export interface Lesson {
  id: string; school_id: string; subject_code: string; grade: string; week_number: number;
  title: string; summary: string; content: string; objectives: string[];
  is_active: boolean; created_by: string | null; created_at: string;
}

export interface Assignment {
  id: string; lesson_id: string; school_id: string; grade: string; title: string;
  description: string; instructions: string; deadline: string | null;
  max_score: number; is_active: boolean; created_at: string;
  lessons?: { title: string; subject_code: string };
}

export interface Submission {
  id: string; assignment_id: string; student_id: string; response: string; submitted_at: string;
  ai_feedback: string | null; ai_score: number | null; ai_model: string | null;
  teacher_feedback: string | null; teacher_score: number | null; final_grade: string | null;
  roster?: { name: string; grade: string };
  assignments?: { title: string; description: string };
}

export interface AIConversation {
  id: string; student_id: string; question: string; ai_response: string; ai_model: string; created_at: string;
  roster?: { name: string; grade: string };
}

export interface StudentQuestion {
  id: string; student_id: string; question: string; context: string | null;
  teacher_response: string | null; responded_by: string | null; responded_at: string | null;
  is_read: boolean; created_at: string;
  roster?: { name: string; grade: string };
}

export interface ConnectionLog {
  id: string; student_id: string; connected_at: string; node_id: number;
}
