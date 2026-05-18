import 'package:flutter/material.dart';
import '../theme/calm_theme.dart';

class CalmBackground extends StatefulWidget {
  const CalmBackground({super.key, required this.child});
  final Widget child;

  @override
  State<CalmBackground> createState() => _CalmBackgroundState();
}

class _CalmBackgroundState extends State<CalmBackground> {
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: dark ? CalmTheme.night : const Color(0xffeef7f3),
        gradient: dark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff06100e), Color(0xff0b1b18), Color(0xff081411)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xfff7fffb), Color(0xffe6f5ef), Color(0xfff4faf7)],
              ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter(dark: dark))),
          Positioned.fill(child: CustomPaint(painter: _LightSweepPainter(dark: dark))),
          widget.child,
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = (dark ? Colors.white : CalmTheme.graphite).withOpacity(dark ? .035 : .035)
      ..strokeWidth = 1;
    const gap = 32.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final band = Paint()
      ..color = (dark ? CalmTheme.glowTeal : CalmTheme.mint).withOpacity(dark ? .055 : .42)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 88), band);
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => oldDelegate.dark != dark;
}

class _LightSweepPainter extends CustomPainter {
  const _LightSweepPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          (dark ? CalmTheme.glowTeal : CalmTheme.teal).withOpacity(dark ? .12 : .10),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width * .72, size.height * .05), radius: size.width * .48));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _LightSweepPainter oldDelegate) => oldDelegate.dark != dark;
}
