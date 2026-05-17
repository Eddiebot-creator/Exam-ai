import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../theme/calm_theme.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';

class StudyRoomScreen extends StatefulWidget {
  const StudyRoomScreen({super.key, required this.api, required this.userId, required this.focusTopic});
  final ApiClient api;
  final int userId;
  final String focusTopic;

  @override
  State<StudyRoomScreen> createState() => _StudyRoomScreenState();
}

class _StudyRoomScreenState extends State<StudyRoomScreen> {
  List<dynamic> rooms = [];
  bool loading = true;
  bool creating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      rooms = await widget.api.studyRooms();
    } catch (_) {
      rooms = [];
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionIntro(icon: Icons.groups_rounded, title: 'Study With Friends', subtitle: 'Small rooms, shared focus, peer accountability, and quiz momentum for real student groups.', mascot: StudentMascot(size: 100, mood: MascotMood.happy)),
        const SizedBox(height: 16),
        ResponsiveCalmGrid(minWidth: 230, children: const [
          CalmMetric(title: 'Room size', value: '2-6', subtitle: 'focused classmates', icon: Icons.group_rounded, color: CalmTheme.teal),
          CalmMetric(title: 'Invites', value: 'Share', subtitle: 'WhatsApp-ready code', icon: Icons.ios_share_rounded, color: CalmTheme.green),
          CalmMetric(title: 'Mode', value: 'Live', subtitle: 'timers and quiz streaks', icon: Icons.timer_rounded, color: CalmTheme.orange),
        ]),
        const SizedBox(height: 16),
        SoftCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('Friend rooms', style: Theme.of(context).textTheme.titleLarge)),
              PrimaryCalmButton(label: creating ? 'Creating...' : 'Create room', icon: Icons.add_rounded, compact: true, onTap: creating ? null : _createRoom),
            ]),
            const SizedBox(height: 12),
            if (loading)
              const LinearProgressIndicator()
            else if (rooms.isEmpty)
              const SoftText('No active room yet. Create one for your current weak topic.')
            else
              for (final room in rooms)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleIcon(icon: Icons.meeting_room_rounded, color: CalmTheme.teal),
                  title: Text(room['name']?.toString() ?? 'Study Room', style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text(room['topic']?.toString() ?? 'General'),
                  trailing: const Icon(Icons.arrow_forward_rounded),
                  onTap: () => showFeatureSheet(context, 'Room ready', 'Invite code: ROOM-${room['id']}\nShare this with classmates and start a focused session.'),
                ),
          ]),
        ),
      ]);

  Future<void> _createRoom() async {
    setState(() => creating = true);
    try {
      final room = await widget.api.createStudyRoom(widget.userId, '${widget.focusTopic} room', widget.focusTopic);
      await _load();
      if (mounted) showFeatureSheet(context, 'Room created', 'Invite code: ROOM-${room['id']}\nTopic: ${room['topic']}');
    } catch (e) {
      if (mounted) toast(context, 'Could not create room: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => creating = false);
    }
  }
}
