import 'package:flutter/material.dart';

class PremiumCard extends StatelessWidget {
  const PremiumCard({super.key, required this.child, this.padding = const EdgeInsets.all(20)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: padding,
      decoration: BoxDecoration(
        color: dark ? Colors.white.withOpacity(.06) : Colors.white.withOpacity(.90),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: dark ? Colors.white12 : const Color(0xffdcefed)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(dark ? .25 : .08), blurRadius: 28, offset: const Offset(0, 18))],
      ),
      child: child,
    );
  }
}
