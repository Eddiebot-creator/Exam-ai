
import 'package:flutter/material.dart';

class FriendStudyRoomScreen extends StatelessWidget {
  const FriendStudyRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        Text('Study With Friends', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Card(child: ListTile(leading: Icon(Icons.timer), title: Text('Shared focus timer'), subtitle: Text('Run group Pomodoro sessions.'))),
        Card(child: ListTile(leading: Icon(Icons.groups), title: Text('Friend groups'), subtitle: Text('Small accountability groups, not noisy global leaderboards.'))),
        Card(child: ListTile(leading: Icon(Icons.emoji_events), title: Text('Group leaderboard'), subtitle: Text('Compare streaks with your own friends.'))),
      ],
    );
  }
}
