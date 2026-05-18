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
  Widget build(BuildContext context) => Text(
        text,
        textAlign: align,
        style: TextStyle(color: muted(context), fontSize: size, height: 1.45),
      );
}

class StaggeredReveal extends StatelessWidget {
  const StaggeredReveal({super.key, required this.child, this.delay = Duration.zero, this.offset = 14});
  final Widget child;
  final Duration delay;
  final double offset;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 420 + delay.inMilliseconds),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          final delayed = delay.inMilliseconds == 0 ? value : ((value * (420 + delay.inMilliseconds) - delay.inMilliseconds) / 420).clamp(0.0, 1.0);
          return Opacity(
            opacity: delayed,
            child: Transform.translate(offset: Offset(0, offset * (1 - delayed)), child: child),
          );
        },
        child: child,
      );
}

class AnimatedSection extends StatelessWidget {
  const AnimatedSection({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++)
            StaggeredReveal(delay: Duration(milliseconds: i * 42), child: children[i]),
        ],
      );
}

class CalmPill extends StatelessWidget {
  const CalmPill({super.key, required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? CalmTheme.glowTeal : CalmTheme.teal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: accent.withOpacity(dark ? .12 : .10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withOpacity(dark ? .20 : .22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: dark ? const Color(0xffdff8f3) : null),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CircleIcon extends StatelessWidget {
  const CircleIcon({super.key, required this.icon, required this.color});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: color.withOpacity(dark ? .18 : .14), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color),
      );
  }
}

class ResponsiveCalmGrid extends StatelessWidget {
  const ResponsiveCalmGrid({super.key, required this.children, this.minWidth = 260, this.spacing = 14});
  final List<Widget> children;
  final double minWidth;
  final double spacing;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        final usable = constraints.maxWidth <= 0 ? MediaQuery.sizeOf(context).width : constraints.maxWidth;
        final adjustedMin = usable < 430 ? usable : minWidth;
        final cols = (usable / adjustedMin).floor().clamp(1, 4);
        final width = (usable - (cols - 1) * spacing) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children.map((child) => SizedBox(width: width, child: child)).toList(),
        );
      });
}

class SectionIntro extends StatelessWidget {
  const SectionIntro({super.key, required this.icon, required this.title, required this.subtitle, this.mascot});
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? mascot;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 520;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleIcon(icon: icon, color: CalmTheme.teal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: mobile ? Theme.of(context).textTheme.titleLarge : Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 6),
                        SoftText(subtitle, size: mobile ? 13 : 14),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
          return StaggeredReveal(
            child: SoftCard(
            child: mobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (mascot != null) Center(child: mascot!),
                      if (mascot != null) const SizedBox(height: 12),
                      content,
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: content),
                      if (mascot != null) mascot!,
                    ],
                  ),
            ),
          );
        },
      );
}

class CalmMetric extends StatelessWidget {
  const CalmMetric({super.key, required this.title, required this.value, required this.subtitle, required this.icon, required this.color});
  final String title, value, subtitle;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => StaggeredReveal(
        child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleIcon(icon: icon, color: color),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: muted(context), fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      );
}

class EmptyCalmState extends StatelessWidget {
  const EmptyCalmState({super.key, required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => StaggeredReveal(
        child: SoftCard(
        child: Column(
          children: [
            const _FloatingMascot(),
            Icon(icon, color: CalmTheme.teal),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            SoftText(message, align: TextAlign.center),
          ],
        ),
      ),
      );
}

class _FloatingMascot extends StatefulWidget {
  const _FloatingMascot();

  @override
  State<_FloatingMascot> createState() => _FloatingMascotState();
}

class _FloatingMascotState extends State<_FloatingMascot> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, child) => Transform.translate(offset: Offset(0, -4 * controller.value), child: child),
        child: const StudentMascot(size: 100, mood: MascotMood.wave),
      );
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, required this.label});
  final double value;
  final String label;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1)),
        duration: const Duration(milliseconds: 850),
        builder: (context, v, _) => SizedBox(
          width: 74,
          height: 74,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(value: v, strokeWidth: 8, color: CalmTheme.teal, backgroundColor: CalmTheme.teal.withOpacity(.12)),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      );
}
