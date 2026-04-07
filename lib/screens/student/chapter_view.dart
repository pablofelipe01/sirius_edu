import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import '../../models/lesson_chapter.dart';
import '../../models/chapter_activity.dart';
import '../../services/meshtastic_service.dart';

class ChapterView extends StatefulWidget {
  final MeshtasticService meshService;
  final Lesson lesson;
  final String studentName;

  const ChapterView({super.key, required this.meshService, required this.lesson, required this.studentName});

  @override
  State<ChapterView> createState() => _ChapterViewState();
}

class _ChapterViewState extends State<ChapterView> {
  int _currentChapter = 1;
  bool _loadingChapter = false;
  bool _loadingActivities = false;
  LessonChapter? _chapter;
  List<ChapterActivity> _activities = [];
  final Map<int, LessonChapter> _cachedChapters = {};
  final Map<int, List<ChapterActivity>> _cachedActivities = {};

  // Activity state
  final Map<String, String> _testAnswers = {};
  final Map<String, bool> _testResults = {};
  final Map<String, String> _missionResponses = {};
  final Map<String, bool> _missionSubmitted = {};
  final Map<String, Map<String, dynamic>> _missionEvaluations = {};

  StreamSubscription? _chapterSub;
  StreamSubscription? _activitySub;
  StreamSubscription? _syncSub;
  StreamSubscription? _evalSub;

  @override
  void initState() {
    super.initState();
    _chapterSub = widget.meshService.chapterStream.listen((ch) {
      if (ch.lessonId != widget.lesson.id) return;
      _cachedChapters[ch.chapterNumber] = ch;
      if (ch.chapterNumber == _currentChapter && mounted) {
        setState(() {
          _chapter = ch;
          _loadingChapter = false;
        });
        _requestActivities(_currentChapter);
      }
    });

    _activitySub = widget.meshService.activityStream.listen((act) {
      if (act.lessonId != widget.lesson.id || act.chapterNumber != _currentChapter) return;
      if (mounted) {
        setState(() {
          final existing = _activities.indexWhere((a) => a.activityNumber == act.activityNumber);
          if (existing >= 0) {
            _activities[existing] = act;
          } else {
            _activities.add(act);
            _activities.sort((a, b) => a.activityNumber.compareTo(b.activityNumber));
          }
        });
      }
    });

    _syncSub = widget.meshService.syncStatusStream.listen((status) {
      if (status.startsWith('SYNC_END|activities') && mounted) {
        _cachedActivities[_currentChapter] = List.from(_activities);
        setState(() => _loadingActivities = false);
      }
    });

    _evalSub = widget.meshService.evaluationStream.listen((eval) {
      if (mounted) {
        setState(() {
          _missionEvaluations[eval['assignment_id'] ?? ''] = eval;
        });
      }
    });

    _requestChapter(1);
  }

  @override
  void dispose() {
    _chapterSub?.cancel();
    _activitySub?.cancel();
    _syncSub?.cancel();
    _evalSub?.cancel();
    super.dispose();
  }

  void _requestChapter(int num) {
    if (_cachedChapters.containsKey(num)) {
      setState(() {
        _currentChapter = num;
        _chapter = _cachedChapters[num];
        _activities = _cachedActivities[num] ?? [];
        _loadingChapter = false;
      });
      if (!_cachedActivities.containsKey(num)) {
        _requestActivities(num);
      }
      return;
    }
    setState(() {
      _currentChapter = num;
      _chapter = null;
      _activities = [];
      _loadingChapter = true;
    });
    widget.meshService.requestChapter(widget.lesson.id, num);
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && _loadingChapter) setState(() => _loadingChapter = false);
    });
  }

  void _requestActivities(int num) {
    setState(() => _loadingActivities = true);
    widget.meshService.requestActivities(widget.lesson.id, num);
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && _loadingActivities) setState(() => _loadingActivities = false);
    });
  }

  bool get _allActivitiesComplete {
    if (_activities.isEmpty) return true;
    for (final act in _activities) {
      if (act.type == ActivityType.test && !_testResults.containsKey(act.id)) return false;
      if (act.type == ActivityType.mission && !_missionSubmitted.containsKey(act.id)) return false;
    }
    return true;
  }

  int get _totalChapters => widget.lesson.totalChapters > 0 ? widget.lesson.totalChapters : 1;

  void _checkTest(ChapterActivity act, String answer) {
    setState(() {
      _testAnswers[act.id] = answer;
      _testResults[act.id] = answer == act.correctAnswer;
    });
    widget.meshService.submitTestAnswer(act.id, widget.studentName, answer);
    _maybeReportProgress();
  }

  void _submitMission(ChapterActivity act, String response) {
    setState(() => _missionSubmitted[act.id] = true);
    widget.meshService.sendSubmission(act.id, widget.studentName, response);
    _maybeReportProgress();
  }

  void _maybeReportProgress() {
    if (_allActivitiesComplete) {
      widget.meshService.reportProgress(widget.lesson.id, _currentChapter, _activities.length);
    }
  }

  void _openAIChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _AIQuestionSheet(
        meshService: widget.meshService,
        studentName: widget.studentName,
        lessonId: widget.lesson.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title, style: const TextStyle(fontSize: 15)),
        backgroundColor: const Color(0xFF27AE60),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _openAIChat,
        backgroundColor: const Color(0xFF2980B9),
        child: const Icon(Icons.question_answer, color: Colors.white, size: 20),
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: _currentChapter / _totalChapters,
            backgroundColor: Colors.grey.shade200,
            color: const Color(0xFF27AE60),
            minHeight: 4,
          ),

          // Chapter indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27AE60).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Capitulo $_currentChapter de $_totalChapters',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF27AE60))),
                ),
                const Spacer(),
                if (_loadingChapter || _loadingActivities)
                  const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF27AE60))),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _loadingChapter
                ? const Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF27AE60)),
                      SizedBox(height: 16),
                      Text('Recibiendo capitulo...', style: TextStyle(color: Color(0xFF95A5A6))),
                    ],
                  ))
                : _chapter == null
                    ? Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.signal_wifi_off, size: 48, color: Color(0xFFBDC3C7)),
                          const SizedBox(height: 12),
                          const Text('No se pudo recibir el capitulo', style: TextStyle(color: Color(0xFF7F8C8D))),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => _requestChapter(_currentChapter),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Chapter title
                            Text(_chapter!.title,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                            const SizedBox(height: 16),

                            // Chapter content
                            Text(_chapter!.content,
                                style: const TextStyle(fontSize: 16, height: 1.7, color: Color(0xFF2C3E50))),

                            // Activities
                            if (_activities.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 8),
                              const Text('Actividades',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
                              const SizedBox(height: 12),
                              ..._activities.map((act) => _buildActivity(act)),
                            ],

                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
          ),

          // Navigation bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                if (_currentChapter > 1)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _requestChapter(_currentChapter - 1),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Anterior'),
                    ),
                  ),
                if (_currentChapter > 1 && _currentChapter < _totalChapters)
                  const SizedBox(width: 12),
                if (_currentChapter < _totalChapters)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _allActivitiesComplete ? () => _requestChapter(_currentChapter + 1) : null,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: Text(_allActivitiesComplete ? 'Siguiente' : 'Completa las actividades'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AE60)),
                    ),
                  ),
                if (_currentChapter == _totalChapters)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _allActivitiesComplete ? () => Navigator.of(context).pop() : null,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Completar leccion'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AE60)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivity(ChapterActivity act) {
    if (act.type == ActivityType.test) {
      return _buildTest(act);
    } else {
      return _buildMission(act);
    }
  }

  Widget _buildTest(ChapterActivity act) {
    final answered = _testResults.containsKey(act.id);
    final correct = _testResults[act.id] ?? false;
    final selected = _testAnswers[act.id];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: answered ? (correct ? const Color(0xFFE8F5E9) : const Color(0xFFFCE4EC)) : const Color(0xFFF3E5F5).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: answered ? (correct ? const Color(0xFF27AE60) : const Color(0xFFE74C3C)) : const Color(0xFF9B59B6).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.quiz, size: 18, color: Color(0xFF9B59B6)),
              const SizedBox(width: 8),
              Expanded(child: Text(act.testQuestion ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
            ],
          ),
          const SizedBox(height: 12),
          ...act.testOptions.map((opt) {
            final label = opt['label'] ?? '';
            final isSelected = selected == label;
            final isCorrectAnswer = label == act.correctAnswer;

            Color? optColor;
            if (answered) {
              if (isCorrectAnswer) {
                optColor = const Color(0xFF27AE60);
              } else if (isSelected && !correct) {
                optColor = const Color(0xFFE74C3C);
              }
            }

            return GestureDetector(
              onTap: answered ? null : () => _checkTest(act, label),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? (optColor ?? const Color(0xFF9B59B6)).withValues(alpha: 0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: optColor ?? (isSelected ? const Color(0xFF9B59B6) : Colors.grey.shade300)),
                ),
                child: Row(
                  children: [
                    Text('$label)', style: TextStyle(fontWeight: FontWeight.bold, color: optColor ?? const Color(0xFF2C3E50))),
                    const SizedBox(width: 8),
                    Expanded(child: Text(opt['text'] ?? '', style: TextStyle(color: optColor ?? const Color(0xFF2C3E50)))),
                    if (answered && isCorrectAnswer)
                      const Icon(Icons.check_circle, color: Color(0xFF27AE60), size: 20),
                    if (answered && isSelected && !correct)
                      const Icon(Icons.cancel, color: Color(0xFFE74C3C), size: 20),
                  ],
                ),
              ),
            );
          }),
          if (answered)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(correct ? 'Correcto!' : 'La respuesta correcta es ${act.correctAnswer}',
                  style: TextStyle(fontWeight: FontWeight.w500, color: correct ? const Color(0xFF27AE60) : const Color(0xFFE74C3C))),
            ),
        ],
      ),
    );
  }

  Widget _buildMission(ChapterActivity act) {
    final submitted = _missionSubmitted[act.id] ?? false;
    final evaluation = _missionEvaluations[act.id];
    final controller = TextEditingController(text: _missionResponses[act.id] ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: submitted ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: submitted ? const Color(0xFF27AE60) : const Color(0xFFE67E22).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag, size: 18, color: Color(0xFFE67E22)),
              const SizedBox(width: 8),
              Expanded(child: Text(act.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
            ],
          ),
          const SizedBox(height: 8),
          if (act.missionDescription != null)
            Text(act.missionDescription!, style: const TextStyle(fontSize: 14, color: Color(0xFF2C3E50))),
          if (act.missionInstructions != null) ...[
            const SizedBox(height: 8),
            Text(act.missionInstructions!, style: const TextStyle(fontSize: 13, color: Color(0xFF7F8C8D), height: 1.5)),
          ],

          if (evaluation != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nota: ${evaluation['score']}/10', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF27AE60))),
                  const SizedBox(height: 4),
                  Text(evaluation['feedback'] ?? '', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ] else if (submitted) ...[
            const SizedBox(height: 12),
            const Row(
              children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE67E22))),
                SizedBox(width: 8),
                Text('Enviado. Esperando evaluacion...', style: TextStyle(color: Color(0xFF95A5A6), fontSize: 13)),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              onChanged: (v) => _missionResponses[act.id] = v,
              decoration: InputDecoration(
                hintText: 'Escribe tu respuesta...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true, fillColor: Colors.white,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final resp = controller.text.trim();
                  if (resp.isEmpty) return;
                  _submitMission(act, resp);
                },
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Enviar respuesta'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE67E22)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom sheet para preguntar a la IA o al profesor
class _AIQuestionSheet extends StatefulWidget {
  final MeshtasticService meshService;
  final String studentName;
  final String lessonId;

  const _AIQuestionSheet({required this.meshService, required this.studentName, required this.lessonId});

  @override
  State<_AIQuestionSheet> createState() => _AIQuestionSheetState();
}

class _AIQuestionSheetState extends State<_AIQuestionSheet> {
  final _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _waiting = false;
  StreamSubscription? _aiSub;

  @override
  void initState() {
    super.initState();
    _aiSub = widget.meshService.aiResponseStream.listen((data) {
      if (mounted) {
        setState(() {
          _waiting = false;
          _messages.add({'role': 'ai', 'text': data['response'] ?? ''});
        });
      }
    });
  }

  @override
  void dispose() {
    _aiSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _askAI() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _waiting = true;
    });
    widget.meshService.sendAIQuestion(widget.studentName, widget.lessonId, text);
    _controller.clear();
  }

  void _askTeacher() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': '(Al profesor) $text'});
    });
    widget.meshService.sendQuestionToTeacher(widget.studentName, text);
    _controller.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pregunta enviada al profesor'), backgroundColor: Color(0xFF2980B9)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(Icons.question_answer, color: Color(0xFF2980B9)),
              SizedBox(width: 8),
              Text('Preguntar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),

          if (_messages.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _messages.length + (_waiting ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == _messages.length) {
                    return const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Pensando...', style: TextStyle(color: Color(0xFF95A5A6), fontStyle: FontStyle.italic)),
                    );
                  }
                  final m = _messages[i];
                  final isUser = m['role'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                      decoration: BoxDecoration(
                        color: isUser ? const Color(0xFFDCF8C6) : const Color(0xFFE8F4FD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(m['text'] ?? '', style: const TextStyle(fontSize: 14)),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Tu pregunta...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onSubmitted: (_) => _askAI(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _waiting ? null : _askAI,
                icon: const Icon(Icons.smart_toy, color: Color(0xFF27AE60)),
                tooltip: 'Preguntar a la IA',
              ),
              IconButton(
                onPressed: _askTeacher,
                icon: const Icon(Icons.person, color: Color(0xFF2980B9)),
                tooltip: 'Preguntar al profesor',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
