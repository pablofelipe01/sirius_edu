import 'chapter_activity.dart';

class LessonChapter {
  final String lessonId;
  final int chapterNumber;
  final int totalChapters;
  final String title;
  final String content;
  final List<ChapterActivity> activities;

  LessonChapter({
    required this.lessonId,
    required this.chapterNumber,
    required this.totalChapters,
    required this.title,
    required this.content,
    this.activities = const [],
  });

  LessonChapter copyWith({List<ChapterActivity>? activities}) {
    return LessonChapter(
      lessonId: lessonId,
      chapterNumber: chapterNumber,
      totalChapters: totalChapters,
      title: title,
      content: content,
      activities: activities ?? this.activities,
    );
  }
}
