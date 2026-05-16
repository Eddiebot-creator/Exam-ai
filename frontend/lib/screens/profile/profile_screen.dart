import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_client.dart';
import '../../services/biometric_auth_service.dart';
import '../../theme/calm_theme.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/avatar.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/soft_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.user,
    required this.apiBase,
    required this.onLogout,
    required this.onThemeToggle,
    required this.themeMode,
    required this.api,
    required this.userId,
    required this.onUserChanged,
  });

  final Map<String, dynamic> user;
  final String apiBase;
  final VoidCallback onLogout;
  final VoidCallback onThemeToggle;
  final ThemeMode themeMode;
  final ApiClient api;
  final int userId;
  final ValueChanged<Map<String, dynamic>> onUserChanged;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController name;
  late final TextEditingController email;
  late final TextEditingController bio;

  String avatar = 'robot';
  bool saving = false;
  bool biometricEnabled = false;
  bool biometricReady = false;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.user['full_name']?.toString() ?? '');
    email = TextEditingController(text: widget.user['email']?.toString() ?? '');
    bio = TextEditingController(text: widget.user['bio']?.toString() ?? '');
    avatar = widget.user['avatar_character']?.toString() ?? 'robot';
    _loadSecurity();
  }

  Future<void> _loadSecurity() async {
    final prefs = await SharedPreferences.getInstance();
    final ready = await BiometricAuthService.isReady();
    if (!mounted) return;
    setState(() {
      biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      biometricReady = ready;
    });
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    bio.dispose();
    super.dispose();
  }

  String? get profileImageUrl {
    final value = widget.user['profile_image_url']?.toString();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http')) return value;
    return '${widget.apiBase}$value';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionIntro(
          icon: Icons.person_rounded,
          title: widget.user['full_name']?.toString() ?? 'Student',
          subtitle: 'Edit your profile, secure your account, and keep advanced tools neatly tucked away.',
          mascot: ProfileAvatarPreview(
            size: 104,
            avatar: avatar,
            imageUrl: profileImageUrl,
          ),
        ),
        const SizedBox(height: 16),
        _profileDetails(context),
        const SizedBox(height: 16),
        _securityCard(context),
        const SizedBox(height: 16),
        _preferencesCard(),
        const SizedBox(height: 16),
        _moreToolsCard(context),
      ],
    );
  }

  Widget _profileDetails(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profile details', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                ProfileAvatarPreview(
                  size: 112,
                  avatar: avatar,
                  imageUrl: profileImageUrl,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: saving ? null : _uploadProfilePicture,
                      icon: const Icon(Icons.photo_camera_rounded),
                      label: const Text('Upload profile picture'),
                    ),
                    OutlinedButton.icon(
                      onPressed: saving ? null : _chooseAvatar,
                      icon: const Icon(Icons.emoji_emotions_rounded),
                      label: const Text('Change avatar character'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: name,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.badge_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: bio,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Short bio / study goal',
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: saving ? null : _saveProfile,
            icon: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(saving ? 'Saving...' : 'Save profile changes'),
          ),
        ],
      ),
    );
  }

  Widget _securityCard(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Security', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const SoftText('Use password changes and device security where your phone or computer supports it.'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.password_rounded),
            title: const Text('Change password'),
            subtitle: const Text('Update your account password safely.'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _changePassword,
          ),
          SwitchListTile(
            value: biometricEnabled,
            onChanged: biometricReady ? _setBiometric : null,
            secondary: const Icon(Icons.fingerprint_rounded),
            title: const Text('Device security / biometrics'),
            subtitle: Text(
              biometricReady
                  ? 'Use fingerprint, face unlock or device PIN when available.'
                  : 'No biometric/device security support detected.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _preferencesCard() {
    return SoftCard(
      child: Column(
        children: [
          SwitchListTile(
            value: widget.themeMode == ThemeMode.dark,
            onChanged: (_) => widget.onThemeToggle(),
            secondary: const Icon(Icons.contrast_rounded),
            title: const Text('Dark mode'),
            subtitle: const Text('Light mode stays default and calm.'),
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Logout'),
            onTap: widget.onLogout,
          ),
        ],
      ),
    );
  }

  Widget _moreToolsCard(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('More tools', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const SoftText('Advanced features are hidden here so students are not overwhelmed.'),
          const SizedBox(height: 14),
          const ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('Explore advanced tools'),
            children: [
              MoreToolTile(
                icon: Icons.groups_rounded,
                title: 'Community',
                subtitle: 'Groups, rooms and leaderboards',
              ),
              MoreToolTile(
                icon: Icons.storefront_rounded,
                title: 'Marketplace',
                subtitle: 'Sell notes, flashcards and tutoring',
              ),
              MoreToolTile(
                icon: Icons.school_rounded,
                title: 'Teacher Dashboard',
                subtitle: 'Classes, assignments and analytics',
              ),
              MoreToolTile(
                icon: Icons.work_rounded,
                title: 'Career Hub',
                subtitle: 'Internships, CVs and scholarships',
              ),
              MoreToolTile(
                icon: Icons.notifications_rounded,
                title: 'Notifications',
                subtitle: 'Reminders and exam alerts',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _setBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', value);
    setState(() => biometricEnabled = value);
    if (mounted) {
      toast(context, value ? 'Device security enabled.' : 'Device security disabled.');
    }
  }

  Future<void> _saveProfile() async {
    if (name.text.trim().isEmpty || email.text.trim().isEmpty) {
      toast(context, 'Name and email are required.');
      return;
    }
    setState(() => saving = true);
    try {
      final updated = await widget.api.updateProfile(
        widget.userId,
        fullName: name.text,
        email: email.text,
        avatarCharacter: avatar,
        bio: bio.text,
      );
      widget.onUserChanged(updated);
      if (mounted) toast(context, 'Profile updated.');
    } catch (e) {
      if (mounted) toast(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _uploadProfilePicture() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;
    setState(() => saving = true);
    try {
      final updated = await widget.api.uploadProfilePicture(
        widget.userId,
        result.files.single,
      );
      widget.onUserChanged(updated);
      if (mounted) toast(context, 'Profile picture uploaded.');
    } catch (e) {
      if (mounted) toast(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _chooseAvatar() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose avatar character', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final option in avatarOptions)
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.pop(context, option.key),
                    child: Container(
                      width: 92,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: option.key == avatar
                            ? CalmTheme.teal.withOpacity(.12)
                            : cardColor(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: option.key == avatar
                              ? CalmTheme.teal
                              : dividerColor(context),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(option.icon, color: option.color, size: 34),
                          const SizedBox(height: 8),
                          Text(
                            option.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    if (selected != null) setState(() => avatar = selected);
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    bool busy = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: current,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Current password'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: next,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New password'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirm,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm new password'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: busy ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () async {
                          if (next.text.length < 6) {
                            toast(context, 'New password must be at least 6 characters.');
                            return;
                          }
                          if (next.text != confirm.text) {
                            toast(context, 'New passwords do not match.');
                            return;
                          }
                          setDialogState(() => busy = true);
                          try {
                            await widget.api.changePassword(
                              widget.userId,
                              current.text,
                              next.text,
                            );
                            if (dialogContext.mounted) Navigator.pop(dialogContext);
                            if (mounted) toast(this.context, 'Password changed.');
                          } catch (e) {
                            if (context.mounted) {
                              toast(context, e.toString().replaceFirst('Exception: ', ''));
                            }
                          } finally {
                            if (context.mounted) setDialogState(() => busy = false);
                          }
                        },
                  child: Text(busy ? 'Saving...' : 'Update password'),
                ),
              ],
            );
          },
        );
      },
    );

    current.dispose();
    next.dispose();
    confirm.dispose();
  }
}

class MoreToolTile extends StatelessWidget {
  const MoreToolTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: CalmTheme.teal),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
