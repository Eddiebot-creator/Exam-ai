import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/app_tab.dart';
import '../theme/calm_theme.dart';
import '../utils/ui_helpers.dart';
import 'common_widgets.dart';
import 'soft_card.dart';

class CalmTopBar extends StatelessWidget {
  const CalmTopBar({super.key, required this.title, required this.onRefresh, required this.onThemeToggle, required this.themeMode, this.compact = false});
  final String title;
  final VoidCallback onRefresh;
  final VoidCallback onThemeToggle;
  final ThemeMode themeMode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 72 : 64,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: dividerColor(context)))),
      child: Row(children: [
        if (compact) Image.asset(AppConfig.logo, width: 34, errorBuilder: (_, __, ___) => const Icon(Icons.school_rounded)),
        if (compact) const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const Spacer(),
        IconButton.filledTonal(onPressed: onRefresh, icon: const Icon(Icons.refresh_rounded)),
        const SizedBox(width: 8),
        IconButton.filledTonal(onPressed: onThemeToggle, icon: Icon(themeMode == ThemeMode.light ? Icons.dark_mode_rounded : Icons.light_mode_rounded)),
      ]),
    );
  }
}

class CalmSidebar extends StatelessWidget {
  const CalmSidebar({super.key, required this.tabs, required this.selected, required this.onSelect, required this.onLogout, required this.user});
  final List<AppTab> tabs;
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(border: Border(right: BorderSide(color: dividerColor(context)))),
      child: Column(children: [
        Row(children: [Image.asset(AppConfig.logo, width: 42, errorBuilder: (_, __, ___) => const Icon(Icons.school_rounded)), const SizedBox(width: 10), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ExamAI', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), Text('Academic OS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: CalmTheme.teal))]))]),
        const SizedBox(height: 22),
        Expanded(child: ListView(children: [for (var i = 0; i < tabs.length; i++) _SideButton(tab: tabs[i], selected: i == selected, onTap: () => onSelect(i))])),
        SoftCard(padding: const EdgeInsets.all(14), child: Row(children: [const CircleIcon(icon: Icons.verified_rounded, color: CalmTheme.gold), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(user['full_name']?.toString() ?? 'Student', style: const TextStyle(fontWeight: FontWeight.w900)), SoftText('${((user['exam_course']?.toString() ?? '').isNotEmpty) ? user['exam_course'] : 'Course'} command center')]))])),
        const SizedBox(height: 10),
        TextButton.icon(onPressed: onLogout, icon: const Icon(Icons.logout_rounded), label: const Text('Logout')),
      ]),
    );
  }
}

class _SideButton extends StatefulWidget {
  const _SideButton({required this.tab, required this.selected, required this.onTap});
  final AppTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SideButton> createState() => _SideButtonState();
}

class _SideButtonState extends State<_SideButton> {
  bool hover = false;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(color: widget.selected ? CalmTheme.teal.withOpacity(.14) : hover ? CalmTheme.teal.withOpacity(.06) : Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: widget.selected ? CalmTheme.teal.withOpacity(.24) : Colors.transparent)),
          child: Row(children: [AnimatedContainer(duration: const Duration(milliseconds: 180), width: 4, height: widget.selected ? 28 : 8, decoration: BoxDecoration(color: widget.selected ? CalmTheme.teal : Colors.transparent, borderRadius: BorderRadius.circular(4))), const SizedBox(width: 10), Icon(widget.tab.icon, color: widget.selected ? CalmTheme.teal : muted(context)), const SizedBox(width: 12), Expanded(child: Text(widget.tab.label, style: TextStyle(fontWeight: widget.selected ? FontWeight.w900 : FontWeight.w700, color: widget.selected ? CalmTheme.teal : null)))])
        ),
      ),
    ),
  );
}
