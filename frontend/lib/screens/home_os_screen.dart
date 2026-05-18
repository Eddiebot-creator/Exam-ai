import 'package:flutter/material.dart';
import '../widgets/premium_card.dart';
import '../theme/app_theme.dart';
import 'camera/camera_study_screen.dart';
import 'wellness/wellness_screen.dart';
import 'exam_predictor/exam_predictor_screen.dart';
import 'achievements/achievement_economy_screen.dart';
import 'productivity/productivity_tools_screen.dart';

class HomeOSScreen extends StatefulWidget {
  const HomeOSScreen({super.key});

  @override
  State<HomeOSScreen> createState() => _HomeOSScreenState();
}

class _HomeOSScreenState extends State<HomeOSScreen> {
  int index = 0;

  final pages = const [
    _Dashboard(),
    ExamPredictorScreen(),
    _LegacyPlaceholder(title: 'Voice', subtitle: 'Open the main ExamAI Academic OS for voice and local language tutor mode.'),
    CameraStudyScreen(),
    _LegacyPlaceholder(title: 'Rooms', subtitle: 'Open the main ExamAI Academic OS for live study rooms.'),
    WellnessScreen(),
    AchievementEconomyScreen(),
    ProductivityToolsScreen(),
    _LegacyPlaceholder(title: 'School', subtitle: 'Open the main ExamAI Academic OS for curriculum-aware school mode.'),
  ];

  final labels = const ['Home','Exam AI','Voice','Camera','Rooms','Wellness','Rewards','Tools','School'];

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width > 900;
    return Scaffold(
      body: Row(
        children: [
          if (desktop) NavigationRail(
            selectedIndex: index,
            onDestinationSelected: (v) => setState(() => index = v),
            labelType: NavigationRailLabelType.all,
            destinations: labels.map((e) => NavigationRailDestination(icon: const Icon(Icons.auto_awesome_rounded), label: Text(e))).toList(),
          ),
          Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: pages[index])),
        ],
      ),
      bottomNavigationBar: desktop ? null : NavigationBar(
        selectedIndex: index > 4 ? 0 : index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: labels.take(5).map((e) => NavigationDestination(icon: const Icon(Icons.auto_awesome_rounded), label: e)).toList(),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('dashboard'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xfffffbf4), Color(0xffeefcf8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          PremiumCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Good evening, TJ', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('You’re 74% ready for CSC301. Focus on Recursion for 25 minutes today.'),
              const SizedBox(height: 18),
              FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Continue Studying')),
            ]),
          ),
          const SizedBox(height: 16),
          const Wrap(spacing: 16, runSpacing: 16, children: [
            _MiniCard('AI Life Coach', 'Planner, motivator and accountability coach'),
            _MiniCard('Burnout Detection', 'Adaptive recovery mode when stress rises'),
            _MiniCard('AI Memory Graph', 'Tracks weak topics and repeated mistakes'),
            _MiniCard('Adaptive UI', 'Changes by time, stress and exam proximity'),
          ]),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard(this.title, this.subtitle);
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 260, child: PremiumCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.auto_awesome_rounded, color: AppColors.gold),
      const SizedBox(height: 12),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
      const SizedBox(height: 8),
      Text(subtitle),
    ])));
  }
}

class _LegacyPlaceholder extends StatelessWidget {
  const _LegacyPlaceholder({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          PremiumCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(subtitle),
            ]),
          ),
        ],
      );
}
