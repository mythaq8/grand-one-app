// lib/screens/services_screen.dart
// ============================================================
// ServicesScreen — سوق الخدمات (متوافق مع Deno API)
// ============================================================

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../design/tokens.dart';
import '../ui/kit/kit.dart';
import '../ui/layout/responsive.dart';
import '../ui_copy.dart';
import '../services/api_service.dart';
import '../services/api_exceptions.dart';
import '../services/notifications_service.dart';
import '../services/session_service.dart';
import '../utils/service_category_icon.dart';
import '../utils/service_price_label.dart';
import '../widgets/screen_fit.dart';
import '../widgets/brand_decorations.dart';
import '../widgets/subcategory_type_grid.dart';
import '../widgets/ux_helpers.dart';
import 'services/widgets/results_grid.dart';
import 'services/widgets/service_cards.dart';
import 'service_detail_screen.dart';
import 'provider_details_screen.dart';
import 'my_bookings_screen.dart';
import 'intro_screen.dart';
import '../services/search_date.dart';
import 'occasion_organize_screen.dart';

class ServicesScreen extends StatefulWidget {
  /// عند العرض داخل تبويب الهيكل: بلا شريط عنوان مكرّر.
  final bool embedded;

  const ServicesScreen({Key? key, this.embedded = false}) : super(key: key);

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  // ═══ الحالة ═══
  bool _showProviders = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  final List<Map<String, dynamic>> _services = [];
  final List<Map<String, dynamic>> _providers = [];
  final List<Map<String, dynamic>> _categories = [];

  int _servicesOffset = 0;
  bool _servicesHasMore = true;

  int _providersOffset = 0;
  bool _providersHasMore = true;
// ═══ الإعلانات ═══
List<Map<String, dynamic>> _advertisements = [];
int _currentAdPage = 0;
final PageController _adsPageController = PageController();
  // ═══ فلاتر ═══
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _selectedCategoryId;
  String? _trackedCategoryId;
  String? _selectedSubcategoryId;
  bool _typeChosen = false;
  final List<Map<String, dynamic>> _subcategories = [];
  Map<String, String> _serviceSubcategoryIds = {};
  String? _selectedGovernorate;
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;
  String? _selectedSort;
  bool _availableOnly = false;
  List<String> _suggestedDates = [];

  String? _providerCategoryId;
  String? _providerGovernorate;
  double? _providerMinRating;

  static const int _pageSize = 15;

  static const List<String> _syrianGovernorates = [
    'دمشق', 'ريف دمشق', 'حلب', 'حمص', 'حماة', 'اللاذقية',
    'طرطوس', 'إدلب', 'دير الزور', 'الرقة', 'الحسكة',
    'درعا', 'السويداء', 'القنيطرة',
  ];

  // ═══ Lifecycle ═══
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    SearchDate.date.addListener(_onSearchDateChanged);
    _loadAll();
  }

  void _onSearchDateChanged() {
    if (!mounted) return;
    if (_showProviders) {
      _loadProviders();
    } else {
      _loadAll();
    }
  }

  @override
  void dispose() {
    SearchDate.date.removeListener(_onSearchDateChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _adsPageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= max - 300) _loadMore();
  }

  // ═══ تحميل البيانات ═══
  Future<void> _loadAll() async {
    if (_selectedCategoryId != _trackedCategoryId) {
      _selectedSubcategoryId = null;
      _typeChosen = false;
      _trackedCategoryId = _selectedCategoryId;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

   try {
  // ═══ 3 طلبات متوازية (أسرع) ═══
  final results = await Future.wait([
    ApiService.getServiceCategories(),
    ApiService.getAdvertisements().catchError(
      (_) => <Map<String, dynamic>>[],
    ),
    ApiService.getServices(
      limit: _pageSize,
      offset: 0,
      q: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
      categoryId: _selectedCategoryId,
      subcategoryId: _typeChosen ? _selectedSubcategoryId : null,
      governorate: _selectedGovernorate,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      minRating: _minRating,
      sort: _selectedSort,
      date: SearchDate.iso,
      availableOnly: _availableOnly,
    ),
  ]);

  // التصفح المباشر يخفي تصنيفات requires_organizer (تظهر في تنظيم مناسبة)
  final categories = (results[0] as List<Map<String, dynamic>>)
      .where((c) => c['requires_organizer'] != true)
      .toList();
  final ads = results[1] as List<Map<String, dynamic>>;
  final resp = results[2] as Map<String, dynamic>;

  var data = _extractList(resp['data']);
  final pagination = _extractMap(resp['pagination']);
  _suggestedDates = (resp["suggested_dates"] is List)
      ? (resp["suggested_dates"] as List).map((e) => e.toString()).toList()
      : <String>[];
  final categoryId = _selectedCategoryId;
  List<Map<String, dynamic>> subs = [];
  Map<String, String> subMap = {};
  if (categoryId != null && categoryId.isNotEmpty) {
    subs = await ApiService.getServiceSubcategories(categoryId);
    subMap = await ApiService.subcategoryIdByService(categoryId);
    if (_typeChosen) {
      data = await ApiService.keepSubcategory(
        data,
        categoryId: categoryId,
        subcategoryId: _selectedSubcategoryId,
      );
    }
  }

  if (!mounted) return;

  setState(() {
    _subcategories
      ..clear()
      ..addAll(subs);
    _serviceSubcategoryIds = subMap;
    _categories
      ..clear()
      ..addAll(categories);
    _advertisements
      ..clear()
      ..addAll(ads);
    _services
      ..clear()
      ..addAll(data);
    _servicesOffset = data.length;
    _servicesHasMore = pagination['has_more'] == true;
    _isLoading = false;
  });
} on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.userMessage;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ غير متوقع: $e';
      });
    }
  }

  Future<void> _loadProviders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resp = await ApiService.getProviders(
        limit: _pageSize,
        offset: 0,
        q: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
        categoryId: _providerCategoryId,
        governorate: _providerGovernorate,
        minRating: _providerMinRating,
        date: SearchDate.iso,
        availableOnly: _availableOnly,
      );

      final data = _extractList(resp['data']);
      final pagination = _extractMap(resp['pagination']);

      if (!mounted) return;

      setState(() {
        _providers
          ..clear()
          ..addAll(data);
        _providersOffset = data.length;
        _providersHasMore = pagination['has_more'] == true;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.userMessage;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    if (_showProviders) {
      if (!_providersHasMore) return;
      await _loadMoreProviders();
    } else {
      if (!_servicesHasMore) return;
      await _loadMoreServices();
    }
  }

  Future<void> _loadMoreServices() async {
    setState(() => _isLoadingMore = true);

    try {
      final resp = await ApiService.getServices(
        limit: _pageSize,
        offset: _servicesOffset,
        q: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
        categoryId: _selectedCategoryId,
        subcategoryId: _typeChosen ? _selectedSubcategoryId : null,
        governorate: _selectedGovernorate,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating,
        sort: _selectedSort,
        date: SearchDate.iso,
        availableOnly: _availableOnly,
      );

      var data = _extractList(resp['data']);
      if (_typeChosen) {
        data = await ApiService.keepSubcategory(
          data,
          categoryId: _selectedCategoryId,
          subcategoryId: _selectedSubcategoryId,
        );
      }
      final pagination = _extractMap(resp['pagination']);

      if (!mounted) return;

      setState(() {
        _services.addAll(data);
        _servicesOffset += data.length;
        _servicesHasMore = pagination['has_more'] == true;
        _isLoadingMore = false;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _loadMoreProviders() async {
    setState(() => _isLoadingMore = true);

    try {
      final resp = await ApiService.getProviders(
        limit: _pageSize,
        offset: _providersOffset,
        q: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
        categoryId: _providerCategoryId,
        governorate: _providerGovernorate,
        minRating: _providerMinRating,
        date: SearchDate.iso,
        availableOnly: _availableOnly,
      );

      final data = _extractList(resp['data']);
      final pagination = _extractMap(resp['pagination']);

      if (!mounted) return;

      setState(() {
        _providers.addAll(data);
        _providersOffset += data.length;
        _providersHasMore = pagination['has_more'] == true;
        _isLoadingMore = false;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _switchTab(bool showProviders) async {
    setState(() => _showProviders = showProviders);

    if (showProviders && _providers.isEmpty && !_isLoading) {
      await _loadProviders();
    }
  }

  Future<void> _applySearch() async {
    _services.clear();
    _providers.clear();
    _servicesOffset = 0;
    _providersOffset = 0;
    _servicesHasMore = true;
    _providersHasMore = true;

    if (_showProviders) {
      await _loadProviders();
    } else {
      await _loadAll();
    }
  }

  // ═══ Helpers ═══
  List<Map<String, dynamic>> _extractList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  Map<String, dynamic> _extractMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
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

  // ═══ فتح التفاصيل ═══
  void _openServiceDetails(Map<String, dynamic> service) {
    final id = service['id']?.toString() ?? '';
    if (id.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceDetailScreen(
          serviceId: id,
          initialService: service,
        ),
      ),
    );
  }

  // ═══ عدد الفلاتر ═══
  int get _activeFiltersCount {
    int count = 0;
    if (_showProviders) {
      if (_providerCategoryId != null) count++;
      if (_providerGovernorate != null) count++;
      if (_providerMinRating != null) count++;
    } else {
      if (_selectedCategoryId != null) count++;
      if (_selectedGovernorate != null) count++;
      if (_minPrice != null) count++;
      if (_maxPrice != null) count++;
      if (_minRating != null) count++;
      if (_selectedSort != null) count++;
    }
    return count;
  }

  bool get _hasActiveFilters => _activeFiltersCount > 0;

  Future<void> _openFiltersSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _buildFiltersSheet(ctx),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════
 @override
Widget build(BuildContext context) {
  return Directionality(
    textDirection: ui.TextDirection.rtl,
    child: BrandScaffold(
      appBar: widget.embedded
          ? null
          : BrandAppBar(
              title: 'الخدمات',
              actions: [
                IconButton(
                  tooltip: 'الإعدادات',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
                IconButton(
                  tooltip: 'حجوزاتي',
                  icon: const Icon(Icons.calendar_month_rounded),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyBookingsScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'تسجيل الخروج',
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: _logout,
                ),
              ],
            ),
      body: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth =
                constraints.maxWidth > 900 ? 900.0 : constraints.maxWidth;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  children: [
                    if (widget.embedded)
                      _buildDiscoveryHeader()
                    else
                      const InfoBanner(
                        message: UiCopy.servicesBrowseHint,
                        tone: InfoBannerTone.info,
                      ),
                    _buildAdsBanner(),
                    _buildDateBar(),
                    _buildSearchBar(),
                    _buildTabs(),
                    Expanded(child: _buildBody()),
                  ],
                ),
              ),
            );
          },
        ),
      
    ),
  );
}

  // ═══ شريط تاريخ المناسبة ═══
  Future<void> _pickSearchDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: SearchDate.date.value ?? now.add(const Duration(days: 2)),
      firstDate: now,
      lastDate: DateTime(now.year + 1, now.month, now.day),
      helpText: 'تاريخ مناسبتك',
    );
    if (picked != null) SearchDate.date.value = picked;
  }

  Widget _buildDateBar() {
    final date = SearchDate.date.value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickSearchDate,
                  icon: const Icon(Icons.event, size: 18),
                  label: Text(
                    date == null
                        ? 'اختر تاريخ مناسبتك'
                        : 'المناسبة: ${SearchDate.iso}',
                  ),
                ),
              ),
              if (date != null)
                IconButton(
                  tooltip: 'إزالة التاريخ',
                  icon: const Icon(Icons.close),
                  onPressed: () => SearchDate.date.value = null,
                ),
            ],
          ),
          if (date != null)
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('المتاحون في هذا التاريخ فقط'),
              value: _availableOnly,
              onChanged: (v) {
                setState(() => _availableOnly = v);
                _onSearchDateChanged();
              },
            ),
        ],
      ),
    );
  }

  Widget _suggestedDatesRow() {
    if (_suggestedDates.isEmpty || SearchDate.date.value == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          const Text('جرّب أقرب تاريخ متاح:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final d in _suggestedDates)
                ActionChip(
                  label: Text(d),
                  onPressed: () {
                    final parsed = DateTime.tryParse(d);
                    if (parsed != null) SearchDate.date.value = parsed;
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: AppGradients.header,
        borderRadius: Radii.brLg,
        border: Border.all(
          color: AppPalette.gold.withValues(alpha: 0.28),
        ),
        boxShadow: AppShadows.soft,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اكتشف ما يناسب احتياجاتك',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'خيارات متنوعة في مكان واحد — اختر خدماتك بكل سهولة.',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFFE8ECF3),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ═══ البحث ═══
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _applySearch(),
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: _showProviders
                    ? 'ابحث عن مزود...'
                    : 'ابحث عن خدمة...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: AppColors.mutedText,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _applySearch();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppPalette.gold.withValues(alpha: 0.35),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _hasActiveFilters ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: _openFiltersSheet,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _hasActiveFilters
                        ? AppColors.primary
                        : AppPalette.gold.withValues(alpha: 0.45),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: _hasActiveFilters
                          ? Colors.white
                          : AppColors.primary,
                    ),
                    if (_activeFiltersCount > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$_activeFiltersCount',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══ التبويبات ═══
 Widget _buildTabs() {
  return Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.surfaceTint,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.borderLight),
    ),
    child: Row(
      children: [
        Expanded(
          child: _buildTab(
            title: 'الخدمات',
            icon: Icons.miscellaneous_services_rounded,
            selected: !_showProviders,
            onTap: () => _switchTab(false),
          ),
        ),
        Expanded(
          child: _buildTab(
            title: 'المزودون',
            icon: Icons.storefront_rounded,
            selected: _showProviders,
            onTap: () => _switchTab(true),
          ),
        ),
        Expanded(
          child: _buildPartyTab(),
        ),
      ],
    ),
  );
}

Widget _buildPartyTab() {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(13),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const OccasionOrganizeScreen(),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 8,
        ),
        child: const ShrinkIconLabel(
          icon: Icons.celebration_outlined,
          label: 'ابدأ التخطيط',
          color: AppColors.goldDark,
          fontSize: 12,
        ),
      ),
    ),
  );
}
  Widget _buildTab({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: ShrinkIconLabel(
            icon: icon,
            label: title,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ═══ الجسم ═══
  Widget _buildBody() {
    if (_isLoading) return _buildLoading();
    if (_errorMessage != null) return _buildError();
    if (_showProviders) return _buildProvidersList();
    if (_selectedCategoryId != null &&
        _subcategories.isNotEmpty &&
        !_typeChosen) {
      return _buildSubcategoryPicker();
    }
    return _buildServicesList();
  }

  String? _coverUrlOf(Map<String, dynamic> service) {
    final cover = service['cover_image'];
    if (cover is! Map) return null;
    final signed = cover['signed_url']?.toString() ?? '';
    if (signed.startsWith('http')) return signed;
    final url = cover['image_url']?.toString() ?? '';
    if (url.startsWith('http')) return url;
    return null;
  }

  String? _coverForSubcategory(String subcategoryId) {
    for (final service in _services) {
      if (_serviceSubcategoryIds[service['id']?.toString()] == subcategoryId) {
        return _coverUrlOf(service);
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

  void _pickServiceType(String? id) {
    setState(() {
      _selectedSubcategoryId = id;
      _typeChosen = true;
      _services.clear();
      _servicesOffset = 0;
      _servicesHasMore = true;
    });
    _loadAll();
  }

  void _reopenTypePicker() {
    setState(() {
      _typeChosen = false;
      _selectedSubcategoryId = null;
      _services.clear();
      _servicesOffset = 0;
      _servicesHasMore = true;
    });
    _loadAll();
  }

  Widget _buildSubcategoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
            onPick: _pickServiceType,
          ),
        ),
      ],
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
                onPressed: () {
                  if (_showProviders) {
                    _providers.clear();
                    _loadProviders();
                  } else {
                    _loadAll();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _badgesOf(Map<String, dynamic> row) {
    final raw = row['badges'];
    return raw is List ? raw.map((e) => e.toString()).toList() : const [];
  }

  // ═══ قائمة الخدمات ═══
  bool get _showTypeBar => _subcategories.isNotEmpty && _typeChosen;

  Widget _typeBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
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
    );
  }

  // ═══ قائمة الخدمات ═══
  Widget _buildServicesList() {
    if (_services.isEmpty) {
      return Column(
        children: [
          if (_showTypeBar) _typeBar(),
          Expanded(
            child: ListView(
              children: [
                const EmptyState(
              icon: Icons.miscellaneous_services_outlined,
              title: 'لا توجد خدمات',
              body: 'لم نجد خدمات تطابق البحث الحالي. جرّب توسيع الفلاتر.',
            ),
                _suggestedDatesRow(),
              ],
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // على الشاشات العريضة نعرض شبكة بعمودين/ثلاثة؛
        // على الهاتف تبقى قائمة أفقية مريحة للقراءة.
        final columns = Responsive.gridColumns(
          constraints.maxWidth - Space.screenH * 2,
          minItemWidth: 260,
          max: 3,
        );
        final asGrid = columns > 1;

        return ResultsGrid(
          controller: _scrollController,
          onRefresh: _loadAll,
          isLoadingMore: _isLoadingMore,
          header: (_showTypeBar || _suggestedDates.isNotEmpty)
              ? Column(
                  children: [
                    if (_showTypeBar) _typeBar(),
                    _suggestedDatesRow(),
                  ],
                )
              : null,
          itemCount: _services.length,
          itemBuilder: (context, index) {
            final service = _services[index];
            return ServiceCard(
              compact: asGrid,
              name: service['name']?.toString() ?? 'خدمة',
              governorate: service['governorate']?.toString() ?? '',
              location: service['location']?.toString() ?? '',
              priceLabel: servicePriceLabel(
                service,
                formatPrice: _formatPrice,
              ),
              rating: _toDouble(service['rating']),
              reviewsCount: _toInt(service['reviews_count']),
              isBookable: service['is_bookable'] == true,
              badges: _badgesOf(service),
              availableOnDate: service['available_on_date'] as bool?,
              coverUrl: _coverUrlOf(service),
              onTap: () => _openServiceDetails(service),
            );
          },
        );
      },
    );
  }

  // ═══ قائمة المزودين ═══
  Widget _buildProvidersList() {
    if (_providers.isEmpty) {
      return EmptyState(
        icon: Icons.storefront_outlined,
        title: 'لا يوجد مزودون',
        body: 'لم نجد مزودين يطابقون البحث الحالي.',
      );
    }

    return ResultsGrid(
      controller: _scrollController,
      onRefresh: _loadProviders,
      isLoadingMore: _isLoadingMore,
      minItemWidth: 280,
      itemCount: _providers.length,
      itemBuilder: (context, index) {
        final provider = _providers[index];
        final cover = provider['cover_image'];
        String? coverUrl;
        if (cover is Map) {
          coverUrl = cover['signed_url']?.toString() ??
              cover['image_url']?.toString();
        }

        return ProviderCard(
          name: provider['name']?.toString() ?? 'مزود',
          governorate: provider['governorate']?.toString() ?? '',
          description: provider['description']?.toString() ?? '',
          coverUrl: coverUrl,
          logoUrl: provider['logo_url']?.toString(),
          rating: _toDouble(provider['rating']),
          reviewsCount: _toInt(provider['reviews_count']),
          isVerified: provider['is_verified'] == true,
          badges: _badgesOf(provider),
          availableOnDate: provider['available_on_date'] as bool?,
          onTap: () {
            final id = provider['id']?.toString() ?? '';
            if (id.isEmpty) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProviderDetailsScreen(
                  providerId: id,
                  initialProvider: provider,
                ),
              ),
            );
          },
        );
      },
    );
  }
  // ═══ شيت الفلاتر (مبسّط) ═══
  Widget _buildFiltersSheet(BuildContext sheetContext) {
    String? catId = _showProviders ? _providerCategoryId : _selectedCategoryId;
    String? govId = _showProviders ? _providerGovernorate : _selectedGovernorate;
    double? minPrice = _minPrice;
    double? maxPrice = _maxPrice;
    double? minRating = _showProviders ? _providerMinRating : _minRating;
    String? sort = _selectedSort;

    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _showProviders
                                  ? 'فلاتر المزودين'
                                  : 'فلاتر الخدمات',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                catId = null;
                                govId = null;
                                minPrice = null;
                                maxPrice = null;
                                minRating = null;
                                sort = null;
                              });
                            },
                            child: const Text('مسح'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        children: [
                          if (_categories.isNotEmpty) ...[
                            const Text(
                              'التصنيف',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _categories.map((cat) {
                                final id = cat['id']?.toString();
                                final selected = catId == id;
                                final name = cat['name']?.toString() ?? '';
                                final iconRaw = cat['icon']?.toString();
                                final emoji =
                                    serviceCategoryIconEmoji(iconRaw);
                                return FilterChip(
                                  avatar: emoji == null
                                      ? Icon(
                                          serviceCategoryIcon(iconRaw),
                                          size: 16,
                                          color: selected
                                              ? Colors.white
                                              : AppColors.primary,
                                        )
                                      : null,
                                  label: Text(
                                    emoji == null
                                        ? name
                                        : '$emoji $name'.trim(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: selected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  selected: selected,
                                  onSelected: (_) {
                                    setSheetState(() {
                                      catId = selected ? null : id;
                                    });
                                  },
                                  selectedColor: AppColors.primary,
                                  backgroundColor: AppColors.surfaceTint,
                                  checkmarkColor: Colors.white,
                                  showCheckmark: false,
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 18),
                          ],
                          const Text(
                            'المحافظة',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String?>(
                            value: govId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              hintText: 'جميع المحافظات',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('جميع المحافظات'),
                              ),
                              ..._syrianGovernorates.map(
                                (g) => DropdownMenuItem<String?>(
                                  value: g,
                                  child: Text(g),
                                ),
                              ),
                            ],
                            onChanged: (v) =>
                                setSheetState(() => govId = v),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'الحد الأدنى للتقييم',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            children: [
                              _ratingChipSheet(
                                label: 'الكل',
                                value: null,
                                selected: minRating,
                                onTap: (v) =>
                                    setSheetState(() => minRating = v),
                              ),
                              _ratingChipSheet(
                                label: '⭐ 3+',
                                value: 3.0,
                                selected: minRating,
                                onTap: (v) =>
                                    setSheetState(() => minRating = v),
                              ),
                              _ratingChipSheet(
                                label: '⭐ 4+',
                                value: 4.0,
                                selected: minRating,
                                onTap: (v) =>
                                    setSheetState(() => minRating = v),
                              ),
                              _ratingChipSheet(
                                label: '⭐ 4.5+',
                                value: 4.5,
                                selected: minRating,
                                onTap: (v) =>
                                    setSheetState(() => minRating = v),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (!_showProviders) ...[
                            const Text(
                              'الترتيب',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _sortChip(
                                  label: 'الأحدث',
                                  value: null,
                                  selected: sort,
                                  onTap: (v) =>
                                      setSheetState(() => sort = v),
                                ),
                                _sortChip(
                                  label: 'السعر ↑',
                                  value: 'price_asc',
                                  selected: sort,
                                  onTap: (v) =>
                                      setSheetState(() => sort = v),
                                ),
                                _sortChip(
                                  label: 'السعر ↓',
                                  value: 'price_desc',
                                  selected: sort,
                                  onTap: (v) =>
                                      setSheetState(() => sort = v),
                                ),
                                _sortChip(
                                  label: 'الأعلى تقييماً',
                                  value: 'rating_desc',
                                  selected: sort,
                                  onTap: (v) =>
                                      setSheetState(() => sort = v),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          top: BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              child: const Text('إلغاء'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_showProviders) {
                                  _providerCategoryId = catId;
                                  _providerGovernorate = govId;
                                  _providerMinRating = minRating;
                                  _providers.clear();
                                  _providersOffset = 0;
                                  _providersHasMore = true;
                                } else {
                                  _selectedCategoryId = catId;
                                  _selectedGovernorate = govId;
                                  _minPrice = minPrice;
                                  _maxPrice = maxPrice;
                                  _minRating = minRating;
                                  _selectedSort = sort;
                                  _services.clear();
                                  _servicesOffset = 0;
                                  _servicesHasMore = true;
                                }
                                Navigator.pop(sheetContext);
                                if (_showProviders) {
                                  _loadProviders();
                                } else {
                                  _loadAll();
                                }
                              },
                              child: const Text(
                                'تطبيق الفلاتر',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _ratingChipSheet({
    required String label,
    required double? value,
    required double? selected,
    required ValueChanged<double?> onTap,
  }) {
    final isSelected = selected == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(isSelected ? null : value),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceTint,
      checkmarkColor: Colors.white,
    );
  }

  Widget _sortChip({
    required String label,
    required String? value,
    required String? selected,
    required ValueChanged<String?> onTap,
  }) {
    final isSelected = selected == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(isSelected ? null : value),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceTint,
      checkmarkColor: Colors.white,
    );
  }
  // ═══════════════════════════════════════════════════════════
  // الإعلانات
  // ═══════════════════════════════════════════════════════════

  Widget _buildAdsBanner() {
    if (_advertisements.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: PageView.builder(
              controller: _adsPageController,
              itemCount: _advertisements.length,
              onPageChanged: (index) {
                setState(() => _currentAdPage = index);
              },
              itemBuilder: (context, index) {
                return _buildAdCard(_advertisements[index]);
              },
            ),
          ),
          if (_advertisements.length > 1) ...[
            const SizedBox(height: 8),
            _buildAdDots(),
          ],
        ],
      ),
    );
  }

  Widget _buildAdCard(Map<String, dynamic> ad) {
    final title = ad['title']?.toString() ?? '';
    final description = ad['description']?.toString() ?? '';
    final imageUrl = ad['signed_url']?.toString() ??
        ad['image_url']?.toString() ??
        '';
    final targetType = ad['target_type']?.toString() ?? '';
    final serviceId = ad['service_id']?.toString();
    final providerId = ad['provider_id']?.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _handleAdTap(
            targetType: targetType,
            serviceId: serviceId,
            providerId: providerId,
          ),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl.isNotEmpty)
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: AppColors.surfaceTint,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) =>
                        _adPlaceholderBackground(),
                  )
                else
                  _adPlaceholderBackground(),

                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.0),
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (title.isNotEmpty)
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.3,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 4,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                            shadows: const [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 4,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'إعلان',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _adPlaceholderBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: const Center(
        child: Icon(
          Icons.campaign_outlined,
          size: 60,
          color: AppColors.goldLight,
        ),
      ),
    );
  }

  Widget _buildAdDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_advertisements.length, (index) {
        final active = index == _currentAdPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Future<void> _handleAdTap({
    required String targetType,
    String? serviceId,
    String? providerId,
  }) async {
    if (targetType == 'service' &&
        serviceId != null &&
        serviceId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ServiceDetailScreen(serviceId: serviceId),
        ),
      );
    } else if (targetType == 'provider' &&
        providerId != null &&
        providerId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderDetailsScreen(providerId: providerId),
        ),
      );
    }
  }
  Future<void> _logout() async {
  try {
    try {
      await NotificationsService.logout();
    } catch (_) {}

    await SessionService.clearSession();
  } catch (e) {
    debugPrint('⚠️ Services logout error: $e');
  }

  if (!mounted) return;

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => const IntroScreen(),
    ),
    (route) => false,
  );
}
}