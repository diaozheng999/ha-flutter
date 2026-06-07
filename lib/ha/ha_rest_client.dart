import 'dart:convert';

import 'package:ha_flutter/ha/ha_connection.dart';
import 'package:ha_flutter/ha/models/entity_state.dart';
import 'package:http/http.dart' as http;

/// One-shot REST reads against the HA API: the initial state bootstrap and the
/// history endpoint used by the DB-cabinet graph.
class HaRestClient {
  final HaConnection _connection;
  final http.Client _http;

  HaRestClient(this._connection, {http.Client? client})
      : _http = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final token = await _connection.getAccessToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Fetches all entity states, returning only those in [filter] (the
  /// allowlist). Used to populate the cache before the first WebSocket diff.
  Future<List<EntityState>> fetchStates(Set<String> filter) async {
    final res = await _http.get(
      Uri.parse('${_connection.instanceUrl}/api/states'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception('GET /api/states failed: ${res.statusCode}');
    }
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    return [
      for (final json in list)
        if (filter.contains(json['entity_id']))
          EntityState.fromJson(json),
    ];
  }

  /// Fetches the last [hours] of history for a single entity, returning
  /// `(timestamp, numericState)` points suitable for a line chart.
  Future<List<({DateTime time, double value})>> fetchHistory(
    String entityId, {
    int hours = 24,
  }) async {
    final start = DateTime.now().toUtc().subtract(Duration(hours: hours));
    final uri = Uri.parse(
      '${_connection.instanceUrl}/api/history/period/'
      '${start.toIso8601String()}'
      '?filter_entity_id=$entityId&minimal_response&no_attributes',
    );
    final res = await _http.get(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('GET /api/history failed: ${res.statusCode}');
    }
    final outer = jsonDecode(res.body) as List;
    if (outer.isEmpty) return const [];
    final series = (outer.first as List).cast<Map<String, dynamic>>();
    final points = <({DateTime time, double value})>[];
    for (final p in series) {
      final value = double.tryParse(p['state']?.toString() ?? '');
      final time = DateTime.tryParse(p['last_changed']?.toString() ?? '');
      if (value != null && time != null) {
        points.add((time: time, value: value));
      }
    }
    return points;
  }

  /// Fetches all entities in a domain (e.g. `scene`), used to discover dynamic
  /// entity sets that aren't worth a permanent WebSocket subscription.
  Future<List<EntityState>> fetchByDomain(String domain) async {
    final res = await _http.get(
      Uri.parse('${_connection.instanceUrl}/api/states'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception('GET /api/states failed: ${res.statusCode}');
    }
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    return [
      for (final json in list)
        if ((json['entity_id'] as String).startsWith('$domain.'))
          EntityState.fromJson(json),
    ];
  }

  /// Counts `update.*` entities currently reporting an available update
  /// (state `on`). Used by the maintenance badge; not in the WS allowlist.
  Future<int> fetchUpdatesCount() async {
    final res = await _http.get(
      Uri.parse('${_connection.instanceUrl}/api/states'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception('GET /api/states failed: ${res.statusCode}');
    }
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    return list
        .where((e) =>
            (e['entity_id'] as String).startsWith('update.') &&
            e['state'] == 'on')
        .length;
  }

  /// Builds an authenticated image/camera proxy URL with a cache-busting token.
  Future<Uri> proxyImageUrl(String path, {bool cacheBust = false}) async {
    final token = await _connection.getAccessToken();
    final buster = cacheBust ? '&_=${DateTime.now().millisecondsSinceEpoch}' : '';
    return Uri.parse(
        '${_connection.instanceUrl}$path?access_token=$token$buster');
  }
}
