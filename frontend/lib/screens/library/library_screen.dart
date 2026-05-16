import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../theme/calm_theme.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.api, required this.userId, required this.notes, required this.onChanged});
  final ApiClient api;
  final int userId;
  final List<dynamic> notes;
  final VoidCallback onChanged;
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final title = TextEditingController();
  final text = TextEditingController();
  bool busy = false;
  @override
  void dispose() { title.dispose(); text.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SectionIntro(icon: Icons.folder_rounded, title: 'Library', subtitle: 'Upload once. Generate summaries, flashcards, quizzes and study actions later.', mascot: StudentMascot(size: 100, mood: MascotMood.happy)),
    const SizedBox(height: 16),
    SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Add a note', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 12), TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')), const SizedBox(height: 10), TextField(controller: text, maxLines: 5, decoration: const InputDecoration(labelText: 'Paste text note')), const SizedBox(height: 14), Wrap(spacing: 10, runSpacing: 10, children: [PrimaryCalmButton(label: busy ? 'Saving...' : 'Save text', icon: Icons.save_rounded, onTap: busy ? null : _saveText, compact: true), SecondaryCalmButton(label: 'Upload file', icon: Icons.upload_file_rounded, onTap: _upload)])])),
    const SizedBox(height: 16),
    if (widget.notes.isEmpty) const EmptyCalmState(icon: Icons.folder_open_rounded, title: 'No notes yet', message: 'Upload a note and ExamAI will help turn it into learning materials.') else ResponsiveCalmGrid(minWidth: 280, children: widget.notes.map((note) { final map = note as Map; return SoftCard(onTap: () => showFeatureSheet(context, map['title']?.toString() ?? 'Note', 'This note can produce summaries, flashcards, MCQs, mind maps and tutor context.'), child: ListTile(contentPadding: EdgeInsets.zero, leading: const CircleIcon(icon: Icons.description_rounded, color: CalmTheme.teal), title: Text(map['title']?.toString() ?? 'Note', style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(map['file_name']?.toString() ?? 'Text note'), trailing: const Icon(Icons.chevron_right_rounded))); }).toList()),
  ]);

  Future<void> _saveText() async { if (title.text.trim().isEmpty || text.text.trim().isEmpty) return; setState(() => busy = true); try { await widget.api.createTextNote(widget.userId, title.text, text.text); title.clear(); text.clear(); widget.onChanged(); if (mounted) toast(context, 'Note saved and processing started.'); } catch (e) { if (mounted) toast(context, e.toString()); } finally { if (mounted) setState(() => busy = false); } }
  Future<void> _upload() async { final result = await FilePicker.platform.pickFiles(); if (result == null) return; try { await widget.api.uploadFile(widget.userId, result.files.single.name, result.files.single); widget.onChanged(); if (mounted) toast(context, 'File uploaded and processing started.'); } catch (e) { if (mounted) toast(context, e.toString()); } }
}
