class Lesson {
  final String id;
  final String subject;
  final String grade;
  final String title;
  final String summary;
  final String fullContent;
  final int totalSteps; // legacy, use totalChapters
  final int totalChapters;
  final DateTime createdAt;
  final bool isActive;
  final List<String> assignmentIds;

  Lesson({
    required this.id,
    required this.subject,
    required this.grade,
    required this.title,
    required this.summary,
    this.fullContent = '',
    this.totalSteps = 0,
    this.totalChapters = 0,
    required this.createdAt,
    this.isActive = true,
    this.assignmentIds = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject': subject,
    'grade': grade,
    'title': title,
    'summary': summary,
    'full_content': fullContent,
    'total_steps': totalSteps,
    'total_chapters': totalChapters,
    'created_at': createdAt.toIso8601String(),
    'is_active': isActive,
    'assignment_ids': assignmentIds,
  };

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
    id: json['id'] as String,
    subject: json['subject'] as String,
    grade: json['grade'] as String,
    title: json['title'] as String,
    summary: json['summary'] as String,
    fullContent: json['full_content'] as String? ?? '',
    totalSteps: json['total_steps'] as int? ?? 0,
    totalChapters: json['total_chapters'] as int? ?? 0,
    createdAt: DateTime.parse(json['created_at'] as String),
    isActive: json['is_active'] as bool? ?? true,
    assignmentIds: (json['assignment_ids'] as List?)?.cast<String>() ?? [],
  );
}
