import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../theme/calm_theme.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';

class TrustDataScreen extends StatefulWidget {
  const TrustDataScreen({super.key, required this.api, required this.userId, required this.onChanged});
  final ApiClient api;
  final int userId;
  final VoidCallback onChanged;

  @override
  State<TrustDataScreen> createState() => _TrustDataScreenState();
}

class _TrustDataScreenState extends State<TrustDataScreen> {
  Map<String, dynamic>? export;
  bool loading = false;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionIntro(icon: Icons.privacy_tip_rounded, title: 'Your Data', subtitle: 'See what ExamAI stores, export it, and delete learning data when you want control back.', mascot: StudentMascot(size: 100, mood: MascotMood.focus)),
        const SizedBox(height: 16),
        ResponsiveCalmGrid(minWidth: 230, children: const [
          CalmMetric(title: 'Control', value: 'Export', subtitle: 'transparent records', icon: Icons.file_download_rounded, color: CalmTheme.teal),
          CalmMetric(title: 'Consent', value: 'Student-first', subtitle: 'sharing is optional', icon: Icons.verified_user_rounded, color: CalmTheme.green),
          CalmMetric(title: 'Delete', value: 'Instant', subtitle: 'learning history reset', icon: Icons.delete_outline_rounded, color: CalmTheme.rose),
        ]),
        const SizedBox(height: 16),
        SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('Stored learning data', style: Theme.of(context).textTheme.titleLarge)),
            PrimaryCalmButton(label: loading ? 'Loading...' : 'Refresh export', icon: Icons.refresh_rounded, compact: true, onTap: loading ? null : _loadExport),
          ]),
          const SizedBox(height: 12),
          if (export == null)
            const SoftText('Tap refresh to see exactly what ExamAI stores for this account.')
          else
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: Column(key: ValueKey(export.hashCode), children: [
                _DataRow(label: 'Notes', value: _count('notes')),
                _DataRow(label: 'Quiz attempts', value: _count('quiz_attempts')),
                _DataRow(label: 'Progress events', value: _count('progress_events')),
                _DataRow(label: 'Learning events', value: _count('learning_events')),
                _DataRow(label: 'Mastery records', value: _count('mastery')),
              ]),
            ),
          const SizedBox(height: 14),
          Wrap(spacing: 10, runSpacing: 10, children: [
            SecondaryCalmButton(label: 'Show privacy summary', icon: Icons.info_outline_rounded, onTap: () => showFeatureSheet(context, 'Privacy summary', 'ExamAI stores your profile, notes metadata, quiz history, study events, weak topics, mastery estimates, and adaptive state. Parent or lecturer sharing should always be consent-first.')),
            SecondaryCalmButton(label: 'Delete learning data', icon: Icons.delete_outline_rounded, onTap: _confirmDelete),
          ]),
        ])),
      ]);

  String _count(String key) {
    final value = export?[key];
    if (value is List) return value.length.toString();
    if (value is Map) return value.isEmpty ? '0' : '1';
    return '0';
  }

  Future<void> _loadExport() async {
    setState(() => loading = true);
    try {
      export = await widget.api.exportMyData(widget.userId);
    } catch (e) {
      if (mounted) toast(context, 'Could not load export: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete learning data?'),
        content: const Text('This resets notes, quiz history, study events, mastery, memory, and adaptive state. Your login account remains.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete data')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => loading = true);
    try {
      await widget.api.deleteMyLearningData(widget.userId);
      export = null;
      widget.onChanged();
      if (mounted) showFeatureSheet(context, 'Data deleted', 'Your learning data was deleted. Your account remains active.');
    } catch (e) {
      if (mounted) toast(context, 'Could not delete data: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleIcon(icon: Icons.storage_rounded, color: CalmTheme.teal),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        trailing: Text(value, style: Theme.of(context).textTheme.titleLarge),
      );
}
