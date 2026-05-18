import 'package:flutter/material.dart';
import '../../theme/calm_theme.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';

class VoiceTutorScreen extends StatefulWidget {
  const VoiceTutorScreen({super.key, required this.focusTopic});
  final String focusTopic;

  @override
  State<VoiceTutorScreen> createState() => _VoiceTutorScreenState();
}

class _VoiceTutorScreenState extends State<VoiceTutorScreen> {
  String language = 'English';
  bool noisyMode = true;

  @override
  Widget build(BuildContext context) => AnimatedSection(children: [
        const SectionIntro(icon: Icons.record_voice_over_rounded, title: 'Voice And Local Language Tutor', subtitle: 'Hands-free study for commuting, hostels, buses, and students who learn best by speaking.', mascot: StudentMascot(size: 100, mood: MascotMood.happy)),
        const SizedBox(height: 16),
        ResponsiveCalmGrid(minWidth: 230, children: [
          CalmMetric(title: 'Language', value: language, subtitle: 'tutor response style', icon: Icons.translate_rounded, color: CalmTheme.teal),
          CalmMetric(title: 'Noise mode', value: noisyMode ? 'On' : 'Off', subtitle: 'shorter robust answers', icon: Icons.graphic_eq_rounded, color: CalmTheme.orange),
          const CalmMetric(title: 'Mode', value: 'Ask aloud', subtitle: 'listen and quiz', icon: Icons.mic_rounded, color: CalmTheme.purple),
        ]),
        const SizedBox(height: 16),
        SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Voice session', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final item in const ['English', 'Pidgin', 'Yoruba', 'Igbo', 'Hausa', 'French', 'Swahili'])
              ChoiceChip(label: Text(item), selected: language == item, onSelected: (_) => setState(() => language = item)),
          ]),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Noisy environment mode', style: TextStyle(fontWeight: FontWeight.w900)),
            subtitle: const Text('Uses shorter answers, repeatable summaries, and clearer pacing.'),
            value: noisyMode,
            onChanged: (value) => setState(() => noisyMode = value),
          ),
          const SizedBox(height: 8),
          PrimaryCalmButton(label: 'Start voice tutor', icon: Icons.mic_rounded, onTap: () => showFeatureSheet(context, 'Voice prompt ready', 'Ask: Explain ${widget.focusTopic} in $language.\nMode: ${noisyMode ? 'Noisy environment' : 'Normal'}')),
        ])),
      ]);
}
