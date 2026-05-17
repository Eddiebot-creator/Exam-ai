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
  void dispose() {
    title.dispose();
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 430;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionIntro(
          icon: Icons.folder_rounded,
          title: 'Library',
          subtitle: 'Upload once. Generate summaries, flashcards, quizzes and study actions later.',
          mascot: StudentMascot(size: 96, mood: MascotMood.happy),
        ),
        const SizedBox(height: 16),
        SoftCard(
          padding: EdgeInsets.all(mobile ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add a note', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              TextField(
                controller: title,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title_rounded)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: text,
                minLines: 5,
                maxLines: 9,
                decoration: const InputDecoration(labelText: 'Paste text note', alignLabelWithHint: true, prefixIcon: Icon(Icons.notes_rounded)),
              ),
              const SizedBox(height: 16),
              mobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PrimaryCalmButton(label: busy ? 'Saving...' : 'Save text', icon: Icons.save_rounded, onTap: busy ? null : _saveText),
                        const SizedBox(height: 10),
                        SecondaryCalmButton(label: 'Upload file', icon: Icons.upload_file_rounded, onTap: () {
  if (!busy) {
    _upload();
  }
}),
                      ],
                    )
                  : Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        PrimaryCalmButton(label: busy ? 'Saving...' : 'Save text', icon: Icons.save_rounded, onTap: busy ? null : _saveText, compact: true),
                        SecondaryCalmButton(label: 'Upload file', icon: Icons.upload_file_rounded, onTap: () {
  if (!busy) {
    _upload();
  }
}),
                      ],
                    ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (widget.notes.isEmpty)
          const EmptyCalmState(
            icon: Icons.folder_open_rounded,
            title: 'No notes yet',
            message: 'Upload or paste a note and ExamAI will turn it into summaries, flashcards and tutor context.',
          )
        else
          ResponsiveCalmGrid(
            minWidth: 280,
            children: widget.notes.map((note) {
              final map = note as Map;
              return SoftCard(
                onTap: () => showFeatureSheet(
                  context,
                  map['title']?.toString() ?? 'Note',
                  '${map['summary']?.toString().isNotEmpty == true ? map['summary'] : 'This note can produce summaries, flashcards, MCQs, mind maps and tutor context.'}',
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleIcon(icon: Icons.description_rounded, color: CalmTheme.teal),
                  title: Text(map['title']?.toString() ?? 'Note', style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text(map['file_name']?.toString().isNotEmpty == true ? map['file_name'].toString() : 'Text note'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Future<void> _saveText() async {
    final noteTitle = title.text.trim();
    final noteText = text.text.trim();
    if (noteTitle.isEmpty || noteText.isEmpty) {
      toast(context, 'Add a title and paste note text first.');
      return;
    }
    setState(() => busy = true);
    try {
      await widget.api.createTextNote(widget.userId, noteTitle, noteText);
      title.clear();
      text.clear();
      widget.onChanged();
      if (mounted) toast(context, 'Note saved. Tutor, quizzes and flashcards can now use it.');
    } catch (e) {
      if (mounted) toast(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _upload() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;
    setState(() => busy = true);
    try {
      await widget.api.uploadFile(widget.userId, result.files.single.name, result.files.single);
      widget.onChanged();
      if (mounted) toast(context, 'File uploaded and processing started.');
    } catch (e) {
      if (mounted) toast(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
