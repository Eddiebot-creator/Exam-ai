import 'package:flutter/material.dart';
import '../theme/calm_theme.dart';

Color muted(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white70 : CalmTheme.softInk;
Color cardColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(.06) : Colors.white;
Color dividerColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(.10) : const Color(0xffdcefed);

List<BoxShadow> softShadow(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return [BoxShadow(color: dark ? Colors.black.withOpacity(.25) : const Color(0xff0f766e).withOpacity(.08), blurRadius: 28, offset: const Offset(0, 14))];
}

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
}

Future<void> showFeatureSheet(BuildContext context, String title, String message) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: muted(context), height: 1.45)),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
        ],
      ),
    ),
  );
}
