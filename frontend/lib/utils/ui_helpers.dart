import 'package:flutter/material.dart';
import '../theme/calm_theme.dart';

Color muted(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xffb8c9c4) : CalmTheme.softInk;
Color cardColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? CalmTheme.nightPanel : Colors.white;
Color dividerColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xff24423b) : const Color(0xffd4e8e2);

List<BoxShadow> softShadow(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return [BoxShadow(color: dark ? Colors.black.withOpacity(.32) : const Color(0xff0f766e).withOpacity(.08), blurRadius: dark ? 22 : 28, offset: const Offset(0, 14))];
}

void toast(BuildContext context, String message) {
  final clean = _friendlyText(message);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(clean), behavior: SnackBarBehavior.floating));
}

Future<void> showFeatureSheet(BuildContext context, String title, String message) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .72),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_friendlyText(title, maxLength: 90), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(_friendlyText(message, maxLength: 1400), style: TextStyle(color: muted(context), height: 1.45)),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
            ],
          ),
        ),
      ),
    ),
  );
}

String _friendlyText(String value, {int maxLength = 220}) {
  var text = value.replaceFirst('Exception: ', '');
  text = text.replaceAll(RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]'), ' ');
  if (text.contains('Traceback') || text.contains('INSERT INTO') || text.contains(r'\u000')) {
    text = 'The server had trouble completing that action. Please try again shortly.';
  }
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.length > maxLength) return '${text.substring(0, maxLength).trim()}...';
  return text;
}
