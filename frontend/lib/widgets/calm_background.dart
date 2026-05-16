import 'package:flutter/material.dart';
import '../theme/calm_theme.dart';

class CalmBackground extends StatefulWidget {
  const CalmBackground({super.key, required this.child});
  final Widget child;

  @override
  State<CalmBackground> createState() => _CalmBackgroundState();
}

class _CalmBackgroundState extends State<CalmBackground> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
                  ? const [Color(0xff07111d), Color(0xff0d1b2a), Color(0xff07111d)]
                  : const [Color(0xfffffbf4), Color(0xffeefcf8), Color(0xfff7fbfa)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(top: -80 + controller.value * 20, left: -40, child: _Glow(size: 250, color: CalmTheme.teal.withOpacity(dark ? .12 : .16))),
              Positioned(bottom: -80, right: -30 + controller.value * 25, child: _Glow(size: 260, color: CalmTheme.purple.withOpacity(dark ? .10 : .12))),
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 20)]));
  }
}
