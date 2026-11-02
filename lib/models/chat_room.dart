// lib/models/chat_room.dart
// ============================================================
// ChatRoom — نموذج غرفة المحادثة
// ============================================================

import '../config.dart';

class ChatRoom {
  final String roomId;
  final String groomCode;
  final String brideCode;
  final DateTime startedAt;
  final DateTime expiresAt;
  final String status;
  final int messageCount;

  const ChatRoom({
    required this.roomId,
    required this.groomCode,
    required this.brideCode,
    required this.startedAt,
    required this.expiresAt,
    required this.status,
    required this.messageCount,
  });

  // ============================================================
  // Computed Properties
  // ============================================================

  /// هل الغرفة منتهية؟
  /// - انتهت مدة الـ 48 ساعة
  /// - أو الحالة ليست "active"
  bool get isExpired =>
      DateTime.now().isAfter(expiresAt) || status != 'active';

  /// هل الغرفة ممتلئة؟
  /// (الحد من AppConfig.maxChatMessages)
  bool get isFull =>
      messageCount >= AppConfig.maxChatMessages;

  /// هل يمكن إرسال رسالة؟
  bool get canSend => !isExpired && !isFull;

  /// الوقت المتبقي
  Duration get remaining {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  // ============================================================
  // Factory — من Map
  // ============================================================

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    // ═══ roomId (مطلوب) ═══
    final roomId = map['room_id']?.toString() ?? '';

    if (roomId.isEmpty) {
      throw const FormatException(
        'ChatRoom: room_id is required',
      );
    }

    // ═══ التواريخ (آمنة) ═══
    final startedAt =
        _tryParseDate(map['started_at']) ?? DateTime.now();

    final expiresAt =
        _tryParseDate(map['expires_at']) ??
            DateTime.now().add(
              const Duration(hours: 48),
            );

    // ═══ باقي الحقول ═══
    return ChatRoom(
      roomId: roomId,
      groomCode: map['groom_code']?.toString() ?? '',
      brideCode: map['bride_code']?.toString() ?? '',
      startedAt: startedAt,
      expiresAt: expiresAt,
      status: map['status']?.toString() ?? 'active',
      messageCount: _tryParseInt(map['message_count']) ?? 0,
    );
  }

  // ============================================================
  // To Map
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'room_id': roomId,
      'groom_code': groomCode,
      'bride_code': brideCode,
      'started_at': startedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'status': status,
      'message_count': messageCount,
    };
  }

  // ============================================================
  // CopyWith
  // ============================================================

  ChatRoom copyWith({
    String? roomId,
    String? groomCode,
    String? brideCode,
    DateTime? startedAt,
    DateTime? expiresAt,
    String? status,
    int? messageCount,
  }) {
    return ChatRoom(
      roomId: roomId ?? this.roomId,
      groomCode: groomCode ?? this.groomCode,
      brideCode: brideCode ?? this.brideCode,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  // ============================================================
  // Helpers — Parsing آمن
  // ============================================================

  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static int? _tryParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  // ============================================================
  // toString — للتشخيص
  // ============================================================

  @override
  String toString() {
    return 'ChatRoom('
        'roomId: $roomId, '
        'status: $status, '
        'messageCount: $messageCount, '
        'expiresAt: $expiresAt, '
        'isExpired: $isExpired, '
        'isFull: $isFull'
        ')';
  }
}