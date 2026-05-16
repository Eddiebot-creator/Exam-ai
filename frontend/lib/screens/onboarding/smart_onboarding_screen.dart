
import 'package:flutter/material.dart';

class SmartOnboardingScreen extends StatelessWidget {
  const SmartOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        Text('Let ExamAI know you', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Text('Ask only three things: what are you studying, when is your next exam, and what is your biggest struggle.'),
        SizedBox(height: 16),
        Card(child: ListTile(title: Text('Course'), subtitle: Text('Example: CSC301'))),
        Card(child: ListTile(title: Text('Exam date'), subtitle: Text('Build urgency and readiness'))),
        Card(child: ListTile(title: Text('Biggest struggle'), subtitle: Text('The app adapts immediately'))),
      ],
    );
  }
}
