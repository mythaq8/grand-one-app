// lib/screens/chat_screen.dart
// ============================================================
// ChatScreen — غرفة المحادثة الشرعية
// ============================================================

import 'dart:async';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart'; 

import '../app_colors.dart';
import '../ui/kit/kit.dart';
import '../ui_copy.dart';
import '../models/chat_room.dart';
import '../services/api_service.dart';
import '../services/api_exceptions.dart';
import '../services/chat_service.dart';
import '../utils/error_handler.dart';
import '../widgets/islamic_decorations.dart';
import '../widgets/screen_fit.dart';
import '../widgets/ux_helpers.dart';
import 'exploration_screen.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String groomCode;
  final bool isWaliSender;
  final String senderName;

  const ChatScreen({
    Key? key,
    required this.roomId,
    required this.groomCode,
    required this.isWaliSender,
    required this.senderName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final SupabaseClient _client = Supabase.instance.client;

  ChatRoom? _room;

  bool _isLoading = true;
  String? _errorMessage;

  bool _isSending = false;
  bool _rulesShown = false;
  bool _isNavigating = false;
  bool _isRoomClosed = false;
  bool _contactDialogShown = false;
  bool _contactDialogSucceeded = false; 
  bool _contactFetching = false;
  bool _stickToBottom = true;
  int _renderedMessageCount = 0;


  StreamSubscription? _roomSubscription;
  Timer? _statusPollTimer;

  @override
  void initState() {
    super.initState();

    _validateRoom();
    _showRulesOnce();
    _watchRoomStatus();
    _scrollController.addListener(_onChatScroll);

    // Fallback إذا لم يصل تحديث Realtime على الويب.
    // البث المباشر يبقى المسار الأساسي.
    _statusPollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _pollRoomStatus(),
    );
  }

  void _onChatScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    _stickToBottom = position.maxScrollExtent - position.pixels <= 80;
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    _roomSubscription?.cancel();
    _scrollController.removeListener(_onChatScroll);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // ترجمة أخطاء RPC
  // ============================================================

  String _translateRpcError(dynamic e) {
    final msg = e.toString().toLowerCase();

    if (msg.contains('chat room is no longer active')) {
      return 'المحادثة لم تعد نشطة.';
    }
    if (msg.contains('chat room not found') ||
        msg.contains('chat room does not exist')) {
      return 'لم يتم العثور على الغرفة.';
    }
    if (msg.contains('not a member')) {
      return 'لست طرفاً في هذه المحادثة.';
    }
    if (msg.contains('already approved')) {
      return 'قمت بتسجيل موافقتك مسبقاً.';
    }
    if (msg.contains('expired')) {
      return 'انتهت مدة المحادثة (48 ساعة).';
    }
    if (msg.contains('unauthorized') ||
        msg.contains('authentication required')) {
      return 'انتهت جلسة الدخول. يرجى تسجيل الدخول مجدداً.';
    }
    if (msg.contains('account is not allowed')) {
      return 'حسابك غير مصرح به. يرجى التواصل مع الإدارة.';
    }
    if (msg.contains('report reason is too short')) {
      return 'سبب البلاغ قصير جداً.';
    }
    if (msg.contains('report reason is too long')) {
      return 'سبب البلاغ طويل جداً.';
    }
    if (msg.contains('unable to identify reported user')) {
      return 'تعذر تحديد الطرف الآخر للإبلاغ.';
    }

    return 'تعذر إتمام العملية. حاول مرة أخرى.';
  }

  // ============================================================
  // فحص دوري لحالة الغرفة (Fallback)
  // ============================================================

 Future<void> _pollRoomStatus() async {
  // ✅ لا early return على _isRoomClosed
  if (!mounted) return;
  if (_isNavigating) return;
  if (_contactDialogSucceeded) return;

  try {
    final room = await _client
        .from('chat_rooms')
        .select(
          'status, groom_user_id, bride_user_id, '
          'groom_approved, bride_approved, expires_at, '
          'admin_approved, admin_rejection_reason'
        )
        .eq('room_id', widget.roomId)
        .maybeSingle();

    if (!mounted) return;
    if (room == null) return;

    final status = room['status']?.toString() ?? '';
    final adminApproved = room['admin_approved'] == true;

    debugPrint('🔍 POLL: status=$status, admin=$adminApproved, closed=$_isRoomClosed');

    // ═══════════════════════════════════════════════
    // ✅ matched + admin_approved → الأرقام
    // ═══════════════════════════════════════════════
    if (status == 'matched' && adminApproved && !_contactDialogSucceeded) {
      debugPrint('✅✅✅ POLL: Admin approved! Showing contact numbers...');

      _isRoomClosed = true;
      _statusPollTimer?.cancel();
      _roomSubscription?.cancel();

      await _showContactNumbers();
      return;
    }

    // matched بلا موافقة إدارة — أبقِ المراقبة واعرض انتظاراً مرة واحدة
    if (status == 'matched' && !adminApproved && !_contactDialogShown) {
      debugPrint('⏳ POLL: matched awaiting admin approval');
      await _showPendingReviewMessage();
      return;
    }

    // ═══════════════════════════════════════════════
    // بانتظار المراجعة الإدارية
    // ═══════════════════════════════════════════════
   if (status == 'pending_admin_review') {
  final gOk = room['groom_approved'] == true;
  final bOk = room['bride_approved'] == true;

  if (gOk && bOk) {
    await _showPartyPaymentDialog();
    if (!_contactDialogShown) {
      debugPrint('⏳ POLL: pending_admin_review — first time');
      await _showPendingReviewMessage();
    }
    return;
  }

  // ✅ إذا الحوار معروض → لا تفعل شيئًا
  return;
}

    // ═══════════════════════════════════════════════
    // رفض إداري
    // ═══════════════════════════════════════════════
    if (status == 'rejected' && !_isRoomClosed) {
      debugPrint('❌ POLL: rejected');

      _isRoomClosed = true;
      _statusPollTimer?.cancel();
      _roomSubscription?.cancel();

      await _showRejectedMessage(
        room['admin_rejection_reason']?.toString(),
      );
      return;
    }

    // ═══════════════════════════════════════════════
    // حالات أخرى
    // ═══════════════════════════════════════════════
    if (status != 'active' &&
        status != 'matched' &&
        status != 'pending_admin_review' &&
        status != 'rejected' &&
        !_isNavigating &&
        !_isRoomClosed) {
      debugPrint('⚠️ POLL: status changed to $status');

      _isNavigating = true;
      _isRoomClosed = true;
      _statusPollTimer?.cancel();
      _roomSubscription?.cancel();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('chat_cancelled_by_other')),
            backgroundColor: AppColors.warning,
          ),
        );
      }

      Future.delayed(
        const Duration(milliseconds: 50),
        () {
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => ExplorationScreen(
                isGroomRole: !widget.isWaliSender,
              ),
            ),
            (route) => false,
          );
        },
      );
    }
  } catch (e, st) {
    debugPrint('❌ Poll error: $e');
    debugPrint('$st');
  }
}
  // ============================================================
  // التحقق من الغرفة
  // ============================================================

  Future<void> _validateRoom() async {
    try {
      final room = await _client
          .from('chat_rooms')
          .select()
          .eq('room_id', widget.roomId)
          .maybeSingle();

      if (!mounted) return;

      if (room == null) {
        _showRoomClosedDialog(tr('room_not_found'));
        return;
      }

      final status = room['status'] as String? ?? '';

      // ═══ بانتظار المراجعة الإدارية ═══
if (status == 'pending_admin_review') {
  _room = ChatRoom.fromMap(room);

  // ✅ احتفظ بالمراقبة نشطة
  if (!_contactDialogShown) {
    await _showPendingReviewMessage();
  }
  return;
}
// ═══ الطرفان وافقا ═══
if (status == 'matched') {
  final aOk = room['admin_approved'] == true;

  if (!aOk) {
    // بانتظار موافقة الإدارة — أبقِ Realtime/Polling نشطين
    // حتى تظهر أرقام التواصل تلقائياً بعد موافقة المشرف
    _room = ChatRoom.fromMap(room);
    if (!_contactDialogShown) {
      await _showPendingReviewMessage();
    }
    return;
  }

  _room = ChatRoom.fromMap(room);
  _isRoomClosed = true;
  _statusPollTimer?.cancel();
  _roomSubscription?.cancel();

  await _showContactNumbers();
  return;
}

// ═══ رفض إداري ═══
if (status == 'rejected') {
  _room = ChatRoom.fromMap(room);
  _isRoomClosed = true;
  _statusPollTimer?.cancel();
  _roomSubscription?.cancel();

  await _showRejectedMessage(
    room['admin_rejection_reason']?.toString(),
  );
  return;
}

      // ═══ حالات أخرى ═══
      if (status != 'active') {
        String message;

        switch (status) {
          case 'cancelled':
            message = tr('chat_cancelled');
            break;
          case 'closed':
            message = tr('chat_closed');
            break;
          case 'rejected':
            message = 'تم إنهاء المحادثة نهائياً';
            break;
          case 'expired':
            message = tr('chat_expired');
            break;
          default:
            message = tr('chat_unavailable');
        }

        _showRoomClosedDialog(message);
        return;
      }

      // ═══ فحص انتهاء الوقت ═══
      final expiresAt = DateTime.parse(room['expires_at'] as String);

      if (DateTime.now().isAfter(expiresAt)) {
        _showRoomClosedDialog(tr('chat_expired'));
        return;
      }

      _loadRoom();
    } catch (e) {
      if (!mounted) return;

      ErrorHandler.showError(
        context,
        e,
        customMessage: tr('room_validation_error'),
      );

      Navigator.pop(context);
    }
  }

  // ============================================================
  // إغلاق الغرفة
  // ============================================================

  void _showRoomClosedDialog(String message) {
    if (_isRoomClosed) return;

    _isRoomClosed = true;
    _statusPollTimer?.cancel();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tr('chat_ended'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
  TextButton(
    onPressed: () {
      // ═══ أغلق Dialog أولاً ═══
      Navigator.of(context).pop();

      // ═══ أغلق ChatScreen إن أمكن ═══
      final navigator = Navigator.of(context);

      if (navigator.canPop()) {
        navigator.pop();
      } else {
        // fallback: عُد لشاشة الاستكشاف
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => ExplorationScreen(
              isGroomRole: !widget.isWaliSender,
            ),
          ),
        );
      }
    },
    child: Text(
      tr('ok'),
      style: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
],
        );
      },
    );
  }

  // ============================================================
  // مراقبة حالة الغرفة Realtime
  // ============================================================

void _watchRoomStatus() {
  _roomSubscription = _client
      .from('chat_rooms')
      .stream(primaryKey: ['room_id'])
      .eq('room_id', widget.roomId)
      .listen(
    (data) async {
      if (data.isEmpty) return;

      final room = data.first;
      final status = room['status'] as String? ?? '';
      final adminApproved = room['admin_approved'] == true;
      final groomApproved = room['groom_approved'] == true;
      final brideApproved = room['bride_approved'] == true;

      debugPrint('═══════════════════════════════════════');
      debugPrint('🔴 REALTIME UPDATE');
      debugPrint('   status=$status');
      debugPrint('   groom_approved=$groomApproved');
      debugPrint('   bride_approved=$brideApproved');
      debugPrint('   admin_approved=$adminApproved');
      debugPrint('   _isRoomClosed=$_isRoomClosed');
      debugPrint('   _contactDialogShown=$_contactDialogShown');
      debugPrint('═══════════════════════════════════════');

      if (!mounted) return;

      setState(() {
        _room = ChatRoom.fromMap(room);
      });

      // ═══════════════════════════════════════════════
      // ✅ الأهم: عندما admin_approved = true و status = matched
      // ═══════════════════════════════════════════════
      if (status == 'matched' && adminApproved && !_contactDialogSucceeded) {
        debugPrint('✅✅✅ REALTIME: Admin approved! Showing contact numbers...');

        _isRoomClosed = true;
        _statusPollTimer?.cancel();
        _roomSubscription?.cancel();

        _showContactNumbers();
        return;
      }

      // matched بلا موافقة إدارة — أبقِ المراقبة واعرض انتظاراً مرة واحدة
      if (status == 'matched' && !adminApproved && !_contactDialogShown) {
        debugPrint('⏳ REALTIME: matched awaiting admin approval');
        _showPendingReviewMessage();
        return;
      }

      // ═══════════════════════════════════════════════
      // بانتظار المراجعة الإدارية
      // ═══════════════════════════════════════════════
      if (status == 'pending_admin_review' &&
          groomApproved &&
          brideApproved) {
        await _showPartyPaymentDialog();
        if (_contactDialogShown) {
          debugPrint('⏳ REALTIME: pending_review — dialog already shown');
          return;
        }

        debugPrint('⏳ REALTIME: pending_admin_review — showing wait dialog');
        _showPendingReviewMessage();
        return;
      }

      // ═══════════════════════════════════════════════
      // رفض إداري
      // ═══════════════════════════════════════════════
      if (status == 'rejected' && !_isRoomClosed) {
        debugPrint('❌ REALTIME: rejected');

        _isRoomClosed = true;
        _statusPollTimer?.cancel();
        _roomSubscription?.cancel();

        _showRejectedMessage(
          room['admin_rejection_reason']?.toString(),
        );
        return;
      }

      // ═══════════════════════════════════════════════
      // حالات أخرى (closed, cancelled, expired)
      // ═══════════════════════════════════════════════
      if (status != 'active' &&
          status != 'matched' &&
          status != 'pending_admin_review' &&
          status != 'rejected' &&
          !_isNavigating &&
          !_isRoomClosed) {
        debugPrint('⚠️ REALTIME: status changed to $status — navigating back');

        _isNavigating = true;
        _isRoomClosed = true;
        _statusPollTimer?.cancel();
        _roomSubscription?.cancel();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('chat_cancelled_by_other')),
              backgroundColor: AppColors.warning,
            ),
          );
        }

        Future.delayed(
          const Duration(milliseconds: 300),
          () {
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => ExplorationScreen(
                  isGroomRole: !widget.isWaliSender,
                ),
              ),
              (route) => false,
            );
          },
        );
      }
    },
    onError: (error) {
      debugPrint('❌ Room realtime error: $error');
    },
  );
}

  // ============================================================
  // قواعد المحادثة
  // ============================================================

  Future<void> _showRulesOnce() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted && !_rulesShown) {
      _rulesShown = true;
      await _showChatRules();
    }
  }

  Future<void> _showChatRules() async {
    await showHelpSheet(
      context,
      title: 'قواعد المحادثة الشرعية',
      body:
          '1. النية الصادقة: لا تدخل إلا بنية الزواج الشرعي.\n'
          '2. غض البصر: لا تطلب صوراً أو معلومات شخصية.\n'
          '3. الأدب: التزم بالأدب الإسلامي في الحوار.\n'
          '4. السرية: لا تشارك محتوى المحادثة مع الآخرين.\n'
          '5. الولي: يُراعى حضور الولي أو موافقته حيث يلزم.\n\n'
          '${UiCopy.chatRulesLong}',
    );
  }

  // ============================================================
  // تحميل الغرفة
  // ============================================================

  Future<void> _loadRoom() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final room = await _chatService.getRoom(widget.roomId);

      if (!mounted) return;

      if (room != null) {
        setState(() {
          _room = room;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = tr('room_not_found');
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = ErrorHandler.getErrorMessage(e);
      });
    }
  }

  // ============================================================
  // إرسال الرسالة
  // ============================================================

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty) return;

    if (_room == null || !_room!.canSend || _isSending) {
      return;
    }

    _stickToBottom = true;

    setState(() {
      _isSending = true;
    });

    final error = await _chatService.sendMessage(
      roomId: widget.roomId,
      groomCode: widget.groomCode,
      text: text,
      isWaliSender: widget.isWaliSender,
    );

    if (!mounted) return;

    setState(() {
      _isSending = false;
    });

    if (error != null) {
      _showSnackBar(error);
      return;
    }

    _messageController.clear();
  }

  // ============================================================
  // إنهاء المحادثة
  // ============================================================

  Future<void> _showEndChatDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.handshake_outlined,
                color: AppColors.goldDark,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'إنهاء المحادثة',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ما هو قرارك؟',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: () {
                    Navigator.pop(context);
                    _approveChat();
                  },
                  label: const Text('تمت الموافقة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 9),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined),
                  onPressed: () {
                    Navigator.pop(context);
                    _rejectChat();
                  },
                  label: const Text('خيار غير مناسب'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ============================================================
// الموافقة
// ============================================================

// ============================================================
// الموافقة
// ============================================================

Future<void> _approveChat() async {
  try {
    debugPrint('🔵 _approveChat started for room: ${widget.roomId}');

    // ═══════════════════════════════════════════════════════
    // 1. افحص الحالة الحالية للغرفة
    // ═══════════════════════════════════════════════════════
    final room = await _client
        .from('chat_rooms')
        .select(
          'status, groom_user_id, bride_user_id, '
          'groom_approved, bride_approved, '
          'admin_approved, admin_rejection_reason'
        )
        .eq('room_id', widget.roomId)
        .maybeSingle();

    if (!mounted) return;

    if (room == null) {
      ErrorHandler.showError(
        context,
        null,
        customMessage: 'لم يتم العثور على الغرفة',
      );
      return;
    }

    final status = room['status']?.toString() ?? '';

    // ═══════════════════════════════════════════════════════
    // 2. matched + admin_approved → اعرض الأرقام
    // ═══════════════════════════════════════════════════════
    if (status == 'matched') {
      final groomOk = room['groom_approved'] == true;
      final brideOk = room['bride_approved'] == true;
      final adminOk = room['admin_approved'] == true;

      if (!groomOk || !brideOk) {
        ErrorHandler.showWarning(
          context,
          'معلومات التواصل غير متوفرة بعد. بانتظار موافقة الطرف الآخر.',
        );
        return;
      }

      if (!adminOk) {
        // ⚠️ لا تقفل الشاشة — اترك المراقبة تعمل
        await _showPendingReviewMessage();
        return;
      }

      // ✅ الإدارة وافقت — اعرض الأرقام مباشرة
      await _showContactNumbers();
      return;
    }

    // ═══════════════════════════════════════════════════════
    // 3. pending_admin_review → اعرض "بانتظار الإدارة"
    // ═══════════════════════════════════════════════════════
    if (status == 'pending_admin_review') {
      final groomOk = room['groom_approved'] == true;
      final brideOk = room['bride_approved'] == true;

      if (!groomOk || !brideOk) {
        ErrorHandler.showWarning(
          context,
          'معلومات التواصل غير متوفرة بعد. بانتظار موافقة الطرف الآخر.',
        );
        return;
      }

      // ⚠️ لا تقفل الشاشة — اترك المراقبة تعمل
      await _showPendingReviewMessage();
      return;
    }

    // ═══════════════════════════════════════════════════════
    // 4. rejected → رسالة رفض إداري
    // ═══════════════════════════════════════════════════════
    if (status == 'rejected') {
      await _showRejectedMessage(
        room['admin_rejection_reason']?.toString(),
      );
      return;
    }

    // ═══════════════════════════════════════════════════════
    // 5. حالات أخرى (expired / closed / cancelled)
    // ═══════════════════════════════════════════════════════
    if (status != 'active') {
      String msg;
      switch (status) {
        case 'expired':
          msg = 'انتهت مدة المحادثة (48 ساعة)';
          break;
        case 'closed':
          msg = 'تم إغلاق المحادثة';
          break;
        case 'cancelled':
          msg = 'تم إلغاء المحادثة';
          break;
        default:
          msg = 'المحادثة لم تعد نشطة';
      }

      ErrorHandler.showWarning(context, msg);
      return;
    }

    // ═══════════════════════════════════════════════════════
    // 6. افحص إذا كان المستخدم قد وافق مسبقاً
    // ═══════════════════════════════════════════════════════
    final currentUserId = _client.auth.currentUser?.id;

    if (currentUserId != null) {
      final isGroom = room['groom_user_id'] == currentUserId;
      final isBride = room['bride_user_id'] == currentUserId;

      final myApproval = isGroom
          ? room['groom_approved'] == true
          : isBride
              ? room['bride_approved'] == true
              : false;

      final otherApproval = isGroom
          ? room['bride_approved'] == true
          : room['groom_approved'] == true;

      if (myApproval) {
        // ─── إذا وافق الطرفان ───
        if (otherApproval) {
          final adminOk = room['admin_approved'] == true;

          if (!adminOk) {
            await _showPendingReviewMessage();
            return;
          }

          await _showContactNumbers();
          return;
        }

        // ─── وافق طرف واحد فقط ───
        ErrorHandler.showWarning(
          context,
          'تم تسجيل موافقتك مسبقاً. بانتظار موافقة الطرف الآخر.',
        );
        return;
      }
    }

    // ═══════════════════════════════════════════════════════
    // 7. استدعِ RPC لتسجيل موافقة هذا الطرف
    // ═══════════════════════════════════════════════════════
    debugPrint('🔵 Calling approve via API...');

    final result = await ApiService.approveChatRoom(widget.roomId);

    debugPrint('✅ Approve result: $result');

    if (!mounted) return;

    if (result is! Map || result['success'] != true) {
      ErrorHandler.showError(
        context,
        null,
        customMessage:
            result?['message']?.toString() ?? 'تعذر تسجيل الموافقة',
      );
      return;
    }

    // ═══════════════════════════════════════════════════════
    // 8. تحليل نتيجة RPC
    // ═══════════════════════════════════════════════════════
    final pendingReview = result['pending_review'] == true;
    final matched = result['matched'] == true;

    // ─── 8a. وافق الطرفان → pending_admin_review ───
if (pendingReview) {
  // طلب دفع شام كاش من الطرفين (العريس والعروس/الولي)
  await _showPartyPaymentDialog();

  // ✅ لا تقفل الشاشة — اترك المراقبة تعمل
  await _showPendingReviewMessage();
  return;
}

    // ─── 8b. matched (نادر) ───
    if (matched) {
      // تحقق من admin_approved في DB
      final updatedRoom = await _client
          .from('chat_rooms')
          .select('admin_approved, status')
          .eq('room_id', widget.roomId)
          .maybeSingle();

      if (!mounted) return;

      final adminOk = updatedRoom?['admin_approved'] == true;
      final newStatus = updatedRoom?['status']?.toString() ?? '';

      if (!adminOk || newStatus != 'matched') {
        await _showPendingReviewMessage();
        return;
      }

      await _showContactNumbers();
      return;
    }

   // ─── 8c. وافق طرف واحد فقط ───
  ErrorHandler.showSuccess(
    context,
    'تم تسجيل موافقتك. بانتظار الطرف الآخر.',
  );

  // ✅ حدّث الواجهة لتعكس الحالة الجديدة
  if (mounted) {
    await _loadRoom();
  }
} catch (e, st) {
    debugPrint('❌ Approve error: $e');
    debugPrint('$st');

    if (!mounted) return;

    ErrorHandler.showError(
      context,
      null,
      customMessage: _translateRpcError(e),
    );
  }
}
  // ============================================================
  // رفض
  // ============================================================

  Future<void> _rejectChat() async {
    try {
      debugPrint('🔵 Calling reject via API...');

      final result = await ApiService.rejectChatRoom(widget.roomId);

      debugPrint('✅ Reject result: $result');

      if (!mounted) return;

      ErrorHandler.showSuccess(
        context,
        'تم إنهاء المحادثة نهائياً',
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ExplorationScreen(
            isGroomRole: !widget.isWaliSender,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint('❌ Reject error: $e');

      if (!mounted) return;

      ErrorHandler.showError(
        context,
        null,
        customMessage: _translateRpcError(e),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // حوار دفع 1$ لكل طرف (عريس أو عروس/ولي) — مرة واحدة لكل غرفة
  // ═══════════════════════════════════════════════════════════

  Future<void> _showPartyPaymentDialog() async {
    if (!mounted) return;

    final party = widget.isWaliSender ? 'bride' : 'groom';
    final notifiedCol = party == 'bride'
        ? 'bride_payment_notified_at'
        : 'groom_payment_notified_at';

    try {
      final room = await _client
          .from('chat_rooms')
          .select(notifiedCol)
          .eq('room_id', widget.roomId)
          .maybeSingle();

      if (room != null && room[notifiedCol] != null) {
        debugPrint('💰 Payment dialog already shown for $party');
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Error checking payment notification: $e');
    }

    if (!mounted) return;

    const String shamCashId = 'ce40f4497f5429b1db116eb9cdf4c307';
    const String amountUsd = '1';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Column(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 48,
                  color: AppColors.gold,
                ),
                SizedBox(height: 10),
                Text(
                  'رسوم تبادل التواصل',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.goldSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'المبلغ المطلوب منك',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$amountUsd \$',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.goldDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'حوّل المبلغ إلى حساب شام كاش التالي:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            shamCashId,
                            textDirection: ui.TextDirection.ltr,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(
                              const ClipboardData(text: shamCashId),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم نسخ الرقم'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.copy_rounded,
                              size: 18,
                              color: AppColors.goldDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: AppColors.warning,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ادفع من حساب شام كاش مسجّل باسمك الحقيقي، '
                            'واكتب اسمك في خانة «اسم المُرسِل» ليتم التحقق يدويًا. '
                            'دفع الطرف الآخر لا يغني عن دفعك.',
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.6,
                              fontWeight: FontWeight.w600,
                              color: AppColors.goldDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'بعد الدفع سيراجع المشرف إشعار شام كاش. '
                    'أرقام التواصل تظهر فقط بعد تأكيد دفع الطرفين وموافقة الإدارة.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text(
                    'حسنًا، سأدفع الآن',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      final ok = await ApiService.recordPaymentNotified(
        widget.roomId,
        party: party,
      );
      debugPrint(
        ok
            ? '💰 Payment dialog recorded for $party / ${widget.roomId}'
            : '⚠️ Failed to record payment notification',
      );
    } catch (e) {
      debugPrint('⚠️ Error recording payment notification: $e');
    }
  }
// ============================================================
// عرض بيانات التواصل بعد الموافقة الكاملة
// ============================================================

Future<void> _showContactNumbers() async {
  // ═══════════════════════════════════════════════════════
  // 1. فحوصات الحماية
  // ═══════════════════════════════════════════════════════
  
  if (!mounted) {
    debugPrint('📞 _showContactNumbers: not mounted — abort');
    return;
  }

  if (_contactDialogSucceeded) {
    debugPrint('📞 _showContactNumbers: already succeeded — skip');
    return;
  }

  if (_contactFetching) {
    debugPrint('📞 _showContactNumbers: already fetching — skip');
    return;
  }

  _contactFetching = true;

  try {
    final Map<String, dynamic> data =
        await ApiService.getMatchedContact(widget.roomId);

    if (!mounted) {
      _contactFetching = false;
      return;
    }

    // ═══════════════════════════════════════════════════════
    // 4. التحقق من success
    // ═══════════════════════════════════════════════════════
    
    final success = data['success'] == true;

    if (!success) {
      final serverMessage = data['message']?.toString() 
          ?? data['error']?.toString() 
          ?? 'لم تتم الموافقة بعد';

      debugPrint('⚠️ RPC success=false: $serverMessage');
      _contactFetching = false;

      ErrorHandler.showWarning(context, serverMessage);
      return;
    }

    // ═══════════════════════════════════════════════════════
    // 5. استخراج البيانات
    // ═══════════════════════════════════════════════════════
    
    final name = data['name']?.toString().trim() ?? '';
    final phone = data['phone']?.toString().trim() ?? '';
    final type = data['type']?.toString();

    if (phone.isEmpty) {
      _contactFetching = false;

      ErrorHandler.showWarning(
        context,
        'رقم التواصل غير متوفر حالياً. حاول لاحقاً.',
      );
      return;
    }

    // ═══════════════════════════════════════════════════════
    // 6. نجح الجلب — اضبط الأعلام
    // ═══════════════════════════════════════════════════════
    
    _contactFetching = false;
    _contactDialogSucceeded = true;
    _contactDialogShown = true;

    final contactLabel = type == 'guardian' 
        ? 'رقم الولي' 
        : type == 'groom' 
            ? 'رقم الشاب' 
            : 'رقم التواصل';

    final nameLabel = type == 'guardian' 
        ? 'اسم الولي' 
        : type == 'groom' 
            ? 'اسم الشاب' 
            : 'الاسم';

    // ═══════════════════════════════════════════════════════
    // 8. عرض الحوار
    // ═══════════════════════════════════════════════════════
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Column(
              children: [
                Icon(
                  Icons.celebration_rounded,
                  size: 45,
                  color: AppColors.gold,
                ),
                SizedBox(height: 8),
                Text(
                  'مبارك!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'تمت الموافقة من الطرفين',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'نسأل الله أن يبارك لكما ويكتب لكما الخير.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                _buildContactInfo(
                  Icons.phone_rounded,
                  contactLabel,
                  phone,
                ),

                if (name.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildContactInfo(
                    Icons.person_rounded,
                    nameLabel,
                    name,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExplorationScreen(
                        isGroomRole: !widget.isWaliSender,
                      ),
                    ),
                    (route) => false,
                  );
                },
                child: const Text(
                  'إغلاق',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    debugPrint('📞✅ Dialog closed');

  } on ApiException catch (e) {
    _contactFetching = false;
    if (!mounted) return;
    ErrorHandler.showError(context, e, customMessage: e.userMessage);
  } catch (e, stackTrace) {
    _contactFetching = false;

    debugPrint('═══════════════════════════════════════════');
    debugPrint('❌❌❌ _showContactNumbers FAILED');
    debugPrint('❌ ERROR: $e');
    debugPrint('❌ TYPE: ${e.runtimeType}');
    debugPrint('❌ STACK: $stackTrace');
    debugPrint('═══════════════════════════════════════════');

    if (!mounted) return;

    // ═══ ترجمة رسائل الأخطاء ═══
    String userMessage = 'تعذر جلب معلومات التواصل';

    final errStr = e.toString().toLowerCase();

    if (errStr.contains('timeout') || errStr.contains('مهلة')) {
      userMessage = 'انتهت مهلة الاتصال. تحقق من الإنترنت.';
    } else if (errStr.contains('not found') || errStr.contains('غير موجود')) {
      userMessage = 'الغرفة غير موجودة';
    } else if (errStr.contains('not approved') || errStr.contains('approval')) {
      userMessage = 'لم تتم الموافقة الكاملة بعد';
    } else if (errStr.contains('unauthorized') || errStr.contains('jwt')) {
      userMessage = 'انتهت جلسة الدخول. أعد تسجيل الدخول.';
    } else if (errStr.contains('network') || errStr.contains('socket')) {
      userMessage = 'تحقق من اتصالك بالإنترنت';
    }

    ErrorHandler.showError(
      context,
      null,
      customMessage: userMessage,
    );
  }
}
// ============================================================
// عرض "بانتظار مراجعة الإدارة"
// ============================================================

// ============================================================
// عرض "بانتظار مراجعة الإدارة"
// ============================================================

Future<void> _showPendingReviewMessage() async {
  if (!mounted) return;

  // ✅ إذا كان الحوار معروضًا بالفعل — لا تكرر
  if (_contactDialogShown) {
    debugPrint('⏳ _showPendingReviewMessage: already shown — skip');
    return;
  }

  _contactDialogShown = true;

  debugPrint('⏳ Showing pending_admin_review dialog');

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Column(
            children: [
              Icon(
                Icons.hourglass_top_rounded,
                size: 48,
                color: AppColors.gold,
              ),
              SizedBox(height: 10),
              Text(
                'بانتظار مراجعة الإدارة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: const Text(
            'تمت الموافقة من الطرفين بنجاح. '
            'سيتم إرسال بيانات التواصل بينكما بعد مراجعة الإدارة للمحادثة.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'حسنًا، سأنتظر',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                // ✅ العودة لشاشة الاستكشاف
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExplorationScreen(
                      isGroomRole: !widget.isWaliSender,
                    ),
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                'خروج',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  // ═══════════════════════════════════════════════════════
  // ⚠️ مهم: لا نُعيد تشغيل المراقبة هنا
  // المراقبة الأصلية (من initState) لا تزال تعمل إن لم تُلغَ
  // ═══════════════════════════════════════════════════════
  debugPrint('⏳ Dialog closed — waiting for admin approval via realtime');
}
// ============================================================
// عرض "تم رفض الطلب"
// ============================================================

Future<void> _showRejectedMessage(String? reason) async {
  if (!mounted) return;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Column(
          children: [
            Icon(
              Icons.cancel_outlined,
              size: 48,
              color: AppColors.error,
            ),
            SizedBox(height: 10),
            Text(
              'تم رفض الطلب',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'للأسف، لم تتم الموافقة على هذه المحادثة من قبل الإدارة.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
            if (reason != null && reason.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'السبب:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      reason,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => ExplorationScreen(
                    isGroomRole: !widget.isWaliSender,
                  ),
                ),
                (route) => false,
              );
            },
            child: const Text(
              'حسنًا',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );
}
// ═══════════════════════════════════════════════════════════
// بناء صف معلومات التواصل
// ═══════════════════════════════════════════════════════════

Widget _buildContactInfo(
  IconData icon,
  String label,
  dynamic value,
) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 10,
    ),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        const SizedBox(width: 2),
        Icon(
          icon,
          size: 19,
          color: AppColors.primary,
        ),
        const SizedBox(width: 9),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value.toString(),
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

  // ============================================================
  // الإبلاغ
  // ============================================================

  Future<void> _showReportDialog() async {
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.report_outlined,
                color: AppColors.error,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'إبلاغ عن مخالفة',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: TextField(
            controller: reasonController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: tr('report_reason'),
              hintText: 'اكتب سبب البلاغ...',
              alignLabelWithHint: true,
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = reasonController.text.trim();

                if (reason.length < 3) {
                  ErrorHandler.showError(
                    context,
                    null,
                    customMessage: 'يرجى كتابة سبب واضح للبلاغ',
                  );
                  return;
                }

                try {
                  final result = await ApiService.reportChatRoom(
                    roomId: widget.roomId,
                    reason: reason,
                  );

                  if (!mounted) return;

                  if (result == true) {
                    Navigator.pop(context);

                    ErrorHandler.showSuccess(
                      context,
                      tr('report_sent'),
                    );
                  } else {
                    ErrorHandler.showError(
                      context,
                      null,
                      customMessage: tr('report_failed'),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;

                  ErrorHandler.showError(
                    context,
                    null,
                    customMessage: _translateRpcError(e),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(tr('send')),
            ),
          ],
        );
      },
    );

    reasonController.dispose();
  }

  // ============================================================
  // SnackBar
  // ============================================================

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // الواجهة
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: ScreenFrame(child: _buildBody()),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 8,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(
          height: 2,
          decoration: const BoxDecoration(gradient: AppColors.goldGradient),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'غرفة الخطوبة الشرعية',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (_room != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 12,
                  color: AppColors.goldLight,
                ),
                const SizedBox(width: 3),
                Text(
                  'المتبقي: ${_chatService.formatRemaining(_room!.remaining)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'قواعد المحادثة',
          icon: const Icon(Icons.info_outline_rounded),
          onPressed: _showChatRules,
        ),
        if (_room != null)
          IconButton(
            tooltip: 'إبلاغ',
            icon: const Icon(Icons.report_outlined),
            onPressed: _showReportDialog,
          ),
        if (_room != null && !_isRoomClosed)
          IconButton(
            tooltip: 'إنهاء المحادثة',
            icon: const Icon(
              Icons.handshake_outlined,
              color: AppColors.goldLight,
            ),
            onPressed: _showEndChatDialog,
          ),
        if (_room != null)
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 4),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  '${_room!.messageCount}/${ChatService.maxMessages}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingState(message: 'جارٍ فتح المحادثة...');
    }

    if (_errorMessage != null) {
      return ErrorState(
        message: _errorMessage!,
        title: 'تعذّر فتح المحادثة',
        onRetry: _loadRoom,
      );
    }

    final status = _room?.status;
    final showAdminHint = status == 'pending_admin_review';

    return Column(
      children: [
        InfoBanner(
          message: UiCopy.chatRulesShort,
          tone: InfoBannerTone.tip,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          onHelp: _showChatRules,
        ),
        if (showAdminHint)
          const InfoBanner(
            message: UiCopy.chatAdminReviewHint,
            tone: InfoBannerTone.warning,
            icon: Icons.hourglass_top_rounded,
            padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
          ),
        if (_room != null && !_room!.canSend) _buildRoomNotice(),
        Expanded(child: _buildMessages()),
        if (_room != null && _room!.canSend) _buildMessageInput(),
      ],
    );
  }

  Widget _buildRoomNotice() {
    final expired = _room!.isExpired;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: expired ? AppColors.errorLight : AppColors.warningLight,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: expired
              ? AppColors.error.withValues(alpha: 0.2)
              : AppColors.warning.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            expired
                ? Icons.timer_off_outlined
                : Icons.chat_bubble_outline_rounded,
            size: 20,
            color: expired ? AppColors.error : AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              expired ? tr('chat_expired') : tr('chat_full'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: expired ? AppColors.error : AppColors.goldDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _client
          .from('chat_messages')
          .stream(primaryKey: ['id'])
          .eq('room_id', widget.roomId)
          .order('created_at', ascending: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          _renderedMessageCount = 0;
          return _buildEmptyMessages();
        }

        if (messages.length != _renderedMessageCount) {
          final follow = _stickToBottom || _renderedMessageCount == 0;
          _renderedMessageCount = messages.length;
          if (follow) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || !_scrollController.hasClients) return;
              _scrollController.jumpTo(
                _scrollController.position.maxScrollExtent,
              );
            });
          }
        }

      return ListView.builder(
  controller: _scrollController,
  padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
  itemCount: messages.length,
  itemBuilder: (context, index) {
    final msg = messages[index];
    final currentUserId = _client.auth.currentUser?.id;
    final isMe = msg['sender_id'] == currentUserId;

    // ═══ عرض مباشر بدون FutureBuilder ═══
    return _buildMessageBubble(msg, isMe);
  },
);
      },
    );
  }

  Widget _buildEmptyMessages() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: IslamicCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.forum_outlined,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'ابدأ الحوار بأدب وجدية',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'هذه الغرفة بين الولي والخاطب فقط',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBubble(bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          '...',
          style: TextStyle(
            color: isMe ? Colors.white : AppColors.mutedText,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> msg,
    bool isMe,
  ) {
    final text = msg['message_text'] as String? ?? '';

    final time = msg['created_at'] != null
        ? DateTime.parse(msg['created_at'] as String).toLocal()
        : null;

    final timeStr = time != null
        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
        : '';

    return Align(
      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        decoration: BoxDecoration(
          gradient: isMe ? AppColors.primaryGradient : null,
          color: isMe ? null : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 5 : 16),
            bottomRight: Radius.circular(isMe ? 16 : 5),
          ),
          border: isMe ? null : Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textDirection: ui.TextDirection.rtl,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              timeStr,
              style: TextStyle(
                color: isMe
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppColors.mutedText,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.borderLight),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 7,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: tr('type_message'),
                  hintStyle: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                textDirection: ui.TextDirection.rtl,
                maxLines: 3,
                minLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.goldDark.withValues(alpha: 0.18),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          color: AppColors.textOnGold,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: AppColors.textOnGold,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}