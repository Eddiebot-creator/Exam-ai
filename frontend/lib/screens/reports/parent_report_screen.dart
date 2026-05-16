
import 'package:flutter/material.dart';

class ParentReportScreen extends StatelessWidget {
  const ParentReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        Text('Weekly Progress Report', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Card(child: ListTile(title: Text('Share with parent'), subtitle: Text('Support without pressure'))),
        Card(child: ListTile(title: Text('Readiness'), subtitle: Text('Shows improvement and weak topics'))),
      ],
    );
  }
}
