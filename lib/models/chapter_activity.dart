import 'dart:convert';

enum ActivityType { mission, test }

class ChapterActivity {
  final String id;
  final String lessonId;
  final int chapterNumber;
  final int activityNumber;
  final ActivityType type;
  final Map<String, dynamic> data;

  ChapterActivity({
    required this.id,
    required this.lessonId,
    required this.chapterNumber,
    required this.activityNumber,
    required this.type,
    required this.data,
  });

  // For test: data has "question", "options" (list), "correct_answer"
  // Mesh format uses short keys: q, a, b, c, d, r
  String? get testQuestion => data['question'] ?? data['q'];
  String? get correctAnswer => data['correct_answer'] ?? data['r'];

  List<Map<String, String>> get testOptions {
    if (data.containsKey('options')) {
      return (data['options'] as List).map((o) => Map<String, String>.from(o as Map)).toList();
    }
    // Short mesh format: a, b, c, d
    final opts = <Map<String, String>>[];
    for (final label in ['a', 'b', 'c', 'd']) {
      if (data.containsKey(label)) {
        final text = data[label] as String;
        // Remove "A) " prefix if present
        final cleanText = text.startsWith('${label.toUpperCase()}) ') ? text.substring(3) : text;
        opts.add({'label': label.toUpperCase(), 'text': cleanText});
      }
    }
    return opts;
  }

  // Title (from data or fallback)
  String get title => data['title'] as String? ?? (type == ActivityType.test ? 'Test' : 'Mision');

  // For mission: data has "description", "instructions"
  // Mesh format uses short keys: d, i
  String? get missionDescription => data['description'] ?? data['d'];
  String? get missionInstructions => data['instructions'] ?? data['i'];

  /// Parse from mesh message: ACTIVIDAD|lesson_id|ch_num|act_num|type|activity_id|data_json
  factory ChapterActivity.fromMeshMessage(String text) {
    final parts = text.split('|');
    final dataJson = parts.length > 6 ? parts.sublist(6).join('|') : '{}';
    return ChapterActivity(
      id: parts.length > 5 ? parts[5] : '',
      lessonId: parts[1],
      chapterNumber: int.tryParse(parts[2]) ?? 0,
      activityNumber: int.tryParse(parts[3]) ?? 0,
      type: parts[4] == 'test' ? ActivityType.test : ActivityType.mission,
      data: _parseJson(dataJson),
    );
  }

  static Map<String, dynamic> _parseJson(String text) {
    try {
      return json.decode(text) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
