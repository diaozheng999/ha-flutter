import 'dart:async';
import 'package:flutter/foundation.dart';

/// Coalesces rapid callbacks (e.g. slider drags) into a single trailing call.
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 200)});

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() => _timer?.cancel();
}
