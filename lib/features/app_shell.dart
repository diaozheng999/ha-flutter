import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/features/home/home_overview_screen.dart';
import 'package:ha_flutter/features/maintenance/maintenance_providers.dart';
import 'package:ha_flutter/features/maintenance/maintenance_screen.dart';
import 'package:ha_flutter/features/room/rooms_screen.dart';
import 'package:ha_flutter/features/scenes/scenes_config_screen.dart';
import 'package:ha_flutter/features/security/security_screen.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/background/background_engine.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';

/// Index of the active tab, so cross-screen taps (e.g. summary chips) can
/// switch tabs.
final activeTabProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _screens = [
    HomeOverviewScreen(),
    RoomsScreen(),
    SecurityScreen(),
    ScenesConfigScreen(),
    MaintenanceScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final init = ref.watch(dashboardInitProvider);
    final index = ref.watch(activeTabProvider);
    final updateCount = ref.watch(updateCountProvider).valueOrNull ?? 0;

    final body = init.isLoading
        ? const Center(child: CircularProgressIndicator())
        : IndexedStack(index: index, children: _screens);

    return Stack(
      children: [
        const Positioned.fill(child: AppBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          // No bottomNavigationBar — the dock is a floating Positioned overlay.
          // Inject extra bottom padding so SafeArea-wrapped screens clear the dock.
          body: _BottomPaddingInject(child: body),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _FloatingDock(
            index: index,
            updateCount: updateCount,
            onTap: (i) => ref.read(activeTabProvider.notifier).state = i,
          ),
        ),
      ],
    );
  }
}

/// Adds extra bottom padding to MediaQuery so every tab's SafeArea clears the
/// floating dock regardless of platform safe-area.
class _BottomPaddingInject extends StatelessWidget {
  final Widget child;
  const _BottomPaddingInject({required this.child});

  static const _dockExtra = 80.0;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(
        padding: mq.padding.copyWith(
          bottom: mq.padding.bottom + _dockExtra,
        ),
      ),
      child: child,
    );
  }
}

class _FloatingDock extends StatelessWidget {
  final int index;
  final int updateCount;
  final ValueChanged<int> onTap;

  const _FloatingDock({
    required this.index,
    required this.updateCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final width = MediaQuery.sizeOf(context).width;
    // Float as a pill on large screens; stretch edge-to-edge on small ones.
    final float = width >= 720;
    final dockWidth = float ? 520.0 : width.toDouble();
    final radius = float
        ? BorderRadius.circular(tokens.cardRadius * 2)
        : BorderRadius.only(
            topLeft: Radius.circular(tokens.cardRadius),
            topRight: Radius.circular(tokens.cardRadius),
          );

    return Padding(
      padding: EdgeInsets.only(bottom: safeBottom + (float ? 16 : 0)),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              width: dockWidth,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: tokens.glassFill,
                borderRadius: radius,
                border: Border.all(color: tokens.glassBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
              _DockItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Home',
                selected: index == 0,
                onTap: () => onTap(0),
              ),
              _DockItem(
                icon: Icons.meeting_room_outlined,
                selectedIcon: Icons.meeting_room,
                label: 'Rooms',
                selected: index == 1,
                onTap: () => onTap(1),
              ),
              _DockItem(
                icon: Icons.security_outlined,
                selectedIcon: Icons.security,
                label: 'Security',
                selected: index == 2,
                onTap: () => onTap(2),
              ),
              _DockItem(
                icon: Icons.auto_awesome_outlined,
                selectedIcon: Icons.auto_awesome,
                label: 'Scenes',
                selected: index == 3,
                onTap: () => onTap(3),
              ),
              _DockItem(
                icon: Icons.build_outlined,
                selectedIcon: Icons.build,
                label: 'Maintenance',
                selected: index == 4,
                badge: updateCount > 0,
                onTap: () => onTap(4),
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final bool badge;
  final VoidCallback onTap;

  const _DockItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = selected ? tokens.onAccent : tokens.offMuted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: selected
            ? BoxDecoration(
                color: tokens.onAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(28),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: badge,
              child: Icon(selected ? selectedIcon : icon, color: color, size: 22),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
