import 'package:flutter/material.dart';
import '../../models/app_tab.dart';
import '../../models/student_snapshot.dart';
import '../../services/api_client.dart';
import '../../services/offline_cache_service.dart';
import '../../widgets/calm_background.dart';
import '../../widgets/navigation.dart';
import '../focus/focus_mode_screen.dart';
import '../diagnostics/deep_diagnostics_screen.dart';
import '../lecturer/lecturer_tools_screen.dart';
import '../library/library_screen.dart';
import '../offline/offline_first_screen.dart';
import '../profile/profile_screen.dart';
import '../quiz/quiz_screen.dart';
import '../school/school_mode_screen.dart';
import '../study_room/study_room_screen.dart';
import '../tasks/tasks_screen.dart';
import '../tools/tools_screen.dart';
import '../tutor/tutor_screen.dart';
import '../voice/voice_tutor_screen.dart';
import 'home_screen.dart';

class CalmStudentApp extends StatefulWidget {
  const CalmStudentApp({super.key, required this.api, required this.user, required this.onLogout, required this.onThemeToggle, required this.themeMode, required this.onUserChanged});
  final ApiClient api;
  final Map<String, dynamic> user;
  final VoidCallback onLogout;
  final VoidCallback onThemeToggle;
  final ThemeMode themeMode;
  final ValueChanged<Map<String, dynamic>> onUserChanged;

  @override
  State<CalmStudentApp> createState() => _CalmStudentAppState();
}

class _CalmStudentAppState extends State<CalmStudentApp> {
  int index = 0;
  bool loading = true;
  List<dynamic> notes = [];
  List<dynamic> history = [];
  Map<String, dynamic> progress = {};
  Map<String, dynamic> adaptive = {};
  bool offline = false;
  final cache = OfflineCacheService();

  int get userId => (widget.user['id'] as num?)?.toInt() ?? 1;
  String get firstName => widget.user['full_name']?.toString().split(' ').first ?? 'Scholar';

  final mainTabs = const [
    AppTab('Home', Icons.home_rounded),
    AppTab('Tutor', Icons.smart_toy_rounded),
    AppTab('Tasks', Icons.checklist_rounded),
    AppTab('Library', Icons.folder_rounded),
    AppTab('Focus', Icons.self_improvement_rounded),
    AppTab('Quiz', Icons.quiz_rounded),
    AppTab('Rooms', Icons.groups_rounded),
    AppTab('Offline', Icons.offline_bolt_rounded),
    AppTab('School', Icons.account_balance_rounded),
    AppTab('Lecturer', Icons.co_present_rounded),
    AppTab('Voice', Icons.record_voice_over_rounded),
    AppTab('Diagnostics', Icons.psychology_alt_rounded),
    AppTab('OS Hub', Icons.apps_rounded),
    AppTab('Profile', Icons.person_rounded),
  ];

  @override
  void initState() { super.initState(); refresh(); }

  Future<void> refresh() async {
    setState(() => loading = true);
    try {
      final results = await Future.wait([widget.api.notes(userId), widget.api.history(userId), widget.api.progress(userId), widget.api.adaptiveHome(userId)]);
      notes = results[0] as List<dynamic>;
      history = results[1] as List<dynamic>;
      progress = results[2] as Map<String, dynamic>;
      adaptive = results[3] as Map<String, dynamic>;
      offline = false;
      await cache.saveList('notes:$userId', notes);
      await cache.saveList('history:$userId', history);
      await cache.saveJson('progress:$userId', progress);
      await cache.saveJson('adaptive:$userId', adaptive);
    } catch (_) {
      notes = await cache.readList('notes:$userId');
      history = await cache.readList('history:$userId');
      progress = await cache.readJson('progress:$userId') ?? progress;
      adaptive = await cache.readJson('adaptive:$userId') ?? adaptive;
      offline = true;
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 980;
    final mobileTabs = [0, 1, 2, 3, mainTabs.length - 1];
    return Scaffold(
      body: CalmBackground(child: SafeArea(child: desktop ? _desktopShell() : _mobileShell())),
      bottomNavigationBar: desktop ? null : NavigationBar(
        selectedIndex: mobileTabs.contains(index) ? mobileTabs.indexOf(index) : 0,
        onDestinationSelected: (value) => setState(() => index = mobileTabs[value]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.smart_toy_rounded), label: 'Tutor'),
          NavigationDestination(icon: Icon(Icons.checklist_rounded), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.folder_rounded), label: 'Library'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _desktopShell() => Row(children: [SizedBox(width: 248, child: CalmSidebar(tabs: mainTabs, selected: index, onSelect: (value) => setState(() => index = value), onLogout: widget.onLogout, user: widget.user)), Expanded(child: Column(children: [CalmTopBar(title: mainTabs[index].label, onRefresh: refresh, onThemeToggle: widget.onThemeToggle, themeMode: widget.themeMode), Expanded(child: _content())]))]);
  Widget _mobileShell() => Column(children: [CalmTopBar(title: mainTabs[index].label, onRefresh: refresh, onThemeToggle: widget.onThemeToggle, themeMode: widget.themeMode, compact: true), Expanded(child: _content())]);

  Widget _content() {
    final data = StudentSnapshot(notes: notes, history: history, progress: progress, user: widget.user, adaptive: adaptive, offline: offline);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: RefreshIndicator(
        key: ValueKey(index),
        onRefresh: refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 90),
          child: switch (index) {
            0 => HomeScreen(firstName: firstName, data: data, loading: loading, goTutor: () => setState(() => index = 1), goTasks: () => setState(() => index = 2), goLibrary: () => setState(() => index = 3), goFocus: () => setState(() => index = 4)),
            1 => TutorScreen(api: widget.api, userId: userId, notes: notes),
            2 => TasksScreen(data: data, api: widget.api, userId: userId, onChanged: refresh),
            3 => LibraryScreen(api: widget.api, userId: userId, notes: notes, onChanged: refresh),
            4 => FocusModeScreen(api: widget.api, userId: userId, onChanged: refresh),
            5 => QuizScreen(api: widget.api, userId: userId, data: data, onChanged: refresh),
            6 => StudyRoomScreen(api: widget.api, userId: userId, focusTopic: data.weakTopic),
            7 => OfflineFirstScreen(api: widget.api, userId: userId),
            8 => SchoolModeScreen(course: data.missionCourse),
            9 => LecturerToolsScreen(api: widget.api, userName: widget.user['full_name']?.toString() ?? 'Lecturer', course: data.missionCourse),
            10 => VoiceTutorScreen(focusTopic: data.weakTopic),
            11 => DeepDiagnosticsScreen(data: data),
            12 => ToolsScreen(data: data, goRooms: () => setState(() => index = 6), goOffline: () => setState(() => index = 7), goSchool: () => setState(() => index = 8), goLecturer: () => setState(() => index = 9), goVoice: () => setState(() => index = 10), goDiagnostics: () => setState(() => index = 11)),
            _ => ProfileScreen(user: widget.user, apiBase: widget.api.baseUrl, onLogout: widget.onLogout, onThemeToggle: widget.onThemeToggle, themeMode: widget.themeMode, api: widget.api, userId: userId, onUserChanged: widget.onUserChanged),
          },
        ),
      ),
    );
  }
}
