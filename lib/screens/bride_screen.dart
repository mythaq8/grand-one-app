// lib/screens/bride_screen.dart
// ============================================================
// BrideProfileSetupScreen — تسجيل ملف الفتاة (7 مراحل)
// ============================================================

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/session_service.dart';
import '../utils/error_handler.dart';
import '../app_colors.dart';
import '../widgets/islamic_decorations.dart';
import '../widgets/form_fields.dart';
import 'waiting_screen.dart';

class BrideProfileSetupScreen extends StatefulWidget {
  const BrideProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<BrideProfileSetupScreen> createState() =>
      _BrideProfileSetupScreenState();
}

class _BrideProfileSetupScreenState extends State<BrideProfileSetupScreen> {
  int _step = 0;
  final _key = GlobalKey<FormState>();
  final _formScroll = ScrollController();

  /// مسار الصورة الشخصية (تظهر للإدارة وللشاب بعد موافقة التطابق)
  String? _personalPhotoPath;

  bool _isSubmitting = false;
  bool _isUploadingPersonalPhoto = false;

  bool get _isPersonalPhotoUploaded => _personalPhotoPath != null;

  final _fullName = TextEditingController();
  final _guardianName = TextEditingController();
  final _guardianPhone = TextEditingController();

  String? _kinship;
  String? _age;
  String? _governorate;
  String? _residence;

  String? _hairColor;
  String? _hairType;
  String? _eyeColor;
  String? _skin;
  String? _height;
  String? _weight;
  String? _beauty;

  String? _chronicDisease;
  final _chronicDiseaseName = TextEditingController();
  String? _birthDefect;
  final _birthDefectName = TextEditingController();

  String? _smoking;
  String? _hookah;
  String? _religiousCommitment;
  String? _hijab;

  String? _education;
  final _educationDetails = TextEditingController();
  final _selfDescription = TextEditingController();
  String? _social;

  List<String> _languages = [];

  // ============================================================
  // الميزات الرسمية للعروس
  // ============================================================
  List<String> _featureReligiousStudy = [];
  List<String> _featureQuran = [];
  List<String> _featureHousing = [];
  List<String> _featurePolygamy = [];
  List<String> _featureLowMahr = [];
  List<String> _featureHighFinancial = [];

  // ============================================================
  // متطلبات العروس الرسمية من العريس
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

  final _client = Supabase.instance.client;

  final List<String> _kinships = [
    'أب', 'أخ', 'عم',  'جد', 'والدة/وكيل',
  ];

  final List<String> _ages =
      List.generate(33, (i) => '${18 + i}');

  final List<String> _governorates = [
    'دمشق', 'ريف دمشق', 'حلب', 'حمص', 'حماة', 'اللاذقية', 'طرطوس',
    'إدلب', 'دير الزور', 'الرقة', 'الحسكة', 'درعا', 'السويداء', 'القنيطرة',
  ];

  final List<String> _hairColors = ['أسود', 'بني', 'أشقر', 'أحمر', 'رمادي'];
  final List<String> _hairTypes = ['ناعم', 'خشن', 'مجعد', 'مموج'];
  final List<String> _eyeColors = [
    'بني', 'أسود', 'أزرق', 'أخضر', 'عسلي', 'رمادي',
  ];
  final List<String> _skins = ['بيضاء', 'حنطية', 'سمراء'];
  final List<String> _heightRanges = [
    '140-150', '150-160', '160-170', '170-180', '180-190',
  ];
  final List<String> _weightRanges = [
    '40-50', '50-60', '60-70', '70-80', '80-90', '90-100', '100-110',
  ];
  final List<String> _beautyLevels = [
    'عادي جداً', 'عادي', 'جيد', 'جيد جداً',
  ];
  final List<String> _yesNo = ['نعم', 'لا'];
  final List<String> _religiousLevels = [
    'ضعيف جداً', 'ضعيف', 'وسط', 'جيد', 'جيد جداً', 'ممتاز',
  ];
  final List<String> _hijabs = ['حجاب', 'حجاب كامل', 'خمار'];
  final List<String> _educationLevels = [
    'تاسع',
    'بكلوريا علمي',
    'بكلوريا أدبي',
    'دراسة جامعية',
    'لا يوجد',
  ];
  final List<String> _socials = ['عزباء', 'مطلقة', 'أرملة'];
  final List<String> _languageOptions = [
    'العربية', 'الإنجليزية', 'الفرنسية', 'الألمانية',
  ];

  final List<String> _incomeRanges = [
    '<100\$',
    '100-200\$',
    '200-400\$',
    '400-600\$',
    '600-1000\$',
    '>1000\$',
  ];

  final List<String> _groomFinancialLevels = [
    'ضعيفة', 'متوسطة', 'جيدة', 'ممتازة',
  ];
  final List<String> _groomHousingTypes = ['إيجار', 'ملك'];
  final List<String> _groomEducationLevels = [
    'تاسع', 'بكلوريا علمي', 'بكلوريا أدبي', 'لا يوجد', 'دراسة جامعية',
  ];

  final List<String> _ageRanges = [
    '18-20', '21-23', '24-26', '27-29', '30-32',
    '33-35', '36-38', '39-41', '42-45', '46-50',
  ];

  final List<String> _groomHeightRanges = [
    '130-140', '140-150', '150-160', '160-170', '170-180',
    '180-190', '190-200',
  ];

  final List<String> _groomWeightRanges = [
    '50-60', '60-70', '70-80', '80-90', '90-100', '100-110', '110-120',
  ];

  final List<String> _stepTitles = [
    'الولي والتحقق',
    'البيانات الشخصية',
    'المظهر الخارجي',
    'الصحة والعادات',
    'التعليم واللغات',
    'الميزات',
    'المتطلبات',
  ];

  final List<IconData> _stepIcons = [
    Icons.verified_user_outlined,
    Icons.person_outline_rounded,
    Icons.face_retouching_natural_rounded,
    Icons.health_and_safety_outlined,
    Icons.school_outlined,
    Icons.auto_awesome_outlined,
    Icons.rule_outlined,
  ];

  @override
  void dispose() {
    _fullName.dispose();
    _guardianName.dispose();
    _guardianPhone.dispose();
    _chronicDiseaseName.dispose();
    _birthDefectName.dispose();
    _educationDetails.dispose();
    _selfDescription.dispose();
    _formScroll.dispose();
    super.dispose();
  }

  // ============================================================
  // جمع جميع الحقول المطلوبة المفقودة
  // ============================================================

  List<String> _missingForStep(int step) {
    final missing = <String>[];

    if (step == 0) {
      if (_fullName.text.trim().isEmpty) {
        missing.add('الاسم الكامل');
      }
      if (_guardianName.text.trim().isEmpty) {
        missing.add('اسم الولي');
      }
      if (_kinship == null) {
        missing.add('صلة القرابة');
      }
      if (_guardianPhone.text.trim().isEmpty) {
        missing.add('رقم جوال الولي');
      } else if (!RegExp(r'^09\d{8}$')
          .hasMatch(_guardianPhone.text.trim())) {
        missing.add('رقم الجوال (يجب أن يبدأ بـ 09 ويتكون من 10 أرقام)');
      }
      if (!_isPersonalPhotoUploaded) missing.add('الصورة الشخصية');
    }

    if (step == 1) {
      if (_age == null) missing.add('العمر');
      if (_social == null) missing.add('الحالة الاجتماعية');
      if (_governorate == null) missing.add('المحافظة');
      if (_residence == null) missing.add('محافظة الإقامة');
      if (_religiousCommitment == null) {
        missing.add('الالتزام الديني');
      }
      if (_hijab == null) missing.add('نوع الحجاب');
      final about = _selfDescription.text.trim();
      if (about.length < 15) {
        missing.add('صف نفسك (١٥ حرفاً على الأقل)');
      } else if (about.length > 300) {
        missing.add('صف نفسك (٣٠٠ حرف كحد أقصى)');
      }
    }

    if (step == 2) {
      if (_hairColor == null) missing.add('لون الشعر');
      if (_hairType == null) missing.add('نوعية الشعر');
      if (_eyeColor == null) missing.add('لون العيون');
      if (_skin == null) missing.add('لون البشرة');
      if (_height == null) missing.add('الطول');
      if (_weight == null) missing.add('الوزن');
      if (_beauty == null) missing.add('مستوى الجمال');
    }

    if (step == 3) {
      if (_chronicDisease == null) missing.add('الأمراض المزمنة');
      if (_chronicDisease == 'نعم' &&
          _chronicDiseaseName.text.trim().isEmpty) {
        missing.add('اسم المرض');
      }
      if (_birthDefect == null) missing.add('العيوب الخلقية');
      if (_birthDefect == 'نعم' && _birthDefectName.text.trim().isEmpty) {
        missing.add('اسم العيب');
      }
      if (_smoking == null) missing.add('التدخين');
      if (_hookah == null) missing.add('النرجيلة');
    }

    if (step == 4) {
      if (_education == null) missing.add('التحصيل العلمي');
      if (_languages.isEmpty) missing.add('اللغات');
    }

    return missing;
  }

  List<String> _collectMissingFields() {
    final missing = <String>[];
    for (var step = 0; step < 7; step++) {
      missing.addAll(_missingForStep(step));
    }
    return missing;
  }

  bool _validateCurrentStep() {
    final missing = _missingForStep(_step);
    if (missing.isEmpty) return true;

    if (missing.length == 1) {
      ErrorHandler.showWarning(
        context,
        'الحقل التالي مطلوب: ${missing.first}',
      );
    } else {
      ErrorHandler.showWarning(
        context,
        'الحقول التالية مطلوبة:\n• ${missing.join('\n• ')}',
      );
    }
    return false;
  }

  void _scrollFormToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_formScroll.hasClients) return;
      _formScroll.jumpTo(0);
    });
  }

  void _nextStep() {
    if (_step < 6) {
      if (!_validateCurrentStep()) return;
      setState(() => _step++);
      _scrollFormToTop();
      return;
    }
    _submit();
  }

  void _previousStep() {
    if (_step == 0 || _isSubmitting) return;
    setState(() => _step--);
    _scrollFormToTop();
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildStepOne();
      case 1:
        return _buildStepTwo();
      case 2:
        return _buildStepThree();
      case 3:
        return _buildStepFour();
      case 4:
        return _buildStepFive();
      case 5:
        return _buildStepSix();
      case 6:
        return _buildStepSeven();
      default:
        return const SizedBox.shrink();
    }
  }

  // ============================================================
  // رفع الصورة الشخصية
  // ============================================================

  Future<void> _pickPersonalPhoto() async {
    if (_isUploadingPersonalPhoto) return;

    setState(() => _isUploadingPersonalPhoto = true);

    try {
      final files = await fp.FilePicker.pickFiles(
        type: fp.FileType.image,
      );

      if (files.isEmpty) return;

      final file = files.first;
      var bytes = await file.xFile.readAsBytes();

      try {
        final compressed =
            await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 400,
          minHeight: 400,
          quality: 60,
        );
        if (compressed.isNotEmpty) bytes = compressed;
      } catch (_) {}

      final fileName =
          'brides/photo_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _client.storage
          .from('profile_photos')
          .uploadBinary(fileName, bytes);

      if (!mounted) return;

      setState(() {
        _personalPhotoPath = fileName;
      });

      ErrorHandler.showSuccess(
        context,
        'تم رفع الصورة الشخصية بنجاح',
      );
    } catch (e) {
      debugPrint('🔴 Bride personal photo upload error: $e');
      if (mounted) ErrorHandler.showError(context, e);
    } finally {
      if (mounted) {
        setState(() => _isUploadingPersonalPhoto = false);
      }
    }
  }

  void _showRequiredMessage(String field) {
    ErrorHandler.showWarning(
      context,
      'الحقل الإجباري غير مملوء: $field',
    );
  }

  // ============================================================
  // بناء Features JSON
  // ============================================================

  Map<String, dynamic> _buildFeaturesJson() {
    return {
      'religious_study': List<String>.from(_featureReligiousStudy),
      'quran_memorization': List<String>.from(_featureQuran),
      'secured_housing': List<String>.from(_featureHousing),
      'accept_polygamy': List<String>.from(_featurePolygamy),
      'reduced_mahr': List<String>.from(_featureLowMahr),
      'high_financial_status': List<String>.from(_featureHighFinancial),
    };
  }

  // ============================================================
  // بناء Requirements JSON
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
  // الإرسال
  // ============================================================

  Future<void> _submit() async {
    if (_isSubmitting) return;

    // ═══ جمع الحقول المفقودة (بدل الإرجاع عند أول خطأ) ═══
    final missing = _collectMissingFields();

    if (missing.isNotEmpty) {
      if (missing.length == 1) {
        ErrorHandler.showWarning(
          context,
          'الحقل التالي مطلوب: ${missing.first}',
        );
      } else {
        ErrorHandler.showWarning(
          context,
          'الحقول التالية مطلوبة:\n• ${missing.join('\n• ')}',
        );
      }
      return;
    }

    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/verify');
      }
      return;
    }

    setState(() => _isSubmitting = true);

    // ═══ حماية من الإدراج المزدوج ═══
    try {
      final existing = await _client
          .from('brides')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        if (mounted) {
          ErrorHandler.showWarning(
            context,
            'لديك ملف مسجل بالفعل. يرجى التواصل مع الإدارة.',
          );
          setState(() => _isSubmitting = false);
        }
        return;
      }
    } catch (e) {
      debugPrint('Check existing bride error: $e');
      // نكمل — إذا فشل الفحص، نحاول الإدراج
    }

    final brideCode =
        'SY-${DateTime.now().microsecondsSinceEpoch.toRadixString(36).toUpperCase()}';

    try {
      // ============================================================
      // 1. إنشاء سجل الولي
      // ============================================================
      final guardianRes = await _client
          .from('guardians')
          .insert({
            'user_id': userId,
            'name': _guardianName.text.trim(),
            'phone_number': _guardianPhone.text.trim(),
            'identifier': userId,
            'kinship':_kinship,
          })
          .select('id')
          .single();

      final guardianId = guardianRes['id'];

      if (guardianId == null) {
        throw Exception('فشل إنشاء سجل الولي');
      }

      // ============================================================
      // 2. إنشاء سجل الفتاة
      // ============================================================
      await _client.from('brides').insert({
        'user_id': userId,
        'full_name': _fullName.text.trim(),
        'guardian_id': guardianId,
        'anonymous_code': brideCode,
        'birth_date': _calculateBirthDate().toIso8601String(),
        'current_governorate': _governorate,
        'current_residence': _residence,
        'hair_color': _hairColor,
        'hair_type': _hairType,
        'eye_color': _eyeColor,
        'skin_color': _skin,
        'height_cm': int.parse(_height?.split('-')[0] ?? '150'),
        'weight_kg': int.parse(_weight?.split('-')[0] ?? '50'),
        'beauty_level': _beauty,
        'chronic_disease': _chronicDisease == 'نعم'
            ? _chronicDiseaseName.text.trim()
            : 'لا',
        'birth_defect': _birthDefect == 'نعم'
            ? _birthDefectName.text.trim()
            : 'لا',
        'smoking': _smoking,
        'hookah': _hookah,
        'religious_commitment': _religiousCommitment,
        'hijab_status': _hijab,
        'education_level': _education,
        'education_details': _educationDetails.text.trim(),
        'languages': _languages.join(', '),
        'social_status': _social,
        'interests': _selfDescription.text.trim(),
        'features': _buildFeaturesJson(),
        'requirements': _buildRequirementsJson(),
        'personal_photo': _personalPhotoPath,
        'identifier': userId,
        'is_verified': false,
      });

      await SessionService.saveBrideCode(brideCode);

      if (!mounted) return;

      ErrorHandler.showSuccess(
        context,
        'تم إرسال البيانات. بانتظار موافقة المشرف على إنشاء الحساب',
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const WaitingScreen(),
        ),
      );
    } catch (e) {
      debugPrint('Bride submit error: $e');

      if (mounted) {
        final detail = e is PostgrestException
            ? (e.message.trim().isNotEmpty ? e.message : 'فشل حفظ البيانات')
            : 'فشل حفظ البيانات';
        ErrorHandler.showError(
          context,
          e,
          customMessage: detail,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ============================================================
  // حساب تاريخ الميلاد
  // ============================================================

  DateTime _calculateBirthDate() {
    final age = int.tryParse(_age ?? '18') ?? 18;
    final now = DateTime.now();

    // ═══ نستخدم 1 يناير من السنة التقريبية ═══
    // (لأن الفورم يطلب العمر وليس تاريخ الميلاد)
    return DateTime(now.year - age, 1, 1);
  }

  // ============================================================
  // الواجهة
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: IslamicScaffold(
        showPattern: false,
        appBar: IslamicAppBar(
          title: 'تسجيل ملف الفتاة',
          accentColor: AppColors.brideAccent,
          actions: [
            IconButton(
              tooltip: 'الإعدادات',
              icon: const Icon(
                Icons.settings_outlined,
                color: AppColors.textOnPrimary,
              ),
              onPressed: () =>
                  Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        body: Form(
          key: _key,
          child: Column(
            children: [
              _buildProgressHeader(),
              Expanded(
                child: SingleChildScrollView(
                  controller: _formScroll,
                  padding:
                      const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: _buildCurrentStep(),
                ),
              ),
              _buildNavigationBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // رأس التقدم
  // ============================================================

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _stepIcons[_step],
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المرحلة ${_step + 1} من 7',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _stepTitles[_step],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${((_step + 1) / 7 * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.goldDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: (_step + 1) / 7,
              backgroundColor: AppColors.borderLight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // الخطوة 1: المعلومات الشخصية
  // ============================================================

  Widget _buildStepOne() {
    return _buildStepCard(
      title: 'الولي والصورة',
      subtitle:
          'بيانات الولي الشرعي والصورة الشخصية. هذه المرحلة أساس تفعيل الحساب.',
      icon: Icons.family_restroom_outlined,
      children: [
        _sectionLabel('بيانات الفتاة والولي'),
        AppTextField(
          controller: _fullName,
          label: 'الاسم الكامل للفتاة',
          hint: 'الاسم الثلاثي.',
        ),
        AppTextField(
          controller: _guardianName,
          label: 'اسم الولي الشرعي',
          hint: 'ولي الأمر المسؤول عن الموافقة على مسار الزواج.',
        ),
        AppDropdown(
          label: 'صلة القرابة',
          hint: 'صلة الولي بالفتاة (أب، أخ، عم…).',
          items: _kinships,
          current: _kinship,
          onChange: (v) => setState(() => _kinship = v),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'رقم جوال ولي الأمر *',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'للتواصل الرسمي عند الحاجة. الصيغة: 09xxxxxxxx',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 7),
              TextFormField(
                controller: _guardianPhone,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                decoration: _inputDecoration(
                  label: 'رقم الجوال',
                  hint: '09xxxxxxxx',
                  icon: Icons.phone_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الرجاء إدخال رقم ولي الأمر';
                  }
                  if (!RegExp(r'^09\d{8}$').hasMatch(value.trim())) {
                    return 'الرجاء إدخال رقم صحيح (09xxxxxxxx)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        _sectionLabel('الصورة الشخصية'),
        _buildPersonalPhotoCard(),
      ],
    );
  }

  // ============================================================
  // الخطوة 2: البيانات الشخصية
  // ============================================================

  Widget _buildStepTwo() {
    return _buildStepCard(
      title: 'البيانات الشخصية',
      subtitle:
          'معلومات عامة تظهر في الملف للمطابقة الجادة مع الباحثين عن الزواج.',
      icon: Icons.person_outline_rounded,
      children: [
        _sectionLabel('البيانات الأساسية'),
        AppDropdown(
          label: 'العمر',
          hint: 'العمر الحالي بالسنوات الكاملة.',
          items: _ages,
          current: _age,
          onChange: (v) => setState(() => _age = v),
        ),
        AppDropdown(
          label: 'الحالة الاجتماعية',
          hint: 'تساعد في فلترة الطلبات المناسبة.',
          items: _socials,
          current: _social,
          onChange: (v) => setState(() => _social = v),
        ),
        _sectionLabel('مكان الإقامة'),
        AppDropdown(
          label: 'المحافظة',
          hint: 'محافظة الأصل أو القيد.',
          items: _governorates,
          current: _governorate,
          onChange: (v) => setState(() => _governorate = v),
        ),
        AppDropdown(
          label: 'محافظة الإقامة',
          hint: 'المحافظة التي تقيمين فيها حالياً.',
          items: _governorates,
          current: _residence,
          onChange: (v) => setState(() => _residence = v),
        ),
        _sectionLabel('الالتزام والمظهر الشرعي'),
        AppDropdown(
          label: 'الالتزام الديني',
          hint: 'تقييم عام لمستوى الالتزام كما ترينه مناسباً للملف.',
          items: _religiousLevels,
          current: _religiousCommitment,
          onChange: (v) => setState(() => _religiousCommitment = v),
        ),
        AppDropdown(
          label: 'نوع الحجاب',
          hint: 'اختر الوصف الأقرب لواقعك.',
          items: _hijabs,
          current: _hijab,
          onChange: (v) => setState(() => _hijab = v),
        ),
        _sectionLabel('نبذة عنك'),
        AppTextField(
          controller: _selfDescription,
          label: 'صف نفسك بشكل مختصر',
          hint:
              'جملة قصيرة عن شخصيتك وما تبحثين عنه في الزواج (١٥–٣٠٠ حرف).',
          maxLines: 4,
        ),
      ],
    );
  }

  // ============================================================
  // الخطوة 3: المظهر الخارجي
  // ============================================================

  Widget _buildStepThree() {
    return _buildStepCard(
      title: 'المظهر الخارجي',
      subtitle:
          'وصف عام للمظهر يساعد في التوافق. يُفضّل الصدق والدقة.',
      icon: Icons.face_retouching_natural_rounded,
      children: [
        _sectionLabel('الشعر والعيون والبشرة'),
        AppDropdown(
          label: 'لون الشعر',
          hint: 'اللون الطبيعي الغالب.',
          items: _hairColors,
          current: _hairColor,
          onChange: (v) => setState(() => _hairColor = v),
        ),
        AppDropdown(
          label: 'نوعية الشعر',
          hint: 'ملمس أو شكل الشعر العام.',
          items: _hairTypes,
          current: _hairType,
          onChange: (v) => setState(() => _hairType = v),
        ),
        AppDropdown(
          label: 'لون العيون',
          hint: 'اللون الأقرب لعينيك.',
          items: _eyeColors,
          current: _eyeColor,
          onChange: (v) => setState(() => _eyeColor = v),
        ),
        AppDropdown(
          label: 'لون البشرة',
          hint: 'اختر الوصف الأقرب دون مبالغة.',
          items: _skins,
          current: _skin,
          onChange: (v) => setState(() => _skin = v),
        ),
        _sectionLabel('القياسات والتقييم'),
        AppDropdown(
          label: 'الطول (سم)',
          hint: 'اختاري المجال الذي يقع فيه طولك.',
          items: _heightRanges,
          current: _height,
          onChange: (v) => setState(() => _height = v),
        ),
        AppDropdown(
          label: 'الوزن (كغ)',
          hint: 'اختاري المجال التقريبي لوزنك.',
          items: _weightRanges,
          current: _weight,
          onChange: (v) => setState(() => _weight = v),
        ),
        AppDropdown(
          label: 'مستوى الجمال',
          hint: 'تقييم ذاتي تقريبي يُستخدم للمطابقة فقط.',
          items: _beautyLevels,
          current: _beauty,
          onChange: (v) => setState(() => _beauty = v),
        ),
      ],
    );
  }

  // ============================================================
  // الخطوة 4: الصحة والعادات
  // ============================================================

  Widget _buildStepFour() {
    return _buildStepCard(
      title: 'الصحة والعادات',
      subtitle:
          'معلومات صحية وعادات مهمة للشفافية قبل بدء التواصل.',
      icon: Icons.health_and_safety_outlined,
      children: [
        _sectionLabel('الصحة'),
        AppDropdown(
          label: 'أمراض مزمنة',
          hint: 'إن وُجد مرض مزمن يُفضّل الإفصاح عنه بصدق.',
          items: _yesNo,
          current: _chronicDisease,
          onChange: (v) => setState(() => _chronicDisease = v),
        ),
        if (_chronicDisease == 'نعم')
          AppTextField(
            controller: _chronicDiseaseName,
            label: 'اسم المرض',
            hint: 'اكتبي الاسم باختصار ووضوح.',
          ),
        AppDropdown(
          label: 'عيوب خلقية',
          hint: 'أي عيب خلقي مؤثر يستحسن ذكره هنا.',
          items: _yesNo,
          current: _birthDefect,
          onChange: (v) => setState(() => _birthDefect = v),
        ),
        if (_birthDefect == 'نعم')
          AppTextField(
            controller: _birthDefectName,
            label: 'اسم العيب',
            hint: 'وصف مختصر يساعد على الوضوح.',
          ),
        _sectionLabel('العادات'),
        AppDropdown(
          label: 'التدخين',
          hint: 'هل تدخنين السجائر؟',
          items: _yesNo,
          current: _smoking,
          onChange: (v) => setState(() => _smoking = v),
        ),
        AppDropdown(
          label: 'النرجيلة',
          hint: 'هل تستخدمين النرجيلة؟',
          items: _yesNo,
          current: _hookah,
          onChange: (v) => setState(() => _hookah = v),
        ),
      ],
    );
  }

  // ============================================================
  // الخطوة 5: التعليم واللغات
  // ============================================================

  Widget _buildStepFive() {
    return _buildStepCard(
      title: 'التعليم واللغات',
      subtitle:
          'التحصيل واللغات لبناء صورة أوضح عن شخصيتك.',
      icon: Icons.school_outlined,
      children: [
        _sectionLabel('التعليم'),
        AppDropdown(
          label: 'التحصيل العلمي',
          hint: 'أعلى مرحلة دراسية وصلتِ إليها.',
          items: _educationLevels,
          current: _education,
          onChange: (v) => setState(() => _education = v),
        ),
        if (_education != null && _education != 'تاسع')
          AppTextField(
            controller: _educationDetails,
            label: 'تفاصيل $_education',
            hint: 'مثال: التخصص أو اسم الكلية (اختياري).',
            required: false,
          ),
        AppLanguagePicker(
          selected: _languages,
          options: _languageOptions,
          onChanged: (v) => setState(() => _languages = v),
          hint: 'اختاري اللغات التي تتقنينها.',
        ),
      ],
    );
  }

  // ============================================================
  // الخطوة 6: الميزات
  // ============================================================

  Widget _buildStepSix() {
    return _buildStepCard(
      title: 'الميزات',
      subtitle:
          'ما تحبين إظهاره في ملفك. اتركي أي بند فارغاً إن لم ينطبق.',
      icon: Icons.auto_awesome_outlined,
      children: [
        _sectionLabel('ميزات ترغبين بإظهارها'),
        _multi(
          'دراسة شرعية',
          _yesNo,
          _featureReligiousStudy,
          (v) => setState(() => _featureReligiousStudy = v),
          hint: 'هل لديكِ دراسة شرعية تريدين إبرازها؟',
        ),
        _multi(
          'حفظ القرآن الكريم',
          _yesNo,
          _featureQuran,
          (v) => setState(() => _featureQuran = v),
          hint: 'إن كنتِ حافظة أو لديكِ ورد منتظم.',
        ),
        _multi(
          'وجود سكن',
          _yesNo,
          _featureHousing,
          (v) => setState(() => _featureHousing = v),
          hint: 'هل يتوفر سكن مناسب ضمن ظروفك؟',
        ),
        _multi(
          'قبول التعدد',
          _yesNo,
          _featurePolygamy,
          (v) => setState(() => _featurePolygamy = v),
          hint: 'موقفك من التعدد إن طُرح لاحقاً.',
        ),
        _multi(
          'مهر منخفض جداً',
          _yesNo,
          _featureLowMahr,
          (v) => setState(() => _featureLowMahr = v),
          hint: 'إن كان المهر المطلوب منخفضاً نسبياً.',
        ),
        _multi(
          'حالة مادية مرتفعة',
          _yesNo,
          _featureHighFinancial,
          (v) => setState(() => _featureHighFinancial = v),
          hint: 'إن رغبتِ بالإشارة إلى وضع مادي مرتفع.',
        ),
      ],
    );
  }

  // ============================================================
  // الخطوة 7: المتطلبات
  // ============================================================

  Widget _buildStepSeven() {
    return _buildStepCard(
      title: 'المتطلبات',
      subtitle:
          'شروطك من العريس. اتركي أي بند فارغاً إن لم يكن شرطاً.',
      icon: Icons.rule_outlined,
      children: [
        _sectionLabel('متطلبات من العريس — الموقع'),
        _multi(
          'المحافظة',
          _governorates,
          _reqGovernorate,
          (v) => setState(() => _reqGovernorate = v),
          hint: 'محافظات مقبولة لأصل العريس. فارغ = لا شرط.',
        ),
        _multi(
          'محافظة الإقامة',
          _governorates,
          _reqResidence,
          (v) => setState(() => _reqResidence = v),
          hint: 'أين تقبلين أن يقيم العريس؟',
        ),
        _sectionLabel('متطلبات — العادات والالتزام'),
        _multi(
          'الالتزام الديني',
          _religiousLevels,
          _reqReligious,
          (v) => setState(() => _reqReligious = v),
          hint: 'مستوى الالتزام المطلوب تقريباً.',
        ),
        _multi(
          'التدخين',
          _yesNo,
          _reqSmoking,
          (v) => setState(() => _reqSmoking = v),
          hint: 'هل تقبلين مدخناً أم لا؟',
        ),
        _multi(
          'النرجيلة',
          _yesNo,
          _reqHookah,
          (v) => setState(() => _reqHookah = v),
          hint: 'موقفك من استخدام النرجيلة.',
        ),
        _sectionLabel('متطلبات — التعليم والمادة'),
        _multi(
          'الدراسة',
          _groomEducationLevels,
          _reqEducation,
          (v) => setState(() => _reqEducation = v),
          hint: 'المستويات الدراسية المقبولة.',
        ),
        _multi(
          'العمر',
          _ageRanges,
          _reqAge,
          (v) => setState(() => _reqAge = v),
          hint: 'الفئات العمرية المناسبة.',
        ),
        _multi(
          'الدخل الشهري',
          _incomeRanges,
          _reqIncome,
          (v) => setState(() => _reqIncome = v),
          hint: 'مجال الدخل المقبول تقريباً.',
        ),
        _multi(
          'الحالة المادية',
          _groomFinancialLevels,
          _reqFinancial,
          (v) => setState(() => _reqFinancial = v),
          hint: 'تقييم عام للوضع المادي.',
        ),
        _multi(
          'السكن',
          _groomHousingTypes,
          _reqHousing,
          (v) => setState(() => _reqHousing = v),
          hint: 'ملك أو إيجار — حسب ما تقبلينه.',
        ),
        _sectionLabel('متطلبات — المظهر'),
        _multi(
          'الطول',
          _groomHeightRanges,
          _reqHeight,
          (v) => setState(() => _reqHeight = v),
          hint: 'اختياري.',
        ),
        _multi(
          'الوزن',
          _groomWeightRanges,
          _reqWeight,
          (v) => setState(() => _reqWeight = v),
          hint: 'اختياري.',
        ),
        _multi(
          'لون البشرة',
          _skins,
          _reqSkin,
          (v) => setState(() => _reqSkin = v),
          hint: 'اختياري.',
        ),
      ],
    );
  }

  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
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
    ValueChanged<List<String>> onChanged, {
    String? hint,
  }) {
    return AppMultiSelect(
      label: label,
      hint: hint,
      options: options,
      selected: selected,
      onChanged: onChanged,
      required: false,
    );
  }

  // ============================================================
  // بطاقة الخطوة
  // ============================================================

  Widget _buildStepCard({
    required String title,
    required String subtitle,
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 23,
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPersonalPhotoCard() {
    final uploaded = _isPersonalPhotoUploaded;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            uploaded ? AppColors.successLight : AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: uploaded
              ? AppColors.success.withValues(alpha: 0.25)
              : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: uploaded
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  uploaded
                      ? Icons.verified_rounded
                      : Icons.photo_camera_outlined,
                  color: uploaded
                      ? AppColors.success
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الصورة الشخصية *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'تُراجعها الإدارة عند التحقق، وتُعرض للشاب فقط بعد موافقة الطرفين ودفع المستحقات وموافقة الإدارة.',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          IslamicButton(
            label: _isUploadingPersonalPhoto
                ? 'جارٍ الرفع...'
                : uploaded
                    ? 'تم رفع الصورة الشخصية'
                    : 'رفع الصورة الشخصية',
            onPressed: _isUploadingPersonalPhoto ? null : _pickPersonalPhoto,
            color: uploaded ? AppColors.success : AppColors.primary,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // شريط التنقل
  // ============================================================

  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Row(
        children: [
          if (_step > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.gold),
                  minimumSize: const Size.fromHeight(50),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'السابق',
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            // نفس العرض للزرّين حتى لا يُضغط «السابق» ويُقصّ نصّه.
            flex: 1,
            child: IslamicButton(
              label: _step < 6 ? 'التالي' : 'إنشاء الحساب',
              onPressed: _isSubmitting ? null : _nextStep,
              isLoading: _isSubmitting,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // تنسيق حقل الإدخال
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
    );
  }
}