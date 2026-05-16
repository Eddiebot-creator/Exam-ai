import 'package:flutter/material.dart';

class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        Text('Analytics Dashboard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Card(child: ListTile(title: Text('Average Score'), subtitle: Text('Connect to /analytics/dashboard'))),
        Card(child: ListTile(title: Text('Weak Topics'), subtitle: Text('AI memory personalization'))),
        Card(child: ListTile(title: Text('Study Minutes'), subtitle: Text('Progress and streak tracking'))),
      ],
    );
  }
}
