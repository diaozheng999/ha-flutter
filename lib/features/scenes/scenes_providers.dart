import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/ha/models/entity_state.dart';

/// All `scene.*` entities, discovered via REST (scenes carry no useful live
/// state, so they aren't on the WebSocket allowlist).
final scenesProvider = FutureProvider<List<EntityState>>((ref) async {
  final scenes = await ref.watch(haRestClientProvider).fetchByDomain('scene');
  scenes.sort((a, b) => a.friendlyName.compareTo(b.friendlyName));
  return scenes;
});
