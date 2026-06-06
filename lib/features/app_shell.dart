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

/// Index of the active tab, so cross-screen taps (e.g. summary chips) can
/// switch tabs.
final activeTabProvider = StateProvider<int>((ref) => 0);

/// Root post-auth scaffold: a single background layer behind a transparent
/// scaffold whose body is an [IndexedStack] of the five tabs.
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
    // Kick off REST bootstrap + WebSocket connect once.
    final init = ref.watch(dashboardInitProvider);
    final index = ref.watch(activeTabProvider);
    final updateCount = ref.watch(updateCountProvider).valueOrNull ?? 0;

    return Stack(
      children: [
        const Positioned.fill(child: AppBackground()),
        Scaffold(
          body: init.isLoading
              ? const Center(child: CircularProgressIndicator())
              : IndexedStack(index: index, children: _screens),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) =>
                ref.read(activeTabProvider.notifier).state = i,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.meeting_room_outlined),
                selectedIcon: Icon(Icons.meeting_room),
                label: 'Rooms',
              ),
              const NavigationDestination(
                icon: Icon(Icons.security_outlined),
                selectedIcon: Icon(Icons.security),
                label: 'Security',
              ),
              const NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome),
                label: 'Scenes',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: updateCount > 0,
                  child: const Icon(Icons.build_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: updateCount > 0,
                  child: const Icon(Icons.build),
                ),
                label: 'Maintenance',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
