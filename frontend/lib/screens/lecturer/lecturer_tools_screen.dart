
import 'package:flutter/material.dart';

class LecturerToolsScreen extends StatelessWidget {
  const LecturerToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        Text('Lecturer Tools', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Card(child: ListTile(title: Text('Upload slides'), subtitle: Text('Generate MCQs, summaries, and flashcards'))),
        Card(child: ListTile(title: Text('Course code'), subtitle: Text('Students join lecturer content'))),
        Card(child: ListTile(title: Text('Class insights'), subtitle: Text('Anonymized weak-area analytics'))),
      ],
    );
  }
}
