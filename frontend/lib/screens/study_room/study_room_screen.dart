import 'package:flutter/material.dart';
import '../../widgets/premium_card.dart';

class StudyRoomScreen extends StatelessWidget {
  const StudyRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('StudyRoomScreen'),
      padding: const EdgeInsets.all(24),
      children: [
        PremiumCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Real-Time Study Rooms', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Study together, solve quizzes live, share whiteboards, and let AI moderate.'),
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.auto_awesome_rounded), label: const Text('Open')),
          ]),
        ),
      ],
    );
  }
}
