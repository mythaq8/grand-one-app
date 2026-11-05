// lib/screens/occasion_organize_screen.dart
// ============================================================
// OccasionOrganizeScreen — تنظيم مناسبة
// الخطوات: البيانات ← التصنيفات ← خدمات التصنيف
// «حفلتي» تظهر من الشاشة 2 فصاعداً (لوحة جانبية)، وليست في بيانات المناسبة
// لا يغيّر تبويبي الخدمات/المزوّدين — شاشة مستقلة فقط
// ============================================================

import 'decor/decor_studio_screen.dart';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_colors.dart';
import '../services/api_exceptions.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';
import '../utils/service_price_label.dart';
import '../widgets/brand_decorations.dart';
import '../widgets/subcategory_type_grid.dart';
import 'my_occasion_requests_screen.dart';
import 'service_detail_screen.dart';

class OccasionOrganizeScreen extends StatefulWidget {
  const OccasionOrganizeScreen({super.key});

  @override
  State<OccasionOrganizeScreen> createState() =>
      _OccasionOrganizeScreenState();
}

class _CartLine {
  _CartLine({
    required this.service,
    required this.quantity,
  });

  final Map<String, dynamic> service;
  double quantity;

  String get id => service['id']?.toString() ?? '';

  String get pricingModel =>
      service['pricing_model']?.toString() ?? 'fixed_package';

  bool get needsManualQuote => pricingModel == 'quote_request';

  bool get needsQuantity =>
      pricingModel == 'per_unit' || pricingModel == 'per_duration';

  double? get unitPrice {
    if (needsManualQuote) return null;
    final raw = pricingModel == 'fixed_package'
        ? service['base_price']
        : (service['unit_price'] ??
            service['duration_price'] ??
            service['base_price']);
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '');
  }

  double? get lineTotal {
    final u = unitPrice;
    if (u == null) return null;
    final q = needsQuantity ? quantity : 1;
    return (u * q * 100).roundToDouble() / 100;
  }
}

class _OccasionOrganizeScreenState extends State<OccasionOrganizeScreen> {
  int _step = 0;
  bool _cartOpen = false;
  bool _loadingCats = true;
  bool _loadingServices = false;
  bool _submitting = false;

  // خطوة 1
  String? _occasionType;
  DateTime? _occasionDate;
  String? _governorate;
  final _addressCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _organizerId;
  String? _organizerName;
  List<Map<String, dynamic>> _organizers = [];
  bool _loadingOrganizers = true;

  // التصنيفات والخدمات وحفلتي
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _subcategories = [];
  String? _selectedSubcategoryId;
  bool _typesReady = false;
  bool _typeChosen = false;
  Map<String, String> _serviceSubcategoryIds = {};
  final _serviceSearchCtrl = TextEditingController();
  String _serviceQuery = '';
  Timer? _searchTimer;
  double? _filterMinRating;
  double? _filterMinPrice;
  double? _filterMaxPrice;
  String? _filterSort;
  final Map<String, _CartLine> _cart = {};
  final Map<String, TextEditingController> _qtyCtrls = {};

  static const _governorates = [
    'دمشق', 'ريف دمشق', 'حلب', 'حمص', 'حماة', 'اللاذقية', 'طرطوس',
    'إدلب', 'دير الزور', 'الرقة', 'الحسكة', 'درعا', 'السويداء', 'القنيطرة',
  ];

  static const _types = [
    {'value': 'wedding', 'label': 'عرس'},
    {'value': 'engagement', 'label': 'خطبة'},
    {'value': 'birthday', 'label': 'عيد ميلاد'},
    {'value': 'graduation', 'label': 'تخرج'},
    {'value': 'other', 'label': 'أخرى'},
  ];

  static const _stepTitles = [
    'بيانات المناسبة',
    'التصنيفات',
    'الخدمات',
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadOrganizers();
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _whatsappCtrl.dispose();
    _notesCtrl.dispose();
    _serviceSearchCtrl.dispose();
    _searchTimer?.cancel();
    for (final ctrl in _qtyCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadOrganizers() async {
    setState(() => _loadingOrganizers = true);
    try {
      final res = await ApiService.getOrganizers(limit: 50);
      final data = res['data'];
      if (data is List) {
        _organizers = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
        _organizers = [];
      }
    } catch (_) {
      _organizers = [];
    }
    if (mounted) setState(() => _loadingOrganizers = false);
  }

  double _minQty(_CartLine line) {
    final raw = line.service['min_qty'];
    final n = raw is num ? raw.toDouble() : double.tryParse('${raw ?? ''}');
    if (n == null || n < 1) return 1;
    return n;
  }

  double? _maxQty(_CartLine line) {
    final raw = line.service['max_qty'];
    if (raw == null) return null;
    final n = raw is num ? raw.toDouble() : double.tryParse('$raw');
    if (n == null || n < 1) return null;
    return n;
  }

  String _qtyText(double q) {
    if (q == q.roundToDouble()) return q.toInt().toString();
    return q.toStringAsFixed(1);
  }

  TextEditingController _qtyCtrl(_CartLine line) {
    return _qtyCtrls.putIfAbsent(
      line.id,
      () => TextEditingController(text: _qtyText(line.quantity)),
    );
  }

  void _writeQty(_CartLine line, double next) {
    final text = _qtyText(next);
    setState(() => line.quantity = next);
    final ctrl = _qtyCtrls[line.id];
    if (ctrl != null && ctrl.text != text) {
      ctrl.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  void _stepQty(_CartLine line, double delta) {
    final minQ = _minQty(line);
    final maxQ = _maxQty(line);
    var next = line.quantity + delta;
    if (next < minQ) next = minQ;
    if (maxQ != null && next > maxQ) next = maxQ;
    _writeQty(line, next);
  }

  void _commitTypedQty(_CartLine line) {
    final raw = _qtyCtrls[line.id]?.text.trim() ?? '';
    final parsed = double.tryParse(raw);
    final minQ = _minQty(line);
    final maxQ = _maxQty(line);
    if (parsed == null || parsed <= 0) {
      _writeQty(line, line.quantity);
      return;
    }
    var next = parsed;
    var clamped = false;
    if (next < minQ) {
      next = minQ;
      clamped = true;
    }
    if (maxQ != null && next > maxQ) {
      next = maxQ;
      clamped = true;
    }
    if (clamped && mounted) {
      ErrorHandler.showWarning(
        context,
        maxQ == null
            ? 'أقل كمية هي ${_qtyText(minQ)}'
            : 'الكمية بين ${_qtyText(minQ)} و ${_qtyText(maxQ)}',
      );
    }
    _writeQty(line, next);
  }

  String? _serviceCoverUrl(Map<String, dynamic> service) {
    String? fromMap(Object? raw) {
      if (raw is! Map) return null;
      final signed = raw['signed_url']?.toString().trim() ?? '';
      if (signed.startsWith('http')) return signed;
      final url = raw['image_url']?.toString().trim() ?? '';
      if (url.startsWith('http')) return url;
      return null;
    }

    final cover = fromMap(service['cover_image']);
    if (cover != null) return cover;
    final images = service['images'];
    if (images is List) {
      for (final img in images) {
        final url = fromMap(img);
        if (url != null) return url;
      }
    }
    return null;
  }

  Widget _serviceCover(
    Map<String, dynamic> service, {
    double height = 150,
    double? width,
  }) {
    final url = _serviceCoverUrl(service);
    if (url == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: width == null ? 8 : 0, left: width == null ? 0 : 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          height: height,
          width: width ?? double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  String _formatPrice(dynamic p) {
    final n = p is num ? p.toDouble() : double.tryParse(p?.toString() ?? '') ?? 0;
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(0);
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCats = true);
    try {
      final list = await ApiService.getServiceCategories();
      if (!mounted) return;
      setState(() {
        _categories = list;
        _loadingCats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCats = false);
      ErrorHandler.showError(context, e, customMessage: 'تعذر تحميل التصنيفات');
    }
  }

  int get _activeServiceFilters {
    var n = 0;
    if (_filterMinRating != null) n++;
    if (_filterMinPrice != null) n++;
    if (_filterMaxPrice != null) n++;
    if (_filterSort != null) n++;
    return n;
  }

  Future<void> _loadServicesForCategory(String categoryId) async {
    _searchTimer?.cancel();
    _serviceSearchCtrl.clear();
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedSubcategoryId = null;
      _subcategories = [];
      _typesReady = false;
      _typeChosen = false;
      _serviceSubcategoryIds = {};
      _serviceQuery = '';
      _filterMinRating = null;
      _filterMinPrice = null;
      _filterMaxPrice = null;
      _filterSort = null;
      _loadingServices = true;
      _services = [];
      _step = 2;
    });
    await Future.wait([
      _fetchServices(),
      _loadSubcategories(categoryId),
      _loadSubcategoryMap(categoryId),
    ]);
    if (!mounted || _selectedCategoryId != categoryId) return;
    setState(() => _typesReady = true);
  }

  Future<void> _loadSubcategoryMap(String categoryId) async {
    final map = await ApiService.subcategoryIdByService(categoryId);
    if (!mounted || _selectedCategoryId != categoryId) return;
    setState(() => _serviceSubcategoryIds = map);
  }

  String? _coverForSubcategory(String subcategoryId) {
    for (final service in _services) {
      if (_serviceSubcategoryIds[service['id']?.toString()] == subcategoryId) {
        return _serviceCoverUrl(service);
      }
    }
    return null;
  }

  String get _selectedTypeName {
    if (_selectedSubcategoryId == null) return 'كل الأنواع';
    for (final sub in _subcategories) {
      if (sub['id']?.toString() == _selectedSubcategoryId) {
        return sub['name']?.toString() ?? 'النوع';
      }
    }
    return 'النوع';
  }

  void _pickType(String? id) {
    setState(() {
      _selectedSubcategoryId = id;
      _typeChosen = true;
    });
    _fetchServices();
  }

  void _reopenTypePicker() {
    setState(() {
      _typeChosen = false;
      _selectedSubcategoryId = null;
    });
    _fetchServices();
  }

  Future<void> _loadSubcategories(String categoryId) async {
    try {
      final list = await ApiService.getServiceSubcategories(categoryId);
      if (!mounted || _selectedCategoryId != categoryId) return;
      setState(() => _subcategories = list);
    } catch (_) {
      if (!mounted || _selectedCategoryId != categoryId) return;
      setState(() => _subcategories = []);
    }
  }

  Future<void> _fetchServices() async {
    final categoryId = _selectedCategoryId;
    if (categoryId == null || categoryId.isEmpty) return;
    setState(() => _loadingServices = true);
    try {
      final resp = await ApiService.getServices(
        categoryId: categoryId,
        subcategoryId: _selectedSubcategoryId,
        q: _serviceQuery.trim().isEmpty ? null : _serviceQuery.trim(),
        minRating: _filterMinRating,
        minPrice: _filterMinPrice,
        maxPrice: _filterMaxPrice,
        sort: _filterSort,
        forOccasion: true,
        limit: 40,
        offset: 0,
      );
      final raw = resp['data'];
      final list = raw is List
          ? raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];
      final visible = await ApiService.keepSubcategory(
        list,
        categoryId: categoryId,
        subcategoryId: _selectedSubcategoryId,
      );
      if (!mounted || _selectedCategoryId != categoryId) return;
      setState(() {
        _services = visible;
        _loadingServices = false;
      });
    } catch (e) {
      if (!mounted || _selectedCategoryId != categoryId) return;
      setState(() => _loadingServices = false);
      ErrorHandler.showError(context, e, customMessage: 'تعذر تحميل الخدمات');
    }
  }

  void _onServiceSearchChanged(String value) {
    setState(() => _serviceQuery = value);
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _fetchServices();
    });
  }

  bool _validateStep0() {
    if (_occasionType == null) {
      ErrorHandler.showWarning(context, 'اختر نوع المناسبة');
      return false;
    }
    if (_organizerId == null || _organizerId!.isEmpty) {
      ErrorHandler.showWarning(context, 'اختر المنظّم');
      return false;
    }
    if (_governorate == null || _governorate!.isEmpty) {
      ErrorHandler.showWarning(context, 'اختر المحافظة');
      return false;
    }
    final wa = _whatsappCtrl.text.trim();
    if (!RegExp(r'^09[0-9]{8}$').hasMatch(wa)) {
      ErrorHandler.showWarning(
        context,
        'رقم الواتساب يجب أن يبدأ بـ 09 ويتكون من 10 أرقام',
      );
      return false;
    }
    return true;
  }

  void _next() {
    if (_cartOpen) return;
    if (_step == 0 && !_validateStep0()) return;
    if (_step < 2) setState(() => _step++);
  }

  /// حفلتي تظهر من خطوة التصنيفات (الشاشة 2) فما فوق.
  bool get _partyVisible => _step >= 1;

  void _openCart() {
    if (!_partyVisible) return;
    FocusScope.of(context).unfocus();
    setState(() => _cartOpen = true);
  }

  void _closeCart() {
    if (!_cartOpen) return;
    FocusScope.of(context).unfocus();
    setState(() => _cartOpen = false);
  }

  void _back() {
    if (_cartOpen) {
      _closeCart();
      return;
    }
    if (_step == 0) {
      Navigator.pop(context);
      return;
    }
    if (_step == 2 && _typeChosen && _subcategories.isNotEmpty) {
      _reopenTypePicker();
      return;
    }
    // الرجوع بين الخطوات لا يمسّ حفلتي ولا يشترط اختيار تصنيف.
    setState(() {
      _step--;
      if (_step < 1) _cartOpen = false;
    });
  }

  void _addToCart(Map<String, dynamic> service) {
    final id = service['id']?.toString() ?? '';
    if (id.isEmpty) return;
    setState(() {
      final existing = _cart[id];
      if (existing != null) {
        if (existing.needsQuantity) {
          existing.quantity += 1;
        }
      } else {
        final model = service['pricing_model']?.toString() ?? 'fixed_package';
        final minQ = (service['min_qty'] as num?)?.toDouble() ?? 1;
        _cart[id] = _CartLine(
          service: service,
          quantity: model == 'fixed_package' || model == 'quote_request'
              ? 1
              : minQ,
        );
      }
    });
    ErrorHandler.showSuccess(context, 'أُضيفت إلى اختياراتك');
  }

  Future<void> _openServiceDetails(Map<String, dynamic> service) async {
    final id = service['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final existing = _cart[id];
    final result = await Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceDetailScreen(
          serviceId: id,
          initialService: service,
          forOccasionCart: true,
          occasionAlreadyInCart: existing != null,
          occasionQuantity: existing != null && existing.needsQuantity
              ? existing.quantity
              : null,
        ),
      ),
    );
    if (!mounted || result == null) return;
    _applyDetailQuantity(service, result);
  }

  void _applyDetailQuantity(Map<String, dynamic> service, double quantity) {
    final id = service['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final existing = _cart[id];
    final wasInCart = existing != null;
    var clamped = false;
    if (existing != null) {
      if (existing.needsQuantity) {
        clamped = _commitQtyValue(existing, quantity);
      }
    } else {
      final line = _CartLine(service: service, quantity: 1);
      if (line.needsQuantity) {
        clamped = _commitQtyValue(line, quantity);
      } else {
        setState(() => _cart[id] = line);
      }
    }
    if (!mounted || clamped) return;
    ErrorHandler.showSuccess(
      context,
      wasInCart ? 'تم تحديث اختياراتك' : 'أُضيفت إلى اختياراتك',
    );
  }

  bool _commitQtyValue(_CartLine line, double raw) {
    final minQ = _minQty(line);
    final maxQ = _maxQty(line);
    var next = raw;
    var clamped = false;
    if (next < minQ) {
      next = minQ;
      clamped = true;
    }
    if (maxQ != null && next > maxQ) {
      next = maxQ;
      clamped = true;
    }
    if (clamped && mounted) {
      ErrorHandler.showWarning(
        context,
        maxQ == null
            ? 'أقل كمية هي ${_qtyText(minQ)}'
            : 'الكمية بين ${_qtyText(minQ)} و ${_qtyText(maxQ)}',
      );
    }
    if (!_cart.containsKey(line.id)) {
      setState(() => _cart[line.id] = line);
    }
    _writeQty(line, next);
    return clamped;
  }

  double get _estimatedPriced {
    var sum = 0.0;
    for (final line in _cart.values) {
      final t = line.lineTotal;
      if (t != null) sum += t;
    }
    return (sum * 100).roundToDouble() / 100;
  }

  int get _manualCount =>
      _cart.values.where((e) => e.needsManualQuote).length;

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_validateStep0()) return;
    if (_cart.isEmpty) {
      ErrorHandler.showWarning(context, 'لا توجد اختيارات بعد');
      return;
    }

    setState(() => _submitting = true);
    final clientKey =
        'occ_${DateTime.now().millisecondsSinceEpoch}_${_cart.length}';

    try {
      final items = _cart.values
          .map(
            (l) => {
              'service_id': l.id,
              'quantity': l.needsQuantity ? l.quantity : 1,
            },
          )
          .toList();

      final result = await ApiService.createOccasionRequest(
        occasionType: _occasionType!,
        governorate: _governorate!,
        whatsapp: _whatsappCtrl.text.trim(),
        organizerId: _organizerId!,
        address: _addressCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        occasionDate: _occasionDate == null
            ? null
            : _occasionDate!.toIso8601String().substring(0, 10),
        items: items,
        clientRequestKey: clientKey,
      );

      if (!mounted) return;

      if (result['success'] != true) {
        throw Exception(result['message'] ?? result['error'] ?? 'فشل الإرسال');
      }

      ErrorHandler.showSuccess(
        context,
        result['message']?.toString() ??
            'تم إرسال طلبك. الأسعار تقديرية حتى عرض الإدارة.',
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MyOccasionRequestsScreen(),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e, customMessage: e.userMessage);
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e, customMessage: 'تعذر إرسال الطلب');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_cartOpen && _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _back();
      },
      child: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: BrandScaffold(
          appBar: BrandAppBar(
            title: 'ابدأ التخطيط',
            actions: [
              IconButton(
                tooltip: 'طلباتي',
                icon: const Icon(Icons.receipt_long_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyOccasionRequestsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              _buildStepHeader(),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        left: _partyVisible ? 64 : 0,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: KeyedSubtree(
                          key: ValueKey(_step),
                          child: _buildStepBody(),
                        ),
                      ),
                    ),
                    if (_partyVisible) ...[
                      ExcludeSemantics(
                        excluding: _cartOpen,
                        child: _buildCartSideButton(),
                      ),
                      _buildCartPanel(),
                    ],
                  ],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartSideButton() {
    final count = _cart.length;
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        label: 'فتح الاختيارات، $count خدمة',
        child: Material(
          color: AppColors.primary,
          elevation: 6,
          shadowColor: AppColors.primaryDark.withValues(alpha: 0.35),
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(16),
          ),
          child: InkWell(
            onTap: _openCart,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 14, 10, 14),
              child: SizedBox(
                width: 44,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.celebration_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      constraints: const BoxConstraints(minWidth: 22),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'اختياراتي',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartPanel() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !_cartOpen,
        child: ExcludeSemantics(
        excluding: !_cartOpen,
        child: AnimatedSlide(
          offset: _cartOpen ? Offset.zero : const Offset(-1.05, 0),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          child: BrandBackground(
            child: SizedBox.expand(
              child: _buildCartStep(),
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildStepHeader() {
    if (_cartOpen) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'اختياراتي',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'الرجوع يعيدك إلى ${_stepTitles[_step]}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            if (_cart.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '${_cart.length} خدمة'
                '${_estimatedPriced > 0 ? ' · تقديري ${_formatPrice(_estimatedPriced)} \$' : ''}'
                '${_manualCount > 0 ? ' · $_manualCount بانتظار تسعير' : ''}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'الخطوة ${_step + 1} من ${_stepTitles.length} — ${_stepTitles[_step]}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_step + 1) / _stepTitles.length,
              minHeight: 6,
              backgroundColor: AppColors.borderLight,
              color: AppColors.primary,
            ),
          ),
          if (_partyVisible && _cart.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'اختياراتي: ${_cart.length} خدمة'
              '${_estimatedPriced > 0 ? ' · تقديري ${_formatPrice(_estimatedPriced)} \$' : ''}'
              '${_manualCount > 0 ? ' · $_manualCount بانتظار تسعير' : ''}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_step) {
      case 0:
        return _buildDetailsStep();
      case 1:
        return _buildCategoriesStep();
      case 2:
        return _buildServicesStep();
      default:
        return _buildCategoriesStep();
    }
  }

  IconData _typeIcon(String? value) {
    switch (value) {
      case 'wedding':
        return Icons.favorite_border_rounded;
      case 'engagement':
        return Icons.diamond_outlined;
      case 'birthday':
        return Icons.cake_outlined;
      case 'graduation':
        return Icons.school_outlined;
      default:
        return Icons.celebration_outlined;
    }
  }

  Widget _buildDetailsStep() {
    final dateLabel = _occasionDate == null
        ? 'اختياري — يمكن تحديده لاحقاً'
        : '${_occasionDate!.year}-'
            '${_occasionDate!.month.toString().padLeft(2, '0')}-'
            '${_occasionDate!.day.toString().padLeft(2, '0')}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppColors.primary.withValues(alpha: 0.12),
                AppColors.goldSoft,
              ],
            ),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.35),
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.goldDark,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ابدأ بمناسبتك',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'أدخل التفاصيل الأساسية واختر المنظّم أولاً. اختيار الخدمات في الخطوة التالية، ثم يراجع المنظّم الطلب ويرسل عرضاً.',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        height: 1.55,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'نوع المناسبة',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _types.map((t) {
            final value = t['value']!;
            final selected = _occasionType == value;
            return Material(
              color: selected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _occasionType = value),
                child: Container(
                  width: 104,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.borderLight,
                      width: selected ? 1.6 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _typeIcon(value),
                        color: selected
                            ? Colors.white
                            : AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t['label']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text(
          'المنظّم',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        BrandCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: _loadingOrganizers
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              : _organizers.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'لا يوجد منظّمون معتمدون حالياً. تواصل مع الإدارة.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      value: _organizerId,
                      decoration: const InputDecoration(
                        labelText: 'اختر المنظّم *',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      items: _organizers.map((o) {
                        final id = o['id']?.toString() ?? '';
                        final name = o['display_name']?.toString() ?? 'منظّم';
                        final gov = o['governorate']?.toString();
                        final label = (gov == null || gov.isEmpty)
                            ? name
                            : '$name · $gov';
                        return DropdownMenuItem(value: id, child: Text(label));
                      }).toList(),
                      onChanged: (v) {
                        String? name;
                        for (final o in _organizers) {
                          if (o['id']?.toString() == v) {
                            name = o['display_name']?.toString();
                            break;
                          }
                        }
                        setState(() {
                          _organizerId = v;
                          _organizerName = name;
                        });
                      },
                    ),
        ),
        const SizedBox(height: 20),
        const Text(
          'الموعد والمكان',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        BrandCard(
          padding: EdgeInsets.zero,
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      _occasionDate ?? now.add(const Duration(days: 14)),
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 365 * 3)),
                );
                if (picked != null) setState(() => _occasionDate = picked);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.goldSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_month_outlined,
                        color: AppColors.goldDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تاريخ المناسبة',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateLabel,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              color: _occasionDate == null
                                  ? AppColors.textSecondary
                                  : AppColors.primary,
                              fontWeight: _occasionDate == null
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.mutedText,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        BrandCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _governorate,
                decoration: const InputDecoration(
                  labelText: 'المحافظة *',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _governorates
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _governorate = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'العنوان التفصيلي (اختياري)',
                  prefixIcon: Icon(Icons.place_outlined),
                  border: OutlineInputBorder(),
                ),
                maxLength: 200,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'للتواصل',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        BrandCard(
          padding: const EdgeInsets.all(14),
          child: TextField(
            controller: _whatsappCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: const InputDecoration(
              labelText: 'واتساب للتواصل *',
              hintText: '09xxxxxxxx',
              prefixIcon: Icon(Icons.chat_outlined),
              border: OutlineInputBorder(),
              helperText: 'رقم سوري يبدأ بـ 09 ويتكون من 10 أرقام',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesStep() {
    if (_loadingCats) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_categories.isEmpty) {
      return const Center(
        child: Text('لا توجد تصنيفات متاحة حالياً'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final c = _categories[i];
        final id = c['id']?.toString() ?? '';
        final name = c['name']?.toString() ?? 'تصنيف';
        final selected = id == _selectedCategoryId;
        return BrandCard(
          padding: EdgeInsets.zero,
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
            title: Text(
              name,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            trailing: Icon(
              selected ? Icons.check_circle : Icons.chevron_left,
              color: selected ? AppColors.success : AppColors.mutedText,
            ),
            onTap: id.isEmpty ? null : () => _loadServicesForCategory(id),
            ),
          ),
        );
      },
    );
  }

  bool get _isDecorCategory {
    final c = _categories.where((c) => c['id']?.toString() == _selectedCategoryId);
    return c.isNotEmpty && (c.first['name']?.toString() ?? '').contains('ديكور');
  }

  Future<void> _openDecorStudio() async {
    final categoryId = _selectedCategoryId;
    if (categoryId == null) return;
    final result = await Navigator.of(context).push<DecorStudioResult>(
      MaterialPageRoute(
        builder: (_) => DecorStudioScreen(
          categoryId: categoryId,
          chosenServices: _cart.values.map((l) => l.service).toList(),
        ),
      ),
    );
    if (result == null || !mounted) return;
    for (final svc in result.services) {
      if (!_cart.containsKey(svc['id']?.toString())) _addToCart(svc);
    }
    // وصف التصميم يُرسَل مع الطلب ليراه المنظّم (يُستبدل إن أعيد التصميم)
    final marker = '— تصميم الديكور —';
    var notes = _notesCtrl.text;
    final i = notes.indexOf(marker);
    if (i >= 0) notes = notes.substring(0, i).trimRight();
    _notesCtrl.text = [
      if (notes.isNotEmpty) notes,
      marker,
      result.description,
    ].join('\n');
    setState(() {});
    ErrorHandler.showSuccess(context, 'اعتُمد تصميم الديكور وأُرفق بطلبك');
  }

  Widget _decorBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _openDecorStudio,
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: AppColors.gold, size: 30),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('صمّم ديكورك وشاهده قبل الطلب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                      SizedBox(height: 2),
                      Text('اختر صورة قاعتك أو ارفعها، ثم ركّب الكوشة والطاولات والورد وشاهد المكان كاملاً', style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServicesStep() {
    if (!_typesReady) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_subcategories.isNotEmpty && !_typeChosen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isDecorCategory) _decorBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
            child: Text(
              'اختر النوع',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'اضغط النوع لعرض خدماته',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: SubcategoryTypeGrid(
              subcategories: _subcategories,
              coverFor: _coverForSubcategory,
              onPick: _pickType,
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        if (_isDecorCategory) _decorBanner(),
        _buildServiceToolbar(),
        if (_subcategories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'النوع: $_selectedTypeName',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _reopenTypePicker,
                  child: const Text('تغيير النوع'),
                ),
              ],
            ),
          ),
        Expanded(child: _buildServicesList()),
      ],
    );
  }

  Widget _buildServiceToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _serviceSearchCtrl,
              textInputAction: TextInputAction.search,
              onChanged: _onServiceSearchChanged,
              onSubmitted: (_) => _fetchServices(),
              decoration: InputDecoration(
                hintText: 'ابحث عن خدمة...',
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                suffixIcon: _serviceQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.mutedText),
                        onPressed: () {
                          _searchTimer?.cancel();
                          _serviceSearchCtrl.clear();
                          setState(() => _serviceQuery = '');
                          _fetchServices();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _activeServiceFilters > 0 ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _openServiceFilters,
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _activeServiceFilters > 0
                        ? AppColors.primary
                        : AppColors.borderLight,
                  ),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: _activeServiceFilters > 0 ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList() {
    if (_loadingServices) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_services.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('لا خدمات تطابق البحث أو الفلاتر'),
            TextButton(
              onPressed: () => setState(() => _step = 1),
              child: const Text('رجوع للتصنيفات'),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _services.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        if (i == 0) {
          return TextButton.icon(
            onPressed: () => setState(() => _step = 1),
            icon: const Icon(Icons.grid_view_rounded, size: 18),
            label: const Text('تصنيف آخر'),
          );
        }
        final s = _services[i - 1];
        final inCart = _cart.containsKey(s['id']?.toString());
        final price = servicePriceLabel(s, formatPrice: _formatPrice);
        return BrandCard(
          padding: const EdgeInsets.all(12),
          onTap: () => _openServiceDetails(s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _serviceCover(s),
              Text(
                s['name']?.toString() ?? 'خدمة',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              if ((s['description']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  s['description'].toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                price.isEmpty ? 'بانتظار التسعير' : price,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.goldDark,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _addToCart(s),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      inCart ? AppColors.success : AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: Text(
                  inCart ? 'في اختياراتك — إضافة أخرى' : 'أضف إلى اختياراتي',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openServiceFilters() async {
    final minCtrl = TextEditingController(
      text: _filterMinPrice == null
          ? ''
          : _filterMinPrice!.toStringAsFixed(
              _filterMinPrice! == _filterMinPrice!.roundToDouble() ? 0 : 2,
            ),
    );
    final maxCtrl = TextEditingController(
      text: _filterMaxPrice == null
          ? ''
          : _filterMaxPrice!.toStringAsFixed(
              _filterMaxPrice! == _filterMaxPrice!.roundToDouble() ? 0 : 2,
            ),
    );
    var rating = _filterMinRating;
    var sort = _filterSort;

    double? parsePrice(String raw) {
      final text = raw.trim().replaceAll(',', '.');
      if (text.isEmpty) return null;
      return double.tryParse(text);
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            Widget ratingChip(String label, double? value) {
              final selected = rating == value;
              return FilterChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) => setSheet(() => rating = value),
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontSize: 12,
                ),
              );
            }

            Widget sortChip(String label, String? value) {
              final selected = sort == value;
              return FilterChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) => setSheet(() => sort = value),
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontSize: 12,
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                16 + MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'فلاتر الخدمات',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    const Text('التقييم', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ratingChip('الكل', null),
                        ratingChip('3+', 3),
                        ratingChip('4+', 4),
                        ratingChip('4.5+', 4.5),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text('السعر', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'من',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: maxCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'إلى',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        sortChip('بدون ترتيب', null),
                        sortChip('الأقل سعراً', 'price_asc'),
                        sortChip('الأعلى سعراً', 'price_desc'),
                        sortChip('الأعلى تقييماً', 'rating_desc'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              minCtrl.clear();
                              maxCtrl.clear();
                              setSheet(() {
                                rating = null;
                                sort = null;
                              });
                            },
                            child: const Text('مسح'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final minPrice = parsePrice(minCtrl.text);
                              final maxPrice = parsePrice(maxCtrl.text);
                              if (minCtrl.text.trim().isNotEmpty && minPrice == null) {
                                ErrorHandler.showWarning(context, 'أدخل سعراً صحيحاً في حقل «من»');
                                return;
                              }
                              if (maxCtrl.text.trim().isNotEmpty && maxPrice == null) {
                                ErrorHandler.showWarning(context, 'أدخل سعراً صحيحاً في حقل «إلى»');
                                return;
                              }
                              if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
                                ErrorHandler.showWarning(context, 'الحد الأدنى أكبر من الحد الأعلى');
                                return;
                              }
                              Navigator.pop(ctx);
                              setState(() {
                                _filterMinRating = rating;
                                _filterMinPrice = minPrice;
                                _filterMaxPrice = maxPrice;
                                _filterSort = sort;
                              });
                              _fetchServices();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('تطبيق'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    minCtrl.dispose();
    maxCtrl.dispose();
  }

  Widget _buildCartStep() {
    final lines = _cart.values.toList();
    if (lines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.celebration_outlined,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              const Text(
                'لا توجد اختيارات بعد',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'أضف خدمات من أي تصنيف. تبقى في اختياراتك حتى لو رجعت ولم تختر تصنيفاً.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _closeCart,
                child: Text('العودة إلى ${_stepTitles[_step]}'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        BrandCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${_types.firstWhere((t) => t['value'] == _occasionType, orElse: () => {'label': ''})['label']} · $_governorate',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'واتساب: ${_whatsappCtrl.text.trim()}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...lines.map((l) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: BrandCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _serviceCover(l.service, height: 64, width: 64),
                      Expanded(
                        child: Text(
                          l.service['name']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () {
                          setState(() => _cart.remove(l.id));
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _qtyCtrls.remove(l.id)?.dispose();
                          });
                        },
                      ),
                    ],
                  ),
                  Text(
                    l.needsManualQuote
                        ? 'بانتظار التسعير'
                        : '${_formatPrice(l.lineTotal)} \$',
                    style: const TextStyle(color: AppColors.goldDark, fontSize: 12),
                  ),
                  if (l.needsQuantity) ...[
                    Row(
                      children: [
                        const Text('الكمية', style: TextStyle(fontSize: 12)),
                        const Spacer(),
                        IconButton(
                          onPressed: () => _stepQty(l, -1),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        SizedBox(
                          width: 84,
                          child: TextField(
                            controller: _qtyCtrl(l),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              final parsed = double.tryParse(value.trim());
                              if (parsed == null || parsed <= 0) return;
                              final minQ = _minQty(l);
                              final maxQ = _maxQty(l);
                              if (parsed < minQ) return;
                              if (maxQ != null && parsed > maxQ) return;
                              if (parsed == l.quantity) return;
                              setState(() => l.quantity = parsed);
                            },
                            onSubmitted: (_) => _commitTypedQty(l),
                            onTapOutside: (_) => _commitTypedQty(l),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _stepQty(l, 1),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    Text(
                      _maxQty(l) == null
                          ? 'يمكن كتابة الكمية. الحد الأدنى ${_qtyText(_minQty(l))}'
                          : 'يمكن كتابة الكمية. من ${_qtyText(_minQty(l))} إلى ${_qtyText(_maxQty(l)!)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        TextField(
          controller: _notesCtrl,
          maxLines: 3,
          maxLength: 2000,
          decoration: const InputDecoration(
            labelText: 'ملاحظات إضافية (اختياري)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        BrandCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_organizerName != null && _organizerName!.isNotEmpty)
                Text(
                  'المنظّم: $_organizerName',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              Text(
                'التكلفة التقديرية الأولية: ${_formatPrice(_estimatedPriced)} \$',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              if (_manualCount > 0)
                Text(
                  '+$_manualCount خدمة بانتظار تسعير يدوي (غير مضافة للمجموع)',
                  style: const TextStyle(fontSize: 11, color: AppColors.warningDark),
                ),
              const SizedBox(height: 6),
              const Text(
                'هذا ليس السعر النهائي. سيراجع المنظّم الطلب ويرسل عرضاً. بعد موافقتك يُطلب عربون 20٪ خلال 24 ساعة.',
                style: TextStyle(fontSize: 11, height: 1.45, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _closeCart,
          child: Text('العودة إلى ${_stepTitles[_step]}'),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    if (_cartOpen) {
      return _bottomBarShell(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _submitting ? null : _closeCart,
              child: const Text('رجوع'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _submitting || _cart.isEmpty ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'إرسال الطلب',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
        ],
      );
    }

    if (_step == 0) {
      return _bottomBarShell(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _submitting ? null : _back,
              child: const Text('إلغاء'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _submitting ? null : _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text(
                'متابعة',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return _bottomBarShell(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _back,
            child: Text(
              _step == 2 && _typeChosen && _subcategories.isNotEmpty
                  ? 'تغيير النوع'
                  : _step == 2
                      ? 'رجوع للتصنيفات'
                      : 'رجوع',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomBarShell({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(children: children),
    );
  }
}
