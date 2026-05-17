import 'package:flutter/material.dart';
import '../theme/calm_theme.dart';
import '../utils/ui_helpers.dart';
import 'mascot.dart';
import 'soft_card.dart';

class SoftText extends StatelessWidget {
  const SoftText(this.text, {super.key, this.size = 14, this.align});
  final String text;
  final double size;
  final TextAlign? align;
  @override
  Widget build(BuildContext context) => Text(text, textAlign: align, style: TextStyle(color: muted(context), fontSize: size, height: 1.5));
}

class CalmPill extends StatelessWidget {
  const CalmPill({super.key, required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: CalmTheme.teal.withOpacity(.10), borderRadius: BorderRadius.circular(8), border: Border.all(color: CalmTheme.teal.withOpacity(.22))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: CalmTheme.teal), const SizedBox(width: 6), Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))]),
    ),
  );
}

class CircleIcon extends StatelessWidget {
  const CircleIcon({super.key, required this.icon, required this.color});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(.14), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color));
}

class ResponsiveCalmGrid extends StatelessWidget {
  const ResponsiveCalmGrid({super.key, required this.children, this.minWidth = 260, this.spacing = 14});
  final List<Widget> children;
  final double minWidth;
  final double spacing;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final cols = (constraints.maxWidth / minWidth).floor().clamp(1, 4);
    final width = (constraints.maxWidth - (cols - 1) * spacing) / cols;
    return Wrap(spacing: spacing, runSpacing: spacing, children: children.map((child) => SizedBox(width: width, child: child)).toList());
  });
}

class SectionIntro extends StatelessWidget {
  const SectionIntro({super.key, required this.icon, required this.title, required this.subtitle, this.mascot});
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? mascot;
  @override
  Widget build(BuildContext context) => SoftCard(
    child: Row(children: [CircleIcon(icon: icon, color: CalmTheme.teal), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 6), SoftText(subtitle)])), if (mascot != null) mascot!]),
  );
}

class CalmMetric extends StatelessWidget {
  const CalmMetric({super.key, required this.title, required this.value, required this.subtitle, required this.icon, required this.color});
  final String title, value, subtitle;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [CircleIcon(icon: icon, color: color), const SizedBox(height: 12), Text(title, style: TextStyle(color: muted(context), fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(subtitle, style: TextStyle(color: color, fontWeight: FontWeight.w800))]));
}

class EmptyCalmState extends StatelessWidget {
  const EmptyCalmState({super.key, required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => SoftCard(child: Column(children: [const StudentMascot(size: 100, mood: MascotMood.wave), Icon(icon, color: CalmTheme.teal), const SizedBox(height: 8), Text(title, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 6), SoftText(message, align: TextAlign.center)]));
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, required this.label});
  final double value;
  final String label;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value.clamp(0, 1)),
    duration: const Duration(milliseconds: 850),
    builder: (context, v, _) => SizedBox(width: 86, height: 86, child: Stack(alignment: Alignment.center, children: [CircularProgressIndicator(value: v, strokeWidth: 8, color: CalmTheme.teal, backgroundColor: CalmTheme.teal.withOpacity(.12)), Text(label, style: const TextStyle(fontWeight: FontWeight.w900))])),
  );
}
