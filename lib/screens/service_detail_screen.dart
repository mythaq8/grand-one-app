// lib/screens/service_detail_screen.dart
// ============================================================
// ServiceDetailScreen — تفاصيل الخدمة + الحجز
//
// متوافق مع Deno:
// - GET /api/service-details?id=...
// - الحجز عبر Deno: POST /api/bookings/quote | /api/bookings
// ============================================================

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../design/tokens.dart';
import '../ui/kit/kit.dart';
import '../ui/layout/responsive.dart';
import '../ui_copy.dart';
import '../services/api_service.dart';
import '../services/api_exceptions.dart';
import '../utils/service_category_icon.dart';
import '../utils/service_price_label.dart';
import '../widgets/brand_decorations.dart';
import '../widgets/ux_helpers.dart';
import 'event/event_form_screen.dart';

class ServiceDetailScreen extends StatefulWidget {
  /// id الخدمة (نمرره من قائمة الخدمات)
  final String serviceId;

  /// بيانات مبدئية من القائمة (لعرض فوري أثناء التحميل)
  final Map<String, dynamic>? initialService;

  /// من تنظيم المناسبة: زر أضف إلى اختياراتي بدل إرسال الحجز
  final bool forOccasionCart;

  /// الكمية الحالية في اختياراتي، إن وُجدت
  final double? occasionQuantity;

  /// الخدمة موجودة مسبقاً في اختياراتي
  final bool occasionAlreadyInCart;

  const ServiceDetailScreen({
    Key? key,
    required this.serviceId,
    this.initialService,
    this.forOccasionCart = false,
    this.occasionQuantity,
    this.occasionAlreadyInCart = false,
  }) : super(key: key);

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ═══ الحد الأقصى لعدد الضيوف ═══
  static const int _maxGuests = 500;

  // ═══ الحالة ═══
  bool _isLoading = true;
  bool _isBooking = false;
  String? _errorMessage;

  // ═══ البيانات ═══
  Map<String, dynamic>? _service;
  Map<String, dynamic>? _provider;
  Map<String, dynamic>? _category;
  List<Map<String, dynamic>> _images = [];
  List<Map<String, dynamic>> _fields = [];
  List<Map<String, dynamic>> _values = [];
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _packages = [];
  List<Map<String, dynamic>> _addons = [];

  // ═══ نموذج الحجز ═══
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _guestsCount = 0;
  String? _selectedPackageId;
  final Set<String> _selectedAddonIds = {};
  double _quantity = 1;
  double _durationValue = 1;
  Map<String, dynamic>? _quote;
  bool _isQuoting = false;

  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _guestsController =
      TextEditingController(text: '0');
  final TextEditingController _quantityController =
      TextEditingController(text: '1');
  final TextEditingController _durationController =
      TextEditingController(text: '1');

  final FocusNode _guestsFocusNode = FocusNode();

  // ============================================================
  // Lifecycle
  // ============================================================

  @override
  void initState() {
    super.initState();

    if (widget.initialService != null) {
      _service = widget.initialService;
    }

    var preset = widget.occasionQuantity;
    if (widget.forOccasionCart && (preset == null || preset <= 0)) {
      final model =
          widget.initialService?['pricing_model']?.toString() ?? 'fixed_package';
      if (model == 'per_unit' || model == 'per_duration') {
        final raw = widget.initialService?['min_qty'];
        final minQ = raw is num ? raw.toDouble() : double.tryParse('${raw ?? ''}');
        preset = (minQ == null || minQ < 1) ? 1 : minQ;
      }
    }
    if (widget.forOccasionCart && preset != null && preset > 0) {
      _quantity = preset;
      _durationValue = preset;
      final text = preset == preset.roundToDouble()
          ? preset.toInt().toString()
          : preset.toString();
      _quantityController.text = text;
      _durationController.text = text;
    }

    // ═══ عند الخروج من حقل الضيوف: طبّع النص ═══
    _guestsFocusNode.addListener(() {
      if (!_guestsFocusNode.hasFocus && mounted) {
        _guestsController.text = _guestsCount.toString();
      }
    });

    _loadDetails();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    _guestsController.dispose();
    _quantityController.dispose();
    _durationController.dispose();
    _guestsFocusNode.dispose();
    super.dispose();
  }

  // ============================================================
  // تحميل التفاصيل
  // ============================================================

  Future<void> _loadDetails() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getServiceDetails(widget.serviceId);

      if (!mounted) return;

      final packages = _asList(response['packages']);
      final addons = _asList(response['addons']);
      setState(() {
        _service = _asMap(response['service']) ?? _service;
        _provider = _asMap(response['provider']);
        _category = _asMap(response['category']);
        _images = _asList(response['images']);
        _fields = _asList(response['fields']);
        _values = _asList(response['values']);
        _reviews = _asList(response['reviews']);
        _packages = packages;
        _addons = addons;
        if (_selectedPackageId == null && packages.isNotEmpty) {
          _selectedPackageId = packages.first['id']?.toString();
        }
        for (final a in addons) {
          if (a['is_required'] == true && a['id'] != null) {
            _selectedAddonIds.add(a['id'].toString());
          }
        }
        _isLoading = false;
      });
      _refreshQuote();
    } on ApiException catch (e) {
      debugPrint(
        '🔴 Service details API error: ${e.message} '
        '(code: ${e.statusCode})',
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.userMessage;
      });
    } catch (e, stackTrace) {
      debugPrint('🔴 Service details error: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ غير متوقع: $e';
      });
    }
  }

  // ============================================================
  // Helpers
  // ============================================================

  Map<String, dynamic>? _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  String _formatPrice(dynamic price) {
    final d = _toDouble(price);
    if (d == d.roundToDouble()) return d.toInt().toString();
    return d.toStringAsFixed(2);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // استخراج قيمة حقل ديناميكي
  // ============================================================

  String _getFieldValue(Map<String, dynamic> field) {
    final fieldId = field['id']?.toString();
    if (fieldId == null) return '';

    Map<String, dynamic>? value;
    for (final v in _values) {
      if (v['field_id']?.toString() == fieldId) {
        value = v;
        break;
      }
    }
    if (value == null) return '';

    final type = field['field_type']?.toString() ?? 'text';

    switch (type) {
      case 'text':
      case 'textarea':
        return value['value_text']?.toString() ?? '';
      case 'integer':
      case 'decimal':
      case 'price':
      case 'duration':
        final n = value['value_number'];
        if (n == null) return '';
        final d = _toDouble(n);
        if (d == d.roundToDouble()) return d.toInt().toString();
        return d.toStringAsFixed(2);
      case 'boolean':
        final b = value['value_boolean'];
        if (b == true) return 'نعم';
        if (b == false) return 'لا';
        return '';
      case 'date':
        return value['value_date']?.toString() ?? '';
      case 'select':
        final json = value['value_json'];
        if (json is List && json.isNotEmpty) return json.first.toString();
        return value['value_text']?.toString() ?? '';
      case 'multiselect':
        final json = value['value_json'];
        if (json is List) {
          return json.map((e) => e.toString()).join(' • ');
        }
        return '';
      default:
        return value['value_text']?.toString() ?? '';
    }
  }

  // ============================================================
  // الحجز — اختيارات
  // ============================================================

  Future<void> _selectDate() async {
    if (!mounted) return;

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: tomorrow,
      firstDate: tomorrow,
      lastDate: DateTime(now.year + 1, now.month, now.day),
      builder: (ctx, child) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: child!,
      ),
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    if (!mounted) return;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: child!,
      ),
    );

    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  // ============================================================
  // تعديل عدد الضيوف (buttons + text)
  // ============================================================

  void _decrementGuests() {
    if (_isBooking || _guestsCount <= 0) return;

    setState(() {
      _guestsCount--;
      _guestsController.text = _guestsCount.toString();
    });
    _refreshQuote();
  }

  void _incrementGuests() {
    if (_isBooking || _guestsCount >= _maxGuests) return;

    setState(() {
      _guestsCount++;
      _guestsController.text = _guestsCount.toString();
    });
    _refreshQuote();
  }

  void _onGuestsTextChanged(String value) {
    final n = int.tryParse(value.trim());

    // ═══ تجاهل المدخلات غير الرقمية ═══
    if (n == null) {
      return;
    }

    // ═══ أقل من صفر ═══
    if (n < 0) {
      setState(() {
        _guestsCount = 0;
        _guestsController.text = '0';
      });
      return;
    }

    // ═══ أكبر من الحد ═══
    if (n > _maxGuests) {
      setState(() {
        _guestsCount = _maxGuests;
        _guestsController.text = _maxGuests.toString();
      });
      return;
    }

    // ═══ قيمة صحيحة ═══
    setState(() => _guestsCount = n);
    _refreshQuote();
  }

  String get _pricingModel =>
      _service?['pricing_model']?.toString() ?? 'fixed_package';

  bool get _isQuoteRequest => _pricingModel == 'quote_request';

  Future<void> _refreshQuote() async {
    if (widget.forOccasionCart) return;
    if (_supabase.auth.currentUser == null) return;
    if (_service == null) return;
    if (_isQuoteRequest) {
      if (mounted) setState(() => _quote = null);
      return;
    }

    setState(() => _isQuoting = true);
    try {
      final guestsForQuote = _pricingModel == 'per_unit'
          ? _quantity.round().clamp(0, _maxGuests)
          : _guestsCount;
      final result = await ApiService.quoteServiceBooking(
        serviceId: widget.serviceId,
        packageId: _pricingModel == 'fixed_package'
            ? _selectedPackageId
            : null,
        quantity: _pricingModel == 'per_unit' ? _quantity : null,
        durationValue:
            _pricingModel == 'per_duration' ? _durationValue : null,
        addonIds: _selectedAddonIds.toList(),
        guestsCount: guestsForQuote,
      );
      if (!mounted) return;
      setState(() {
        _quote = result.isEmpty ? null : result;
        _isQuoting = false;
      });
    } catch (e) {
      debugPrint('quote error: $e');
      if (!mounted) return;
      setState(() {
        _quote = null;
        _isQuoting = false;
      });
    }
  }

  // ============================================================
  // إضافة إلى سلة الفعالية
  // ============================================================

  Future<void> _addToEventCart() async {
    if (!mounted || _isBooking) return;
    if (_service == null) return;
    if (_supabase.auth.currentUser == null) {
      _showMessage('يجب تسجيل الدخول أولاً', isError: true);
      return;
    }

    try {
      var res = await ApiService.getActiveEvent();
      var event = res['event'];
      if (event is! Map) {
        // الفعالية إجبارية قبل الإضافة للسلة
        final created = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const EventFormScreen()),
        );
        if (created != true || !mounted) return;
        res = await ApiService.getActiveEvent();
        event = res['event'];
        if (event is! Map) return;
      }

      final time = _selectedTime != null
          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:'
              '${_selectedTime!.minute.toString().padLeft(2, '0')}:00'
          : null;
      final guestsForBooking = _pricingModel == 'per_unit'
          ? _quantity.round().clamp(0, _maxGuests)
          : _guestsCount;

      await ApiService.addToEventCart(
        event['id'].toString(),
        serviceId: widget.serviceId,
        packageId: _pricingModel == 'fixed_package' ? _selectedPackageId : null,
        quantity: _pricingModel == 'per_unit' ? _quantity : null,
        durationValue: _pricingModel == 'per_duration' ? _durationValue : null,
        addonIds: _selectedAddonIds.toList(),
        guestsCount: guestsForBooking,
        bookingTime: time,
        notes: _notesController.text.trim(),
      );
      if (!mounted) return;
      _showMessage('أُضيفت الخدمة إلى فعاليتك');
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.userMessage, isError: true);
    } catch (e) {
      if (!mounted) return;
      _showMessage(_extractError(e), isError: true);
    }
  }

  // ============================================================
  // إرسال الحجز
  // ============================================================

  Future<void> _submitBooking() async {
    if (!mounted) return;
    if (_isBooking) return;   // ← حماية من الضغط المزدوج

    if (!widget.forOccasionCart && _category?['requires_organizer'] == true) {
      _showMessage(
        'هذا التصنيف يُحجز عبر تنظيم مناسبة مع منظّم فقط',
        isError: true,
      );
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      _showMessage('يجب تسجيل الدخول أولاً', isError: true);
      return;
    }

    if (_service == null) {
      _showMessage('بيانات الخدمة غير محمّلة', isError: true);
      return;
    }

    if (_selectedDate == null) {
      _showMessage('يرجى اختيار تاريخ الحجز', isError: true);
      return;
    }

    if (_locationController.text.trim().isEmpty) {
      _showMessage('يرجى إدخال مكان تنفيذ الخدمة', isError: true);
      return;
    }

    if (_pricingModel == 'fixed_package' &&
        _packages.isNotEmpty &&
        (_selectedPackageId == null || _selectedPackageId!.isEmpty)) {
      _showMessage('يرجى اختيار باقة', isError: true);
      return;
    }

    setState(() => _isBooking = true);

    try {
      final time = _selectedTime != null
          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:'
              '${_selectedTime!.minute.toString().padLeft(2, '0')}:00'
          : null;

      final guestsForBooking = _pricingModel == 'per_unit'
          ? _quantity.round().clamp(0, _maxGuests)
          : _guestsCount;

      await ApiService.createServiceBooking(
        serviceId: widget.serviceId,
        bookingDate: _formatDate(_selectedDate!),
        bookingTime: time,
        location: _locationController.text.trim(),
        guestsCount: guestsForBooking,
        notes: _notesController.text.trim(),
        packageId: _pricingModel == 'fixed_package'
            ? _selectedPackageId
            : null,
        quantity: _pricingModel == 'per_unit' ? _quantity : null,
        durationValue:
            _pricingModel == 'per_duration' ? _durationValue : null,
        addonIds: _selectedAddonIds.toList(),
      );

      if (!mounted) return;

      setState(() {
        _isBooking = false;
        _selectedDate = null;
        _selectedTime = null;
        _guestsCount = 0;
        _guestsController.text = '0';
        _locationController.clear();
        _notesController.clear();
        _quote = null;
      });

      _showMessage(
        _isQuoteRequest
            ? 'تم إرسال طلب عرض السعر بنجاح'
            : 'تم إرسال طلب الحجز بنجاح',
      );
    } on ApiException catch (e) {
      debugPrint('🔴 Submit booking error: $e');
      if (!mounted) return;
      setState(() => _isBooking = false);
      _showMessage('تعذر إرسال الحجز: ${e.userMessage}', isError: true);
    } catch (e) {
      debugPrint('🔴 Submit booking error: $e');

      if (!mounted) return;

      setState(() => _isBooking = false);

      _showMessage(
        'تعذر إرسال الحجز: ${_extractError(e)}',
        isError: true,
      );
    }
  }

  // ============================================================
  // استخراج رسالة خطأ
  // ============================================================

  String _extractError(dynamic e) {
    final msg = e.toString().toLowerCase();

    if (msg.contains('not authenticated') ||
        msg.contains('unauthenticated')) {
      return 'يجب تسجيل الدخول';
    }

    if (msg.contains('not found')) {
      return 'الخدمة غير متوفرة';
    }

    if (msg.contains('bookable')) {
      return 'هذه الخدمة غير قابلة للحجز';
    }

    // ═══ فحص أدق للتاريخ ═══
    if (msg.contains('invalid date') ||
        msg.contains('booking_date') ||
        msg.contains('date must be')) {
      return 'التاريخ غير صالح';
    }

    if (msg.contains('guests')) {
      return 'عدد الضيوف غير صالح';
    }

    // ═══ رسالة عامة ═══
    final original = e.toString();
    return original.length > 100
        ? '${original.substring(0, 100)}...'
        : original;
  }

  // ============================================================
  // SnackBar
  // ============================================================

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
            ),
          ),
          backgroundColor: isError
              ? AppColors.error
              : AppColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: BrandScaffold(
        appBar: BrandAppBar(
          title: _service?['name']?.toString() ?? 'تفاصيل الخدمة',
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _service == null) {
      return const LoadingState(message: 'جارٍ تحميل تفاصيل الخدمة...');
    }
    if (_errorMessage != null && _service == null) {
      return ErrorState(
        message: _errorMessage!,
        onRetry: _loadDetails,
      );
    }

    return RefreshIndicator(
      color: AppPalette.green,
      onRefresh: _loadDetails,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: Space.screenH),
        children: [
          // على التابلت نُبقي عمود القراءة ضيقاً: أسطر طويلة
          // بعرض 900px تكون مرهقة للعين.
          ContentMaxWidth(
            maxWidth: Sizes.formMax + 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Space.md),
                _buildImagesGallery(),
                const SizedBox(height: Space.lg),
                _buildServiceTitle(),
                const SizedBox(height: Space.md),
                _buildMainInfoCard(),
                if (_provider != null) ...[
                  const SizedBox(height: Space.md),
                  _buildProviderCard(),
                ],
                if (_service?['description'] != null) ...[
                  const SizedBox(height: Space.md),
                  _buildDescriptionCard(),
                ],
                if (_fields.isNotEmpty) ...[
                  const SizedBox(height: Space.md),
                  _buildDynamicFieldsCard(),
                ],
                const SizedBox(height: Space.md),
                _buildReviewsCard(),
                const SizedBox(height: Space.lg),
                widget.forOccasionCart
                    ? _buildOccasionCartSection()
                    : _buildBookingSection(),
                const SizedBox(height: Space.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── المعرض ───

  Widget _buildImagesGallery() {
    if (_images.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          gradient: AppColors.primarySoftGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_center_outlined,
              size: 56,
              color: AppColors.primary,
            ),
            SizedBox(height: 8),
            Text(
              'لا توجد صور',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length,
        itemBuilder: (context, index) {
          final img = _images[index];
          final url = img['signed_url']?.toString() ??
              img['image_url']?.toString() ??
              '';
          final viewport = MediaQuery.sizeOf(context).width - 32;
          return Container(
            width: viewport < 300 ? viewport : 300,
            margin: EdgeInsets.only(left: index == 0 ? 0 : 10),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppPalette.gold.withValues(alpha: 0.35),
              ),
              boxShadow: AppShadows.soft,
            ),
            child: url.isEmpty
                ? const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 48,
                      color: AppColors.mutedText,
                    ),
                  )
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  // ─── اسم الخدمة ───

  Widget _buildServiceTitle() {
    final name = _service?['name']?.toString() ?? '';
    final isBookable = _service?['is_bookable'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
        ),
        if (!isBookable && !widget.forOccasionCart) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.warning,
                ),
                SizedBox(width: 5),
                Text(
                  'غير متاح للحجز حالياً',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.warningDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─── بطاقة المعلومات الأساسية ───

  Widget _buildMainInfoCard() {
    final category = _category;
    final governorate = _service?['governorate']?.toString() ?? '';
    final location = _service?['location']?.toString() ?? '';
    final rating = _toDouble(_service?['rating']);
    final reviewsCount = _toInt(_service?['reviews_count']);
    final unitPriceLabel = servicePriceLabel(
      _service,
      formatPrice: _formatPrice,
    );

    return BrandCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          if (category != null)
            _infoRow(
              serviceCategoryIcon(category['icon']?.toString()),
              'التصنيف',
              category['name']?.toString() ?? '',
            ),
          if (governorate.isNotEmpty)
            _infoRow(
              Icons.location_on_outlined,
              'المحافظة',
              governorate,
            ),
          if (location.isNotEmpty)
            _infoRow(
              Icons.place_outlined,
              'العنوان',
              location,
            ),
          _infoRow(
            Icons.star_rounded,
            'التقييم',
            reviewsCount > 0
                ? '${rating.toStringAsFixed(1)} ($reviewsCount تقييم)'
                : 'لا توجد تقييمات',
          ),
          if (_isQuoteRequest)
            _infoRow(
              Icons.request_quote_outlined,
              'التسعير',
              'يتطلب طلب عرض سعر',
              highlight: true,
            )
          else if (unitPriceLabel.isNotEmpty)
            _infoRow(
              Icons.payments_outlined,
              _pricingModel == 'per_unit'
                  ? 'سعر الوحدة'
                  : _pricingModel == 'per_duration'
                      ? 'سعر المدة'
                      : 'السعر',
              unitPriceLabel,
              highlight: true,
            ),
          if (!_isQuoteRequest &&
              _quote != null &&
              _quote!['total'] != null &&
              (_pricingModel == 'per_unit' ||
                  _pricingModel == 'per_duration' ||
                  _selectedAddonIds.isNotEmpty))
            _infoRow(
              Icons.calculate_outlined,
              'الإجمالي التقديري',
              '${_formatPrice(_quote!['total'])} \$',
              highlight: true,
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: highlight
                  ? AppColors.goldSoft
                  : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 17,
              color: highlight
                  ? AppColors.goldDark
                  : AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                color: highlight
                    ? AppColors.goldDark
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── بطاقة المزوّد ───

  Widget _buildProviderCard() {
    final name = _provider?['name']?.toString() ?? '';
    final governorate = _provider?['governorate']?.toString() ?? '';
    final rating = _toDouble(_provider?['rating']);
    final isVerified = _provider?['is_verified'] == true;

    return BrandCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: AppColors.goldLight,
              size: 26,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isVerified)
                      const Padding(
                        padding: EdgeInsets.only(right: 5),
                        child: Icon(
                          Icons.verified_rounded,
                          size: 18,
                          color: AppColors.success,
                        ),
                      ),
                  ],
                ),
                if (governorate.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    governorate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.goldDark,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.goldDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── الوصف ───

  Widget _buildDescriptionCard() {
    return BrandCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  size: 19,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'وصف الخدمة',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _service?['description']?.toString() ?? '',
            style: const TextStyle(
              fontSize: 14,
              height: 1.7,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── الحقول الديناميكية ───

  Widget _buildDynamicFieldsCard() {
    final visible = _fields.where((f) {
      return _getFieldValue(f).trim().isNotEmpty;
    }).toList();

    if (visible.isEmpty) return const SizedBox.shrink();

    return BrandCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.checklist_outlined,
                  size: 19,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'معلومات إضافية',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...visible.map((field) {
            final name = field['field_name']?.toString() ?? '';
            final value = _getFieldValue(field);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 6,
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _confirmOccasionCart() {
    final model = _pricingModel;
    var qty = 1.0;
    if (model == 'per_unit' || model == 'per_duration') {
      final raw = (model == 'per_unit' ? _quantityController : _durationController)
          .text
          .trim()
          .replaceAll(',', '.');
      final parsed = double.tryParse(raw);
      if (parsed == null || parsed <= 0) {
        _showMessage('أدخل كمية صحيحة', isError: true);
        return;
      }
      qty = parsed;
    }
    Navigator.pop(context, qty);
  }

  Widget _buildOccasionCartSection() {
    final model = _pricingModel;
    final needsQty = model == 'per_unit' || model == 'per_duration';
    final inCart = widget.occasionAlreadyInCart;
    final label = !inCart
        ? 'أضف إلى اختياراتي'
        : (needsQty ? 'تحديث اختياراتي' : 'في اختياراتي');

    return BrandCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'أضف إلى اختياراتي',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            needsQty
                ? 'حدد الكمية ثم أضف الخدمة إلى اختياراتي.'
                : 'تُضاف هذه الخدمة إلى اختياراتي.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (model == 'per_unit') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText:
                    'الكمية (${(_service?['unit_label']?.toString().trim().isNotEmpty == true) ? _service!['unit_label'] : 'وحدة'})',
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) {
                final n = double.tryParse(v.replaceAll(',', '.'));
                if (n != null && n > 0) setState(() => _quantity = n);
              },
            ),
          ],
          if (model == 'per_duration') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _durationController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: 'المدة (${_durationUnitLabel()})',
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) {
                final n = double.tryParse(v.replaceAll(',', '.'));
                if (n != null && n > 0) setState(() => _durationValue = n);
              },
            ),
          ],
          if (_isQuoteRequest) ...[
            const SizedBox(height: 12),
            const Text(
              'السعر يُحدد لاحقاً بعد مراجعة الطلب.',
              style: TextStyle(fontSize: 12, color: AppColors.mutedText),
            ),
          ],
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _confirmOccasionCart,
            icon: const Icon(Icons.shopping_bag_outlined, size: 18),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: inCart && !needsQty
                  ? AppColors.success
                  : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _durationUnitLabel() {
    final unit = _service?['duration_unit']?.toString() ?? 'day';
    if (unit == 'hour') return 'ساعة';
    if (unit == 'night') return 'ليلة';
    return 'يوم';
  }

  // ─── قسم الحجز ───

  Widget _buildBookingSection() {
    final isBookable = _service?['is_bookable'] == true;
    final requiresOrganizer = _category?['requires_organizer'] == true;

    if (!widget.forOccasionCart && requiresOrganizer) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceTint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: const Row(
          children: [
            Icon(Icons.event_available_outlined, color: AppColors.primary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'هذا التصنيف يُحجز عبر تنظيم مناسبة مع منظّم فقط، وليس بالحجز المباشر.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!isBookable) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceTint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: AppColors.mutedText,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'هذه الخدمة غير متاحة للحجز حالياً.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return BrandCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InfoBanner(
            message: UiCopy.serviceDetailBookHint,
            tone: InfoBannerTone.tip,
            padding: EdgeInsets.only(bottom: 14),
          ),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.textOnGold,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'احجز الخدمة',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'خطوتك الأولى نحو تجربة متكاملة',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // التاريخ
          _pickerTile(
            icon: Icons.calendar_today_outlined,
            label: _selectedDate == null
                ? 'اختر تاريخ الحجز'
                : _formatDate(_selectedDate!),
            isEmpty: _selectedDate == null,
            onTap: _isBooking ? null : _selectDate,
          ),
          const SizedBox(height: 10),

          // الوقت
          _pickerTile(
            icon: Icons.access_time_rounded,
            label: _selectedTime == null
                ? 'اختر وقت التنفيذ (اختياري)'
                : _selectedTime!.format(context),
            isEmpty: _selectedTime == null,
            onTap: _isBooking ? null : _selectTime,
          ),
          const SizedBox(height: 10),

          // مكان التنفيذ
          TextField(
            controller: _locationController,
            textInputAction: TextInputAction.next,
            enabled: !_isBooking,
            decoration: const InputDecoration(
              labelText: 'مكان تنفيذ الخدمة *',
              hintText: 'مثال: صالة النور - دمشق',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 10),

          // عدد الضيوف — يُخفى عند التسعير بالكمية لتجنب ازدواجية الحقول
          if (_pricingModel != 'per_unit') ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'عدد الضيوف',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isBooking || _guestsCount <= 0
                      ? null
                      : _decrementGuests,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppColors.primary,
                ),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _guestsController,
                    focusNode: _guestsFocusNode,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    enabled: !_isBooking,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceGreen,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: _onGuestsTextChanged,
                  ),
                ),
                IconButton(
                  onPressed: _isBooking || _guestsCount >= _maxGuests
                      ? null
                      : _incrementGuests,
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          _buildPricingSelectors(),
          const SizedBox(height: 12),
          _buildQuoteSummary(),
          const SizedBox(height: 8),

          // زر الحجز
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isBooking ? null : _submitBooking,
              icon: _isBooking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _isQuoteRequest
                          ? Icons.request_quote_outlined
                          : Icons.send_rounded,
                      size: 18,
                    ),
              label: Text(
                _isBooking
                    ? 'جاري الإرسال...'
                    : (_isQuoteRequest
                        ? 'طلب عرض سعر'
                        : 'أرسل طلبك'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AppPalette.gold.withValues(alpha: 0.45),
                  ),
                ),
                elevation: 0,
              ),
            ),
          ),
          if (!widget.forOccasionCart &&
              _category?['requires_organizer'] != true) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isBooking ? null : _addToEventCart,
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                label: const Text('أضف إلى فعاليتي'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPricingSelectors() {
    final children = <Widget>[];

    if (_pricingModel == 'fixed_package' && _packages.isNotEmpty) {
      children.add(const Text(
        'اختر الباقة',
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ));
      children.add(const SizedBox(height: 8));
      for (final pkg in _packages) {
        final id = pkg['id']?.toString() ?? '';
        final selected = id == _selectedPackageId;
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: selected ? AppColors.primarySoft : AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isBooking
                    ? null
                    : () {
                        setState(() => _selectedPackageId = id);
                        _refreshQuote();
                      },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pkg['name']?.toString() ?? '',
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            if ((pkg['description']?.toString() ?? '')
                                .isNotEmpty)
                              Text(
                                pkg['description'].toString(),
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${_formatPrice(pkg['price'])} \$',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w800,
                          color: AppColors.goldDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    if (_pricingModel == 'per_unit') {
      final unit = (_service?['unit_label']?.toString().trim().isNotEmpty ==
              true)
          ? _service!['unit_label'].toString().trim()
          : 'وحدة';
      final unitPrice = _service?['unit_price'] ?? _service?['base_price'];
      children.add(
        Text(
          unitPrice != null
              ? 'الكمية — ${_formatPrice(unitPrice)} \$ لكل $unit'
              : 'الكمية ($unit)',
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      );
      children.add(const SizedBox(height: 8));
      children.add(TextField(
        controller: _quantityController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        enabled: !_isBooking,
        decoration: InputDecoration(
          labelText: 'العدد',
          hintText: 'مثال: 1',
          prefixIcon: const Icon(Icons.numbers_rounded),
          suffixText: unit,
          helperText: unitPrice != null
              ? 'الإجمالي: ${_formatPrice((num.tryParse(unitPrice.toString()) ?? 0) * _quantity)} \$'
              : null,
        ),
        onChanged: (v) {
          final n = double.tryParse(v.replaceAll(',', '.'));
          if (n != null && n > 0) {
            setState(() => _quantity = n);
            _refreshQuote();
          }
        },
      ));
      children.add(const SizedBox(height: 10));
    }

    if (_pricingModel == 'per_duration') {
      final unit = _service?['duration_unit']?.toString() ?? 'يوم';
      final unitAr = unit == 'hour'
          ? 'ساعة'
          : unit == 'night'
              ? 'ليلة'
              : 'يوم';
      children.add(TextField(
        controller: _durationController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        enabled: !_isBooking,
        decoration: InputDecoration(
          labelText: 'المدة ($unitAr)',
          prefixIcon: const Icon(Icons.timelapse_rounded),
        ),
        onChanged: (v) {
          final n = double.tryParse(v.replaceAll(',', '.'));
          if (n != null && n > 0) {
            setState(() => _durationValue = n);
            _refreshQuote();
          }
        },
      ));
      children.add(const SizedBox(height: 10));
    }

    if (_addons.isNotEmpty) {
      children.add(const Text(
        'إضافات اختيارية',
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ));
      children.add(const SizedBox(height: 6));
      for (final addon in _addons) {
        final id = addon['id']?.toString() ?? '';
        final required = addon['is_required'] == true;
        final selected = _selectedAddonIds.contains(id);
        children.add(
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: selected,
            onChanged: (_isBooking || required)
                ? null
                : (v) {
                    setState(() {
                      if (v == true) {
                        _selectedAddonIds.add(id);
                      } else {
                        _selectedAddonIds.remove(id);
                      }
                    });
                    _refreshQuote();
                  },
            title: Text(
              '${addon['name'] ?? ''}${required ? ' (إلزامي)' : ''}',
              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
            ),
            subtitle: Text(
              '${_formatPrice(addon['price'])} \$'
              '${addon['pricing_mode'] == 'per_unit' ? ' / وحدة' : ''}',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                color: AppColors.goldDark,
              ),
            ),
            activeColor: AppColors.primary,
          ),
        );
      }
    }

    if (_isQuoteRequest) {
      children.add(const InfoBanner(
        message:
            'هذه الخدمة تتطلب عرض سعر مخصص. سيُراجع طلبك من الإدارة قبل تحديد السعر.',
        tone: InfoBannerTone.info,
        padding: EdgeInsets.zero,
      ));
    }

    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _buildQuoteSummary() {
    if (_isQuoteRequest) return const SizedBox.shrink();
    if (_isQuoting) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_quote == null) return const SizedBox.shrink();

    final subtotal = _quote!['subtotal'];
    final discount = _quote!['discount_amount'];
    final total = _quote!['total'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceGreen,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ملخص السعر (محسوب من الخادم)',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'قبل الحسم: ${_formatPrice(subtotal)} \$',
            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
          ),
          if (_toDouble(discount) > 0)
            Text(
              'الحسم: -${_formatPrice(discount)} \$',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                color: AppColors.success,
              ),
            ),
          Text(
            'الإجمالي: ${_formatPrice(total)} \$',
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.goldDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required String label,
    required bool isEmpty,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isEmpty
                      ? AppColors.mutedText
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: AppColors.mutedText,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // قسم التقييمات
  // ============================================================

  Widget _buildReviewsCard() {
    final rating = _toDouble(_service?['rating']);
    final reviewsCount = _toInt(_service?['reviews_count']);

    return BrandCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.star_rate_outlined,
                  size: 19,
                  color: AppColors.goldDark,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'تقييمات العملاء',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ملخص التقييم
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.goldDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStars(rating, size: 20),
                      const SizedBox(height: 4),
                      Text(
                        reviewsCount > 0
                            ? 'بناءً على ${reviewsCount == 1 ? 'تقييم واحد' : reviewsCount == 2 ? 'تقييمين' : reviewsCount <= 10 ? '$reviewsCount تقييمات' : '$reviewsCount تقييماً'}'
                            : 'لا توجد تقييمات بعد',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // قائمة التقييمات
          if (_reviews.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.rate_review_outlined,
                    size: 36,
                    color: AppColors.mutedText,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    // التقييم بالنجوم موجود لكن بلا تعليقات مكتوبة
                    reviewsCount > 0
                        ? 'لا توجد تعليقات مكتوبة بعد'
                        : 'كن أول من يقيّم هذه الخدمة',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._reviews.map((r) => _buildReviewItem(r)),
        ],
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final rating = _toDouble(review['rating']);
    final comment = review['comment']?.toString().trim() ?? '';
    final createdAt = review['created_at']?.toString() ?? '';

    String dateText = '';
    if (createdAt.isNotEmpty) {
      final parsed = DateTime.tryParse(createdAt);
      if (parsed != null) {
        dateText =
            '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceGreen,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primarySoft,
                child: const Icon(
                  Icons.person_outline,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'مستخدم',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (dateText.isNotEmpty)
                Text(
                  dateText,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedText,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildStars(rating, size: 16),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStars(double rating, {double size = 20}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        return Icon(
          star <= rating
              ? Icons.star_rounded
              : (star - 0.5 <= rating
                  ? Icons.star_half_rounded
                  : Icons.star_border_rounded),
          size: size,
          color: AppColors.goldDark,
        );
      }),
    );
  }
}