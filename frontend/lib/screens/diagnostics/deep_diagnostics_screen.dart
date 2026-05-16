
import 'package:flutter/material.dart';

class DeepDiagnosticsScreen extends StatelessWidget {
  const DeepDiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        Text('Weak Area Diagnosis', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Card(child: ListTile(title: Text('Conceptual gap'), subtitle: Text('Student does not understand the idea yet'))),
        Card(child: ListTile(title: Text('Application gap'), subtitle: Text('Student understands but cannot apply'))),
        Card(child: ListTile(title: Text('Exam-format gap'), subtitle: Text('Student struggles with question style'))),
        Card(child: ListTile(title: Text('Recall gap'), subtitle: Text('Student needs spaced repetition'))),
      ],
    );
  }
}
