import 'package:flutter/material.dart';
import '../../widgets/premium_card.dart';

class CameraStudyScreen extends StatelessWidget {
  const CameraStudyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('CameraStudyScreen'),
      padding: const EdgeInsets.all(24),
      children: [
        PremiumCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Smart Camera Study Mode', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Scan textbooks, handwritten notes and whiteboards, then explain or quiz instantly.'),
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.auto_awesome_rounded), label: const Text('Open')),
          ]),
        ),
      ],
    );
  }
}
