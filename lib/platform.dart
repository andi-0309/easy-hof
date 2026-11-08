import 'dart:convert';
import 'package:flutter/services.dart';

class Device {
  static const channel = MethodChannel('eu.zerver.easyhof/device');
  static Future<T?> call<T>(String method, [Map<String, dynamic>? args]) =>
      channel.invokeMethod<T>(method, args);
  static Future<Map<String, dynamic>> snapshot() async =>
      Map<String, dynamic>.from(
        jsonDecode(await call<String>('snapshot') ?? '{}') as Map,
      );
  static Future<void> save(Map<String, dynamic> session) async {
    await call('saveSession', {'json': jsonEncode(session)});
  }

  static Future<void> speak(String text, String language) async {
    await call('speak', {'text': text, 'language': language});
  }
}
