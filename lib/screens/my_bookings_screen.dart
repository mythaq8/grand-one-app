// lib/screens/my_bookings_screen.dart
// ============================================================
// MyBookingsScreen — قائمة حجوزات المستخدم
//
// - البيانات: Supabase مباشرة (RLS محمي)
// - التقييم: Deno POST /api/bookings/review
// - اسم وصورة الخدمة: Deno /api/service-details
// ============================================================

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../app_colors.dart';
import '../ui_copy.dart';
import '../services/api_service.dart';
import '../services/api_exceptions.dart';
import '../widgets/brand_decorations.dart';
import '../widgets/ux_helpers.dart';
import 'service_detail_screen.dart';


class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key, this.embedded = false}) : super(key: key);

  /// عند العرض داخل تبويب «طلباتي» لا نعيد شريط عنوان.
  final bool embedded;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ═══ الحالة ═══
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all'; // all | pending | approved | rejected | cancelled | completed

  // ═══ البيانات ═══
  final List<Map<String, dynamic>> _bookings = [];
  final Map<String, Map<String, dynamic>> _serviceCache = {};

  // ═══ للتحكم في إعادة التقييم ═══
  
  String? _reviewingBookingId;
  // ═══ حالة رفع إشعار الدفع ═══
String? _uploadingDepositForBookingId;

  // ═══ Lifecycle ═══
  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  // ═══════════════════════════════════════════════════════════
  // تحميل الحجوزات
  // ═══════════════════════════════════════════════════════════
Future<void> _loadBookings() async {
  if (!mounted) return;

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'يجب تسجيل الدخول أولاً';
      });
      return;
    }

    // جلب كل حجوزات المستخدم من Supabase
    final result = await _supabase
        .from('bookings')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    if (!mounted) return;

    final bookings = List<Map<String, dynamic>>.from(result);

    // جلب اسم/صورة كل خدمة عبر Deno
    for (final booking in bookings) {
      if (!mounted) return;

      final serviceId = booking['service_id']?.toString();
      if (serviceId == null || serviceId.isEmpty) continue;

      if (_serviceCache.containsKey(serviceId)) continue;

      try {
        final details = await ApiService.getServiceDetails(serviceId);
        final service = details['service'];
        if (service is Map) {
          _serviceCache[serviceId] = Map<String, dynamic>.from(service);
        }
      } catch (e) {
        debugPrint('⚠️ Service details load failed for "$serviceId": $e');
        // تجاهل الأخطاء — سنعرض بديلاً
      }
    }

    if (!mounted) return;

    setState(() {
      _bookings
        ..clear()
        ..addAll(bookings);
      _isLoading = false;
    });
  } catch (e) {
    debugPrint('🔴 Load bookings error: $e');

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = 'فشل تحميل الحجوزات: $e';
    });
  }
}
  // ═══════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  String _formatPrice(dynamic price) {
    final d = _toDouble(price);
    if (d == d.roundToDouble()) return d.toInt().toString();
    return d.toStringAsFixed(2);
  }
  String _formatDate(dynamic value) {
  if (value == null) return '';
  try {
    final date = DateTime.parse(value.toString()).toLocal();
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  } catch (_) {
    return value.toString();
  }
}

  // ═══════════════════════════════════════════════════════════
  // تصفية القائمة
  // ═══════════════════════════════════════════════════════════

  List<Map<String, dynamic>> get _filteredBookings {
    if (_selectedFilter == 'all') return _bookings;
    return _bookings.where((b) {
      return b['status']?.toString() == _selectedFilter;
    }).toList();
  }

  int _countByStatus(String status) {
    if (status == 'all') return _bookings.length;
    return _bookings
        .where((b) => b['status']?.toString() == status)
        .length;
  }

  // ═══════════════════════════════════════════════════════════
  // إلغاء الحجز
  // ═══════════════════════════════════════════════════════════

  Future<void> _cancelBooking(String bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('إلغاء الحجز'),
          content: const Text(
            'هل أنت متأكد من إلغاء هذا الحجز؟\nلا يمكن التراجع عن هذا الإجراء.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('رجوع'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'إلغاء الحجز',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.cancelServiceBooking(bookingId: bookingId);

      if (!mounted) return;

      _showMessage('✅ تم إلغاء الحجز بنجاح');
      await _loadBookings();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage('تعذر إلغاء الحجز: ${e.userMessage}', isError: true);
    } catch (e) {
      if (!mounted) return;
      _showMessage('تعذر إلغاء الحجز: ${_extractError(e)}', isError: true);
    }
  }

  // ═══════════════════════════════════════════════════════════
// رفع إشعار دفع العربون
// ═══════════════════════════════════════════════════════════

Future<void> _uploadDeposit(Map<String, dynamic> booking) async {
  final bookingId = booking['id']?.toString();
  if (bookingId == null || bookingId.isEmpty) return;

  if (_uploadingDepositForBookingId != null) return;

  // ═══ اختيار الصورة ═══
  try {
    final files = await fp.FilePicker.pickFiles(
      type: fp.FileType.image,
    );

    if (files.isEmpty) return;

    final file = files.first;

    setState(() => _uploadingDepositForBookingId = bookingId);

    var bytes = await file.xFile.readAsBytes();

    // ═══ ضغط الصورة ═══
    try {
      final compressed =
          await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 800,
        minHeight: 800,
        quality: 70,
      );

      if (compressed.isNotEmpty) {
        bytes = compressed;
      }
    } catch (_) {}

    // ═══ رفع الصورة إلى Supabase Storage ═══
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('يجب تسجيل الدخول');
    }

    final fileName =
        '$userId/deposit_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _supabase.storage
        .from('booking_deposits')
        .uploadBinary(fileName, bytes);

    // ═══ استدعاء Deno ═══
    await ApiService.uploadBookingDeposit(
      bookingId: bookingId,
      proofPath: fileName,
    );

    if (!mounted) return;

    setState(() => _uploadingDepositForBookingId = null);

    _showMessage('✅ تم رفع إشعار الدفع. بانتظار تحقق الإدارة.');

    // ═══ إعادة تحميل ═══
    await _loadBookings();
  } catch (e) {
    debugPrint('🔴 Deposit upload error: $e');

    if (!mounted) return;

    setState(() => _uploadingDepositForBookingId = null);

    _showMessage(
      'تعذر رفع الإشعار: ${_extractError(e)}',
      isError: true,
    );
  }
}

  // ═══════════════════════════════════════════════════════════
  // فتح تقييم
  // ═══════════════════════════════════════════════════════════

  Future<void> _openReview(
    Map<String, dynamic> booking,
    String target, // 'service' | 'provider'
  ) async {
    final serviceId = booking['service_id']?.toString() ?? '';
    final providerId = booking['provider_id']?.toString() ?? '';
    final bookingId = booking['id']?.toString() ?? '';

    if (bookingId.isEmpty) return;

    if (target == 'service' && serviceId.isEmpty) return;
    if (target == 'provider' && providerId.isEmpty) return;

    int selectedRating = 0;
    final commentController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: ui.TextDirection.rtl,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                title: Text(
                  target == 'service'
                      ? 'تقييم الخدمة'
                      : 'تقييم المزود',
                  textAlign: TextAlign.center,
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'كيف كانت تجربتك؟',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final star = i + 1;
                          return IconButton(
                            onPressed: () {
                              setDialogState(() => selectedRating = star);
                            },
                            icon: Icon(
                              star <= selectedRating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 38,
                              color: AppColors.gold,
                            ),
                          );
                        }),
                      ),
                      if (selectedRating > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '$selectedRating من 5',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.goldDark,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      if (target == 'service')
                        TextField(
                          controller: commentController,
                          maxLines: 3,
                          maxLength: 500,
                          decoration: const InputDecoration(
                            labelText: 'تعليقك (اختياري)',
                            hintText: 'اكتب رأيك هنا...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: selectedRating == 0
                        ? null
                        : () async {
                            Navigator.pop(dialogCtx);
                            await _submitReview(
                              bookingId: bookingId,
                              target: target,
                              serviceId: serviceId,
                              providerId: providerId,
                              rating: selectedRating,
                              comment: commentController.text.trim(),
                            );
                          },
                    child: const Text('إرسال'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    commentController.dispose();
  }

 Future<void> _submitReview({
  required String bookingId,
  required String target,
  required String serviceId,
  required String providerId,
  required int rating,
  required String comment,
}) async {
  if (!mounted) return;

  final user = _supabase.auth.currentUser;
  if (user == null) {
    _showMessage('يجب تسجيل الدخول', isError: true);
    return;
  }

  if (target == 'service' && serviceId.isEmpty) {
    _showMessage('معرّف الخدمة غير متوفر', isError: true);
    return;
  }
  if (target == 'provider' && providerId.isEmpty) {
    _showMessage('معرّف المزود غير متوفر', isError: true);
    return;
  }

  setState(() => _reviewingBookingId = bookingId);

  try {
    await ApiService.submitBookingReview(
      bookingId: bookingId,
      target: target,
      rating: rating,
      comment: target == 'service' && comment.isNotEmpty ? comment : null,
    );

    if (!mounted) return;

    setState(() => _reviewingBookingId = null);

    _showMessage(target == 'service'
        ? '✅ شكراً لتقييمك للخدمة'
        : '✅ شكراً لتقييمك للمزود');

    await _loadBookings();
  } on ApiException catch (e) {
    if (!mounted) return;
    setState(() => _reviewingBookingId = null);
    _showMessage(e.userMessage, isError: true);
  } catch (e) {
    debugPrint('🔴 Submit review error: $e');

    if (!mounted) return;
    setState(() => _reviewingBookingId = null);
    _showMessage(
      'تعذر إرسال التقييم: ${_extractError(e)}',
      isError: true,
    );
  }
}
  // ═══════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════

  String _extractError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('not authenticated') ||
        msg.contains('unauthenticated')) {
      return 'يجب تسجيل الدخول';
    }
    if (msg.contains('already reviewed') ||
        msg.contains('duplicate')) {
      return 'قمت بتقييم هذا مسبقاً';
    }
    if (msg.contains('not completed')) {
      return 'لا يمكن التقييم قبل إكمال الحجز';
    }
    return msg.length > 100 ? '${msg.substring(0, 100)}...' : msg;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
          ),
          backgroundColor: isError ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ═══════════════════════════════════════════════════════════
  // الواجهة
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: BrandScaffold(
        // عند العرض داخل تبويب «طلباتي» لا نعيد شريط عنوان،
        // فالهيكل يوفّر العنوان والمبدّل.
        appBar: widget.embedded
            ? null
            : BrandAppBar(
                title: 'حجوزاتي',
                actions: [
                  IconButton(
                    tooltip: 'تحديث',
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _isLoading ? null : _loadBookings,
                  ),
                ],
              ),
        body: Column(
            children: [
              if (!widget.embedded)
                const InfoBanner(
                  message: UiCopy.bookingsStatusHint,
                  tone: InfoBannerTone.info,
                ),
              _buildFiltersBar(),
              Expanded(child: _buildBody()),
            ],
          ),
        
      ),
    );
  }

  // ─── شريط التصفيات ───

  Widget _buildFiltersBar() {
   final filters = [
  ('all', 'الكل', Icons.list_alt_outlined),
  ('pending', 'قيد المراجعة', Icons.schedule_rounded),
  ('quote_requested', 'طلب عرض سعر', Icons.request_quote_outlined),
  ('quoted', 'عرض سعر جاهز', Icons.price_change_outlined),
  ('approved', 'بانتظار الدفع', Icons.payment_outlined),
  ('paid_pending_verification', 'بانتظار التحقق', Icons.hourglass_top_rounded),
  ('ready', 'جاهز', Icons.event_available_rounded),
  ('completed', 'مكتملة', Icons.verified_rounded),
  ('cancelled', 'ملغاة', Icons.block_rounded),
];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: filters.map((f) {
            final (key, label, icon) = f;
            final selected = _selectedFilter == key;
            final count = _countByStatus(key);

            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Material(
                color: selected
                    ? AppColors.primary
                    : AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _selectedFilter = key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 15,
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$label ($count)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── الجسم ───

  Widget _buildBody() {
    if (_isLoading) return _buildLoading();
    if (_errorMessage != null) return _buildError();
    if (_bookings.isEmpty) return _buildEmpty();

    final filtered = _filteredBookings;
    if (filtered.isEmpty) return _buildEmptyFiltered();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadBookings,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
        itemCount: filtered.length,
        itemBuilder: (context, index) =>
            _buildBookingCard(filtered[index]),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: BrandCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 15),
              Text(
                _errorMessage ?? 'حدث خطأ',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 15),
              BrandButton(
                label: 'إعادة المحاولة',
                icon: const Icon(Icons.refresh_rounded, size: 19),
                onPressed: _loadBookings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadBookings,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          Center(
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.calendar_month_outlined,
                    size: 46,
                    color: AppColors.goldDark,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'لا توجد حجوزات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'احجز خدمتك الأولى من قسم "الخدمات"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFiltered() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.filter_alt_off_outlined,
                size: 38,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد حجوزات في هذه الحالة',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── بطاقة الحجز ───

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final bookingId = booking['id']?.toString() ?? '';
    final serviceId = booking['service_id']?.toString() ?? '';
    final status = booking['status']?.toString() ?? 'pending';

    final service = _serviceCache[serviceId];
    final serviceName = service?['name']?.toString() ?? 'خدمة';

    // صورة
    String? coverUrl;
    final cover = service?['cover_image'];
    if (cover is Map) {
      coverUrl = cover['signed_url']?.toString() ??
          cover['image_url']?.toString();
    }

    final date = booking['booking_date']?.toString() ?? '';
    final time = booking['booking_time']?.toString() ?? '';
    final guests = _toInt(booking['guests_count']);
    final price = booking['total_price'];
    final snapshot = booking['price_snapshot'];
    final Map<String, dynamic>? priceSnap = snapshot is Map
        ? Map<String, dynamic>.from(snapshot)
        : null;
    final notes = booking['notes']?.toString() ?? '';
    final rejectionReason = booking['rejection_reason']?.toString() ?? '';

    final serviceReviewed = booking['service_reviewed'] == true;
    final providerReviewed = booking['provider_reviewed'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // رأس البطاقة
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // صورة الخدمة
                Container(
                  width: 68,
                  height: 68,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceTint,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: (coverUrl != null && coverUrl.isNotEmpty)
                      ? Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.business_center_outlined,
                            size: 30,
                            color: AppColors.gold,
                          ),
                        )
                      : const Icon(
                          Icons.business_center_outlined,
                          size: 30,
                          color: AppColors.gold,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildStatusBadge(status),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // التفاصيل
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                if (date.isNotEmpty)
                  _infoRow(Icons.calendar_today_outlined, 'التاريخ', date),
                if (time.isNotEmpty)
                  _infoRow(Icons.access_time_rounded, 'الوقت', time),
                if (guests > 0)
                  _infoRow(
                    Icons.people_outline_rounded,
                    'عدد الضيوف',
                    '$guests',
                  ),
                if (status == 'quote_requested')
                  _infoRow(
                    Icons.request_quote_outlined,
                    'التسعير',
                    'بانتظار عرض سعر من الإدارة',
                    highlight: true,
                  )
                else if (price != null)
                  _infoRow(
                    Icons.payments_outlined,
                    'الإجمالي',
                    '${_formatPrice(price)} \$',
                    highlight: true,
                  ),
                if (priceSnap != null &&
                    priceSnap.isNotEmpty &&
                    status != 'quote_requested') ...[
                  if (priceSnap['subtotal'] != null)
                    _infoRow(
                      Icons.receipt_long_outlined,
                      'قبل الحسم',
                      '${_formatPrice(priceSnap['subtotal'])} \$',
                    ),
                  if (_toDouble(priceSnap['discount_amount']) > 0)
                    _infoRow(
                      Icons.local_offer_outlined,
                      'الحسم',
                      '-${_formatPrice(priceSnap['discount_amount'])} \$',
                    ),
                  if (priceSnap['package'] is Map &&
                      (priceSnap['package'] as Map)['name'] != null)
                    _infoRow(
                      Icons.inventory_2_outlined,
                      'الباقة',
                      (priceSnap['package'] as Map)['name'].toString(),
                    ),
                ],
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      notes,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
                if (status == 'rejected' && rejectionReason.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 16,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'سبب الرفض: $rejectionReason',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

         // ═══════════════════════════════════════════════
// قسم العربون (للحالات: approved / awaiting_payment / paid_pending_verification / deposit_rejected)
// ═══════════════════════════════════════════════
if ([
  'approved',
  'paid_pending_verification',
  'deposit_rejected',
].contains(status))
  _buildDepositSection(booking, status),

// الأزرار الأساسية
if (status == 'pending' || status == 'approved') ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: bookingId.isEmpty
                          ? null
                          : () => _cancelBooking(bookingId),
                      icon: const Icon(Icons.cancel_outlined, size: 17),
                      label: const Text('إلغاء الحجز'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (status == 'ready') ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 20,
                      color: AppColors.goldDark,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'تم تأكيد العربون والحجز جاهز. تنفيذ الخدمة في موعدها.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: AppColors.goldDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (status == 'completed') ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildReviewButton(
                      label: 'قيّم الخدمة',
                      done: serviceReviewed,
                      isBusy: _reviewingBookingId == bookingId,
                      onTap: serviceReviewed
                          ? null
                          : () => _openReview(booking, 'service'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildReviewButton(
                      label: 'قيّم المزود',
                      done: providerReviewed,
                      isBusy: _reviewingBookingId == bookingId,
                      onTap: providerReviewed
                          ? null
                          : () => _openReview(booking, 'provider'),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // زر التفاصيل
          if (serviceId.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ServiceDetailScreen(
                        serviceId: serviceId,
                        initialService: service,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility_outlined, size: 17),
                label: const Text('عرض تفاصيل الخدمة'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
// قسم العربون
// ═══════════════════════════════════════════════════════════

Widget _buildDepositSection(
  Map<String, dynamic> booking,
  String status,
) {
  final bookingId = booking['id']?.toString() ?? '';
  final depositAmount = booking['deposit_amount'];
  final depositReason =
      booking['deposit_rejection_reason']?.toString() ?? '';
  final paymentDeadline =
      booking['payment_deadline']?.toString() ?? '';

  // ═══ الحالة: approved → يطلب الدفع ═══
  if (status == 'approved') {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColors.goldDark,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'مطلوب دفع العربون',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.goldDark,
                  ),
                ),
              ),
            ],
          ),
          if (depositAmount != null) ...[
            const SizedBox(height: 8),
            _infoRow(
              Icons.payments_outlined,
              'المبلغ المطلوب',
              '${_formatPrice(depositAmount)} \$',
              highlight: true,
            ),
          ],
          if (paymentDeadline.isNotEmpty) ...[
            const SizedBox(height: 4),
            _infoRow(
              Icons.timer_outlined,
              'آخر موعد',
              _formatDate(paymentDeadline),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _uploadingDepositForBookingId == bookingId
                  ? null
                  : () => _uploadDeposit(booking),
              icon: _uploadingDepositForBookingId == bookingId
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.upload_file_outlined, size: 18),
              label: Text(
                _uploadingDepositForBookingId == bookingId
                    ? 'جارٍ الرفع...'
                    : 'رفع إشعار الدفع',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ═══ الحالة: paid_pending_verification ═══
  if (status == 'paid_pending_verification') {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.hourglass_top_rounded,
            size: 20,
            color: AppColors.info,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'تم رفع الإشعار. بانتظار تحقق الإدارة.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.info,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══ الحالة: deposit_rejected → يطلب إعادة الرفع ═══
  if (status == 'deposit_rejected') {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 18,
                color: AppColors.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تم رفض إشعار الدفع',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    if (depositReason.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'السبب: $depositReason',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.error,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _uploadingDepositForBookingId == bookingId
                  ? null
                  : () => _uploadDeposit(booking),
              icon: _uploadingDepositForBookingId == bookingId
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                _uploadingDepositForBookingId == bookingId
                    ? 'جارٍ الرفع...'
                    : 'إعادة رفع الإشعار',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  return const SizedBox.shrink();
}

  Widget _buildReviewButton({
    required String label,
    required bool done,
    required bool isBusy,
    required VoidCallback? onTap,
  }) {
    if (done) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.3),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: AppColors.success,
            ),
            SizedBox(width: 5),
            Text(
              'تم التقييم',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: isBusy ? null : onTap,
      icon: isBusy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.star_rounded, size: 17),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        ),
      ),
    );
  }

 Widget _buildStatusBadge(String status) {
  Color color;
  Color bg;
  IconData icon;
  String label;

  switch (status) {
    case 'pending':
      color = AppColors.warning;
      bg = AppColors.warningLight;
      icon = Icons.schedule_rounded;
      label = 'قيد المراجعة';
      break;
    case 'approved':
      color = AppColors.success;
      bg = AppColors.successLight;
      icon = Icons.check_circle_outline_rounded;
      label = 'مقبول — يرجى دفع العربون';
      break;
    case 'awaiting_payment':
      color = AppColors.goldDark;
      bg = AppColors.goldSoft;
      icon = Icons.payment_outlined;
      label = 'بانتظار الدفع';
      break;
    case 'paid_pending_verification':
      color = AppColors.info;
      bg = AppColors.infoLight;
      icon = Icons.hourglass_top_rounded;
      label = 'بانتظار تحقق الإدارة';
      break;
    case 'ready':
      color = AppColors.goldDark;
      bg = AppColors.goldSoft;
      icon = Icons.event_available_rounded;
      label = 'جاهز — بانتظار التنفيذ';
      break;
    case 'deposit_rejected':
      color = AppColors.error;
      bg = AppColors.errorLight;
      icon = Icons.error_outline_rounded;
      label = 'تم رفض إشعار الدفع';
      break;
    case 'rejected':
      color = AppColors.error;
      bg = AppColors.errorLight;
      icon = Icons.cancel_outlined;
      label = 'مرفوض';
      break;
    case 'cancelled':
      color = AppColors.mutedText;
      bg = AppColors.surfaceTint;
      icon = Icons.block_rounded;
      label = 'ملغي';
      break;
    case 'expired':
      color = AppColors.mutedText;
      bg = AppColors.surfaceTint;
      icon = Icons.timer_off_outlined;
      label = 'انتهت المهلة';
      break;
    case 'completed':
      color = AppColors.success;
      bg = AppColors.successLight;
      icon = Icons.verified_rounded;
      label = 'مكتمل';
      break;
    case 'quote_requested':
      color = AppColors.info;
      bg = AppColors.infoLight;
      icon = Icons.request_quote_outlined;
      label = 'طلب عرض سعر';
      break;
    case 'quoted':
      color = AppColors.goldDark;
      bg = AppColors.goldSoft;
      icon = Icons.price_change_outlined;
      label = 'عرض سعر جاهز';
      break;
    default:
      color = AppColors.mutedText;
      bg = AppColors.surfaceTint;
      icon = Icons.help_outline_rounded;
      label = status;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: highlight ? AppColors.goldDark : AppColors.mutedText,
          ),
          const SizedBox(width: 7),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: highlight
                    ? AppColors.goldDark
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}