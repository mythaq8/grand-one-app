// lib/screens/provider_details_screen.dart
// ============================================================
// ProviderDetailsScreen — تفاصيل المزود
//
// متوافق مع Deno:
// - GET /api/provider-details?id=...
//
// 🔒 ملاحظة خصوصية:
// لا تُعرض بيانات التواصل (phone/whatsapp/website)
// ============================================================

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../design/tokens.dart';
import '../ui/kit/kit.dart';
import '../ui/layout/responsive.dart';
import '../services/api_service.dart';
import '../services/api_exceptions.dart';
import '../utils/service_category_icon.dart';
import '../utils/service_price_label.dart';
import '../widgets/islamic_decorations.dart';
import 'service_detail_screen.dart';

class ProviderDetailsScreen extends StatefulWidget {
  final String providerId;
  final Map<String, dynamic>? initialProvider;

  const ProviderDetailsScreen({
    Key? key,
    required this.providerId,
    this.initialProvider,
  }) : super(key: key);

  @override
  State<ProviderDetailsScreen> createState() =>
      _ProviderDetailsScreenState();
}

class _ProviderDetailsScreenState extends State<ProviderDetailsScreen> {
  // ═══ الحالة ═══
  bool _isLoading = true;
  String? _errorMessage;

  // ═══ البيانات ═══
  Map<String, dynamic>? _provider;
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _images = [];
  List<Map<String, dynamic>> _categories = [];
  Map<String, dynamic>? _dynamicFields; // {fields: [...], values: [...]}
  List<Map<String, dynamic>> _reviews = [];

  // ============================================================
  // Lifecycle
  // ============================================================

  @override
  void initState() {
    super.initState();

    if (widget.initialProvider != null) {
      _provider = widget.initialProvider;
    }

    _loadDetails();
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
      final response =
          await ApiService.getProviderDetails(widget.providerId);

      if (!mounted) return;

      setState(() {
        _provider = _asMap(response['provider']) ?? _provider;
        _services = _asList(response['services']);
        _images = _asList(response['images']);
        _categories = _asList(response['categories']);
        _dynamicFields = _asMap(response['dynamic_fields']);
        _reviews = _asList(response['reviews']);
        _isLoading = false;
      });
    } on ApiException catch (e) {
      debugPrint(
        '🔴 Provider details API error: ${e.message} '
        '(code: ${e.statusCode})',
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.userMessage;
      });
    } catch (e, stackTrace) {
      debugPrint('🔴 Provider details error: $e');
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

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: IslamicScaffold(
        appBar: IslamicAppBar(
          title: _provider?['name']?.toString() ?? 'تفاصيل المزود',
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _provider == null) {
      return const LoadingState(message: 'جارٍ تحميل بيانات المزود...');
    }
    if (_errorMessage != null && _provider == null) {
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
          ContentMaxWidth(
            maxWidth: Sizes.formMax + 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Space.md),
                _buildHeader(),
                const SizedBox(height: Space.lg),
                _buildInfoCard(),
                if (_categories.isNotEmpty) ...[
                  const SizedBox(height: Space.md),
                  _buildCategoriesCard(),
                ],
                if (_images.isNotEmpty) ...[
                  const SizedBox(height: Space.md),
                  _buildImagesGallery(),
                ],
                _buildDynamicFieldsCard(),
                const SizedBox(height: Space.md),
                _buildReviewsCard(),
                const SizedBox(height: Space.xl),
                _buildServicesHeader(),
                const SizedBox(height: Space.sm),
                _buildServicesList(),
                const SizedBox(height: Space.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── رأس الصفحة ───

  Widget _buildHeader() {
    final name = _provider?['name']?.toString() ?? '';
    final isVerified = _provider?['is_verified'] == true;
    final rating = _toDouble(_provider?['rating']);
    final reviewsCount = _toInt(_provider?['reviews_count']);

    // محاولة عرض صورة الغلاف
    String? coverUrl;
    if (_images.isNotEmpty) {
      final cover = _images.firstWhere(
        (img) => img['is_cover'] == true,
        orElse: () => _images.first,
      );
      coverUrl = cover['signed_url']?.toString() ??
          cover['image_url']?.toString();
    }
    if (coverUrl == null || coverUrl.isEmpty) {
      coverUrl = _provider?['cover_image_url']?.toString();
    }
    if ((coverUrl == null || coverUrl.isEmpty)) {
      coverUrl = _provider?['logo_url']?.toString();
    }

    return IslamicCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // صورة الغلاف
          if (coverUrl != null && coverUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Container(
                height: 160,
                width: double.infinity,
                color: AppColors.surfaceTint,
                child: Image.network(
                  coverUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: AppColors.surfaceTint,
                      child: const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.storefront_outlined,
                      size: 48,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(15),
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
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 19,
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
                                    size: 22,
                                    color: AppColors.success,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 18,
                                color: AppColors.goldDark,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.goldDark,
                                ),
                              ),
                              if (reviewsCount > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '($reviewsCount تقييم)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
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

  // ─── بطاقة المعلومات ───

  Widget _buildInfoCard() {
    final description = _provider?['description']?.toString() ?? '';
    final governorate = _provider?['governorate']?.toString() ?? '';
    final address = _provider?['address']?.toString() ?? '';

    return IslamicCard(
      padding: const EdgeInsets.all(16),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  size: 19,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'عن المزود',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.7,
                color: AppColors.textSecondary,
              ),
            ),
          ],

          if (governorate.isNotEmpty) ...[
            const SizedBox(height: 12),
            _infoRow(Icons.location_on_outlined, 'المحافظة', governorate),
          ],

          if (address.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow(Icons.place_outlined, 'العنوان', address),
          ],

          // 🔒 لا نعرض phone/whatsapp/website
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceGreen,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // ─── الفئات ───

  Widget _buildCategoriesCard() {
    return IslamicCard(
      padding: const EdgeInsets.all(16),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.category_outlined,
                  size: 19,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'التخصصات',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final iconRaw = cat['icon']?.toString();
              final emoji = serviceCategoryIconEmoji(iconRaw);
              final name = cat['name']?.toString() ?? '';
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (emoji == null)
                      Icon(
                        serviceCategoryIcon(iconRaw),
                        size: 14,
                        color: AppColors.primary,
                      )
                    else
                      Text(
                        emoji,
                        style: const TextStyle(fontSize: 12),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── معرض الصور ───

  Widget _buildImagesGallery() {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length,
        itemBuilder: (context, index) {
          final img = _images[index];
          final url = img['signed_url']?.toString() ??
              img['image_url']?.toString() ??
              '';
          return Container(
            width: 180,
            margin: EdgeInsets.only(left: index == 0 ? 0 : 10),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: url.isEmpty
                ? const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 40,
                      color: AppColors.mutedText,
                    ),
                  )
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: AppColors.surfaceTint,
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 40,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  // ─── الحقول الديناميكية ───

  Widget _buildDynamicFieldsCard() {
    final fields = _asList(_dynamicFields?['fields']);
    final values = _asList(_dynamicFields?['values']);

    if (fields.isEmpty || values.isEmpty) return const SizedBox.shrink();

    // عرض فقط الحقول التي لها قيمة
    final visible = <MapEntry<Map<String, dynamic>, String>>[];

    for (final field in fields) {
      final fieldId = field['id']?.toString();
      if (fieldId == null) continue;

      Map<String, dynamic>? value;
      for (final v in values) {
        if (v['field_id']?.toString() == fieldId) {
          value = v;
          break;
        }
      }
      if (value == null) continue;

      final displayValue = _formatFieldValue(field, value);
      if (displayValue.isEmpty) continue;

      visible.add(MapEntry(field, displayValue));
    }

    if (visible.isEmpty) return const SizedBox.shrink();

    return IslamicCard(
      padding: const EdgeInsets.all(16),
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
                  borderRadius: BorderRadius.circular(10),
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
          ...visible.map((entry) {
            final name = entry.key['field_name']?.toString() ?? '';
            final value = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceGreen,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 12.5,
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

  String _formatFieldValue(
    Map<String, dynamic> field,
    Map<String, dynamic> value,
  ) {
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

  // ─── رأس قائمة الخدمات ───

  Widget _buildServicesHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.handyman_outlined,
            color: AppColors.goldLight,
            size: 21,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            'خدمات المزود (${_services.length})',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // ─── قائمة الخدمات ───

  Widget _buildServicesList() {
    if (_services.isEmpty) {
      return IslamicCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: AppColors.gold.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'لا توجد خدمات لهذا المزود حالياً',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _services.map((s) => _buildServiceCard(s)).toList(),
    );
  }

  // ─── بطاقة الخدمة ───

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final name = service['name']?.toString() ?? '';
    final governorate = service['governorate']?.toString() ?? '';
    final priceLabel = servicePriceLabel(
      Map<String, dynamic>.from(service),
      formatPrice: _formatPrice,
    );
    final rating = _toDouble(service['rating']);
    final reviewsCount = _toInt(service['reviews_count']);

    final cover = service['cover_image'];
    String? coverUrl;
    if (cover is Map) {
      coverUrl = cover['signed_url']?.toString() ??
          cover['image_url']?.toString();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
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
          },
          child: Container(
            padding: const EdgeInsets.all(12),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الصورة
                Container(
                  width: 88,
                  height: 88,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceTint,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: (coverUrl != null && coverUrl.isNotEmpty)
                      ? Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: AppColors.surfaceTint,
                              child: const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.business_center_outlined,
                            size: 37,
                            color: AppColors.gold,
                          ),
                        )
                      : const Icon(
                          Icons.business_center_outlined,
                          size: 37,
                          color: AppColors.gold,
                        ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (governorate.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.mutedText,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              governorate,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.goldSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 15,
                                  color: AppColors.goldDark,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.goldDark,
                                  ),
                                ),
                                if (reviewsCount > 0) ...[
                                  const SizedBox(width: 3),
                                  Text(
                                    '($reviewsCount)',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.goldDark,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (priceLabel.isNotEmpty)
                            Flexible(
                              child: Text(
                                priceLabel,
                                textAlign: TextAlign.left,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // قسم التقييمات
  // ============================================================

  Widget _buildReviewsCard() {
    final rating = _toDouble(_provider?['rating']);
    final reviewsCount = _toInt(_provider?['reviews_count']);

    return IslamicCard(
      padding: const EdgeInsets.all(16),
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
                  borderRadius: BorderRadius.circular(10),
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
                  'تقييمات المزود',
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
                            ? 'بناءً على $reviewsCount تقييم'
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

          if (_reviews.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 36,
                    color: AppColors.mutedText,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'كن أول من يقيّم هذا المزود',
                    style: TextStyle(
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
      child: Row(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
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
                          fontSize: 10,
                          color: AppColors.mutedText,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildStars(rating, size: 15),
              ],
            ),
          ),
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