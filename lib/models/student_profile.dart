class StudentProfile {
  final String id;
  final String name;
  final String grade;
  final int nodeId;
  final List<String> teacherNotes;
  final Map<String, String> levelBySubject;
  final List<String> recentConversationSummary;
  final int assignmentsCompletedThisWeek;
  final int assignmentsTotalThisWeek;
  final int aiQuestionsThisWeek;
  final String? teacherMessageToParent;

  StudentProfile({
    required this.id,
    required this.name,
    required this.grade,
    required this.nodeId,
    this.teacherNotes = const [],
    this.levelBySubject = const {},
    this.recentConversationSummary = const [],
    this.assignmentsCompletedThisWeek = 0,
    this.assignmentsTotalThisWeek = 0,
    this.aiQuestionsThisWeek = 0,
    this.teacherMessageToParent,
  });

  StudentProfile copyWith({
    String? id,
    String? name,
    String? grade,
    int? nodeId,
    List<String>? teacherNotes,
    Map<String, String>? levelBySubject,
    List<String>? recentConversationSummary,
    int? assignmentsCompletedThisWeek,
    int? assignmentsTotalThisWeek,
    int? aiQuestionsThisWeek,
    String? teacherMessageToParent,
  }) {
    return StudentProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      nodeId: nodeId ?? this.nodeId,
      teacherNotes: teacherNotes ?? this.teacherNotes,
      levelBySubject: levelBySubject ?? this.levelBySubject,
      recentConversationSummary: recentConversationSummary ?? this.recentConversationSummary,
      assignmentsCompletedThisWeek: assignmentsCompletedThisWeek ?? this.assignmentsCompletedThisWeek,
      assignmentsTotalThisWeek: assignmentsTotalThisWeek ?? this.assignmentsTotalThisWeek,
      aiQuestionsThisWeek: aiQuestionsThisWeek ?? this.aiQuestionsThisWeek,
      teacherMessageToParent: teacherMessageToParent ?? this.teacherMessageToParent,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'grade': grade,
    'node_id': nodeId,
    'teacher_notes': teacherNotes,
    'level_by_subject': levelBySubject,
    'recent_conversation_summary': recentConversationSummary,
    'assignments_completed_this_week': assignmentsCompletedThisWeek,
    'assignments_total_this_week': assignmentsTotalThisWeek,
    'ai_questions_this_week': aiQuestionsThisWeek,
    'teacher_message_to_parent': teacherMessageToParent,
  };

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    grade: json['grade'] as String,
    nodeId: json['node_id'] as int,
    teacherNotes: (json['teacher_notes'] as List?)?.cast<String>() ?? [],
    levelBySubject: (json['level_by_subject'] as Map?)?.cast<String, String>() ?? {},
    recentConversationSummary: (json['recent_conversation_summary'] as List?)?.cast<String>() ?? [],
    assignmentsCompletedThisWeek: json['assignments_completed_this_week'] as int? ?? 0,
    assignmentsTotalThisWeek: json['assignments_total_this_week'] as int? ?? 0,
    aiQuestionsThisWeek: json['ai_questions_this_week'] as int? ?? 0,
    teacherMessageToParent: json['teacher_message_to_parent'] as String?,
  );
}
