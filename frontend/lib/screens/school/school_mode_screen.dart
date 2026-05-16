import 'package:flutter/material.dart';
import '../../widgets/premium_card.dart';

class SchoolModeScreen extends StatelessWidget {
  const SchoolModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('SchoolModeScreen'),
      padding: const EdgeInsets.all(24),
      children: [
        PremiumCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('School / University Mode', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Institution dashboards, class analytics, uploaded materials and AI insights.'),
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.auto_awesome_rounded), label: const Text('Open')),
          ]),
        ),
      ],
    );
  }
}
