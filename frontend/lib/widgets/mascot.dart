import 'package:flutter/material.dart';
import '../theme/calm_theme.dart';
import '../utils/ui_helpers.dart';

enum MascotMood { happy, wave, focus, celebrate, sleep }

class StudentMascot extends StatefulWidget {
  const StudentMascot({super.key, this.size = 120, this.mood = MascotMood.happy});
  final double size;
  final MascotMood mood;

  @override
  State<StudentMascot> createState() => _StudentMascotState();
}

class _StudentMascotState extends State<StudentMascot> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final face = dark ? const Color(0xffbff8ee) : const Color(0xff9deee0);
    final outline = dark ? Colors.white.withOpacity(.12) : const Color(0xff0f766e).withOpacity(.16);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final float = (controller.value - .5) * 8;
        return Transform.translate(offset: Offset(0, float), child: child);
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(bottom: widget.size * .05, child: Container(width: widget.size * .82, height: widget.size * .20, decoration: BoxDecoration(color: CalmTheme.teal.withOpacity(.12), borderRadius: BorderRadius.circular(999)))),
            Positioned(bottom: widget.size * .16, child: Container(width: widget.size * .58, height: widget.size * .42, decoration: BoxDecoration(color: dark ? const Color(0xff1d3042) : Colors.white, borderRadius: BorderRadius.circular(widget.size * .18), border: Border.all(color: outline), boxShadow: softShadow(context)))),
            Positioned(top: widget.size * .13, child: Container(width: widget.size * .60, height: widget.size * .54, decoration: BoxDecoration(color: face, shape: BoxShape.circle, border: Border.all(color: outline, width: 2), boxShadow: softShadow(context)))),
            Positioned(top: widget.size * .32, left: widget.size * .39, child: _eye()),
            Positioned(top: widget.size * .32, right: widget.size * .39, child: _eye()),
            Positioned(top: widget.size * .44, child: Container(width: widget.size * .17, height: widget.size * .06, decoration: BoxDecoration(color: Colors.white.withOpacity(.9), borderRadius: BorderRadius.circular(999)))),
            Positioned(top: widget.size * .04, child: Transform.rotate(angle: -.08, child: Container(width: widget.size * .56, height: widget.size * .18, decoration: BoxDecoration(color: CalmTheme.ink, borderRadius: BorderRadius.circular(12)), child: Align(alignment: Alignment.centerRight, child: Container(width: widget.size * .16, height: widget.size * .06, margin: EdgeInsets.only(right: widget.size * .05), decoration: BoxDecoration(color: CalmTheme.orange, borderRadius: BorderRadius.circular(8))))))),
            if (widget.mood == MascotMood.wave || widget.mood == MascotMood.celebrate) Positioned(right: widget.size * .05, bottom: widget.size * .31, child: Transform.rotate(angle: -.55, child: Container(width: widget.size * .10, height: widget.size * .30, decoration: BoxDecoration(color: face, borderRadius: BorderRadius.circular(999))))),
            if (widget.mood == MascotMood.focus) Positioned(right: widget.size * .18, top: widget.size * .18, child: Icon(Icons.auto_awesome_rounded, color: CalmTheme.orange, size: widget.size * .18)),
            if (widget.mood == MascotMood.celebrate) Positioned(left: widget.size * .12, top: widget.size * .12, child: Icon(Icons.celebration_rounded, color: CalmTheme.gold, size: widget.size * .20)),
            if (widget.mood == MascotMood.sleep) Positioned(right: widget.size * .15, top: widget.size * .12, child: Text('Zz', style: TextStyle(color: muted(context), fontWeight: FontWeight.w900, fontSize: widget.size * .16))),
          ],
        ),
      ),
    );
  }

  Widget _eye() => Container(width: widget.size * .055, height: widget.size * .09, decoration: BoxDecoration(color: CalmTheme.ink, borderRadius: BorderRadius.circular(999)));
}
