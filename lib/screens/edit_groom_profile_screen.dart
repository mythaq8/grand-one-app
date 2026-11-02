// lib/screens/edit_groom_profile_screen.dart
// ============================================================
// تعديل ملف الشاب — حقول قابلة للتحديث بعد التسجيل
// ------------------------------------------------------------
// لا يغيّر الاسم أو الهاتف أو تاريخ الميلاد أو رمز الشاب؛
// هذه تبقى ثابتة بعد التحقق. للتغييرات الحساسة: تواصل مع الإدارة.
// ============================================================

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../utils/error_handler.dart';
import '../widgets/form_fields.dart';
import '../widgets/islamic_decorations.dart';

class EditGroomProfileScreen extends StatefulWidget {
  const EditGroomProfileScreen({super.key});

  @override
  State<EditGroomProfileScreen> createState() => _EditGroomProfileScreenState();
}

class _EditGroomProfileScreenState extends State<EditGroomProfileScreen> {
  final _client = Supabase.instance.client;

  bool _isLoading = true;
  bool _isSaving = false;

  final _job = TextEditingController();
  final _properties = TextEditingController();
  final _educationDetails = TextEditingController();
  final _selfDescription = TextEditingController();

  String? _income;
  String? _financial;
  String? _housingType;
  String? _marriageReady;
  String? _smoking;
  String? _hookah;
  String? _religiousCommitment;
  String? _height;
  String? _weight;
  String? _skin;
  List<String> _languages = [];

  static const _incomeLevels = [
    'أقل من 100\$',
    '100-200\$',
    '200-400\$',
    '400-600\$',
    '600-1000\$',
    'أكثر من 1000\$',
  ];
  static const _financialLevels = ['ضعيفة', 'متوسطة', 'جيدة', 'ممتازة'];
  static const _housingTypes = ['إيجار', 'ملك'];
  static const _yesNo = ['نعم', 'لا'];
  static const _marriageReadyOptions = [
    'جاهز خلال شهر',
    'جاهز خلال 3 أشهر',
    'جاهز خلال 6 أشهر',
    'جاهز خلال سنة',
    'جاهز خلال سنتين',
  ];
  static const _religiousLevels = [
    'ضعيف جداً',
    'ضعيف',
    'وسط',
    'جيد',
    'جيد جداً',
    'ممتاز',
  ];
  static const _heightRanges = [
    '130-140',
    '140-150',
    '150-160',
    '160-170',
    '170-180',
    '180-190',
    '190-200',
  ];
  static const _weightRanges = [
    '50-60',
    '60-70',
    '70-80',
    '80-90',
    '90-100',
    '100-110',
    '110-120',
  ];
  static const _skinColors = ['أبيض', 'حنطي', 'أسمر'];
  static const _languageOptions = [
    'العربية',
    'الإنجليزية',
    'الفرنسية',
    'الألمانية',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _job.dispose();
    _properties.dispose();
    _educationDetails.dispose();
    _selfDescription.dispose();
    super.dispose();
  }

  String? _inList(String? value, List<String> items) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.trim();
    return items.contains(v) ? v : null;
  }

  int _rangeStart(String? range, int fallback) {
    if (range == null || range.isEmpty) return fallback;
    final part = range.split('-').first.trim();
    return int.tryParse(part) ?? fallback;
  }

  String? _rangeFromStored(dynamic value, List<String> ranges) {
    final n = value is int
        ? value
        : int.tryParse(value?.toString().trim() ?? '');
    if (n == null) return null;
    for (final r in ranges) {
      final parts = r.split('-');
      if (parts.length != 2) continue;
      final a = int.tryParse(parts[0].trim());
      final b = int.tryParse(parts[1].trim());
      if (a != null && b != null && n >= a && n <= b) return r;
    }
    return null;
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final data = await _client
          .from('grooms')
          .select(
            'job_title, income, financial_status, housing_type, properties, '
            'marriage_ready, smoking, hookah, religious_commitment, '
            'education_details, height_cm, weight_kg, skin_color, languages, '
            'interests',
          )
          .eq('user_id', userId)
          .maybeSingle();

      if (!mounted) return;
      if (data == null) {
        setState(() => _isLoading = false);
        return;
      }

      setState(() {
        _job.text = data['job_title']?.toString() ?? '';
        _properties.text = data['properties']?.toString() ?? '';
        _educationDetails.text = data['education_details']?.toString() ?? '';
        _selfDescription.text = data['interests']?.toString() ?? '';
        _income = _inList(data['income']?.toString(), _incomeLevels);
        _financial =
            _inList(data['financial_status']?.toString(), _financialLevels);
        _housingType =
            _inList(data['housing_type']?.toString(), _housingTypes);
        _marriageReady =
            _inList(data['marriage_ready']?.toString(), _marriageReadyOptions);
        _smoking = _inList(data['smoking']?.toString(), _yesNo);
        _hookah = _inList(data['hookah']?.toString(), _yesNo);
        _religiousCommitment = _inList(
          data['religious_commitment']?.toString(),
          _religiousLevels,
        );
        _skin = _inList(data['skin_color']?.toString(), _skinColors);
        _height = _rangeFromStored(data['height_cm'], _heightRanges);
        _weight = _rangeFromStored(data['weight_kg'], _weightRanges);
        final langs = data['languages']?.toString().trim() ?? '';
        _languages = langs.isEmpty
            ? <String>[]
            : langs
                .split(',')
                .map((e) => e.trim())
                .where((e) => _languageOptions.contains(e))
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Edit groom load: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorHandler.showError(context, e);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _isSaving = false);
        return;
      }

      final about = _selfDescription.text.trim();
      if (about.isNotEmpty && about.length < 15) {
        if (mounted) {
          setState(() => _isSaving = false);
          ErrorHandler.showWarning(
            context,
            'صف نفسك: ١٥ حرفاً على الأقل أو اترك الحقل فارغاً',
          );
        }
        return;
      }
      if (about.length > 300) {
        if (mounted) {
          setState(() => _isSaving = false);
          ErrorHandler.showWarning(
            context,
            'صف نفسك: ٣٠٠ حرف كحد أقصى',
          );
        }
        return;
      }

      await _client.from('grooms').update({
        'job_title': _job.text.trim(),
        'income': _income,
        'financial_status': _financial,
        'housing_type': _housingType,
        'properties': _properties.text.trim(),
        'marriage_ready': _marriageReady,
        'smoking': _smoking,
        'hookah': _hookah,
        'religious_commitment': _religiousCommitment,
        'education_details': _educationDetails.text.trim(),
        'height_cm': _rangeStart(_height, 170),
        'weight_kg': _rangeStart(_weight, 70),
        'skin_color': _skin,
        'languages': _languages.join(', '),
        'interests': about,
      }).eq('user_id', userId);

      if (!mounted) return;
      ErrorHandler.showSuccess(context, 'تم تحديث الملف بنجاح');
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Edit groom save: $e');
      if (!mounted) return;
      ErrorHandler.showError(
        context,
        e,
        customMessage:
            'تعذر الحفظ. إن استمر الخطأ تواصل مع الإدارة لتعديل بياناتك.',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: IslamicScaffold(
        appBar: const IslamicAppBar(title: 'تعديل الملف الشخصي'),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.goldSoft,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Text(
                              'يمكنك تحديث بيانات العمل والسكن والمظهر والالتزام. '
                              'الاسم والهاتف وتاريخ الميلاد لا تُعدَّل من هنا.',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                                height: 1.5,
                                color: AppColors.goldDeep,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _selfDescription,
                            label: 'صف نفسك بشكل مختصر',
                            hint: 'جملة قصيرة عن شخصيتك (١٥–٣٠٠ حرف).',
                            required: false,
                            maxLines: 4,
                          ),
                          AppDropdown(
                            label: 'الجاهزية للزواج',
                            items: _marriageReadyOptions,
                            current: _marriageReady,
                            onChange: (v) =>
                                setState(() => _marriageReady = v),
                          ),
                          AppDropdown(
                            label: 'الالتزام الديني',
                            items: _religiousLevels,
                            current: _religiousCommitment,
                            onChange: (v) =>
                                setState(() => _religiousCommitment = v),
                          ),
                          AppTextField(
                            controller: _job,
                            label: 'المهنة',
                            required: false,
                          ),
                          AppDropdown(
                            label: 'الدخل',
                            items: _incomeLevels,
                            current: _income,
                            onChange: (v) => setState(() => _income = v),
                          ),
                          AppDropdown(
                            label: 'الحالة المادية',
                            items: _financialLevels,
                            current: _financial,
                            onChange: (v) => setState(() => _financial = v),
                          ),
                          AppDropdown(
                            label: 'السكن',
                            items: _housingTypes,
                            current: _housingType,
                            onChange: (v) => setState(() => _housingType = v),
                          ),
                          AppTextField(
                            controller: _properties,
                            label: 'الممتلكات',
                            required: false,
                          ),
                          AppTextField(
                            controller: _educationDetails,
                            label: 'تفاصيل التعليم',
                            required: false,
                          ),
                          AppDropdown(
                            label: 'الطول',
                            items: _heightRanges,
                            current: _height,
                            onChange: (v) => setState(() => _height = v),
                          ),
                          AppDropdown(
                            label: 'الوزن',
                            items: _weightRanges,
                            current: _weight,
                            onChange: (v) => setState(() => _weight = v),
                          ),
                          AppDropdown(
                            label: 'لون البشرة',
                            items: _skinColors,
                            current: _skin,
                            onChange: (v) => setState(() => _skin = v),
                          ),
                          AppDropdown(
                            label: 'التدخين',
                            items: _yesNo,
                            current: _smoking,
                            onChange: (v) => setState(() => _smoking = v),
                          ),
                          AppDropdown(
                            label: 'النرجيلة',
                            items: _yesNo,
                            current: _hookah,
                            onChange: (v) => setState(() => _hookah = v),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'اللغات',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final lang in _languageOptions)
                                FilterChip(
                                  label: Text(lang),
                                  selected: _languages.contains(lang),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _languages = [..._languages, lang];
                                      } else {
                                        _languages = _languages
                                            .where((e) => e != lang)
                                            .toList();
                                      }
                                    });
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: IslamicButton(
                        label: 'حفظ التعديلات',
                        onPressed: _isSaving ? null : _save,
                        isLoading: _isSaving,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
