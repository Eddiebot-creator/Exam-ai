import 'package:flutter/material.dart';
import '../../widgets/premium_card.dart';

class VoiceTutorScreen extends StatelessWidget {
  const VoiceTutorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('VoiceTutorScreen'),
      padding: const EdgeInsets.all(24),
      children: [
        PremiumCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Full AI Voice Mode', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Talk naturally, hear spoken answers, and study hands-free.'),
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.auto_awesome_rounded), label: const Text('Open')),
          ]),
        ),
      ],
    );
  }
}
