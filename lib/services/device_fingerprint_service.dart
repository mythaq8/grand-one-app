import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// بصمة جهاز مستقرة قدر الإمكان:
/// - Android: ANDROID_ID (تبقى بعد مسح بيانات التطبيق / إعادة التثبيت)
/// - غير ذلك: مُعرّف تثبيت في SharedPreferences
///
/// ملاحظة: على الويب أو بعد إعادة ضبط المصنع يمكن تجاوز الحد — الإنفاذ الحقيقي في قاعدة البيانات.
class DeviceFingerprintService {
  static const _prefsKey = 'grand_one_device_fingerprint_v2';
  static const _legacyPrefsKey = 'grand_one_device_fingerprint_v1';
  static const _channel = MethodChannel('com.grandone.app/device_id');

  static Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();

    // فضّل بصمة العتاد دائماً عند توفرها (توحّد الحسابات بعد مسح البيانات)
    final hardware = await _fingerprintFromHardware();
    if (hardware != null) {
      await prefs.setString(_prefsKey, hardware);
      return hardware;
    }

    final existing = prefs.getString(_prefsKey);
    if (existing != null && existing.length >= 16) {
      return existing;
    }

    final legacy = prefs.getString(_legacyPrefsKey);
    if (legacy != null && legacy.length >= 16) {
      await prefs.setString(_prefsKey, legacy);
      return legacy;
    }

    final generated = _generateInstallFingerprint();
    await prefs.setString(_prefsKey, generated);
    return generated;
  }

  static Future<String?> _fingerprintFromHardware() async {
    final hardwareId = await _readHardwareId();
    if (hardwareId == null || hardwareId.isEmpty) return null;
    final digest = sha256.convert(utf8.encode('grand_one|$hardwareId'));
    return digest.toString();
  }

  static Future<String?> _readHardwareId() async {
    if (kIsWeb) return null;
    if (defaultTargetPlatform != TargetPlatform.android) return null;

    try {
      final id = await _channel.invokeMethod<String>('getAndroidId');
      final trimmed = id?.trim();
      if (trimmed == null || trimmed.isEmpty || trimmed == '9774d56d682e549c') {
        return null;
      }
      return trimmed;
    } on PlatformException catch (e) {
      debugPrint('device_id channel: ${e.message}');
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  static String _generateInstallFingerprint() {
    final rand = Random.secure();
    final bytes = List<int>.generate(32, (_) => rand.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String platformLabel() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return defaultTargetPlatform.name;
    }
  }
}
