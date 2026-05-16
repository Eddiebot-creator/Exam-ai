import 'package:flutter/material.dart';
import '../../widgets/calm_background.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mascot.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: CalmBackground(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [StudentMascot(size: 150, mood: MascotMood.happy), SizedBox(height: 18), Text('ExamAI', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), SizedBox(height: 8), SoftText('Your calm AI study coach')]))));
}
