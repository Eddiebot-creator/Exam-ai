
import 'package:flutter/material.dart';
import '../../services/intelligence_api.dart';

class ExamCountdownDashboard extends StatefulWidget {
  const ExamCountdownDashboard({super.key, required this.api});
  final IntelligenceApi api;

  @override
  State<ExamCountdownDashboard> createState() => _ExamCountdownDashboardState();
}

class _ExamCountdownDashboardState extends State<ExamCountdownDashboard> {
  Map<String, dynamic>? mission;

  @override
  void initState() {
    super.initState();
    widget.api.getDailyMission(1).then((value) => setState(() => mission = value));
  }

  @override
  Widget build(BuildContext context) {
    final data = mission;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Exam Mission', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (data == null)
          const Center(child: CircularProgressIndicator())
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data['title'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${data['course']} • ${data['days_left']} days left • ${data['readiness']}% ready'),
                const SizedBox(height: 16),
                ...(data['tasks'] as List).map((task) => ListTile(leading: const Icon(Icons.check_circle_outline), title: Text(task.toString()))),
              ]),
            ),
          ),
      ],
    );
  }
}
