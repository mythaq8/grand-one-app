// lib/screens/groom_screen.dart
// ============================================================
// GroomProfileSetupScreen — تسجيل ملف الشاب (4 مراحل)
// ============================================================

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/services.dart';

import '../services/session_service.dart';
import '../utils/error_handler.dart';
import '../app_colors.dart';
import '../widgets/islamic_decorations.dart';
import '../widgets/form_fields.dart';
import '../ui/shell/app_shell.dart';

class GroomProfileSetupScreen extends StatefulWidget {
  const GroomProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<GroomProfileSetupScreen> createState() =>
      _GroomProfileSetupScreenState();
}

class _GroomProfileSetupScreenState
    extends State<GroomProfileSetupScreen> {
  final _key = GlobalKey<FormState>();
  final _client = Supabase.instance.client;
  final _formScroll = ScrollController();

  int _step = 0;
  bool _isSubmitting = false;

  // ============================================================
  // مسارات الملفات المرفوعة
  // ============================================================

  String? _personalPhotoPath;

  bool _isUploadingPhoto = false;

  // ═══ Getters (مصدر حقيقة واحد) ═══
  bool get _isPhotoUploaded => _personalPhotoPath != null;

  // ============================================================
  // الحقول
  // ============================================================

  final _fullName = TextEditingController();
  final _fatherName = TextEditingController();
  final _country = TextEditingController();
  final _phoneController = TextEditingController();



  String? _age;
  String? _governorate;
  String? _residence;
  bool _isAbroad = false;

  String? _education;
  final _educationDetails = TextEditingController();
  final _job = TextEditingController();
  final _selfDescription = TextEditingController();
  String? _income;
  String? _financial;
  String? _housingType;
  final _properties = TextEditingController();

  String? _smoking;
  String? _hookah;
  String? _marriageReady;
  String? _religiousCommitment;

  String? _chronicDisease;
  final _chronicDiseaseName = TextEditingController();

  String? _birthDefect;
  final _birthDefectName = TextEditingController();

  String? _height;
  String? _weight;
  String? _skin;

  List<String> _languages = [];

  // ============================================================
  // الخيارات
  // ============================================================

  final List<String> _ages =
      List.generate(33, (i) => '${18 + i}');

  final List<String> _governorates = [
    'دمشق', 'ريف دمشق', 'حلب', 'حمص', 'حماة', 'اللاذقية', 'طرطوس',
    'إدلب', 'دير الزور', 'الرقة', 'الحسكة', 'درعا', 'السويداء', 'القنيطرة',
  ];

  final List<String> _educationLevels = [
    'تاسع', 'بكلوريا علمي', 'بكلوريا أدبي', 'لا يوجد', 'دراسة جامعية',
  ];

  final List<String> _incomeLevels = [
    'أقل من 100\$',
    '100-200\$',
    '200-400\$',
    '400-600\$',
    '600-1000\$',
    'أكثر من 1000\$',
  ];

  final List<String> _financialLevels = [
    'ضعيفة', 'متوسطة', 'جيدة', 'ممتازة',
  ];

  final List<String> _housingTypes = ['إيجار', 'ملك'];

  final List<String> _yesNo = ['نعم', 'لا'];

  final List<String> _marriageReadyOptions = [
    'جاهز خلال شهر',
    'جاهز خلال 3 أشهر',
    'جاهز خلال 6 أشهر',
    'جاهز خلال سنة',
    'جاهز خلال سنتين',
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

  final List<String> _skinColors = ['أبيض', 'حنطي', 'أسمر'];

  final List<String> _languageOptions = [
    'العربية', 'الإنجليزية', 'الفرنسية', 'الألمانية',
  ];

  final List<String> _stepTitles = [
    'البيانات الأساسية',
    'البيانات الشخصية',
    'التعليم والوضع المادي',
    'الصحة واللغات',
  ];

  final List<IconData> _stepIcons = [
    Icons.badge_outlined,
    Icons.person_outline_rounded,
    Icons.work_outline_rounded,
    Icons.favorite_outline_rounded,
  ];

  // ============================================================
  // Dispose
  // ============================================================

  @override
  void dispose() {
    _fullName.dispose();
    _fatherName.dispose();
    _country.dispose();
    _phoneController.dispose();
    _educationDetails.dispose();
    _job.dispose();
    _selfDescription.dispose();
    _properties.dispose();
    _chronicDiseaseName.dispose();
    _birthDefectName.dispose();
    _formScroll.dispose();

    super.dispose();
  }

  // ============================================================
  // رسائل مساعدة
  // ============================================================

  void _showRequiredMessage(String field) {
    ErrorHandler.showWarning(
      context,
      'الحقل الإجباري غير مملوء: $field',
    );
  }

  // ============================================================
  // رفع الصورة الشخصية
  // ============================================================

  Future<void> _pickPersonalPhoto() async {
    if (_isUploadingPhoto) return;

    setState(() => _isUploadingPhoto = true);

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

        if (compressed.isNotEmpty) {
          bytes = compressed;
        }
      } catch (_) {}

      final fileName =
          'grooms/photo_${DateTime.now().millisecondsSinceEpoch}.jpg';

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
      debugPrint('🔴 Photo upload error: $e');

      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
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
  // تحويل النطاق إلى الرقم المخزن
  // ============================================================

  int _rangeStart(String? range, int fallback) {
    if (range == null || range.trim().isEmpty) {
      return fallback;
    }

    final start = int.tryParse(
      range.split('-').first.trim(),
    );

    return start ?? fallback;
  }

  // ============================================================
  // جمع الحقول المفقودة في الخطوة الحالية
  // ============================================================

  List<String> _collectMissingFields() {
    final missing = <String>[];

    if (_step == 0) {
      if (_fullName.text.trim().isEmpty) missing.add('الاسم الكامل');
      if (_fatherName.text.trim().isEmpty) missing.add('اسم الأب');
      if (_phoneController.text.trim().isEmpty) {
        missing.add('رقم الهاتف');
      } else if (!RegExp(r'^09\d{8}$')
          .hasMatch(_phoneController.text.trim())) {
        missing.add('رقم الهاتف (يجب أن يبدأ بـ 09)');
      }
    }

    if (_step == 1) {
      if (_age == null) missing.add('العمر');
      if (_governorate == null) missing.add('المحافظة');
      if (_residence == null) missing.add('الإقامة');
      if (_isAbroad && _country.text.trim().isEmpty) {
        missing.add('اسم الدولة');
      }
      if (_religiousCommitment == null) missing.add('الالتزام الديني');
      if (_marriageReady == null) missing.add('الجاهزية للزواج');
      if (_height == null) missing.add('الطول');
      if (_weight == null) missing.add('الوزن');
      if (_skin == null) missing.add('لون البشرة');
      final about = _selfDescription.text.trim();
      if (about.length < 15) {
        missing.add('صف نفسك (١٥ حرفاً على الأقل)');
      } else if (about.length > 300) {
        missing.add('صف نفسك (٣٠٠ حرف كحد أقصى)');
      }
    }

    if (_step == 2) {
      if (_education == null) missing.add('التحصيل العلمي');
      if (_job.text.trim().isEmpty) missing.add('المهنة');
      if (_income == null) missing.add('الدخل');
      if (_financial == null) missing.add('الحالة المادية');
      if (_housingType == null) missing.add('السكن');
    }

    if (_step == 3) {
      if (_smoking == null) missing.add('التدخين');
      if (_hookah == null) missing.add('النرجيلة');
      if (_chronicDisease == null) missing.add('الأمراض المزمنة');
      if (_chronicDisease == 'نعم' &&
          _chronicDiseaseName.text.trim().isEmpty) {
        missing.add('اسم المرض');
      }
      if (_birthDefect == null) missing.add('العيوب الخلقية');
      if (_birthDefect == 'نعم' &&
          _birthDefectName.text.trim().isEmpty) {
        missing.add('اسم العيب');
      }
      if (_languages.isEmpty) missing.add('اللغات');
    }

    return missing;
  }

  // ============================================================
  // التحقق من الخطوة الحالية
  // ============================================================

  bool _validateCurrentStep() {
    final missing = _collectMissingFields();

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

  // ============================================================
  // حذف الصور المرفوعة (في حال فشل _submit)
  // ============================================================

  Future<void> _cleanupUploadedFiles() async {
    try {
      if (_personalPhotoPath != null) {
        await _client.storage
            .from('profile_photos')
            .remove([_personalPhotoPath!]);
      }
    } catch (e) {
      debugPrint('⚠️ Cleanup failed: $e');
    }
  }

  // ============================================================
  // إرسال الملف
  // ============================================================

  Future<void> _submit() async {
    if (!_validateCurrentStep()) return;

    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/verify');
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // ═══ حماية من الإدراج المزدوج ═══
      final existing = await _client
          .from('grooms')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        if (!mounted) return;
        ErrorHandler.showWarning(
          context,
          'لديك ملف مسجل بالفعل. يرجى التواصل مع الإدارة.',
        );
        return;
      }

      final groomCode =
          'GROOM-${DateTime.now().microsecondsSinceEpoch.toRadixString(36).toUpperCase()}';

      await _client.from('grooms').insert({
        'user_id': userId,
        'full_name': _fullName.text.trim(),
        'father_name': _fatherName.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'birth_date': _calculateBirthDate().toIso8601String(),
        'governorate': _governorate,
        'place_of_birth': _isAbroad
            ? _country.text.trim()
            : _residence,
        'education_level': _education,
        'education_details': _educationDetails.text.trim(),
        'job_title': _job.text.trim(),
        'income': _income,
        'financial_status': _financial,
        'housing_type': _housingType,
        'properties': _properties.text.trim(),
        'smoking': _smoking,
        'hookah': _hookah,
        'marriage_ready': _marriageReady,
        'religious_commitment': _religiousCommitment,
        'chronic_disease': _chronicDisease == 'نعم'
            ? _chronicDiseaseName.text.trim()
            : 'لا',
        'birth_defect': _birthDefect == 'نعم'
            ? _birthDefectName.text.trim()
            : 'لا',
        'languages': _languages.join(', '),
        'height_cm': _rangeStart(_height, 160),
        'weight_kg': _rangeStart(_weight, 70),
        'skin_color': _skin,
        'interests': _selfDescription.text.trim(),
        if (_personalPhotoPath != null)
          'personal_photo': _personalPhotoPath,
        'groom_code': groomCode,
        'identifier': userId,
        'is_verified': true,
      });

      await SessionService.saveGroomCode(groomCode);

      if (!mounted) return;

      ErrorHandler.showSuccess(
        context,
        'تم حفظ بياناتك بنجاح',
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AppShell(isGroomRole: true),
        ),
      );
    } catch (e) {
      debugPrint('🔴 Groom submit error: $e');

      // ═══ حذف الصور المرفوعة (cleanup) ═══
      await _cleanupUploadedFiles();

      if (!mounted) return;

      ErrorHandler.showError(
        context,
        e,
        customMessage: 'فشل حفظ البيانات',
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ============================================================
  // الانتقال بين الخطوات
  // ============================================================

  void _scrollFormToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_formScroll.hasClients) return;
      _formScroll.jumpTo(0);
    });
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;

    if (_step < 3) {
      setState(() => _step++);
      _scrollFormToTop();
    } else {
      _submit();
    }
  }

  void _previousStep() {
    if (_step > 0) {
      setState(() => _step--);
      _scrollFormToTop();
    }
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildVerificationStep();
      case 1:
        return _buildPersonalStep();
      case 2:
        return _buildEducationStep();
      case 3:
        return _buildHealthInterestsStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: IslamicScaffold(
        showPattern: true,
        appBar: IslamicAppBar(
          title: '☪ تسجيل الشاب',
          accentColor: AppColors.groomAccent,
          actions: [
            IconButton(
              tooltip: 'الإعدادات',
              icon: const Icon(
                Icons.settings_outlined,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
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
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  _stepIcons[_step],
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stepTitles[_step],
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'الخطوة ${_step + 1} من 4',
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${((_step + 1) / 4 * 100).round()}%',
                  style: const TextStyle(
                    color: AppColors.goldDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: (_step + 1) / 4,
              backgroundColor: AppColors.primarySoft,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // الخطوة 1: التحقق والهوية
  // ============================================================

  Widget _buildVerificationStep() {
    return _buildSectionCard(
      icon: Icons.badge_outlined,
      title: 'البيانات الأساسية',
      subtitle: 'الاسم والتواصل. يمكنك إضافة صورة شخصية اختيارية.',
      children: [
        _sectionLabel('الاسم والعائلة'),
        AppTextField(
          controller: _fullName,
          label: 'الاسم الكامل',
          hint: 'الاسم الثلاثي.',
        ),
        AppTextField(
          controller: _fatherName,
          label: 'اسم الأب',
          hint: 'للتوثيق الرسمي والمطابقة.',
        ),
        _sectionLabel('التواصل'),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'رقم الهاتف *',
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
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف',
                  hintText: '09xxxxxxxx',
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide:
                        const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide:
                        const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الرجاء إدخال رقم الهاتف';
                  }
                  if (!RegExp(r'^09\d{8}$').hasMatch(value.trim())) {
                    return 'الرقم يجب أن يبدأ بـ 09 ويتكون من 10 أرقام';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        _sectionLabel('الصورة الشخصية'),
        _buildUploadCard(
          icon: Icons.photo_camera_outlined,
          title: 'الصورة الشخصية',
          subtitle: 'اختيارية ويمكن إضافتها لاحقًا.',
          uploaded: _isPhotoUploaded,
          isUploading: _isUploadingPhoto,
          onPressed: _isUploadingPhoto ? null : _pickPersonalPhoto,
          required: false,
        ),
      ],
    );
  }

  // ============================================================
  // الخطوة 2: البيانات الشخصية
  // ============================================================

  Widget _buildPersonalStep() {
    return _buildSectionCard(
      icon: Icons.person_outline_rounded,
      title: 'البيانات الشخصية',
      subtitle:
          'معلومات عامة ومظهر تقريبي تساعد على التوافق الجاد.',
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
          label: 'الالتزام الديني',
          hint: 'تقييم عام لمستوى الالتزام كما تراه مناسباً للملف.',
          items: _religiousLevels,
          current: _religiousCommitment,
          onChange: (v) => setState(() => _religiousCommitment = v),
        ),
        AppDropdown(
          label: 'الجاهزية للزواج',
          hint: 'متى تتوقع أن تكون جاهزاً لإتمام الزواج؟',
          items: _marriageReadyOptions,
          current: _marriageReady,
          onChange: (v) => setState(() => _marriageReady = v),
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
          label: 'الإقامة',
          hint: 'أين تقيم حالياً؟ إن كنت خارج سوريا اختر ذلك.',
          items: [..._governorates, 'خارج سوريا'],
          current: _residence,
          onChange: (v) {
            setState(() {
              _residence = v;
              _isAbroad = v == 'خارج سوريا';
              if (!_isAbroad) {
                _country.clear();
              }
            });
          },
        ),
        if (_isAbroad)
          AppTextField(
            controller: _country,
            label: 'اسم الدولة',
            hint: 'الدولة التي تقيم فيها حالياً.',
          ),
        _sectionLabel('المظهر العام'),
        AppDropdown(
          label: 'الطول',
          hint: 'اختَر المجال الذي يقع فيه طولك.',
          items: _heightRanges,
          current: _height,
          onChange: (v) => setState(() => _height = v),
        ),
        AppDropdown(
          label: 'الوزن',
          hint: 'اختَر المجال التقريبي لوزنك.',
          items: _weightRanges,
          current: _weight,
          onChange: (v) => setState(() => _weight = v),
        ),
        AppDropdown(
          label: 'لون البشرة',
          hint: 'اختر الوصف الأقرب دون مبالغة.',
          items: _skinColors,
          current: _skin,
          onChange: (v) => setState(() => _skin = v),
        ),
        _sectionLabel('نبذة عنك'),
        AppTextField(
          controller: _selfDescription,
          label: 'صف نفسك بشكل مختصر',
          hint:
              'جملة قصيرة عن شخصيتك وما تبحث عنه في الزواج (١٥–٣٠٠ حرف).',
          maxLines: 4,
        ),
      ],
    );
  }

  // ============================================================
  // الخطوة 3: التعليم والوضع المادي
  // ============================================================

  Widget _buildEducationStep() {
    return _buildSectionCard(
      icon: Icons.work_outline_rounded,
      title: 'التعليم والوضع المادي',
      subtitle:
          'صورة واضحة عن تحصيلك وعملك ووضعك المعيشي.',
      children: [
        _sectionLabel('التعليم والعمل'),
        AppDropdown(
          label: 'التحصيل العلمي',
          hint: 'أعلى مرحلة دراسية وصلت إليها.',
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
        AppTextField(
          controller: _job,
          label: 'المهنة',
          hint: 'عملك الحالي أو مجالك المهني.',
        ),
        _sectionLabel('الوضع المادي والسكن'),
        AppDropdown(
          label: 'الدخل الشهري',
          hint: 'تقدير تقريبي يُستخدم للمطابقة فقط.',
          items: _incomeLevels,
          current: _income,
          onChange: (v) => setState(() => _income = v),
        ),
        AppDropdown(
          label: 'الحالة المادية',
          hint: 'تقييم عام لوضعك المادي.',
          items: _financialLevels,
          current: _financial,
          onChange: (v) => setState(() => _financial = v),
        ),
        AppDropdown(
          label: 'السكن',
          hint: 'هل السكن ملك أم إيجار؟',
          items: _housingTypes,
          current: _housingType,
          onChange: (v) => setState(() => _housingType = v),
        ),
        AppTextField(
          controller: _properties,
          label: 'الممتلكات',
          hint: 'اختياري — مثل سيارة أو عقار باختصار.',
          required: false,
        ),
      ],
    );
  }

  // ============================================================
  // الخطوة 4: الصحة واللغات
  // ============================================================

  Widget _buildHealthInterestsStep() {
    return _buildSectionCard(
      icon: Icons.favorite_outline_rounded,
      title: 'الصحة واللغات',
      subtitle:
          'شفافية صحية وعادات، ثم لغاتك.',
      children: [
        _sectionLabel('الصحة والعادات'),
        AppDropdown(
          label: 'التدخين',
          hint: 'هل تدخن السجائر؟',
          items: _yesNo,
          current: _smoking,
          onChange: (v) => setState(() => _smoking = v),
        ),
        AppDropdown(
          label: 'النرجيلة',
          hint: 'هل تستخدم النرجيلة؟',
          items: _yesNo,
          current: _hookah,
          onChange: (v) => setState(() => _hookah = v),
        ),
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
            hint: 'اكتبه باختصار ووضوح.',
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
        _sectionLabel('اللغات'),
        AppLanguagePicker(
          selected: _languages,
          options: _languageOptions,
          onChanged: (v) => setState(() => _languages = v),
          hint: 'اختر اللغات التي تتقنها.',
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
  // بطاقة القسم
  // ============================================================

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return IslamicCard(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
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

  // ============================================================
  // بطاقة رفع الملفات
  // ============================================================

  Widget _buildUploadCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool uploaded,
    required bool isUploading,
    required VoidCallback? onPressed,
    required bool required,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isUploading ? null : onPressed,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: uploaded
                ? AppColors.successLight
                : AppColors.surfaceTint,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: uploaded
                  ? AppColors.success
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: uploaded
                      ? AppColors.success
                      : AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: isUploading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        uploaded
                            ? Icons.check_rounded
                            : icon,
                        color: uploaded
                            ? Colors.white
                            : AppColors.goldDark,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title + (required ? ' *' : ''),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isUploading
                          ? 'جارٍ الرفع...'
                          : uploaded
                              ? 'تم رفع الملف بنجاح'
                              : subtitle,
                      style: TextStyle(
                        color: isUploading
                            ? AppColors.primary
                            : uploaded
                                ? AppColors.success
                                : AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isUploading
                    ? Icons.hourglass_top_rounded
                    : uploaded
                        ? Icons.verified_rounded
                        : Icons.cloud_upload_outlined,
                color: isUploading
                    ? AppColors.primary
                    : uploaded
                        ? AppColors.success
                        : AppColors.primary,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // شريط التنقل
  // ============================================================

  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_step > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _isSubmitting ? null : _previousStep,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.gold,
                    ),
                    minimumSize: const Size.fromHeight(50),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _step < 3 ? 'التالي' : 'إنشاء الحساب',
                          maxLines: 1,
                          softWrap: false,
                          textAlign: TextAlign.center,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}