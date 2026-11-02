// lib/services/chat_service.dart
// ============================================================
// ChatService — إدارة غرف المحادثة والرسائل
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../models/chat_room.dart';
import '../utils/chat_filter.dart';
import 'api_exceptions.dart';
import 'api_service.dart';

class ChatService {
  /// الحد الأقصى لعدد الرسائل في الغرفة
  static const int maxMessages = AppConfig.maxChatMessages;

  final SupabaseClient _client;

  ChatService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  // ============================================================
  // إنشاء غرفة المحادثة
  // ============================================================

  /// إنشاء غرفة محادثة عبر Deno POST /api/rooms
  /// - الشاب: يمرّر brideCode
  /// - الولي: يمرّر groomCode (مع brideCode فارغ أو العكس)
  Future<ChatRoom> createRoom({
    String? groomCode,
    String? brideCode,
  }) async {
    final bride = brideCode?.trim() ?? '';
    final groom = groomCode?.trim() ?? '';
    final hasBride = bride.isNotEmpty;
    final hasGroom = groom.isNotEmpty;

    if (hasBride == hasGroom) {
      throw ApiException.server('يلزم bride_code أو groom_code فقط.');
    }

    final result = await ApiService.createRoom(
      hasBride ? {'bride_code': bride} : {'groom_code': groom},
    );

    if (result == null) {
      throw ApiException.server('فشل إنشاء غرفة المحادثة.');
    }

    return ChatRoom.fromMap(result);
  }

  // ============================================================
  // جلب غرفة
  // ============================================================

  /// جلب بيانات غرفة عبر room_id
  Future<ChatRoom?> getRoom(String roomId) async {
    final cleanedRoomId = roomId.trim();

    if (cleanedRoomId.isEmpty) {
      return null;
    }

    final data = await _client
        .from('chat_rooms')
        .select()
        .eq('room_id', cleanedRoomId)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return ChatRoom.fromMap(data);
  }

  // ============================================================
  // مراقبة الرسائل لحظياً
  // ============================================================

  /// Stream لمراقبة الرسائل الجديدة
  Stream<List<Map<String, dynamic>>> watchMessages(String roomId) {
    final cleanedRoomId = roomId.trim();

    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', cleanedRoomId)
        .order('created_at', ascending: true);
  }

  // ============================================================
  // إرسال رسالة
  // ============================================================

  /// إرسال رسالة نصية
  ///
  /// الفحوصات:
  /// - فحص محلي للفلتر (UI فقط)
  /// - فحص محلي لحالة الغرفة (UI فقط)
  /// - الفحص النهائي في RPC `send_message`
  ///
  /// يُرجع:
  /// - `null` عند النجاح
  /// - رسالة نصية عند الفشل
  Future<String?> sendMessage({
    required String roomId,
    required String groomCode,
    required String text,
    required bool isWaliSender,
  }) async {
    final cleanedRoomId = roomId.trim();
    final cleanedText = text.trim();

    if (cleanedRoomId.isEmpty) {
      return '❌ معرف الغرفة غير صالح.';
    }

    if (cleanedText.isEmpty) {
      return '❌ لا يمكن إرسال رسالة فارغة.';
    }

    // ═══ فحص واجهة المستخدم ═══
    final filter = ChatFilter.validate(cleanedText);

    if (!filter.allowed) {
      return filter.reason;
    }

    // ═══ فحص سريع لحالة الغرفة ═══
    final room = await getRoom(cleanedRoomId);

    if (room == null) {
      return '❌ الغرفة غير موجودة.';
    }

    if (room.isExpired) {
      return '⏱️ انتهت مهلة الـ ٤٨ ساعة.';
    }

    if (room.isFull) {
      return '❌ تم استهلاك سقف الـ ٥٠ رسالة.';
    }

    // ═══ إرسال عبر API ═══
    try {
      final success = await ApiService.sendMessage({
        'room_id': cleanedRoomId,
        'message_text': cleanedText,
      });

      if (!success) {
        return '❌ فشل إرسال الرسالة.';
      }

      return null;
    } on ApiException catch (e) {
      return e.userMessage;
    }
  }

  // ============================================================
// عرض الرسائل
// ============================================================

/// استخراج نص الرسالة للعرض
///
/// ملاحظة: لا يوجد تشفير حقيقي مطبق حالياً.
/// الرسائل محفوظة كنص قابل للعرض مباشرة.
String getDisplayText(Map<String, dynamic> message) {
  return message['message_text']?.toString() ?? '';
}

/// ⚠️ مؤقت — للتوافق مع chat_screen.dart الحالي
///
/// TODO: حذف هذه الدالة بعد تحديث chat_screen
/// لاستخدام `getDisplayText` مباشرة.
@Deprecated('Use getDisplayText instead')
Future<String> decryptMessage(String encryptedText) async {
  return encryptedText;
}

  // ============================================================
  // الوقت المتبقي
  // ============================================================

  /// تنسيق الوقت المتبقي
  String formatRemaining(Duration d) {
    if (d.isNegative || d.inSeconds <= 0) {
      return 'انتهت';
    }

    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours س و $minutes د';
    }

    if (minutes > 0) {
      return '$minutes د';
    }

    return 'أقل من دقيقة';
  }
}