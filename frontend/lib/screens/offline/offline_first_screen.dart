import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../theme/calm_theme.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';

class OfflineFirstScreen extends StatefulWidget {
  const OfflineFirstScreen({super.key, required this.api, required this.userId});
  final ApiClient api;
  final int userId;

  @override
  State<OfflineFirstScreen> createState() => _OfflineFirstScreenState();
}

class _OfflineFirstScreenState extends State<OfflineFirstScreen> {
  List<dynamic> queue = [];
  bool busy = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => busy = true);
    try {
      final data = await widget.api.offlineQueue(widget.userId);
      queue = (data['items'] as List?) ?? [];
    } catch (_) {
      queue = [];
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionIntro(icon: Icons.offline_bolt_rounded, title: 'Offline-First Reliability', subtitle: 'Notes, plans, quizzes, and progress stay useful when internet is unstable, then sync later.', mascot: StudentMascot(size: 100, mood: MascotMood.focus)),
        const SizedBox(height: 16),
        const ResponsiveCalmGrid(minWidth: 230, children: [
          CalmMetric(title: 'Notes', value: 'Cached', subtitle: 'read anywhere', icon: Icons.folder_copy_rounded, color: CalmTheme.teal),
          CalmMetric(title: 'Quizzes', value: 'Offline', subtitle: 'answers queue', icon: Icons.quiz_rounded, color: CalmTheme.purple),
          CalmMetric(title: 'Sync', value: 'Later', subtitle: 'no work lost', icon: Icons.sync_rounded, color: CalmTheme.green),
        ]),
        const SizedBox(height: 16),
        SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('Sync queue', style: Theme.of(context).textTheme.titleLarge)),
            SecondaryCalmButton(label: 'Save offline snapshot', icon: Icons.playlist_add_rounded, onTap: _queueSnapshot),
            const SizedBox(width: 8),
            PrimaryCalmButton(label: 'Sync now', icon: Icons.cloud_sync_rounded, compact: true, onTap: _sync),
          ]),
          const SizedBox(height: 12),
          if (busy) const LinearProgressIndicator() else if (queue.isEmpty) const SoftText('No pending actions. Offline work will appear here before it syncs.') else for (final item in queue) ListTile(contentPadding: EdgeInsets.zero, leading: const CircleIcon(icon: Icons.pending_actions_rounded, color: CalmTheme.orange), title: Text(item['action_type']?.toString() ?? 'Offline action', style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(item['payload']?.toString() ?? 'Pending sync')),
        ])),
      ]);

  Future<void> _queueSnapshot() async {
    await widget.api.queueOfflineAction(widget.userId, 'offline_study_snapshot', {'saved_at': DateTime.now().toIso8601String(), 'reason': 'student_requested_backup'});
    await _load();
  }

  Future<void> _sync() async {
    try {
      await widget.api.syncOfflineQueue(widget.userId);
      await _load();
      if (mounted) showFeatureSheet(context, 'Synced', 'Queued offline actions were marked as synced.');
    } catch (e) {
      if (mounted) toast(context, 'Could not sync: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }
}
