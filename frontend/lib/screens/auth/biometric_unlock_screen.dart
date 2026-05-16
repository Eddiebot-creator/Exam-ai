import 'package:flutter/material.dart';

import '../../widgets/buttons.dart';
import '../../widgets/calm_background.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';

class BiometricUnlockScreen extends StatelessWidget {
  const BiometricUnlockScreen({
    super.key,
    required this.user,
    required this.onUnlock,
    required this.onUsePassword,
    required this.onThemeToggle,
    required this.themeMode,
  });

  final Map<String, dynamic> user;
  final VoidCallback onUnlock;
  final VoidCallback onUsePassword;
  final VoidCallback onThemeToggle;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    final firstName = user['full_name']?.toString().split(' ').first ?? 'Scholar';

    return Scaffold(
      body: CalmBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SoftCard(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const StudentMascot(size: 130, mood: MascotMood.wave),
                      const SizedBox(height: 18),
                      Text(
                        'Welcome back, $firstName',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const SoftText(
                        'Use your device security to reopen your calm study space.',
                        align: TextAlign.center,
                      ),
                      const SizedBox(height: 22),
                      PrimaryCalmButton(
                        label: 'Unlock with device security',
                        icon: Icons.fingerprint_rounded,
                        onTap: onUnlock,
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: onUsePassword,
                        icon: const Icon(Icons.password_rounded),
                        label: const Text('Use email and password instead'),
                      ),
                      const SizedBox(height: 6),
                      IconButton.filledTonal(
                        tooltip: 'Light / dark mode',
                        onPressed: onThemeToggle,
                        icon: Icon(
                          themeMode == ThemeMode.light
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
