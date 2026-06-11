import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/ha_providers.dart';

/// Count of `update.*` entities with an available update. Polled via REST since
/// update entities are intentionally excluded from the WebSocket allowlist.
final updateCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(haRestClientProvider).fetchUpdatesCount();
});
