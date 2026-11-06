// lib/screens/party_request_screen.dart
// ============================================================
// PartyRequestScreen — إنشاء طلب تنظيم حفلة
// ============================================================

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../ui_copy.dart';
import '../services/api_exceptions.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';
import '../utils/service_category_icon.dart';
import '../widgets/brand_decorations.dart';
import '../widgets/ux_helpers.dart';
import 'my_party_requests_screen.dart';

class PartyRequestScreen extends StatefulWidget {
  const PartyRequestScreen({Key? key}) : super(key: key);

  @override
  State<PartyRequestScreen> createState() =>
      _PartyRequestScreenState();
}

class _PartyRequestScreenState extends State<PartyRequestScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ═══ الحالة ═══
  String? _partyType;
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  String? _governorate;
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  // ═══ الفئات ═══
  List<Map<String, dynamic>> _categories = [];
  bool _loadingCategories = true;
  final Set<String> _essentialCategoryIds = {};

  // ═══ الصورة ═══
  fp.PlatformFile? _paymentProofFile;
  String? _uploadedPaymentPath;
  bool _isUploading = false;

  // ═══ الإعدادات ═══
  String _shamCashNumber = '0900000000';
  num _feeUsd = 2;

  bool _isSubmitting = false;

  static const List<String> _governorates = [
    'دمشق', 'ريف دمشق', 'حلب', 'حمص', 'حماة', 'اللاذقية', 'طرطوس',
    'إدلب', 'دير الزور', 'الرقة', 'الحسكة', 'درعا', 'السويداء', 'القنيطرة',
  ];

  static const List<Map<String, String>> _partyTypes = [
    {'value': 'wedding', 'label': 'عرس'},
    {'value': 'engagement', 'label': 'خطبة'},
    {'value': 'birthday', 'label': 'عيد ميلاد'},
    {'value': 'graduation', 'label': 'تخرج'},
    {'value': 'other', 'label': 'أخرى'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // تحميل البيانات
  // ═══════════════════════════════════════════════════════════

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.getServiceCategories(),
        ApiService.getPublicSettings().catchError(
          (_) => <String, dynamic>{},
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _categories = results[0] as List<Map<String, dynamic>>;

        final settings = results[1] as Map<String, dynamic>;
        _shamCashNumber =
            settings['sham_cash_number']?.toString() ?? '0900000000';
        _feeUsd = (settings['party_request_fee_usd'] as num?) ?? 2;

        _loadingCategories = false;
      });
    } catch (e) {
      debugPrint('❌ load data: $e');
      if (mounted) {
        setState(() => _loadingCategories = false);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // رفع إشعار الدفع
  // ═══════════════════════════════════════════════════════════

  Future<void> _pickPaymentProof() async {
  try {
    final result = await fp.FilePicker.pickFiles(
      type: fp.FileType.image,
      withData: true,
    );

    if (result == null || result.isEmpty) return;

    setState(() {
      _paymentProofFile = result.first;
    });
  } catch (e) {
    if (mounted) {
      ErrorHandler.showError(context, e);
    }
  }
}

 Future<String?> _uploadPaymentProof() async {
  final file = _paymentProofFile;
  if (file == null) return null;

  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) return null;

  try {
    // ═══ اقرأ البايتات مباشرة من xFile ═══
    final bytes = await file.xFile.readAsBytes();

    if (bytes.isEmpty) return null;

    final fileName =
        '$userId/party_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _supabase.storage
        .from('party_payments')
        .uploadBinary(fileName, bytes);

    return fileName;
  } catch (e) {
    debugPrint('❌ upload error: $e');
    return null;
  }
}

  // ═══════════════════════════════════════════════════════════
  // إرسال
  // ═══════════════════════════════════════════════════════════

  Future<void> _submit() async {
    if (_isSubmitting) return;

    // ═══ التحقق ═══
    if (_partyType == null) {
      ErrorHandler.showWarning(context, 'يرجى اختيار نوع الحفلة');
      return;
    }

    if (_governorate == null) {
      ErrorHandler.showWarning(context, 'يرجى اختيار المحافظة');
      return;
    }

    if (_paymentProofFile == null) {
      ErrorHandler.showWarning(context, 'يرجى رفع إشعار الدفع');
      return;
    }

    if (_essentialCategoryIds.isEmpty) {
      ErrorHandler.showWarning(
        context,
        'يرجى اختيار فئة أساسية واحدة على الأقل',
      );
      return;
    }

    // ═══ الميزانية ═══
    num? budgetMin;
    num? budgetMax;

    if (_budgetMinController.text.trim().isNotEmpty) {
      budgetMin = num.tryParse(_budgetMinController.text.trim());
      if (budgetMin == null || budgetMin < 0) {
        ErrorHandler.showWarning(context, 'الميزانية الدنيا غير صحيحة');
        return;
      }
    }

    if (_budgetMaxController.text.trim().isNotEmpty) {
      budgetMax = num.tryParse(_budgetMaxController.text.trim());
      if (budgetMax == null || budgetMax < 0) {
        ErrorHandler.showWarning(context, 'الميزانية العليا غير صحيحة');
        return;
      }
    }

    if (budgetMin != null && budgetMax != null && budgetMin > budgetMax) {
      ErrorHandler.showWarning(
        context,
        'الميزانية الدنيا يجب أن تكون أقل من العليا',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // ═══ رفع الصورة ═══
      setState(() => _isUploading = true);
      final proofPath = await _uploadPaymentProof();
      setState(() => _isUploading = false);

      if (proofPath == null) {
        throw Exception('فشل رفع إشعار الدفع');
      }

      _uploadedPaymentPath = proofPath;

      // ═══ إرسال الطلب ═══
      await ApiService.createPartyRequest(
        partyType: _partyType!,
        governorate: _governorate!,
        paymentProofPath: proofPath,
        budgetMin: budgetMin,
        budgetMax: budgetMax,
        address: _addressController.text,
        description: _descriptionController.text,
        essentialCategories: _essentialCategoryIds.toList(),
        // يبقى الحقل للتوافق مع API الحالية، دون إتاحة اختيار فئات كمالية.
        luxuryCategories: const [],
      );

      if (!mounted) return;

      ErrorHandler.showSuccess(
        context,
        'تم إرسال طلبك بنجاح. سيتم التواصل معك قريبًا.',
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MyPartyRequestsScreen(),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e, customMessage: e.userMessage);
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(
        context,
        e,
        customMessage: 'فشل إرسال الطلب',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isUploading = false;
        });
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: BrandScaffold(
        appBar: BrandAppBar(
          title: 'تنظيم حفلة',
          actions: [
            IconButton(
              tooltip: 'طلباتي',
              icon: const Icon(Icons.list_alt_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyPartyRequestsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: _loadingCategories
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const InfoBanner(
                      message: UiCopy.partyRequestHint,
                      tone: InfoBannerTone.tip,
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    _buildPartyDetailsSection(),
                    const SizedBox(height: 16),
                    _buildBudgetSection(),
                    const SizedBox(height: 16),
                    _buildCategoriesSection(),
                    const SizedBox(height: 16),
                    _buildLocationSection(),
                    const SizedBox(height: 16),
                    _buildDescriptionSection(),
                    const SizedBox(height: 16),
                    _buildPaymentSection(),
                    const SizedBox(height: 24),
                    _buildSubmitButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // بطاقة معلومات
  // ═══════════════════════════════════════════════════════════

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.3),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.goldDark,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'اطلب تنظيم حفلتك، وسيتواصل معك فريقنا لتنسيق كل التفاصيل.',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // قسم نوع الحفلة
  // ═══════════════════════════════════════════════════════════

  Widget _buildPartyDetailsSection() {
    return _buildSection(
      icon: Icons.celebration_outlined,
      title: 'نوع الحفلة',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _partyTypes.map((t) {
          final value = t['value']!;
          final label = t['label']!;
          final selected = _partyType == value;

          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => setState(() => _partyType = value),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.border,
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontSize: 13,
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.w500,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // قسم الميزانية
  // ═══════════════════════════════════════════════════════════

  Widget _buildBudgetSection() {
    return _buildSection(
      icon: Icons.attach_money_rounded,
      title: 'الميزانية (بالدولار)',
      subtitle: 'اتركها فارغة إن لم تكن محددة',
      child: Row(
        children: [
          Expanded(
            child: _buildTextField(
              controller: _budgetMinController,
              label: 'من',
              hint: '0',
              isNumber: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTextField(
              controller: _budgetMaxController,
              label: 'إلى',
              hint: '10000',
              isNumber: true,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // قسم الفئات
  // ═══════════════════════════════════════════════════════════

  Widget _buildCategoriesSection() {
    return _buildSection(
      icon: Icons.category_outlined,
      title: 'الفئات',
      subtitle: 'اختر ما تحتاجه لحفلتك',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الفئات الأساسية',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildCategoriesWrap(_essentialCategoryIds),
        ],
      ),
    );
  }

  Widget _buildCategoriesWrap(Set<String> selectedSet) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _categories.map((cat) {
        final id = cat['id']?.toString() ?? '';
        final name = cat['name']?.toString() ?? '';
        final iconRaw = cat['icon']?.toString();
        final emoji = serviceCategoryIconEmoji(iconRaw);
        final selected = selectedSet.contains(id);

        return FilterChip(
          avatar: emoji == null
              ? Icon(
                  serviceCategoryIcon(iconRaw),
                  size: 16,
                  color: selected ? Colors.white : AppColors.primary,
                )
              : null,
          label: Text(
            emoji == null ? name : '$emoji $name'.trim(),
          ),
          selected: selected,
          onSelected: (_) {
            setState(() {
              if (selected) {
                selectedSet.remove(id);
              } else {
                selectedSet.add(id);
              }
            });
          },
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          showCheckmark: false,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // قسم الموقع
  // ═══════════════════════════════════════════════════════════

  Widget _buildLocationSection() {
    return _buildSection(
      icon: Icons.location_on_outlined,
      title: 'المكان',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _governorate,
            isExpanded: true,
            decoration: _inputDecoration('المحافظة'),
            items: _governorates
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) => setState(() => _governorate = v),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _addressController,
            label: 'العنوان (اختياري)',
            hint: 'مثال: دمشق - المزة',
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // قسم الوصف
  // ═══════════════════════════════════════════════════════════

  Widget _buildDescriptionSection() {
    return _buildSection(
      icon: Icons.description_outlined,
      title: 'الوصف',
      child: _buildTextField(
        controller: _descriptionController,
        label: 'تفاصيل إضافية',
        hint: 'عدد المدعوين، تاريخ الحفل، أي تفاصيل مهمة...',
        maxLines: 5,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // قسم الدفع
  // ═══════════════════════════════════════════════════════════

  Widget _buildPaymentSection() {
    return _buildSection(
      icon: Icons.payment_outlined,
      title: 'رسوم الطلب ($_feeUsd)',
      subtitle: 'يُدفع عبر شام كاش',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ═══ رقم شام كاش ═══
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
                  'رقم شام كاش',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _shamCashNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.goldDark,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: AppColors.goldDark,
                      ),
                      onPressed: () {
                        // TODO: نسخ إلى الحافظة
                        ErrorHandler.showSuccess(
                          context,
                          'تم نسخ الرقم',
                        );
                      },
                      tooltip: 'نسخ',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'المبلغ المطلوب: $_feeUsd\$',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.goldDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ═══ رفع الإشعار ═══
          const Text(
            'ارفع صورة إشعار الدفع',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildPaymentProofPicker(),
        ],
      ),
    );
  }

  Widget _buildPaymentProofPicker() {
  final hasFile = _paymentProofFile != null;

  return InkWell(
    onTap: _isUploading ? null : _pickPaymentProof,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hasFile
            ? AppColors.successLight
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasFile
              ? AppColors.success
              : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            hasFile
                ? Icons.check_circle_rounded
                : Icons.cloud_upload_outlined,
            size: 40,
            color: hasFile
                ? AppColors.success
                : AppColors.primary,
          ),
          const SizedBox(height: 8),
          Text(
            hasFile
                ? 'تم رفع الإشعار ✓'
                : 'اضغط لاختيار صورة',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: hasFile
                  ? AppColors.success
                  : AppColors.textSecondary,
            ),
          ),
          if (hasFile) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FutureBuilder<Uint8List>(
                future: _paymentProofFile!.xFile.readAsBytes(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container(
                      height: 150,
                      color: AppColors.surfaceTint,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }
                  return Image.memory(
                    snapshot.data!,
                    height: 150,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () =>
                  setState(() => _paymentProofFile = null),
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('إزالة'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
  // ═══════════════════════════════════════════════════════════
  // زر الإرسال
  // ═══════════════════════════════════════════════════════════

  Widget _buildSubmitButton() {
    final busy = _isSubmitting || _isUploading;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: busy ? null : _submit,
        icon: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send_rounded, size: 20),
        label: Text(
          _isUploading
              ? 'جارٍ رفع الإشعار...'
              : _isSubmitting
                  ? 'جارٍ إرسال الطلب...'
                  : 'إرسال الطلب',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Widgets مساعدة
  // ═══════════════════════════════════════════════════════════

  Widget _buildSection({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return BrandCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      maxLines: maxLines,
      textDirection: TextDirection.rtl,
      decoration: _inputDecoration(label, hint: hint),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
    );
  }
}