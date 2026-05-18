import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../theme/calm_theme.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';

class LecturerToolsScreen extends StatefulWidget {
  const LecturerToolsScreen({super.key, required this.api, required this.userName, required this.course});
  final ApiClient api;
  final String userName;
  final String course;

  @override
  State<LecturerToolsScreen> createState() => _LecturerToolsScreenState();
}

class _LecturerToolsScreenState extends State<LecturerToolsScreen> {
  Map<String, dynamic>? course;
  Map<String, dynamic>? insights;
  bool busy = false;

  @override
  Widget build(BuildContext context) => AnimatedSection(children: [
        const SectionIntro(icon: Icons.co_present_rounded, title: 'Lecturer And School Tools', subtitle: 'Turn uploaded materials into course codes, revision packs, and anonymized class-wide weak-area insight.', mascot: StudentMascot(size: 100, mood: MascotMood.wave)),
        const SizedBox(height: 16),
        const ResponsiveCalmGrid(minWidth: 230, children: [
          CalmMetric(title: 'Slides', value: 'Upload', subtitle: 'generate content', icon: Icons.upload_file_rounded, color: CalmTheme.teal),
          CalmMetric(title: 'Course code', value: 'Instant', subtitle: 'students join fast', icon: Icons.qr_code_rounded, color: CalmTheme.indigo),
          CalmMetric(title: 'Insights', value: 'Private', subtitle: 'anonymized only', icon: Icons.analytics_rounded, color: CalmTheme.green),
        ]),
        const SizedBox(height: 16),
        SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(course == null ? 'Create lecturer course' : course!['title']?.toString() ?? 'Course', style: Theme.of(context).textTheme.titleLarge)),
            PrimaryCalmButton(label: busy ? 'Working...' : 'Create course', icon: Icons.add_business_rounded, compact: true, onTap: busy ? null : _createCourse),
          ]),
          const SizedBox(height: 12),
          if (course != null) ...[
            CalmPill(icon: Icons.key_rounded, label: course!['join_code']?.toString() ?? 'Join code'),
            const SizedBox(height: 12),
          ],
          if (insights == null) const SoftText('Create a course to preview class insight, weak areas, and recommended lecturer action.') else ...[
            Text('Top weak areas', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [for (final item in (insights!['anonymized_weak_areas'] as List? ?? [])) CalmPill(icon: Icons.psychology_rounded, label: item.toString())]),
            const SizedBox(height: 12),
            SoftText(insights!['recommended_lecturer_action']?.toString() ?? ''),
          ],
        ])),
      ]);

  Future<void> _createCourse() async {
    setState(() => busy = true);
    try {
      final code = widget.course.isEmpty ? 'CSC301' : widget.course;
      course = await widget.api.createInstitutionCourse(courseCode: code, lecturer: widget.userName, title: '$code Revision Hub');
      insights = await widget.api.classInsights(code);
    } catch (e) {
      if (mounted) toast(context, 'Could not create course: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
