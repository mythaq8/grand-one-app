// lib/screens/edit_bride_profile_screen.dart
// ============================================================
// EditBrideProfileScreen — تعديل متطلبات الفتاة من العريس
// ============================================================

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../utils/error_handler.dart';
import '../widgets/islamic_decorations.dart';
import '../widgets/form_fields.dart';

class EditBrideProfileScreen extends StatefulWidget {
  const EditBrideProfileScreen({super.key});

  @override
  State<EditBrideProfileScreen> createState() =>
      _EditBrideProfileScreenState();
}

class _EditBrideProfileScreenState
    extends State<EditBrideProfileScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  bool _isLoading = true;
  bool _isSaving = false;

  final _selfDescription = TextEditingController();

  // ============================================================
  // قيم المتطلبات (14 حقلًا)
  // ============================================================

  List<String> _reqGovernorate = [];
  List<String> _reqResidence = [];
  List<String> _reqEducation = [];
  List<String> _reqIncome = [];
  List<String> _reqAge = [];
  List<String> _reqFinancial = [];
  List<String> _reqHousing = [];
  List<String> _reqSmoking = [];
  List<String> _reqHookah = [];
  List<String> _reqReligious = [];
  List<String> _reqHeight = [];
  List<String> _reqWeight = [];
  List<String> _reqSkin = [];

  // ============================================================
  // قوائم الخيارات
  // ============================================================

  final List<String> _governorates = [
    'دمشق', 'ريف دمشق', 'حلب', 'حمص', 'حماة', 'اللاذقية', 'طرطوس',
    'إدلب', 'دير الزور', 'الرقة', 'الحسكة', 'درعا', 'السويداء', 'القنيطرة',
  ];

  final List<String> _incomeRanges = [
    '<100\$',
    '100-200\$',
    '200-400\$',
    '400-600\$',
    '600-1000\$',
    '>1000\$',
  ];

  final List<String> _ageRanges = [
    '18-20', '21-23', '24-26', '27-29', '30-32',
    '33-35', '36-38', '39-41', '42-45', '46-50',
  ];

  final List<String> _financialLevels = [
    'ضعيفة', 'متوسطة', 'جيدة', 'ممتازة',
  ];

  final List<String> _housingTypes = ['إيجار', 'ملك'];

  final List<String> _educationLevels = [
    'تاسع', 'بكلوريا علمي', 'بكلوريا أدبي', 'لا يوجد', 'دراسة جامعية',
  ];

  final List<String> _religiousLevels = [
    'ضعيف جداً', 'ضعيف', 'وسط', 'جيد', 'جيد جداً', 'ممتاز',
  ];

  final List<String> _heightRanges = [
    '130-140', '140-150', '150-160', '160-170',
    '170-180', '180-190', '190-200',
  ];

  final List<String> _weightRanges = [
    '50-60', '60-70', '70-80', '80-90',
    '90-100', '100-110', '110-120',
  ];

  final List<String> _skins = ['بيضاء', 'حنطية', 'سمراء'];

  final List<String> _yesNo = ['نعم', 'لا'];

  // ============================================================
  // Lifecycle
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadRequirements();
  }

  @override
  void dispose() {
    _selfDescription.dispose();
    super.dispose();
  }

  // ============================================================
  // تحميل المتطلبات الحالية
  // ============================================================

  Future<void> _loadRequirements() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final userId = _client.auth.currentUser?.id;

      if (userId == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      final data = await _client
          .from('brides')
          .select('requirements, interests')
          .eq('user_id', userId)
          .maybeSingle();

      if (!mounted) return;

      if (data != null) {
        _selfDescription.text = data['interests']?.toString() ?? '';
        if (data['requirements'] != null) {
          final reqMap = _parseRequirements(data['requirements']);

          setState(() {
            _reqGovernorate = _toList(reqMap['governorate']);
            _reqResidence = _toList(reqMap['residence']);
            _reqEducation = _toList(
              reqMap['education'] ?? reqMap['education_level'],
            );
            _reqIncome = _toList(reqMap['income']);
            _reqAge = _toList(reqMap['age']);
            _reqFinancial = _toList(reqMap['financial_status']);
            _reqHousing = _toList(
              reqMap['housing'] ?? reqMap['housing_type'],
            );
            _reqSmoking = _toList(reqMap['smoking']);
            _reqHookah = _toList(reqMap['hookah']);
            _reqReligious = _toList(reqMap['religious_commitment']);
            _reqHeight = _toList(reqMap['height']);
            _reqWeight = _toList(reqMap['weight']);
            _reqSkin = _toList(reqMap['skin_color']);
          });
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('🔴 Load requirements error: $e');

      if (!mounted) return;
      setState(() => _isLoading = false);

      ErrorHandler.showError(context, e);
    }
  }

  // ============================================================
  // استخراج requirements كـ Map
  // ============================================================

  Map<String, dynamic> _parseRequirements(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        debugPrint('⚠️ Failed to parse requirements JSON: $e');
      }
    }

    return {};
  }

  // ============================================================
  // تحويل قيمة إلى List<String>
  // ============================================================

  List<String> _toList(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return [];
      return [trimmed];
    }

    return [value.toString()];
  }

  // ============================================================
  // بناء requirements JSON
  // ============================================================

  Map<String, dynamic> _buildRequirementsJson() {
    return {
      'governorate': List<String>.from(_reqGovernorate),
      'residence': List<String>.from(_reqResidence),
      'education': List<String>.from(_reqEducation),
      'income': List<String>.from(_reqIncome),
      'age': List<String>.from(_reqAge),
      'financial_status': List<String>.from(_reqFinancial),
      'housing': List<String>.from(_reqHousing),
      'smoking': List<String>.from(_reqSmoking),
      'hookah': List<String>.from(_reqHookah),
      'religious_commitment': List<String>.from(_reqReligious),
      'height': List<String>.from(_reqHeight),
      'weight': List<String>.from(_reqWeight),
      'skin_color': List<String>.from(_reqSkin),
    };
  }

  // ============================================================
  // الحفظ
  // ============================================================

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final userId = _client.auth.currentUser?.id;

      if (userId == null) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        return;
      }

      final about = _selfDescription.text.trim();
      if (about.isNotEmpty && about.length < 15) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        ErrorHandler.showWarning(
          context,
          'صف نفسك: ١٥ حرفاً على الأقل أو اترك الحقل فارغاً',
        );
        return;
      }
      if (about.length > 300) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        ErrorHandler.showWarning(
          context,
          'صف نفسك: ٣٠٠ حرف كحد أقصى',
        );
        return;
      }

      await _client.from('brides').update({
        'requirements': _buildRequirementsJson(),
        'interests': about,
      }).eq('user_id', userId);

      if (!mounted) return;

      ErrorHandler.showSuccess(
        context,
        'تم تحديث الملف بنجاح',
      );

      await Future.delayed(
        const Duration(milliseconds: 800),
      );

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      debugPrint('🔴 Save requirements error: $e');

      if (!mounted) return;

      ErrorHandler.showError(
        context,
        e,
        customMessage: 'فشل تحديث المتطلبات',
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ============================================================
  // الواجهة
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: IslamicScaffold(
        appBar: IslamicAppBar(
          title: tr('edit_profile'),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ═══ بطاقة توضيحية ═══
                    _buildHeaderCard(),

                    const SizedBox(height: 16),

                    _buildSection(
                      title: 'نبذة عنك',
                      icon: Icons.notes_rounded,
                      children: [
                        AppTextField(
                          controller: _selfDescription,
                          label: 'صف نفسك بشكل مختصر',
                          hint:
                              'جملة قصيرة عن شخصيتك (١٥–٣٠٠ حرف).',
                          required: false,
                          maxLines: 4,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ═══ المتطلبات الأساسية ═══
                    _buildSection(
                      title: 'المتطلبات الأساسية',
                      icon: Icons.person_outline_rounded,
                      children: [
                        _multi(
                          'المحافظة',
                          _governorates,
                          _reqGovernorate,
                          (v) => setState(() => _reqGovernorate = v),
                        ),
                        _multi(
                          'محافظة الإقامة',
                          _governorates,
                          _reqResidence,
                          (v) => setState(() => _reqResidence = v),
                        ),
                        _multi(
                          'الدراسة',
                          _educationLevels,
                          _reqEducation,
                          (v) => setState(() => _reqEducation = v),
                        ),
                        _multi(
                          'العمر',
                          _ageRanges,
                          _reqAge,
                          (v) => setState(() => _reqAge = v),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ═══ الحالة المادية ═══
                    _buildSection(
                      title: 'الحالة المادية',
                      icon: Icons.payments_outlined,
                      children: [
                        _multi(
                          'الدخل الشهري',
                          _incomeRanges,
                          _reqIncome,
                          (v) => setState(() => _reqIncome = v),
                        ),
                        _multi(
                          'الحالة المادية',
                          _financialLevels,
                          _reqFinancial,
                          (v) => setState(() => _reqFinancial = v),
                        ),
                        _multi(
                          'السكن',
                          _housingTypes,
                          _reqHousing,
                          (v) => setState(() => _reqHousing = v),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ═══ الصحة والعادات ═══
                    _buildSection(
                      title: 'الصحة والعادات',
                      icon: Icons.health_and_safety_outlined,
                      children: [
                        _multi(
                          'التدخين',
                          _yesNo,
                          _reqSmoking,
                          (v) => setState(() => _reqSmoking = v),
                        ),
                        _multi(
                          'النرجيلة',
                          _yesNo,
                          _reqHookah,
                          (v) => setState(() => _reqHookah = v),
                        ),
                        _multi(
                          'الالتزام الديني',
                          _religiousLevels,
                          _reqReligious,
                          (v) => setState(() => _reqReligious = v),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ═══ المواصفات الجسدية ═══
                    _buildSection(
                      title: 'المواصفات الجسدية',
                      icon: Icons.face_retouching_natural_rounded,
                      children: [
                        _multi(
                          'الطول',
                          _heightRanges,
                          _reqHeight,
                          (v) => setState(() => _reqHeight = v),
                        ),
                        _multi(
                          'الوزن',
                          _weightRanges,
                          _reqWeight,
                          (v) => setState(() => _reqWeight = v),
                        ),
                        _multi(
                          'لون البشرة',
                          _skins,
                          _reqSkin,
                          (v) => setState(() => _reqSkin = v),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ═══ زر الحفظ ═══
                    IslamicButton(
                      label: _isSaving
                          ? 'جارٍ الحفظ...'
                          : 'حفظ المتطلبات',
                      icon: _isSaving
                          ? null
                          : const Icon(
                              Icons.save_rounded,
                              color: AppColors.textOnPrimary,
                              size: 22,
                            ),
                      onPressed: _isSaving ? null : _saveProfile,
                      isLoading: _isSaving,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ============================================================
  // بطاقة توضيحية
  // ============================================================

  Widget _buildHeaderCard() {
    return IslamicCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.checklist_rounded,
              color: AppColors.primary,
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'متطلباتك من العريس',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'حددي المواصفات التي يجب أن تتوفر في العريس. اتركي أي حقل فارغاً إذا لم يكن شرطاً.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.5,
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

  // ============================================================
  // قسم
  // ============================================================

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return IslamicCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // Multi-Select موحّد
  // ============================================================

  Widget _multi(
    String label,
    List<String> options,
    List<String> selected,
    ValueChanged<List<String>> onChanged,
  ) {
    return AppMultiSelect(
      label: label,
      options: options,
      selected: selected,
      onChanged: onChanged,
      required: false,
    );
  }
}