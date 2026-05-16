
import 'package:flutter/material.dart';

class OfflineFirstScreen extends StatelessWidget {
  const OfflineFirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        Text('Offline First', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Card(child: ListTile(title: Text('Cached notes'), subtitle: Text('Study without internet.'))),
        Card(child: ListTile(title: Text('Offline quizzes'), subtitle: Text('Answers sync when connected.'))),
        Card(child: ListTile(title: Text('Sync queue'), subtitle: Text('Stores actions until network returns.'))),
      ],
    );
  }
}
