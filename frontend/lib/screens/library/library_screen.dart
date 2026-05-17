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
                onTap: () => _openNote(map),
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

  Future<void> _openNote(Map note) async {
    final noteId = (note['id'] as num?)?.toInt();
    if (noteId == null) return;
    Map<String, dynamic>? materials;
    try {
      materials = await widget.api.noteMaterials(widget.userId, noteId);
    } catch (_) {
      materials = null;
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final cards = (materials?['flashcards'] as List?) ?? [];
        final mcqs = (materials?['mcqs'] as List?) ?? [];
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: .72,
            minChildSize: .42,
            maxChildSize: .92,
            builder: (context, controller) => ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              children: [
                Text(note['title']?.toString() ?? 'Note', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                SoftText(note['summary']?.toString().isNotEmpty == true ? note['summary'].toString() : 'This note can produce summaries, flashcards, MCQs and tutor context.'),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    PrimaryCalmButton(
                      label: 'Generate questions',
                      icon: Icons.auto_awesome_rounded,
                      onTap: () {
                        Navigator.pop(context);
                        _generateNoteMaterials(noteId);
                      },
                      compact: true,
                    ),
                    SecondaryCalmButton(
                      label: 'Refresh materials',
                      icon: Icons.refresh_rounded,
                      onTap: () {
                        Navigator.pop(context);
                        _openNote(note);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Flashcards (${cards.length})', style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                if (cards.isEmpty)
                  const SoftText('No flashcards found yet. Generate materials to create them.')
                else
                  for (final item in cards.take(6))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.style_rounded),
                      title: Text((item as Map)['question']?.toString() ?? 'Flashcard'),
                      subtitle: Text(item['answer']?.toString() ?? ''),
                    ),
                const SizedBox(height: 14),
                Text('MCQs (${mcqs.length})', style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                if (mcqs.isEmpty)
                  const SoftText('No MCQs found yet. Generate questions to create quiz items.')
                else
                  for (final item in mcqs.take(6))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.quiz_rounded),
                      title: Text((item as Map)['question']?.toString() ?? 'Question'),
                      subtitle: Text(item['explanation']?.toString() ?? ''),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateNoteMaterials(int noteId) async {
    setState(() => busy = true);
    try {
      final response = await widget.api.regenerateNoteMaterials(widget.userId, noteId);
      final generated = response['generated'] as Map? ?? {};
      widget.onChanged();
      if (mounted) {
        toast(context, 'Generated ${generated['mcqs'] ?? 0} MCQs and ${generated['flashcards'] ?? 0} flashcards.');
      }
    } catch (e) {
      if (mounted) toast(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
