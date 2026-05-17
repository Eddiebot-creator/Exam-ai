import 'package:flutter/material.dart';
import '../../theme/calm_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';

class SchoolModeScreen extends StatelessWidget {
  const SchoolModeScreen({super.key, required this.course});
  final String course;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionIntro(icon: Icons.account_balance_rounded, title: 'Curriculum And School Awareness', subtitle: 'ExamAI should feel built for the student exact exam, school, and assessment style.', mascot: const StudentMascot(size: 100, mood: MascotMood.focus)),
        const SizedBox(height: 16),
        ResponsiveCalmGrid(minWidth: 230, children: const [
          CalmMetric(title: 'Nigeria', value: 'WAEC/JAMB', subtitle: 'plus universities', icon: Icons.public_rounded, color: CalmTheme.green),
          CalmMetric(title: 'Global', value: 'SAT/AP/IB', subtitle: 'GCSE and A-Level', icon: Icons.school_rounded, color: CalmTheme.indigo),
          CalmMetric(title: 'Style', value: 'Aligned', subtitle: 'past-question drills', icon: Icons.history_edu_rounded, color: CalmTheme.orange),
        ]),
        const SizedBox(height: 16),
        SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$course curriculum map', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: const [
            CalmPill(icon: Icons.location_city_rounded, label: 'UNILAG'),
            CalmPill(icon: Icons.location_city_rounded, label: 'UI'),
            CalmPill(icon: Icons.location_city_rounded, label: 'NOUN'),
            CalmPill(icon: Icons.edit_note_rounded, label: 'JAMB style'),
            CalmPill(icon: Icons.menu_book_rounded, label: 'WAEC style'),
            CalmPill(icon: Icons.public_rounded, label: 'GCSE'),
            CalmPill(icon: Icons.public_rounded, label: 'A-Level'),
          ]),
          const SizedBox(height: 12),
          const SoftText('Next production step: attach official syllabi, lecturer packs, and verified past-question patterns to every course profile.'),
        ])),
      ]);
}
