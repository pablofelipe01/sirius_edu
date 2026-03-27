enum AssignmentStatus { pending, submitted, aiEvaluated, fullyEvaluated }

class Assignment {
  final String id;
  final String? lessonId;
  final String? studentId;
  final String description;
  final DateTime? deadline;
  final AssignmentStatus status;

  Assignment({
    required this.id,
    this.lessonId,
    this.studentId,
    required this.description,
    this.deadline,
    this.status = AssignmentStatus.pending,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'lesson_id': lessonId,
    'student_id': studentId,
    'description': description,
    'deadline': deadline?.toIso8601String(),
    'status': status.name,
  };

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
    id: json['id'] as String,
    lessonId: json['lesson_id'] as String?,
    studentId: json['student_id'] as String?,
    description: json['description'] as String,
    deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
    status: AssignmentStatus.values.firstWhere(
      (e) => e.name == (json['status'] as String? ?? 'pending'),
      orElse: () => AssignmentStatus.pending,
    ),
  );
}
