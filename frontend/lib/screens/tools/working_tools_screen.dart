
import 'package:flutter/material.dart';
import '../../services/intelligence_api.dart';

class WorkingToolsScreen extends StatefulWidget {
  const WorkingToolsScreen({super.key, required this.api});
  final IntelligenceApi api;

  @override
  State<WorkingToolsScreen> createState() => _WorkingToolsScreenState();
}

class _WorkingToolsScreenState extends State<WorkingToolsScreen> {
  String output = 'Choose a tool to run.';

  Future<void> runTimetable() async {
    final data = await widget.api.generateTimetable(1, [
      {'course': 'CSC301', 'topics': ['Recursion', 'Trees', 'Graphs']},
      {'course': 'SEN407', 'topics': ['Quality', 'Standards', 'Compliance']},
    ]);
    setState(() => output = data.toString());
  }

  Future<void> runGpa() async {
    final data = await widget.api.calculateGpa([
      {'course': 'CSC301', 'units': 3, 'score': 72},
      {'course': 'SEN407', 'units': 2, 'score': 65},
    ]);
    setState(() => output = data.toString());
  }

  Future<void> runExamCountdown() async {
    final data = await widget.api.examCountdown(1);
    setState(() => output = data.toString());
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Working Study Tools', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('These cards call the backend and return real results.'),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            FilledButton(onPressed: runTimetable, child: const Text('Generate timetable')),
            FilledButton(onPressed: runGpa, child: const Text('Calculate GPA')),
            FilledButton(onPressed: runExamCountdown, child: const Text('Exam countdown')),
          ],
        ),
        const SizedBox(height: 24),
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Text(output))),
      ],
    );
  }
}
