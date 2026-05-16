import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../theme/calm_theme.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({super.key, required this.api, required this.userId, required this.onChanged});
  final ApiClient api; final int userId; final VoidCallback onChanged;
  @override State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  int seconds = 25 * 60; Timer? timer; bool running = false;
  @override void dispose(){ timer?.cancel(); super.dispose(); }
  @override Widget build(BuildContext context) { final min = (seconds~/60).toString().padLeft(2,'0'); final sec=(seconds%60).toString().padLeft(2,'0'); return Column(children:[const SectionIntro(icon: Icons.self_improvement_rounded,title:'Focus Mode',subtitle:'One task. One calm timer. No distractions.',mascot:StudentMascot(size:100,mood:MascotMood.sleep)),const SizedBox(height:16),SoftCard(child:Column(children:[const StudentMascot(size:160,mood:MascotMood.focus),const SizedBox(height:16),Text('$min:$sec',style:const TextStyle(fontSize:56,fontWeight:FontWeight.w900)),const SoftText('Recursion practice • calm focus session'),const SizedBox(height:20),Wrap(spacing:10,children:[PrimaryCalmButton(label:running?'Pause':'Start',icon:running?Icons.pause_rounded:Icons.play_arrow_rounded,onTap:_toggle),SecondaryCalmButton(label:'Reset',icon:Icons.restart_alt_rounded,onTap:_reset)]),]))]); }
  void _toggle(){ if(running){ timer?.cancel(); setState(()=>running=false); } else { setState(()=>running=true); timer=Timer.periodic(const Duration(seconds:1),(_){ if(seconds<=0){ timer?.cancel(); setState(()=>running=false); _save(); } else { setState(()=>seconds--); } }); } }
  void _reset(){ timer?.cancel(); setState((){ seconds=25*60; running=false; }); }
  Future<void> _save() async { try{ await widget.api.recordStudyTime(widget.userId,null,'focus-mode',25*60); widget.onChanged(); if(mounted) showFeatureSheet(context,'Focus complete','Great job. Your focus session has been saved.'); } catch(e){ if(mounted) toast(context,'Could not save focus time.'); } }
}
