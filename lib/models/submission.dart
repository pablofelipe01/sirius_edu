class Submission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String response;
  final DateTime submittedAt;
  final String? aiFeedback;
  final double? aiScore;
  final String? teacherCriteria;
  final String? finalGrade;

  Submission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.response,
    required this.submittedAt,
    this.aiFeedback,
    this.aiScore,
    this.teacherCriteria,
    this.finalGrade,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'assignment_id': assignmentId,
    'student_id': studentId,
    'response': response,
    'submitted_at': submittedAt.toIso8601String(),
    'ai_feedback': aiFeedback,
    'ai_score': aiScore,
    'teacher_criteria': teacherCriteria,
    'final_grade': finalGrade,
  };

  factory Submission.fromJson(Map<String, dynamic> json) => Submission(
    id: json['id'] as String,
    assignmentId: json['assignment_id'] as String,
    studentId: json['student_id'] as String,
    response: json['response'] as String,
    submittedAt: DateTime.parse(json['submitted_at'] as String),
    aiFeedback: json['ai_feedback'] as String?,
    aiScore: (json['ai_score'] as num?)?.toDouble(),
    teacherCriteria: json['teacher_criteria'] as String?,
    finalGrade: json['final_grade'] as String?,
  );
}
