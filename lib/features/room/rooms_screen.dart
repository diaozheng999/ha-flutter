import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/features/home/widgets/room_grid.dart';
import 'package:ha_flutter/shared/widgets/connection_chip.dart';

/// The Rooms tab: a grid of rooms; tapping a card pushes the room detail.
class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rooms'), actions: const [ConnectionChip()]),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: const RoomGrid(),
        ),
      ),
    );
  }
}
