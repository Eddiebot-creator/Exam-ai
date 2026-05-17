import 'package:flutter/material.dart';
import '../utils/ui_helpers.dart';

class SoftCard extends StatefulWidget {
  const SoftCard({super.key, this.child, this.padding = const EdgeInsets.all(18), this.onTap});
  final Widget? child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  State<SoftCard> createState() => _SoftCardState();
}

class _SoftCardState extends State<SoftCard> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final body = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      transform: Matrix4.identity()..translate(0.0, hover && widget.onTap != null ? -2.0 : 0.0),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: dark ? Colors.white.withOpacity(.055) : Colors.white.withOpacity(.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: dark ? Colors.white.withOpacity(.09) : const Color(0xffd9e5e2)),
        boxShadow: softShadow(context),
      ),
      child: widget.child,
    );
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: widget.onTap == null ? body : InkWell(borderRadius: BorderRadius.circular(8), onTap: widget.onTap, child: body),
    );
  }
}
