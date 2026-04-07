import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import '../../services/meshtastic_service.dart';
import 'chapter_view.dart';

class LessonScreen extends StatefulWidget {
  final MeshtasticService meshService;
  final String studentName;
  const LessonScreen({super.key, required this.meshService, required this.studentName});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  bool _syncing = false;
  StreamSubscription? _syncSub;

  @override
  void initState() {
    super.initState();
    _syncSub = widget.meshService.syncStatusStream.listen((status) {
      if (status == 'SYNC_END|lessons' && mounted) {
        setState(() => _syncing = false);
      }
    });
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    super.dispose();
  }

  void _requestLessons() {
    if (!widget.meshService.isConnected || _syncing) return;
    setState(() => _syncing = true);
    widget.meshService.requestSync('lessons');
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && _syncing) setState(() => _syncing = false);
    });
  }

  void _openLesson(Lesson lesson) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChapterView(
          meshService: widget.meshService,
          lesson: lesson,
          studentName: widget.studentName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.meshService,
      builder: (context, _) {
        final lessons = widget.meshService.lessons;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  const Text('Lecciones',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
                  const Spacer(),
                  if (_syncing)
                    const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF27AE60)))
                  else
                    IconButton(
                      onPressed: _requestLessons,
                      icon: const Icon(Icons.refresh, color: Color(0xFF27AE60)),
                      tooltip: 'Buscar lecciones',
                    ),
                ],
              ),
            ),
            Expanded(
              child: lessons.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book, size: 80, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            const Text('No hay lecciones',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF7F8C8D))),
                            const SizedBox(height: 8),
                            Text(_syncing ? 'Buscando lecciones...' : 'Pide tus lecciones al gateway',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14, color: Color(0xFF95A5A6))),
                            const SizedBox(height: 24),
                            if (!_syncing)
                              OutlinedButton.icon(
                                onPressed: _requestLessons,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Buscar lecciones'),
                              ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: lessons.length,
                      itemBuilder: (context, index) {
                        final lesson = lessons[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _openLesson(lesson),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF27AE60).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.menu_book, color: Color(0xFF27AE60), size: 28),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(lesson.title,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
                                        const SizedBox(height: 4),
                                        Text(lesson.summary,
                                            maxLines: 2, overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 13, color: Color(0xFF7F8C8D))),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(Icons.school, size: 14, color: Colors.grey.shade400),
                                            const SizedBox(width: 4),
                                            Text('${lesson.subject} - Grado ${lesson.grade}',
                                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                            const Spacer(),
                                            if (lesson.totalChapters > 0)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF2980B9).withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text('${lesson.totalChapters} capitulos',
                                                    style: const TextStyle(fontSize: 11, color: Color(0xFF2980B9), fontWeight: FontWeight.w500)),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Color(0xFFBDC3C7)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

