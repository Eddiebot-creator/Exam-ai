import 'package:flutter/material.dart';
import '../../widgets/premium_card.dart';

class ExamPredictorScreen extends StatelessWidget {
  const ExamPredictorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('ExamPredictorScreen'),
      padding: const EdgeInsets.all(24),
      children: [
        PremiumCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI Exam Prediction Engine', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Predict likely topics, readiness score, pass probability and urgent weak areas.'),
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.auto_awesome_rounded), label: const Text('Open')),
          ]),
        ),
      ],
    );
  }
}
