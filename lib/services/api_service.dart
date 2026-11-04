// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import 'api_exceptions.dart';

class ApiService {
  static String get baseUrl => AppConfig.denoApiBaseUrl;
  static const Duration _defaultTimeout = AppConfig.httpTimeout;


  // بناء Headers مع التوكن (مع تجديد تلقائي)
  static Future<Map<String, String>> _getHeaders() async {
    final supabase = Supabase.instance.client;
    var session = supabase.auth.currentSession;

    if (session == null) {
      throw ApiException.unauthorized();
    }

    final expiresAt = session.expiresAt;
    if (expiresAt != null) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (expiresAt <= now + 60) {
        try {
          final response = await supabase.auth.refreshSession();
          session = response.session;

          if (session == null) {
            throw ApiException.unauthorized();
          }
        } on ApiException {
          rethrow;
        } catch (e) {
          final msg = e.toString().toLowerCase();

          if (msg.contains('network') ||
              msg.contains('socket') ||
              msg.contains('timeout') ||
              msg.contains('connection') ||
              msg.contains('failed host lookup')) {
            throw ApiException.network(
              'تعذر تحديث الجلسة، تحقق من الإنترنت',
            );
          }

          throw ApiException.unauthorized();
        }
      }
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${session.accessToken}',
    };
  }

  // دالة موحدة لكل طلبات Deno
  static Future<dynamic> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final headers = await _getHeaders();
    var uri = Uri.parse('$baseUrl$path');

    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }

    try {
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(_defaultTimeout);
          break;
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(_defaultTimeout);
          break;
        case 'PUT':
          response = await http
              .put(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(_defaultTimeout);
          break;
        case 'PATCH':
          response = await http
              .patch(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(_defaultTimeout);
          break;
        case 'DELETE':
          response = await http
              .delete(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
              .timeout(_defaultTimeout);
          break;
        default:
          throw ArgumentError('Method غير مدعوم: $method');
      }

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.network('فشل الاتصال بالخادم: $e');
    }
  }

  // معالجة الاستجابة
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 204) {
      return null;
    }

    dynamic data;
    final responseBody = response.bodyBytes.isNotEmpty 
        ? utf8.decode(response.bodyBytes) 
        : '';

    if (responseBody.isNotEmpty) {
      try {
        data = jsonDecode(responseBody);
      } catch (_) {
        data = responseBody;
      }
    }

    String errorMessage = '';
    if (data is Map) {
      errorMessage = (data['error'] ?? data['message'] ?? '').toString().trim();
    } else if (data is String) {
      errorMessage = data.trim();
    }

    switch (response.statusCode) {
      case 200:
      case 201:
        return data;

      case 400:
        throw ApiException.badRequest(errorMessage);

      case 401:
        throw ApiException.unauthorized(
          errorMessage.isNotEmpty ? errorMessage : null,
        );

      case 403:
        throw ApiException.forbidden(
          errorMessage.isNotEmpty ? errorMessage : null,
        );

      case 404:
        throw ApiException.notFound(
          errorMessage.isNotEmpty ? errorMessage : null,
        );

      case 409:
        throw ApiException.conflict(
          errorMessage.isNotEmpty ? errorMessage : null,
        );

      case 429:
        throw ApiException.tooManyRequests(
          errorMessage.isNotEmpty ? errorMessage : null,
        );

      case 500:
      case 502:
      case 503:
        throw ApiException.server(
          errorMessage.isNotEmpty ? errorMessage : null,
        );

      default:
        throw ApiException.unknown('رمز الحالة: ${response.statusCode}');
    }
  }

  // Helpers للقراءة الآمنة
  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  static List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  /// تسجيل audit / login_attempt عبر Deno (بدون الاعتماد على INSERT من العميل)
  static Future<void> logAuthEvent({
    required String kind,
    required String identifier,
    required bool success,
    String? action,
    String? details,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/auth/events');
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      final token =
          Supabase.instance.client.auth.currentSession?.accessToken;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'kind': kind,
              'identifier': identifier,
              'success': success,
              if (action != null) 'action': action,
              if (details != null) 'details': details,
            }),
          )
          .timeout(_defaultTimeout);
    } catch (e) {
      // لا نكسر تدفق المصادقة بسبب فشل السجل
      assert(() {
        // ignore: avoid_print
        print('⚠️ logAuthEvent failed: $e');
        return true;
      }());
    }
  }


  // ============================================================
  // التواصل والجهاز
  // ============================================================

  static Future<bool> contactAdmin(Map<String, dynamic> message) async {
    final text = message['message']?.toString().trim();

    if (text == null || text.isEmpty) return false;

    try {
      await _request(
        method: 'POST',
        path: '/api/contact',
        body: {'message': text},
      );
      return true;
    } on ApiException {
      return false;
    }
  }

  /// ربط بصمة الجهاز (حد حسابين لكل جهاز)
  static Future<Map<String, dynamic>> registerDeviceFingerprint({
    required String fingerprint,
    String? platform,
  }) async {
    final data = await _request(
      method: 'POST',
      path: '/api/device/register',
      body: {
        'fingerprint': fingerprint,
        if (platform != null && platform.isNotEmpty) 'platform': platform,
      },
    );
    return _asMap(data);
  }

  static Future<void> touchLastSeen() async {
    try {
      await _request(method: 'POST', path: '/api/device/touch');
    } on ApiException {
      // غير حرج
    }
  }

  // ============================================================
  // سوق الخدمات
  // ============================================================

  static Future<List<Map<String, dynamic>>> getServiceSubcategories(
    String categoryId,
  ) async {
    try {
      final data = await _request(
        method: 'GET',
        path: '/api/service-subcategories',
        query: {'category_id': categoryId},
      );
      final list = _asList(data);
      if (list.isNotEmpty) return list;
    } catch (_) {
      // الواجهة المنشورة قد لا تعرف هذا المسار بعد.
    }
    return _subcategoriesFromDatabase(categoryId);
  }

  static Future<List<Map<String, dynamic>>> _subcategoriesFromDatabase(
    String categoryId,
  ) async {
    try {
      final rows = await Supabase.instance.client
          .from('service_subcategories')
          .select('id, category_id, name, sort_order')
          .eq('category_id', categoryId)
          .eq('is_active', true)
          .order('sort_order');
      return _asList(rows);
    } catch (_) {
      return [];
    }
  }

  /// ربط الخدمة بفئتها الفرعية. القراءة عامة ومسموحة بسياسة الجدول.
  static Future<Map<String, String>> subcategoryIdByService(
    String categoryId,
  ) async {
    try {
      final rows = await Supabase.instance.client
          .from('services')
          .select('id, subcategory_id')
          .eq('category_id', categoryId)
          .eq('is_active', true);
      final map = <String, String>{};
      for (final row in _asList(rows)) {
        final id = row['id']?.toString() ?? '';
        final sub = row['subcategory_id']?.toString() ?? '';
        if (id.isNotEmpty && sub.isNotEmpty) map[id] = sub;
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  /// يُبقي خدمات النوع المختار حتى لو الواجهة تجاهلت subcategory_id.
  static Future<List<Map<String, dynamic>>> keepSubcategory(
    List<Map<String, dynamic>> services, {
    required String? categoryId,
    required String? subcategoryId,
  }) async {
    if (subcategoryId == null || subcategoryId.isEmpty) return services;
    final tagged = services
        .where((s) => (s['subcategory_id']?.toString() ?? '').isNotEmpty)
        .length;
    if (services.isNotEmpty && tagged == services.length) {
      return services
          .where((s) => s['subcategory_id'].toString() == subcategoryId)
          .toList();
    }
    if (categoryId == null || categoryId.isEmpty) return services;
    final map = await subcategoryIdByService(categoryId);
    return services
        .where((s) => map[s['id']?.toString()] == subcategoryId)
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getServiceCategories() async {
    final data = await _request(
      method: 'GET',
      path: '/api/service-categories',
    );
    return _asList(data);
  }

  static Future<Map<String, dynamic>> getServices({
    String? q,
    String? categoryId,
    String? governorate,
    num? minPrice,
    num? maxPrice,
    num? minRating,
    String? sort,
    String? subcategoryId,
    bool forOccasion = false,
    String? date,
    bool availableOnly = false,
    int limit = 20,
    int offset = 0,
  }) async {
    final query = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
      if (subcategoryId != null && subcategoryId.isNotEmpty)
        'subcategory_id': subcategoryId,
      if (governorate != null && governorate.isNotEmpty) 'governorate': governorate,
      if (minPrice != null) 'min_price': minPrice.toString(),
      if (maxPrice != null) 'max_price': maxPrice.toString(),
      if (minRating != null) 'min_rating': minRating.toString(),
      if (sort != null && sort.isNotEmpty) 'sort': sort,
      if (forOccasion) 'for_occasion': '1',
      if (date != null && date.isNotEmpty) 'date': date,
      if (date != null && date.isNotEmpty && availableOnly) 'available_only': '1',
    };

    final data = await _request(
      method: 'GET',
      path: '/api/services',
      query: query,
    );
    return _asMap(data);
  }

  static Future<Map<String, dynamic>> getServiceDetails(String id) async {
    final data = await _request(
      method: 'GET',
      path: '/api/service-details',
      query: {'id': id},
    );
    return _asMap(data);
  }

  static Future<Map<String, dynamic>> getProviders({
    String? q,
    String? governorate,
    String? categoryId,
    num? minRating,
    String? sort,
    String? date,
    bool availableOnly = false,
    int limit = 20,
    int offset = 0,
  }) async {
    final query = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (governorate != null && governorate.isNotEmpty) 'governorate': governorate,
      if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
      if (minRating != null) 'min_rating': minRating.toString(),
      if (sort != null && sort.isNotEmpty) 'sort': sort,
      if (date != null && date.isNotEmpty) 'date': date,
      if (date != null && date.isNotEmpty && availableOnly) 'available_only': '1',
    };

    final data = await _request(
      method: 'GET',
      path: '/api/providers',
      query: query,
    );
    return _asMap(data);
  }

  static Future<Map<String, dynamic>> getProviderDetails(String id) async {
    final data = await _request(
      method: 'GET',
      path: '/api/provider-details',
      query: {'id': id},
    );
    return _asMap(data);
  }

  static Future<List<Map<String, dynamic>>> getAdvertisements() async {
    final data = await _request(
      method: 'GET',
      path: '/api/advertisements',
    );
    return _asList(data);
  }

  /// GET /api/home-promo — بطاقات ترويجية للرئيسية
  static Future<List<Map<String, dynamic>>> getHomePromoCards() async {
    try {
      final data = await _request(
        method: 'GET',
        path: '/api/home-promo',
      );
      return _asList(data);
    } on ApiException {
      return [];
    }
  }



// ============================================================
// الإشعارات
// ============================================================

/// GET /api/notifications
static Future<Map<String, dynamic>> getNotifications({
  int limit = 50,
  int offset = 0,
}) async {
  final data = await _request(
    method: 'GET',
    path: '/api/notifications',
    query: {
      'limit': limit.toString(),
      'offset': offset.toString(),
    },
  );
  return _asMap(data);
}

/// GET /api/notifications/unread-count
static Future<int> getUnreadNotificationsCount() async {
  try {
    final data = await _request(
      method: 'GET',
      path: '/api/notifications/unread-count',
    );

    if (data is Map) {
      return (data['count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  } on ApiException {
    return 0;
  } catch (_) {
    return 0;
  }
}

/// POST /api/notifications/:id/read
static Future<void> markNotificationRead(String id) async {
  final cleaned = id.trim();
  if (cleaned.isEmpty) return;

  try {
    await _request(
      method: 'POST',
      path: '/api/notifications/$cleaned/read',
    );
  } on ApiException {
    // نتجاهل الأخطاء
  }
}

/// POST /api/notifications/read-all
static Future<void> markAllNotificationsRead() async {
  try {
    await _request(
      method: 'POST',
      path: '/api/notifications/read-all',
    );
  } on ApiException {
    // نتجاهل الأخطاء
  }
}

// ============================================================
// تسجيل ملف مستخدم الخدمات
// ============================================================

/// POST /api/services/signup
///
/// يحفظ ملف مستخدم الخدمات (الاسم، المحافظة، الواتساب).
/// يُستدعى مرة واحدة بعد التسجيل لأول مرة.
static Future<Map<String, dynamic>> signupServicesUser({
  required String fullName,
  required String governorate,
  required String whatsapp,
}) async {
  final data = await _request(
    method: 'POST',
    path: '/api/services/signup',
    body: {
      'full_name': fullName.trim(),
      'governorate': governorate.trim(),
      'whatsapp': whatsapp.trim(),
    },
  );
  return _asMap(data);
}
// ============================================================
// حجوزات الخدمات (عبر Deno فقط)
// ============================================================

/// POST /api/bookings/quote
static Future<Map<String, dynamic>> quoteServiceBooking({
  required String serviceId,
  String? packageId,
  num? quantity,
  num? durationValue,
  List<String>? addonIds,
  String? discountId,
  int guestsCount = 0,
}) async {
  if (serviceId.trim().isEmpty) {
    throw ApiException.badRequest('معرّف الخدمة مطلوب');
  }

  final data = await _request(
    method: 'POST',
    path: '/api/bookings/quote',
    body: {
      'service_id': serviceId.trim(),
      'package_id': packageId,
      'quantity': quantity,
      'duration_value': durationValue,
      'addon_ids': addonIds ?? const <String>[],
      'discount_id': discountId,
      'guests_count': guestsCount,
    },
  );
  return _asMap(data);
}

/// POST /api/bookings
static Future<Map<String, dynamic>> createServiceBooking({
  required String serviceId,
  required String bookingDate,
  String? bookingTime,
  String? location,
  int guestsCount = 0,
  String? notes,
  String? packageId,
  num? quantity,
  num? durationValue,
  List<String>? addonIds,
  String? discountId,
}) async {
  if (serviceId.trim().isEmpty) {
    throw ApiException.badRequest('معرّف الخدمة مطلوب');
  }
  if (bookingDate.trim().isEmpty) {
    throw ApiException.badRequest('تاريخ الحجز مطلوب');
  }

  final data = await _request(
    method: 'POST',
    path: '/api/bookings',
    body: {
      'service_id': serviceId.trim(),
      'booking_date': bookingDate.trim(),
      'booking_time': bookingTime,
      'location': location,
      'guests_count': guestsCount,
      'notes': notes,
      'package_id': packageId,
      'quantity': quantity,
      'duration_value': durationValue,
      'addon_ids': addonIds ?? const <String>[],
      'discount_id': discountId,
    },
  );
  return _asMap(data);
}

/// POST /api/bookings/cancel
static Future<Map<String, dynamic>> cancelServiceBooking({
  required String bookingId,
}) async {
  if (bookingId.trim().isEmpty) {
    throw ApiException.badRequest('معرّف الحجز مطلوب');
  }

  final data = await _request(
    method: 'POST',
    path: '/api/bookings/cancel',
    body: {'booking_id': bookingId.trim()},
  );
  return _asMap(data);
}

/// POST /api/bookings/review
///
/// يتحقق الخادم أن الحجز مكتمل ويملكه المستخدم قبل حفظ التقييم.
static Future<Map<String, dynamic>> submitBookingReview({
  required String bookingId,
  required String target,
  required int rating,
  String? comment,
}) async {
  if (bookingId.trim().isEmpty) {
    throw ApiException.badRequest('معرّف الحجز مطلوب');
  }
  if (target != 'service' && target != 'provider') {
    throw ApiException.badRequest('نوع التقييم غير صالح');
  }
  if (rating < 1 || rating > 5) {
    throw ApiException.badRequest('التقييم يجب أن يكون بين 1 و 5');
  }

  final data = await _request(
    method: 'POST',
    path: '/api/bookings/review',
    body: {
      'booking_id': bookingId.trim(),
      'target': target,
      'rating': rating,
      'comment': comment,
    },
  );
  return _asMap(data);
}

// ============================================================
// رفع إشعار دفع العربون
// ============================================================

/// POST /api/bookings/:id/deposit
///
/// يُرسل مسار صورة إشعار الدفع للـ Deno.
/// (الصورة نفسها تُرفع مسبقًا إلى Supabase Storage مباشرة)
static Future<Map<String, dynamic>> uploadBookingDeposit({
  required String bookingId,
  required String proofPath,
}) async {
  if (bookingId.trim().isEmpty) {
    throw ApiException.badRequest('معرّف الحجز مطلوب');
  }
  if (proofPath.trim().isEmpty) {
    throw ApiException.badRequest('مسار الإشعار مطلوب');
  }

  final data = await _request(
    method: 'POST',
    path: '/api/bookings/$bookingId/deposit',
    body: {
      'proof_path': proofPath.trim(),
    },
  );
  return _asMap(data);
}
// ═══════════════════════════════════════════════════════════
// 🎉  Party — تنظيم الحفلات
// ═══════════════════════════════════════════════════════════

/// GET /api/party/requests
///
/// طلبات المستخدم الحالي.
static Future<Map<String, dynamic>> getMyPartyRequests({
  int limit = 20,
  int offset = 0,
}) async {
  final data = await _request(
    method: 'GET',
    path: '/api/party/requests',   // ← مباشرة
    query: {
      'limit': limit.toString(),
      'offset': offset.toString(),
    },
  );
  return _asMap(data);
}

/// POST /api/party/requests
///
/// إنشاء طلب تنظيم حفلة جديد.
static Future<Map<String, dynamic>> createPartyRequest({
  required String partyType,
  required String governorate,
  required String paymentProofPath,
  num? budgetMin,
  num? budgetMax,
  String? address,
  String? description,
  required List<String> essentialCategories,
  required List<String> luxuryCategories,
  List<String> providerIds = const [],  // ⭐ جديد
  List<String> serviceIds = const [],   // ⭐ جديد
}) async {
  // ... التحقق

  final data = await _request(
    method: 'POST',
    path: '/api/party/requests',
    body: {
      'party_type': partyType,
      'governorate': governorate.trim(),
      'payment_proof_path': paymentProofPath.trim(),
      if (budgetMin != null) 'budget_min': budgetMin,
      if (budgetMax != null) 'budget_max': budgetMax,
      if (address != null && address.trim().isNotEmpty)
        'address': address.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      'essential_categories': essentialCategories,
      'luxury_categories': luxuryCategories,
      // ⭐ جديد
      if (providerIds.isNotEmpty) 'provider_ids': providerIds,
      if (serviceIds.isNotEmpty) 'service_ids': serviceIds,
    },
  );
  return _asMap(data);
}

/// إعدادات عامة (رقم شام كاش، سعر الطلب).
///
/// ⚠️ مؤقتًا: قيم ثابتة. سنُضيف API call لاحقًا.
static Future<Map<String, dynamic>> getPublicSettings() async {
  return {
    'sham_cash_number': 'ce40f4497f5429b1db116eb9cdf4c307',
    'party_request_fee_usd': 2,
  };
}

// ═══════════════════════════════════════════════════════════
// تنظيم مناسبة (occasion) — مسار جديد منفصل عن party/bookings
// ═══════════════════════════════════════════════════════════

static Future<Map<String, dynamic>> getMyOccasionRequests({
  int limit = 20,
  int offset = 0,
}) async {
  final data = await _request(
    method: 'GET',
    path: '/api/occasion/requests',
    query: {
      'limit': limit.toString(),
      'offset': offset.toString(),
    },
  );
  return _asMap(data);
}

static Future<Map<String, dynamic>> getOccasionRequestDetails(
  String id,
) async {
  final cleaned = id.trim();
  if (cleaned.isEmpty) return {};
  final data = await _request(
    method: 'GET',
    path: '/api/occasion/requests/$cleaned',
  );
  return _asMap(data);
}

static Future<Map<String, dynamic>> createOccasionRequest({
  required String occasionType,
  required String governorate,
  required String whatsapp,
  required String organizerId,
  required List<Map<String, dynamic>> items,
  String? address,
  String? notes,
  String? occasionDate,
  String? occasionDateEnd,
  String? clientRequestKey,
}) async {
  final data = await _request(
    method: 'POST',
    path: '/api/occasion/requests',
    body: {
      'occasion_type': occasionType,
      'governorate': governorate.trim(),
      'whatsapp': whatsapp.trim(),
      'organizer_id': organizerId.trim(),
      'items': items,
      if (address != null && address.trim().isNotEmpty)
        'address': address.trim(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      if (occasionDate != null && occasionDate.trim().isNotEmpty)
        'occasion_date': occasionDate.trim(),
      if (occasionDateEnd != null && occasionDateEnd.trim().isNotEmpty)
        'occasion_date_end': occasionDateEnd.trim(),
      if (clientRequestKey != null && clientRequestKey.trim().isNotEmpty)
        'client_request_key': clientRequestKey.trim(),
    },
  );
  return _asMap(data);
}

static Future<Map<String, dynamic>> decideOccasionQuote({
  required String requestId,
  required String quoteId,
  required String action,
  String? note,
}) async {
  final rid = requestId.trim();
  final qid = quoteId.trim();
  if (rid.isEmpty || qid.isEmpty) return {};
  final data = await _request(
    method: 'POST',
    path: '/api/occasion/requests/$rid/quote-decision',
    body: {
      'quote_id': qid,
      'action': action,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    },
  );
  return _asMap(data);
}

// ═══════════════════════════════════════════════════════════
// بوابة المزود (Grand One)
// ═══════════════════════════════════════════════════════════

// ── الفعالية والسلة ──

/// الفعالية النشطة مع ملخصها؛ `event` فارغة إن لم توجد.
static Future<Map<String, dynamic>> getActiveEvent() async {
  final data = await _request(method: 'GET', path: '/api/events/active');
  return _asMap(data);
}

static Future<Map<String, dynamic>> createEvent(Map<String, dynamic> body) async {
  final data = await _request(method: 'POST', path: '/api/events', body: body);
  return _asMap(data);
}

static Future<Map<String, dynamic>> updateEvent(
    String id, Map<String, dynamic> body) async {
  final data = await _request(method: 'PATCH', path: '/api/events/$id', body: body);
  return _asMap(data);
}

static Future<Map<String, dynamic>> closeEvent(String id) async {
  final data = await _request(method: 'POST', path: '/api/events/$id/close');
  return _asMap(data);
}

static Future<Map<String, dynamic>> addToEventCart(
  String eventId, {
  required String serviceId,
  String? packageId,
  num? quantity,
  num? durationValue,
  List<String> addonIds = const [],
  int? guestsCount,
  String? bookingTime,
  String? notes,
}) async {
  final data = await _request(
    method: 'POST',
    path: '/api/events/$eventId/cart',
    body: {
      'service_id': serviceId,
      if (packageId != null) 'package_id': packageId,
      if (quantity != null) 'quantity': quantity,
      if (durationValue != null) 'duration_value': durationValue,
      'addon_ids': addonIds,
      if (guestsCount != null) 'guests_count': guestsCount,
      if (bookingTime != null) 'booking_time': bookingTime,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    },
  );
  return _asMap(data);
}

static Future<void> removeEventCartItem(String eventId, String itemId) async {
  await _request(method: 'DELETE', path: '/api/events/$eventId/cart/$itemId');
}

static Future<Map<String, dynamic>> sendEventCart(String eventId,
    {List<String>? itemIds}) async {
  final data = await _request(
    method: 'POST',
    path: '/api/events/$eventId/send',
    body: {if (itemIds != null) 'item_ids': itemIds},
  );
  return _asMap(data);
}

// ── أداة تنظيم العمل (مزوّد ومنظّم) ──

static Future<Map<String, dynamic>> getWorkBookings({String? from, String? to}) async {
  final data = await _request(
    method: 'GET',
    path: '/api/work/bookings',
    query: {if (from != null) 'from': from, if (to != null) 'to': to},
  );
  return _asMap(data);
}

static Future<Map<String, dynamic>> createWorkBooking(Map<String, dynamic> body) async {
  final data = await _request(method: 'POST', path: '/api/work/bookings', body: body);
  return _asMap(data);
}

static Future<Map<String, dynamic>> updateWorkBooking(String id, Map<String, dynamic> body) async {
  final data = await _request(method: 'PATCH', path: '/api/work/bookings/$id', body: body);
  return _asMap(data);
}

static Future<void> deleteWorkBooking(String id) async {
  await _request(method: 'DELETE', path: '/api/work/bookings/$id');
}

static Future<List<Map<String, dynamic>>> getWorkChecklist(String kind, String id) async {
  final data = await _request(
    method: 'GET',
    path: '/api/work/checklist',
    query: {'kind': kind, 'id': id},
  );
  final items = _asMap(data)['items'];
  return items is List
      ? items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : <Map<String, dynamic>>[];
}

static Future<Map<String, dynamic>> addWorkChecklistItem(String kind, String id, String title) async {
  final data = await _request(
    method: 'POST',
    path: '/api/work/checklist',
    body: {'kind': kind, 'id': id, 'title': title},
  );
  return _asMap(data);
}

static Future<Map<String, dynamic>> updateWorkChecklistItem(String itemId, Map<String, dynamic> body) async {
  final data = await _request(method: 'PATCH', path: '/api/work/checklist/$itemId', body: body);
  return _asMap(data);
}

static Future<void> deleteWorkChecklistItem(String itemId) async {
  await _request(method: 'DELETE', path: '/api/work/checklist/$itemId');
}

static Future<Map<String, dynamic>> getProviderMe() async {
  final data = await _request(method: 'GET', path: '/api/provider/me');
  return _asMap(data);
}

static Future<Map<String, dynamic>> getProviderAvailability() async {
  final data =
      await _request(method: 'GET', path: '/api/provider/availability');
  return _asMap(data);
}

static Future<Map<String, dynamic>> saveProviderAvailability({
  required List<Map<String, dynamic>> rules,
  List<Map<String, dynamic>>? exceptions, // null = لا تلمس الاستثناءات
}) async {
  final data = await _request(
    method: 'PUT',
    path: '/api/provider/availability',
    body: {
      'rules': rules,
      if (exceptions != null) 'exceptions': exceptions,
    },
  );
  return _asMap(data);
}

static Future<List<Map<String, dynamic>>> getProviderServices() async {
  final data = await _request(method: 'GET', path: '/api/provider/services');
  final map = _asMap(data);
  final list = map['services'];
  if (list is! List) return [];
  return list
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

static Future<Map<String, dynamic>> createProviderService(
  Map<String, dynamic> fields,
) async {
  final data = await _request(
    method: 'POST',
    path: '/api/provider/services',
    body: fields,
  );
  return _asMap(data);
}

static Future<Map<String, dynamic>> updateProviderService({
  required String serviceId,
  required Map<String, dynamic> fields,
}) async {
  final data = await _request(
    method: 'PUT',
    path: '/api/provider/services/${serviceId.trim()}',
    body: fields,
  );
  return _asMap(data);
}

static Future<void> deleteProviderService(String serviceId) async {
  final id = serviceId.trim();
  if (id.isEmpty) {
    throw ApiException.badRequest('معرّف الخدمة مطلوب');
  }
  await _request(method: 'DELETE', path: '/api/provider/services/$id');
}

static Future<Map<String, dynamic>> getProviderBookings({
  String? status,
  int limit = 30,
  int offset = 0,
}) async {
  final data = await _request(
    method: 'GET',
    path: '/api/provider/bookings',
    query: {
      if (status != null && status.isNotEmpty) 'status': status,
      'limit': limit.toString(),
      'offset': offset.toString(),
    },
  );
  return _asMap(data);
}

/// رد العميل على تعديل المزوّد (قبول يطبّق التاريخ/الوقت المقترحين).
static Future<Map<String, dynamic>> respondBookingModification({
  required String bookingId,
  required bool accept,
}) async {
  final data = await _request(
    method: 'POST',
    path: '/api/bookings/modification',
    body: {'booking_id': bookingId, 'action': accept ? 'accept' : 'decline'},
  );
  return _asMap(data);
}

/// رد المزوّد على مجموعة طلبات فعالية واحدة دفعة واحدة.
static Future<Map<String, dynamic>> respondProviderBookingGroup({
  required String groupId,
  required String action, // confirm | reject
  String? note,
}) async {
  final act = action.trim().toLowerCase();
  if (groupId.trim().isEmpty || (act != 'confirm' && act != 'reject')) {
    return {};
  }
  final data = await _request(
    method: 'POST',
    path: '/api/provider/booking-groups/$groupId/$act',
    body: {if (note != null && note.trim().isNotEmpty) 'note': note.trim()},
  );
  return _asMap(data);
}

static Future<Map<String, dynamic>> respondProviderBooking({
  required String bookingId,
  required String action, // confirm | reject | modify
  String? note,
  String? newDate,
  String? newTime,
  String? alternativeServiceId,
  num? newQuantity,
  num? newDurationValue,
}) async {
  final id = bookingId.trim();
  final act = action.trim().toLowerCase();
  if (id.isEmpty ||
      (act != 'confirm' && act != 'reject' && act != 'modify')) {
    return {};
  }
  final data = await _request(
    method: 'POST',
    path: '/api/provider/bookings/$id/$act',
    body: {
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      if (newDate != null) 'new_date': newDate,
      if (newTime != null) 'new_time': newTime,
      if (alternativeServiceId != null)
        'alternative_service_id': alternativeServiceId,
      if (newQuantity != null) 'new_quantity': newQuantity,
      if (newDurationValue != null) 'new_duration_value': newDurationValue,
    },
  );
  return _asMap(data);
}

// ═══════════════════════════════════════════════════════════
// منظّمون (عام + بوابة المنظّم)
// ═══════════════════════════════════════════════════════════

static Future<Map<String, dynamic>> getOrganizers({
  String? q,
  int limit = 30,
  int offset = 0,
}) async {
  final data = await _request(
    method: 'GET',
    path: '/api/organizers',
    query: {
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
    },
  );
  return _asMap(data);
}

static Future<Map<String, dynamic>> getOrganizerMe() async {
  final data = await _request(method: 'GET', path: '/api/organizer/me');
  return _asMap(data);
}

static Future<Map<String, dynamic>> getOrganizerRequests({
  String? status,
  int limit = 30,
  int offset = 0,
}) async {
  final data = await _request(
    method: 'GET',
    path: '/api/organizer/requests',
    query: {
      if (status != null && status.isNotEmpty) 'status': status,
      'limit': limit.toString(),
      'offset': offset.toString(),
    },
  );
  return _asMap(data);
}

static Future<Map<String, dynamic>> getOrganizerRequestDetails(
  String requestId,
) async {
  final data = await _request(
    method: 'GET',
    path: '/api/organizer/requests/${requestId.trim()}',
  );
  return _asMap(data);
}

static Future<Map<String, dynamic>> createOrganizerQuote({
  required String requestId,
  required List<Map<String, dynamic>> items,
  double organizerFeePct = 0,
  double extraFees = 0,
  String? terms,
  String? clientMessage,
  bool send = false,
  int validHours = 24,
}) async {
  final data = await _request(
    method: 'POST',
    path: '/api/organizer/requests/${requestId.trim()}/quotes',
    body: {
      'items': items,
      'organizer_fee_pct': organizerFeePct,
      'extra_fees': extraFees,
      'send': send,
      'valid_hours': validHours,
      if (terms != null && terms.trim().isNotEmpty) 'terms': terms.trim(),
      if (clientMessage != null && clientMessage.trim().isNotEmpty)
        'client_message': clientMessage.trim(),
    },
  );
  return _asMap(data);
}

static Future<List<Map<String, dynamic>>> getOrganizerOwnedServices() async {
  final data =
      await _request(method: 'GET', path: '/api/organizer/owned-services');
  final map = _asMap(data);
  final list = map['services'];
  if (list is! List) return [];
  return list
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

static Future<Map<String, dynamic>> createOrganizerOwnedService(
  Map<String, dynamic> fields,
) async {
  final data = await _request(
    method: 'POST',
    path: '/api/organizer/owned-services',
    body: fields,
  );
  return _asMap(data);
}

static Future<Map<String, dynamic>> updateOrganizerOwnedService({
  required String serviceId,
  required Map<String, dynamic> fields,
}) async {
  final data = await _request(
    method: 'PUT',
    path: '/api/organizer/owned-services/${serviceId.trim()}',
    body: fields,
  );
  return _asMap(data);
}

static Future<void> deleteOrganizerOwnedService(String serviceId) async {
  final id = serviceId.trim();
  if (id.isEmpty) {
    throw ApiException.badRequest('معرّف الخدمة مطلوب');
  }
  await _request(method: 'DELETE', path: '/api/organizer/owned-services/$id');
}

static Future<Map<String, dynamic>> getOrganizerAvailability() async {
  final data =
      await _request(method: 'GET', path: '/api/organizer/availability');
  return _asMap(data);
}

static Future<Map<String, dynamic>> saveOrganizerAvailability({
  List<Map<String, dynamic>>? rules,
  List<Map<String, dynamic>>? exceptions,
}) async {
  final data = await _request(
    method: 'PUT',
    path: '/api/organizer/availability',
    body: {
      if (rules != null) 'rules': rules,
      if (exceptions != null) 'exceptions': exceptions,
    },
  );
  return _asMap(data);
}

static Future<Map<String, dynamic>> uploadOccasionDeposit({
  required String requestId,
  required String proofPath,
}) async {
  final id = requestId.trim();
  if (id.isEmpty || proofPath.trim().isEmpty) return {};
  final data = await _request(
    method: 'POST',
    path: '/api/occasion/requests/$id/deposit',
    body: {'proof_path': proofPath.trim()},
  );
  return _asMap(data);
}

}