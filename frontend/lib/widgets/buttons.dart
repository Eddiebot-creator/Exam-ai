import 'package:flutter/material.dart';

class PrimaryCalmButton extends StatefulWidget {
  const PrimaryCalmButton({super.key, required this.label, required this.icon, required this.onTap, this.compact = false});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool compact;

  @override
  State<PrimaryCalmButton> createState() => _PrimaryCalmButtonState();
}

class _PrimaryCalmButtonState extends State<PrimaryCalmButton> {
  bool down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => down = true),
      onTapUp: (_) => setState(() => down = false),
      onTapCancel: () => setState(() => down = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        scale: down ? .97 : 1,
        child: FilledButton.icon(
          onPressed: widget.onTap,
          icon: Icon(widget.icon, size: widget.compact ? 18 : 20),
          label: Text(widget.label),
          style: FilledButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: widget.compact ? 14 : 18, vertical: widget.compact ? 12 : 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}

class SecondaryCalmButton extends StatelessWidget {
  const SecondaryCalmButton({super.key, required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), textStyle: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
