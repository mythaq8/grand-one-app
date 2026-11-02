// lib/config.dart
// ============================================================
// AppConfig — إعدادات التطبيق العامة
// ============================================================

import 'package:flutter/foundation.dart';

/// إعدادات التطبيق العامة
///
/// يحتوي على:
/// - إعدادات Supabase
/// - منطق العمل (business logic constants)
/// - إعدادات Deno API
/// - إعدادات الشبكة (timeouts)
/// - معلومات التطبيق
class AppConfig {
  // ============================================================
  // إعدادات Supabase (قيم افتراضية + تجاوز من Remote Config)
  // ============================================================

  // ضع قيم مشروع Golden Party الجديد هنا محلياً — لا تستخدم مشروع ميثاق
  static const String _defaultSupabaseUrl =
      'https://lowaodnfythczegmmdvn.supabase.co';

  /// مفتاح Supabase العام (anon) — افتراضي لمشروع Golden Party فقط
  ///
  /// ⚠️ ملاحظة أمنية:
  /// - هذا المفتاح آمن للاستخدام في العميل
  /// - الحماية الحقيقية عبر RLS + GRANT على الجداول
  /// - لا تضع أبداً `service_role_key` في التطبيق
  static const String _defaultSupabaseAnonKey =
      'sb_publishable_cKbgp8Pe4R12iN_a0scFqQ_N9lS61-L';

  static String _supabaseUrl = _defaultSupabaseUrl;
  static String _supabaseAnonKey = _defaultSupabaseAnonKey;
  static String _productionApiUrl = 'https://golden-party.mythaq8.deno.net';

  /// رابط مشروع Supabase (قد يُحدَّث من /api/bootstrap)
  static String get supabaseUrl => _supabaseUrl;

  static String get supabaseAnonKey => _supabaseAnonKey;

  // ============================================================
  // منطق العمل
  // ============================================================

  /// الحد الأقصى لعدد الرغبات التي يمكن للشاب إرسالها دفعة واحدة
  static const int maxGroomRequests = 5;

  /// الحد الأقصى لعدد الرسائل في غرفة محادثة واحدة
  static const int maxChatMessages = 50;

  /// مدة صلاحية غرفة المحادثة بالساعات
  static const int chatRoomHoursLimit = 48;

  // ============================================================
  // Deno API
  // ============================================================

  /// رابط الإنتاج (قد يُحدَّث من Remote Config)
  static String get productionApiUrl => _productionApiUrl;

  /// رابط التطوير المحلي
  static const String localApiUrl = 'http://localhost:8000';

  /// فعّل فقط عند تطوير الـ API محلياً:
  /// flutter run --dart-define=USE_LOCAL_API=true
  static const bool useLocalApi =
      bool.fromEnvironment('USE_LOCAL_API', defaultValue: false);

  /// Base URL لخدمة Deno API
  ///
  /// يُستخدم في:
  /// - ApiService (سوق الخدمات، الزواج، المحادثة)
  /// - SettingsScreen (حذف الحساب)
  static String get denoApiBaseUrl =>
      (kDebugMode && useLocalApi) ? localApiUrl : _productionApiUrl;

  /// تطبيق إعداد بعيد من `/api/bootstrap`
  static void applyRemoteBootstrap(Map<String, dynamic> map) {
    final su = map['supabase_url'];
    final sk = map['supabase_anon_key'];
    final api = map['deno_api_base_url'];

    if (su is String && su.startsWith('https://')) {
      _supabaseUrl = su.trim();
    }
    if (sk is String && sk.length > 20) {
      _supabaseAnonKey = sk.trim();
    }
    if (api is String &&
        (api.startsWith('https://') || api.startsWith('http://localhost'))) {
      _productionApiUrl = api.trim().replaceAll(RegExp(r'/$'), '');
    }
  }

  // ============================================================
  // Timeouts
  // ============================================================

  /// مهلة طلبات HTTP الافتراضية
  static const Duration httpTimeout = Duration(seconds: 30);

  /// مهلة فحص جلسة المصادقة
  static const Duration authTimeout = Duration(seconds: 10);

  /// مهلة انتظار حدث Auth على البداية
  static const Duration authStateTimeout = Duration(seconds: 3);

  // ============================================================
  // معلومات التطبيق
  // ============================================================

  /// اسم التطبيق
  static const String appName = 'Golden Party';

  /// اسم التطبيق الكامل
  static const String appFullName = 'Golden Party - خدمات الأعراس';

  /// نسخة التطبيق
  static const String appVersion = '1.0.0';

  // ============================================================
  // Environment
  // ============================================================

  /// هل التطبيق في وضع Debug؟
  ///
  /// استخدمه لتشغيل/إيقاف:
  /// - طباعة logs
  /// - أدوات تشخيصية
  /// - validation checks
  static bool get isDebugMode => kDebugMode;

  // ============================================================
  // Validation
  // ============================================================

  /// فحص صحة الإعدادات
  ///
  /// يُنفّذ في وضع Debug فقط.
  /// يكتشف الأخطاء الشائعة مبكراً.
  static void validate() {
    assert(
      supabaseUrl.isNotEmpty,
      '❌ supabaseUrl مطلوب',
    );

    assert(
      supabaseUrl.startsWith('https://'),
      '❌ supabaseUrl يجب أن يبدأ بـ https://',
    );

    assert(
      supabaseAnonKey.isNotEmpty,
      '❌ supabaseAnonKey مطلوب',
    );

    assert(
      maxGroomRequests > 0 && maxGroomRequests <= 10,
      '❌ maxGroomRequests يجب أن يكون بين 1 و 10',
    );

    assert(
      maxChatMessages > 0 && maxChatMessages <= 1000,
      '❌ maxChatMessages يجب أن يكون بين 1 و 1000',
    );

    assert(
      chatRoomHoursLimit > 0 && chatRoomHoursLimit <= 720,
      '❌ chatRoomHoursLimit يجب أن يكون بين 1 و 720 (30 يوماً)',
    );

    assert(
      denoApiBaseUrl.isNotEmpty,
      '❌ denoApiBaseUrl مطلوب',
    );

    assert(
      denoApiBaseUrl.startsWith('https://') ||
          (kDebugMode && useLocalApi && denoApiBaseUrl == localApiUrl),
      '❌ استخدم HTTPS للإنتاج، أو localhost مع USE_LOCAL_API=true في Debug فقط',
    );

    assert(
      httpTimeout.inSeconds > 0,
      '❌ httpTimeout يجب أن يكون أكبر من صفر',
    );

    debugPrint('✅ AppConfig.validate() passed');
  }
}