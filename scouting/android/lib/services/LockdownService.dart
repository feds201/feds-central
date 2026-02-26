import 'package:flutter/services.dart';

class LockdownService {
  static const MethodChannel _channel = MethodChannel('com.pyintel.scoutOps/lockTask');

  static Future<void> startLockTask() async {
    try {
      await _channel.invokeMethod('startLockTask');
    } on PlatformException catch (e) {
      print("Failed to start lock task: '${e.message}'.");
    }
  }

  static Future<void> stopLockTask() async {
    try {
      await _channel.invokeMethod('stopLockTask');
    } on PlatformException catch (e) {
      print("Failed to stop lock task: '${e.message}'.");
    }
  }
}
