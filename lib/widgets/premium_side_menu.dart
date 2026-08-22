import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

/// Data model for a single entry in [PremiumSideMenu].
class SideMenuItem {
  const SideMenuItem({
    required this.icon,
    required this.label,
    this.activeIcon,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
}

/// Premium animated side navigation drawer used across the app.
///
/// Drop it into any `Scaffold.drawer:` slot and trigger it with
/// `Scaffold.of(context).openDrawer()` from a menu button.
class PremiumSideMenu extends StatelessWidget {
  const PremiumSideMenu({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onItemTap,
    required this.roleLabel,
    this.onLogout,
  });

  final List<SideMenuItem> items;
  final int currentIndex;
  final ValueChanged<int> onItemTap;
  final String roleLabel;
  final VoidCallback? onLogout;

  /// Closes the drawer, then replaces the route once the exit transition
  /// has finished so both animations never fight each other.
  static void navigateAfterClose(
    BuildContext context,
    Widget destination, {
    required bool isCurrent,
  }) {
    final navigator = Navigator.of(context);
    navigator.pop();
    if (isCurrent) return;
    Future.delayed(const Duration(milliseconds: 300), () {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => destination),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final menuWidth =
        screenWidth < 360 ? screenWidth * 0.86 : min(320.0, screenWidth * 0.8);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: menuWidth,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF161C33), Color(0xFF070A18)],
          ),
          borderRadius: BorderRadius.horizontal(right: Radius.circular(32)),
          border: Border(right: BorderSide(color: AppColors.border)),
        ),
        child: ClipRRect(
          borderRadius:
              const BorderRadius.horizontal(right: Radius.circular(32)),
          child: Stack(
            children: [
              Positioned(
                top: -110,
                right: -100,
                child: _glow(300, AppColors.primary.withValues(alpha: 0.26)),
              ),
              Positioned(
                bottom: -140,
                left: -130,
                child: _glow(340, AppColors.primaryDeep.withValues(alpha: 0.30)),
              ),
              Positioned(
                top: 320,
                left: -150,
                child: _glow(240, AppColors.accent.withValues(alpha: 0.14)),
              ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MenuHeader(roleLabel: roleLabel),
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: MicroLabel('Navigation'),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: items.length,
                        itemBuilder: (context, index) => _NavTile(
                          item: items[index],
                          index: index,
                          selected: index == currentIndex,
                          onTap: () => onItemTap(index),
                        ),
                      ),
                    ),
                    if (onLogout != null) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Divider(color: AppColors.border, height: 1),
                      ),
                      const SizedBox(height: 12),
                      _LogoutTile(onLogout: onLogout!),
                      const SizedBox(height: 8),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14, top: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_car,
                              size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            'DriveOn • v1.0.0',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 0.4,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glow(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

/// Avatar + name + role badge pulled live from the profiles table.
class _MenuHeader extends StatelessWidget {
  const _MenuHeader({required this.roleLabel});

  final String roleLabel;

  Future<Map<String, dynamic>?> _loadProfile(SupabaseClient client) {
    final uid = client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) return Future.value(null);
    return client.from('profiles').select().eq('id', uid).maybeSingle();
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadProfile(client),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final name = (profile?['name'] as String?)?.trim();
        final displayName =
            (name == null || name.isEmpty) ? 'Guest User' : name;
        final image = profile?['profile_image'] as String?;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 12, 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 27,
                  backgroundColor: AppColors.surfaceHigh,
                  backgroundImage:
                      image != null && image.isNotEmpty ? NetworkImage(image) : null,
                  child: image == null || image.isEmpty
                      ? Text(
                          _initials(displayName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.workspace_premium,
                              size: 13, color: AppColors.gold),
                          const SizedBox(width: 5),
                          Text(
                            roleLabel.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final SideMenuItem item;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = selected ? (item.activeIcon ?? item.icon) : item.icon;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + index * 55),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset((1 - t) * -28, 0),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOut,
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: selected ? AppGradients.primary : null,
                        color: selected ? null : AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.45),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        icon,
                        size: 21,
                        color: selected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 19,
                      color: selected
                          ? AppColors.accent
                          : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.22)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onLogout,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      size: 21,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Log Out',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      size: 19, color: AppColors.danger.withValues(alpha: 0.6)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
