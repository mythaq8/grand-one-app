// lib/services/session_service.dart
// ============================================================
// SessionService — إدارة الجلسة والبيانات المحلية
// ============================================================

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionService {
  static final _auth = Supabase.instance.client.auth;

  // ============================================================
  // Supabase Session
  // ============================================================

  /// هل يوجد جلسة نشطة؟
  static Future<bool> hasSession() async {
    return _auth.currentSession != null;
  }

  /// الحصول على UID الحقيقي من Supabase Auth
  static Future<String?> getIdentifier() async {
    return _auth.currentUser?.id;
  }

  // ============================================================
  // كود الشاب
  // ============================================================

  /// حفظ كود الشاب محلياً
  static Future<void> saveGroomCode(String groomCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('groom_code', groomCode);
  }

  /// قراءة كود الشاب
  static Future<String?> getGroomCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('groom_code');
  }

  /// حذف كود الشاب
  static Future<void> clearGroomCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('groom_code');
  }

  // ============================================================
  // كود الفتاة
  // ============================================================

  /// حفظ كود الفتاة محلياً
  static Future<void> saveBrideCode(String brideCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bride_code', brideCode);
  }

  /// قراءة كود الفتاة
  static Future<String?> getBrideCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('bride_code');
  }

  /// حذف كود الفتاة
  static Future<void> clearBrideCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bride_code');
  }

  // ============================================================
  // تسجيل الخروج
  // ============================================================

  /// مسح الجلسة بالكامل (مع الحفاظ على seen_onboarding)
  static Future<void> clearSession() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // نكمل التنظيف حتى لو فشل تسجيل الخروج
    }

    final prefs = await SharedPreferences.getInstance();

    // ═══ احفظ حالة onboarding قبل المسح ═══
    final onboardingSeen = prefs.getBool('seen_onboarding') ?? false;

    // ═══ امسح كل شيء ═══
    await prefs.clear();

    // ═══ أعِد onboarding ═══
    if (onboardingSeen) {
      await prefs.setBool('seen_onboarding', true);
    }
  }

  // ============================================================
  // Onboarding
  // ============================================================

  /// هل شاهد المستخدم الشاشات التعريفية؟
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('seen_onboarding') ?? false;
  }

  /// تسجيل مشاهدة الـ onboarding
  static Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
  }
}