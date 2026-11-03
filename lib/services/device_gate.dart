import 'package:shared_preferences/shared_preferences.dart';

import 'api_exceptions.dart';
import 'api_service.dart';
import 'device_fingerprint_service.dart';

enum DeviceGateStatus {
  /// الربط نجح أو الحساب مرتبط مسبقاً
  allowed,

  /// الجهاز تجاوز حد الحسابين — يجب تسجيل الخروج
  blocked,

  /// فشل الاتصال ولم يُؤكد الربط من قبل — منع المتابعة (fail-closed)
  unavailable,
}

class DeviceGateResult {
  final DeviceGateStatus status;
  final String message;

  const DeviceGateResult._(this.status, this.message);

  factory DeviceGateResult.allowed() =>
      const DeviceGateResult._(DeviceGateStatus.allowed, '');

  factory DeviceGateResult.blocked([String? message]) => DeviceGateResult._(
        DeviceGateStatus.blocked,
        message ?? 'تم تجاوز الحد المسموح: حسابان فقط لكل جهاز',
      );

  factory DeviceGateResult.unavailable([String? message]) => DeviceGateResult._(
        DeviceGateStatus.unavailable,
        message ??
            'تعذر التحقق من الجهاز. تأكد من الاتصال بالإنترنت ثم أعد المحاولة.',
      );

  bool get isAllowed => status == DeviceGateStatus.allowed;
}

/// بوابة إلزامية: لا يدخل المستخدم التطبيق دون ربط ناجح للجهاز (أو تأكيد سابق لنفس البصمة).
class DeviceGate {
  static const _linkedFpKey = 'grand_one_device_linked_fp_v1';

  static bool isLimitMessage(String message) {
    return message.contains('حسابان فقط') || message.contains('تجاوز الحد');
  }

  static Future<DeviceGateResult> ensureRegistered() async {
    final fp = await DeviceFingerprintService.getOrCreate();
    final prefs = await SharedPreferences.getInstance();

    try {
      await ApiService.registerDeviceFingerprint(
        fingerprint: fp,
        platform: DeviceFingerprintService.platformLabel(),
      );
      await prefs.setString(_linkedFpKey, fp);
      return DeviceGateResult.allowed();
    } on ApiException catch (e) {
      if (e.statusCode == 403 || isLimitMessage(e.message)) {
        await prefs.remove(_linkedFpKey);
        return DeviceGateResult.blocked(e.message);
      }

      // شبكة / خادم: اسمح فقط إن رُبطت نفس البصمة بنجاح سابقاً على هذا التثبيت
      final linked = prefs.getString(_linkedFpKey);
      if (linked != null && linked == fp) {
        return DeviceGateResult.allowed();
      }
      return DeviceGateResult.unavailable(e.message);
    } catch (e) {
      final linked = prefs.getString(_linkedFpKey);
      if (linked != null && linked == fp) {
        return DeviceGateResult.allowed();
      }
      return DeviceGateResult.unavailable(e.toString());
    }
  }

  static Future<void> clearLocalLinkFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_linkedFpKey);
  }
}
