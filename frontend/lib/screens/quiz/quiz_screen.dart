import 'package:flutter/material.dart';

import '../../models/student_snapshot.dart';
import '../../services/api_client.dart';
import '../../services/autonomous_intelligence_service.dart';
import '../../theme/calm_theme.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.api,
    required this.userId,
    required this.data,
    required this.onChanged,
  });

  final ApiClient api;
  final int userId;
  final StudentSnapshot data;
  final VoidCallback onChanged;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final selected = <int, int>{};
  final startedAt = DateTime.now();
  List<dynamic> questions = [];
  Map<String, dynamic>? result;
  bool loading = true;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  @override
  Widget build(BuildContext context) {
    final answered = selected.length;
    final total = questions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionIntro(
          icon: Icons.quiz_rounded,
          title: 'Adaptive Quiz Engine',
          subtitle: 'Questions come from your saved notes and update future AI behavior automatically.',
          mascot: StudentMascot(size: 100, mood: MascotMood.celebrate),
        ),
        const SizedBox(height: 16),
        SoftCard(
          child: loading
              ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              : questions.isEmpty
                  ? Column(
                      children: [
                        const EmptyCalmState(
                          icon: Icons.quiz_rounded,
                          title: 'No generated questions yet',
                          message: 'Upload or paste a note in Library, then ExamAI will generate MCQs and flashcards automatically.',
                        ),
                        const SizedBox(height: 12),
                        SecondaryCalmButton(label: 'Refresh quiz', icon: Icons.refresh_rounded, onTap: _loadQuiz),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: total == 0 ? 0 : answered / total,
                                color: CalmTheme.teal,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('$answered/$total', style: const TextStyle(fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const SizedBox(height: 18),
                        for (var i = 0; i < questions.length; i++) _QuestionBlock(
                          index: i,
                          question: questions[i] as Map,
                          selected: selected[i],
                          locked: result != null || submitting,
                          review: _reviewFor(questions[i] as Map),
                          onSelected: (value) => setState(() => selected[i] = value),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            PrimaryCalmButton(
                              label: result == null ? (submitting ? 'Submitting...' : 'Submit Quiz') : 'Try New Quiz',
                              icon: result == null ? Icons.check_rounded : Icons.refresh_rounded,
                              onTap: submitting ? null : (result == null ? _submit : _resetQuiz),
                              compact: true,
                            ),
                            if (result != null)
                              SecondaryCalmButton(
                                label: 'Show Coaching',
                                icon: Icons.psychology_rounded,
                                onTap: _showCoaching,
                              ),
                          ],
                        ),
                      ],
                    ),
        ),
      ],
    );
  }

  Map<String, dynamic>? _reviewFor(Map question) {
    final rows = (result?['review'] as List?) ?? [];
    for (final row in rows) {
      final map = row as Map;
      if (map['question_id'] == question['id']) return Map<String, dynamic>.from(map);
    }
    return null;
  }

  Future<void> _loadQuiz() async {
    setState(() {
      loading = true;
      result = null;
      selected.clear();
    });
    try {
      final response = await widget.api.startQuiz(widget.userId, limit: 10);
      if (!mounted) return;
      setState(() => questions = List<dynamic>.from(response['questions'] as List? ?? []));
    } catch (e) {
      if (mounted) toast(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _resetQuiz() async {
    await _loadQuiz();
  }

  Future<void> _submit() async {
    if (questions.isEmpty) return;
    if (selected.length < questions.length) {
      toast(context, 'Answer all questions before submitting.');
      return;
    }
    setState(() => submitting = true);
    final seconds = DateTime.now().difference(startedAt).inSeconds;
    final answers = <Map<String, dynamic>>[
      for (var i = 0; i < questions.length; i++)
        {
          'question_id': (questions[i] as Map)['id'],
          'selected_index': selected[i],
        },
    ];

    try {
      final response = await widget.api.submitQuiz(widget.userId, answers, secondsUsed: seconds);
      final weak = (response['weak_topics'] as List?)?.map((x) => x.toString()).toList() ?? <String>[];
      final adaptive = AutonomousIntelligenceService(api: widget.api, userId: widget.userId);
      await adaptive.recordQuizResult(
        topic: weak.isNotEmpty ? weak.first : widget.data.weakTopic,
        correct: weak.isEmpty,
        confidence: weak.isEmpty ? 0.82 : 0.34,
        difficulty: 'medium',
        seconds: seconds,
        gapType: weak.isEmpty ? 'recall' : 'conceptual',
      );
      widget.onChanged();
      if (!mounted) return;
      setState(() => result = response);
      _showCoaching();
    } catch (e) {
      if (mounted) toast(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  void _showCoaching() {
    final data = result;
    if (data == null) return;
    showFeatureSheet(
      context,
      'Quiz Complete',
      '''
Score: ${data['score']}/${data['total']} (${data['percent']}%)

Coach:
${data['coach_message']}

Weak Topics:
${((data['weak_topics'] as List?) ?? []).isEmpty ? 'No weak topic detected in this quiz.' : ((data['weak_topics'] as List?) ?? []).join(', ')}
''',
    );
  }
}

class _QuestionBlock extends StatelessWidget {
  const _QuestionBlock({
    required this.index,
    required this.question,
    required this.selected,
    required this.locked,
    required this.review,
    required this.onSelected,
  });

  final int index;
  final Map question;
  final int? selected;
  final bool locked;
  final Map<String, dynamic>? review;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = (question['options'] as List? ?? []).map((x) => x.toString()).toList();
    final isCorrect = review?['correct'] == true;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: review == null ? dividerColor(context) : (isCorrect ? CalmTheme.green : CalmTheme.rose)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Question ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w900, color: CalmTheme.teal)),
          const SizedBox(height: 8),
          Text(question['question']?.toString() ?? 'Question', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (var i = 0; i < options.length; i++)
            RadioListTile<int>(
              dense: true,
              value: i,
              groupValue: selected,
              onChanged: locked ? null : (value) => onSelected(value ?? i),
              title: Text(options[i]),
            ),
          if (review != null) ...[
            const SizedBox(height: 8),
            Text(
              isCorrect ? 'Correct' : 'Review this',
              style: TextStyle(fontWeight: FontWeight.w900, color: isCorrect ? CalmTheme.green : CalmTheme.rose),
            ),
            const SizedBox(height: 4),
            Text(review!['explanation']?.toString() ?? ''),
          ],
        ],
      ),
    );
  }
}
