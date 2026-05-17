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
    required this.onVoice,
  });

  final ApiClient api;
  final int userId;
  final List<dynamic> notes;
  final VoidCallback onVoice;

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
    final screen = MediaQuery.sizeOf(context);
    final mobile = screen.width < 430;
    final chatHeight = mobile ? max<double>(520, screen.height * .70) : min<double>(660, screen.height - 190);

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
                  padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 430 ? 14 : 16),
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
                        label: 'Voice mode',
                        onTap: widget.onVoice,
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
                    reverse: false,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (sending ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == messages.length) return const TypingBubble();
                      return AnimatedTutorBubble(message: messages[i], index: i);
                    },
                  ),
                ),
                Divider(height: 1, color: dividerColor(context)),
                TutorComposer(input: input, sending: sending, onAttach: _pickImage, onSend: _send),
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
            'Attached image: ${result.files.single.name}. I will use it as study context when image extraction is available for this device.',
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
            'I could not reach the tutor cleanly. ${e.toString().replaceFirst('Exception: ', '')}\n\nTry again in a moment, or ask a shorter question.',
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

class AnimatedTutorBubble extends StatelessWidget {
  const AnimatedTutorBubble({super.key, required this.message, required this.index});

  final TutorMessage message;
  final int index;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        key: ValueKey('$index-${message.text.hashCode}'),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(message.me ? 18 * (1 - value) : -18 * (1 - value), 8 * (1 - value)), child: child),
        ),
        child: TutorBubble(message: message),
      );
}

class TutorBubble extends StatelessWidget {
  const TutorBubble({super.key, required this.message});

  final TutorMessage message;

  @override
  Widget build(BuildContext context) => Align(
        alignment: message.me ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width < 430 ? MediaQuery.sizeOf(context).width * .82 : 760),
          decoration: BoxDecoration(
            color: message.me ? CalmTheme.teal : cardColor(context),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(8),
              topRight: const Radius.circular(8),
              bottomLeft: Radius.circular(message.me ? 8 : 2),
              bottomRight: Radius.circular(message.me ? 2 : 8),
            ),
            border: Border.all(color: message.me ? CalmTheme.teal : dividerColor(context)),
            boxShadow: softShadow(context),
          ),
          child: SelectableText(
            message.text,
            style: TextStyle(
              height: 1.5,
              fontSize: 15,
              color: message.me ? Colors.white : null,
            ),
          ),
        ),
      );
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
        decoration: BoxDecoration(color: cardColor(context), borderRadius: BorderRadius.circular(8), border: Border.all(color: dividerColor(context))),
        child: const _TypingDots(),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < 3; i++)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 7,
              height: 7 + (controller.value * 6 - i * 2).clamp(0, 4),
              decoration: BoxDecoration(color: CalmTheme.teal.withOpacity(.35 + .45 * ((controller.value + i / 3) % 1)), borderRadius: BorderRadius.circular(7)),
            ),
        ]),
      );
}

class TutorComposer extends StatelessWidget {
  const TutorComposer({super.key, required this.input, required this.sending, required this.onAttach, required this.onSend});
  final TextEditingController input;
  final bool sending;
  final VoidCallback onAttach;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 430;
    return Container(
      padding: EdgeInsets.all(mobile ? 10 : 14),
      color: Theme.of(context).colorScheme.surface.withOpacity(.72),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Tooltip(
            message: 'Attach image',
            child: IconButton.filledTonal(onPressed: sending ? null : onAttach, icon: const Icon(Icons.attach_file_rounded)),
          ),
          SizedBox(width: mobile ? 6 : 8),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(boxShadow: sending ? [] : softShadow(context)),
              child: TextField(
                controller: input,
                minLines: 1,
                maxLines: mobile ? 3 : 4,
                onSubmitted: (_) {
                  if (!sending) onSend();
                },
                decoration: const InputDecoration(hintText: 'Ask your tutor...'),
              ),
            ),
          ),
          SizedBox(width: mobile ? 6 : 8),
          FloatingActionButton.small(
            tooltip: 'Send',
            onPressed: sending ? null : onSend,
            child: sending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.arrow_upward_rounded),
          ),
        ],
      ),
    );
  }
}
