// lib/services/api_exceptions.dart

/// استثناء موحد لكل أخطاء الـAPI
/// 
/// الفكرة: بدلاً من إرجاع [] عند أي خطأ (كما في الكود القديم)،
/// نرمي استثناء محدد حتى تعرف الشاشة ماذا تفعل.
class ApiException implements Exception {
  final String type;
  final String message;
  final int? statusCode;

  ApiException(this.type, this.message, [this.statusCode]);

  // ─── Factory constructors ───

  factory ApiException.network(String message) =>
      ApiException('network', message);

  factory ApiException.unauthorized([String? message]) =>
      ApiException('unauthorized',
          message ?? 'انتهت جلسة الدخول، يرجى تسجيل الدخول مرة أخرى', 401);

  factory ApiException.forbidden([String? message]) =>
      ApiException('forbidden', message ?? 'لا تملك صلاحية لهذا الإجراء', 403);

  factory ApiException.notFound([String? message]) =>
      ApiException('not_found', message ?? 'العنصر غير موجود', 404);

  factory ApiException.badRequest([String? message]) =>
      ApiException('bad_request', message ?? 'بيانات غير صالحة', 400);

  factory ApiException.conflict([String? message]) =>
      ApiException('conflict', message ?? 'تعارض في العملية', 409);

  factory ApiException.tooManyRequests([String? message]) =>
      ApiException('rate_limit',
          message ?? 'محاولات كثيرة، يرجى الانتظار قليلاً', 429);

  factory ApiException.server([String? message]) =>
      ApiException('server', message ?? 'خطأ في الخادم، حاول لاحقاً', 500);

  factory ApiException.unknown([String? message]) =>
      ApiException('unknown', message ?? 'حدث خطأ غير متوقع');

  // ─── رسائل جاهزة للعرض ───

  /// رسالة عربية جاهزة لعرضها في SnackBar
  String get userMessage {
    switch (type) {
      case 'unauthorized':
        return 'انتهت جلسة الدخول، يرجى تسجيل الدخول مرة أخرى';
      case 'forbidden':
        return message.isNotEmpty ? message : 'لا تملك صلاحية لهذا الإجراء';
      case 'not_found':
        return message.isNotEmpty ? message : 'العنصر غير موجود';
      case 'bad_request':
        return message.isNotEmpty ? message : 'بيانات غير صالحة';
      case 'conflict':
        return message.isNotEmpty ? message : 'تعارض في العملية';
      case 'rate_limit':
        return message.isNotEmpty
            ? message
            : 'محاولات كثيرة، يرجى الانتظار قليلاً';
      case 'server':
        // إن وصلت رسالة عربية من الخادم نعرضها؛ وإلا الرسالة العامة.
        if (message.trim().isNotEmpty &&
            !message.toLowerCase().startsWith('failed') &&
            !message.toLowerCase().contains('internal server')) {
          return message.trim();
        }
        return 'خطأ في الخادم، حاول لاحقاً';
      case 'network':
        return 'فشل الاتصال بالإنترنت، تحقق من اتصالك';
      default:
        return message.isNotEmpty ? message : 'حدث خطأ غير متوقع';
    }
  }

  @override
  String toString() => 'ApiException($type, $statusCode): $message';
}