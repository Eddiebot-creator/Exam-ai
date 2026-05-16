import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/tutor_message.dart';
import '../../services/api_client.dart';
import '../../theme/calm_theme.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';

class TutorScreen extends StatefulWidget {
  const TutorScreen({
    super.key,
    required this.api,
    required this.userId,
    required this.notes,
  });

  final ApiClient api;
  final int userId;
  final List<dynamic> notes;

  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> {
  final input = TextEditingController();

  final messages = <TutorMessage>[
    TutorMessage(
      false,
      'Hi, I am your study buddy. Ask me one question, and I will use your backend AI tutor to answer.',
    ),
  ];

  bool sending = false;

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatHeight = min<double>(
      660,
      MediaQuery.sizeOf(context).height - 190,
    );

    return Column(
      children: [
        const SectionIntro(
          icon: Icons.smart_toy_rounded,
          title: 'AI Tutor',
          subtitle:
              'Live AI tutor with note context, suggested prompts, and step-by-step answers.',
          mascot: StudentMascot(size: 100, mood: MascotMood.wave),
        ),
        const SizedBox(height: 16),
        SoftCard(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: chatHeight,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleIcon(
                        icon: Icons.psychology_rounded,
                        color: CalmTheme.teal,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Tutor is ready',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      CalmPill(
                        icon: Icons.mic_rounded,
                        label: 'Voice ready',
                        onTap: () => toast(
                          context,
                          'Voice tutor button is active.',
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: dividerColor(context)),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      for (final prompt in [
                        'Explain this like I am 12 using simple examples.',
                        'Generate 5 MCQs from my uploaded note.',
                        'Summarize my latest uploaded note.',
                        'Give me exam tips based on my weak topics.',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CalmPill(
                            icon: Icons.auto_awesome_rounded,
                            label: _shortPrompt(prompt),
                            onTap: sending
                                ? null
                                : () {
                                    input.text = prompt;
                                    _send();
                                  },
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (sending ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == messages.length) return const TypingBubble();
                      return TutorBubble(message: messages[i]);
                    },
                  ),
                ),
                Divider(height: 1, color: dividerColor(context)),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: sending ? null : _pickImage,
                        icon: const Icon(Icons.attach_file_rounded),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: input,
                          minLines: 1,
                          maxLines: 4,
                          onSubmitted: (_) {
                            if (!sending) _send();
                          },
                          decoration: const InputDecoration(
                            hintText: 'Ask one question...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton.small(
                        onPressed: sending ? null : _send,
                        child: sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.arrow_upward_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _shortPrompt(String prompt) {
    if (prompt.startsWith('Explain')) return 'Explain like I am 12';
    if (prompt.startsWith('Generate')) return 'Make 5 MCQs';
    if (prompt.startsWith('Summarize')) return 'Summarize my note';
    return 'Give exam tips';
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      setState(
        () => messages.add(
          TutorMessage(
            true,
            'Uploaded image: ${result.files.single.name}. Please explain this image when OCR/image AI is connected.',
          ),
        ),
      );
    }
  }

  Future<void> _send() async {
    final text = input.text.trim();
    if (text.isEmpty || sending) return;

    setState(() {
      messages.add(TutorMessage(true, text));
      input.clear();
      sending = true;
    });

    try {
      final noteId = widget.notes.isNotEmpty
          ? (widget.notes.first as Map)['id'] as int?
          : null;

      final response = await widget.api.aiChat(
        widget.userId,
        noteId,
        text,
      );

      final answer = response['answer']?.toString() ??
          response['response']?.toString() ??
          response['message']?.toString() ??
          'AI could not generate a response.';

      setState(() {
        messages.add(TutorMessage(false, answer));
      });
    } catch (e) {
      setState(() {
        messages.add(
          TutorMessage(
            false,
            'Backend connection error: $e',
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => sending = false);
      }
    }
  }
}

class TutorBubble extends StatelessWidget {
  const TutorBubble({super.key, required this.message});

  final TutorMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.me ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 680),
        decoration: BoxDecoration(
          color: message.me ? CalmTheme.teal : cardColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: dividerColor(context)),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            height: 1.45,
            color: message.me ? Colors.white : null,
          ),
        ),
      ),
    );
  }
}

class TypingBubble extends StatelessWidget {
  const TypingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: dividerColor(context)),
        ),
        child: const Text('AI is thinking...'),
      ),
    );
  }
}