// lib/services/remote_config_service.dart
// إعداد بعيد للعناوين — يُحفظ محلياً ويُحدَّث من /api/bootstrap

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

class RemoteConfigService {
  static const _prefsKey = 'grand_one_remote_bootstrap_v1';

  /// تطبيق القيم المحفوظة قبل تهيئة Supabase
  static Future<void> applyCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      AppConfig.applyRemoteBootstrap(map);
      debugPrint('✅ Remote config applied from cache');
    } catch (e) {
      debugPrint('Remote config cache skipped: $e');
    }
  }

  /// تحديث من الشبكة (يؤثر فوراً على API URL، وعلى Supabase في التشغيل التالي)
  static Future<void> refresh() async {
    try {
      final uri = Uri.parse('${AppConfig.denoApiBaseUrl}/api/bootstrap');
      final res = await http.get(uri).timeout(AppConfig.httpTimeout);

      if (res.statusCode != 200) {
        debugPrint('Remote config fetch HTTP ${res.statusCode}');
        return;
      }

      final map = jsonDecode(res.body) as Map<String, dynamic>;
      AppConfig.applyRemoteBootstrap(map);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, res.body);
      debugPrint('✅ Remote config fetched and cached');
    } catch (e) {
      debugPrint('Remote config fetch failed (using fallbacks): $e');
    }
  }
}
