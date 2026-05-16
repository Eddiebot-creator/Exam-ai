import 'package:flutter/material.dart';
import '../../theme/calm_theme.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';

class ToolsScreen extends StatelessWidget { const ToolsScreen({super.key});
  @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const SectionIntro(icon:Icons.apps_rounded,title:'Study Tools',subtitle:'Useful tools kept organized so the app stays calm.',mascot:StudentMascot(size:100,mood:MascotMood.happy)),const SizedBox(height:16),ResponsiveCalmGrid(minWidth:250,children:[for(final t in _tools) SoftCard(onTap:()=>showFeatureSheet(context,t.$1,t.$2),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[CircleIcon(icon:t.$3,color:t.$4),const SizedBox(height:12),Text(t.$1,style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:6),SoftText(t.$2)]))])]); }
const _tools=[('Timetable Generator','Build weekly study schedules automatically.',Icons.calendar_month_rounded,CalmTheme.teal),('Assignment Planner','Track deadlines and split tasks.',Icons.assignment_rounded,CalmTheme.purple),('GPA Calculator','Estimate GPA/CGPA quickly.',Icons.calculate_rounded,CalmTheme.orange),('PDF Highlighter','Mark important parts of notes.',Icons.draw_rounded,CalmTheme.blue),('Past Question Bank','Organize and practice past questions.',Icons.history_edu_rounded,CalmTheme.green),('Scholarships','Track internship and scholarship alerts.',Icons.work_rounded,CalmTheme.rose)];
