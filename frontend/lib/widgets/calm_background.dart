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
        color: dark ? const Color(0xff07111d) : const Color(0xfff4f7f5),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter(dark: dark))),
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
      ..color = (dark ? Colors.white : CalmTheme.graphite).withOpacity(dark ? .035 : .045)
      ..strokeWidth = 1;
    const gap = 32.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final band = Paint()
      ..color = (dark ? CalmTheme.teal : CalmTheme.mint).withOpacity(dark ? .08 : .55)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 96), band);
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => oldDelegate.dark != dark;
}
