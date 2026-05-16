import 'package:flutter/material.dart';
import '../theme/calm_theme.dart';
import '../utils/ui_helpers.dart';

class AvatarOption {
  const AvatarOption(this.key, this.label, this.icon, this.color);
  final String key;
  final String label;
  final IconData icon;
  final Color color;
}

const avatarOptions = [
  AvatarOption('robot', 'Robot', Icons.smart_toy_rounded, CalmTheme.teal),
  AvatarOption('fox', 'Fox', Icons.pets_rounded, CalmTheme.orange),
  AvatarOption('owl', 'Owl', Icons.school_rounded, CalmTheme.indigo),
  AvatarOption('cat', 'Cat', Icons.cruelty_free_rounded, CalmTheme.rose),
  AvatarOption('panda', 'Panda', Icons.emoji_nature_rounded, CalmTheme.green),
  AvatarOption('star', 'Star', Icons.auto_awesome_rounded, CalmTheme.purple),
  AvatarOption('rocket', 'Rocket', Icons.rocket_launch_rounded, CalmTheme.blue),
];

class ProfileAvatarPreview extends StatelessWidget {
  const ProfileAvatarPreview({super.key, required this.size, required this.avatar, this.imageUrl});
  final double size;
  final String avatar;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final option = avatarOptions.firstWhere((item) => item.key == avatar, orElse: () => avatarOptions.first);
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(radius: size / 2, backgroundColor: option.color.withOpacity(.12), backgroundImage: NetworkImage(imageUrl!));
    }
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: option.color.withOpacity(.12), border: Border.all(color: option.color.withOpacity(.32)), boxShadow: softShadow(context)), child: Icon(option.icon, size: size * .42, color: option.color));
  }
}
