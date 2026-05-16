import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        Text('Push Notifications', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        SwitchListTile(value: true, onChanged: null, title: Text('Daily study reminder')),
        SwitchListTile(value: true, onChanged: null, title: Text('Exam countdown')),
        SwitchListTile(value: false, onChanged: null, title: Text('Weak-topic alerts')),
      ],
    );
  }
}
