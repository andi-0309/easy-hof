import 'dart:async';
import 'package:flutter/services.dart';

class Rotary {
  static const channel = MethodChannel('io.github.andi_0309.easyhof/rotary');
  static final _events = StreamController<double>.broadcast();
  static Stream<double> get events {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'scroll' && call.arguments is num) {
        final delta = (call.arguments as num).toDouble();
        if (delta.isFinite) _events.add(delta);
      }
    });
    return _events.stream;
  }
}
