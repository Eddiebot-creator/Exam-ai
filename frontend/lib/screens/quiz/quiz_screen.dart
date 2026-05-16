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
  int selected = -1;
  int score = 0;

  final question =
      'Which technique helps solve recursive problems?';

  final options = const [
    'Memorizing syntax only',
    'Breaking problems into smaller repeated cases',
    'Ignoring base cases',
    'Using only loops',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionIntro(
          icon: Icons.quiz_rounded,
          title: 'Adaptive Quiz Engine',
          subtitle:
              'Quiz results now affect future AI behavior automatically.',
          mascot: StudentMascot(
            size: 100,
            mood: MascotMood.celebrate,
          ),
        ),
        const SizedBox(height: 16),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: .35,
                      color: CalmTheme.teal,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '03:00',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                question,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              for (var i = 0; i < options.length; i++)
                RadioListTile<int>(
                  value: i,
                  groupValue: selected,
                  onChanged: (v) {
                    setState(() {
                      selected = v ?? -1;
                    });
                  },
                  title: Text(options[i]),
                ),

              const SizedBox(height: 10),

              PrimaryCalmButton(
                label: 'Submit Answer',
                icon: Icons.check_rounded,
                onTap: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final correct = selected == 1;

    setState(() {
      score = correct ? 100 : 0;
    });

    try {
      final adaptive =
          AutonomousIntelligenceService(
        api: widget.api,
        userId: widget.userId,
      );

      final update =
          await adaptive.recordQuizResult(
        topic: widget.data.weakTopic,
        correct: correct,
        confidence: correct ? 0.8 : 0.25,
        difficulty: 'medium',
        seconds: 180,
        gapType:
            correct ? 'recall' : 'conceptual',
      );

      widget.onChanged();

      if (!mounted) return;

      showFeatureSheet(
        context,
        correct
            ? 'Correct!'
            : 'Review Needed',
        '''
Adaptive Intelligence Updated

Readiness:
${update['readiness']}%

Next Difficulty:
${update['next_difficulty']}

Emotional Tone:
${update['emotional_tone']}

Recommended Room:
${update['recommended_room']}

Next Review:
${update['next_review_at']}

AI Explanation:
Recursion works by breaking a problem into smaller repeated cases while stopping at a base case.
''',
      );
    } catch (e) {
      if (!mounted) return;

      toast(
        context,
        'Adaptive update failed: $e',
      );
    }
  }
}