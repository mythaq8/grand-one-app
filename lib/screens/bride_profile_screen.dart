import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import '../widgets/islamic_decorations.dart';
import '../app_colors.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';
import '../utils/profile_fields.dart';

class BrideProfileScreen extends StatefulWidget {
  const BrideProfileScreen({super.key});

  @override
  State<BrideProfileScreen> createState() => _BrideProfileScreenState();
}

class _BrideProfileScreenState extends State<BrideProfileScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  Future<String?>? _photoUrlFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

 Future<void> _loadProfile() async {
  if (!mounted) return;

  setState(() => _isLoading = true);

  try {
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ErrorHandler.showWarning(
        context,
        'انتهت جلسة الدخول. يرجى تسجيل الدخول مجدداً.',
      );
      return;
    }

    final data = await _client
        .from('brides')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (!mounted) return;

    setState(() {
      _profile = data;
      _isLoading = false;
      _photoUrlFuture = data == null ? null : _resolvePersonalPhotoUrl(data);
    });
  } catch (e) {
    debugPrint('Bride profile load error: $e');

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _photoUrlFuture = null;
    });

    ErrorHandler.showError(context, e);
  }
}

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: IslamicScaffold(
        appBar: IslamicAppBar(
          title: tr('view_profile'),
          actions: [
            IconButton(
              tooltip: 'تعديل المتطلبات',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                Navigator.pushNamed(context, '/edit-bride-profile');
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
            : _profile == null
                ? _buildEmptyState()
                : _buildProfile(),
      ),
    );
  }

  // ============================================================
  // الملف الشخصي
  // ============================================================

  Widget _buildProfile() {
    final fullName =
        (_profile?['full_name'] ?? 'غير محدد').toString();
    final requirementRows = brideRequirementRows(_profile);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          18,
          16,
          30,
        ),
        child: Column(
          children: [
            _buildProfileHeader(fullName),

            const SizedBox(height: 18),

            _buildSection(
              icon: Icons.person_outline_rounded,
              title: 'المعلومات الشخصية',
              children: [
                _buildInfoRow(
                  Icons.cake_outlined,
                  'العمر',
                  _calculateAge(_profile?['birth_date']),
                ),
                _buildInfoRow(
                  Icons.location_on_outlined,
                  'المحافظة',
                  _profile?['current_governorate'],
                ),
                _buildInfoRow(
                  Icons.home_outlined,
                  'الإقامة',
                  _profile?['current_residence'],
                ),
                _buildInfoRow(
                  Icons.school_outlined,
                  'التعليم',
                  _profile?['education_level'],
                ),
                _buildInfoRow(
                  Icons.menu_book_outlined,
                  'تفاصيل التعليم',
                  _profile?['education_details'],
                ),
                _buildInfoRow(
                  Icons.favorite_border_rounded,
                  'الحالة الاجتماعية',
                  _profile?['social_status'],
                ),
                _buildInfoRow(
                  Icons.person_outline_rounded,
                  'الحجاب',
                  _profile?['hijab_status'],
                ),
                _buildInfoRow(
                  Icons.mosque_outlined,
                  'الالتزام الديني',
                  _profile?['religious_commitment'],
                ),
                _buildInfoRow(
                  Icons.qr_code_2_outlined,
                  'الرمز',
                  _profile?['anonymous_code'],
                ),
              ],
            ),

            const SizedBox(height: 14),

            _buildSection(
              icon: Icons.auto_awesome_outlined,
              title: 'المظهر الخارجي',
              children: [
                _buildInfoRow(
                  Icons.face_rounded,
                  'لون الشعر',
                  _profile?['hair_color'],
                ),
                _buildInfoRow(
                  Icons.waves_rounded,
                  'نوعية الشعر',
                  _profile?['hair_type'],
                ),
                _buildInfoRow(
                  Icons.remove_red_eye_outlined,
                  'لون العيون',
                  _profile?['eye_color'],
                ),
                _buildInfoRow(
                  Icons.palette_outlined,
                  'لون البشرة',
                  _profile?['skin_color'],
                ),
                _buildInfoRow(
                  Icons.height_rounded,
                  'الطول',
                  _profile?['height_cm'] != null
                      ? '${_profile?['height_cm']} سم'
                      : null,
                ),
                _buildInfoRow(
                  Icons.monitor_weight_outlined,
                  'الوزن',
                  _profile?['weight_kg'] != null
                      ? '${_profile?['weight_kg']} كغ'
                      : null,
                ),
                _buildInfoRow(
                  Icons.star_border_rounded,
                  'مستوى الجمال',
                  _profile?['beauty_level'],
                ),
              ],
            ),

            const SizedBox(height: 14),

            _buildSection(
              icon: Icons.health_and_safety_outlined,
              title: 'الصحة والعادات',
              children: [
                _buildInfoRow(
                  Icons.medical_information_outlined,
                  'أمراض مزمنة',
                  _profile?['chronic_disease'],
                ),
                _buildInfoRow(
                  Icons.warning_amber_rounded,
                  'عيوب خلقية',
                  _profile?['birth_defect'],
                ),
                _buildInfoRow(
                  Icons.smoking_rooms_outlined,
                  'التدخين',
                  _profile?['smoking'],
                ),
                _buildInfoRow(
                  Icons.air_rounded,
                  'النرجيلة',
                  _profile?['hookah'],
                ),
              ],
            ),

            const SizedBox(height: 14),

            _buildSection(
              icon: Icons.star_outline_rounded,
              title: 'الميزات',
              children: [
                for (final f in kBrideFeatureKeys)
                  _buildInfoRow(
                    Icons.check_circle_outline,
                    f.value,
                    featureDisplay(_profile, f.key, legacyColumn: f.key),
                  ),
                _buildInfoRow(
                  Icons.diamond_outlined,
                  'المهر المطلوب',
                  _profile?['required_mahr'],
                ),
                _buildInfoRow(
                  Icons.house_outlined,
                  'سكن منفصل',
                  _profile?['separate_housing'],
                ),
                _buildInfoRow(
                  Icons.location_on_outlined,
                  'موقع محدد',
                  _profile?['specific_location'],
                ),
                _buildInfoRow(
                  Icons.description_outlined,
                  'متطلبات إضافية',
                  _profile?['additional_requirements'],
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (requirementRows.isNotEmpty)
              _buildSection(
                icon: Icons.rule_outlined,
                title: 'متطلبات الشاب',
                children: [
                  for (final r in requirementRows)
                    _buildInfoRow(
                      Icons.checklist_rtl_outlined,
                      r.key,
                      r.value,
                    ),
                ],
              ),

            if (requirementRows.isNotEmpty) const SizedBox(height: 14),

            _buildSection(
              icon: Icons.info_outline_rounded,
              title: 'معلومات إضافية',
              children: [
                _buildInfoRow(
                  Icons.notes_rounded,
                  'صف نفسك',
                  _profile?['interests'],
                ),
                _buildInfoRow(
                  Icons.language_rounded,
                  'اللغات',
                  _profile?['languages'],
                ),
                _buildInfoRow(
                  Icons.description_outlined,
                  'تفاصيل إضافية',
                  _profile?['details'],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // رأس الملف الشخصي
  // ============================================================

  Widget _buildProfileHeader(String fullName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        24,
        20,
        22,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -35,
            top: -35,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  width: 2,
                ),
              ),
            ),
          ),
          Positioned(
            right: -45,
            bottom: -45,
            child: Container(
              width: 125,
              height: 125,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.14),
                  width: 2,
                ),
              ),
            ),
          ),

          Column(
            children: [
              _buildProfileImage(fullName),

              const SizedBox(height: 14),

              Text(
                fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnPrimary,
                ),
              ),

              const SizedBox(height: 7),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.goldLight.withValues(alpha: 0.45),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 15,
                      color: AppColors.goldLight,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'الملف الشخصي',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String fullName) {
    final future = _photoUrlFuture;
    if (future == null) return _buildLetterAvatar(fullName);

    return FutureBuilder<String?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildAvatarLoading();
        }
        if (snapshot.hasError) {
          debugPrint('Bride signed URL error: ${snapshot.error}');
          return _buildLetterAvatar(fullName);
        }
        final imageUrl = snapshot.data;
        if (imageUrl == null || imageUrl.isEmpty) {
          return _buildLetterAvatar(fullName);
        }
        return Container(
          width: 108,
          height: 108,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.gold,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _buildAvatarLoading();
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint('⚠️ Bride Image.network failed: $error');
                return _buildLetterAvatar(fullName);
              },
            ),
          ),
        );
      },
    );
  }

  Future<String?> _resolvePersonalPhotoUrl(Map<String, dynamic> profile) async {
    final fromApi = await ApiService.getMyPersonalPhotoUrl();
    if (fromApi != null && fromApi.isNotEmpty) {
      debugPrint('✅ bride photo via /api/account/personal-photo');
      return fromApi;
    }

    final photo = profile['personal_photo']?.toString().trim();
    if (photo == null || photo.isEmpty) {
      debugPrint('⚠️ لا يوجد personal_photo في ملف الفتاة');
      return null;
    }

    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      return photo;
    }

    try {
      final url = await _client.storage
          .from('profile_photos')
          .createSignedUrl(photo, 3600);
      debugPrint('✅ bride photo via createSignedUrl');
      return url;
    } catch (e) {
      debugPrint('⚠️ Bride signed URL error for "$photo": $e');
      return null;
    }
  }

  Widget _buildAvatarLoading() {
    return Container(
      width: 108,
      height: 108,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.gold,
      ),
      padding: const EdgeInsets.all(3),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primarySoft,
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLetterAvatar(String fullName) {
    final firstLetter =
        fullName.trim().isNotEmpty ? fullName.trim()[0] : '?';
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(
          color: AppColors.gold,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          firstLetter,
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // القسم
  // ============================================================

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              15,
              16,
              12,
            ),
            child: Row(
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
  size: 21,
),
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                Container(
                  width: 26,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),

          const Divider(
            height: 1,
            color: AppColors.divider,
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              7,
              16,
              12,
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // صف المعلومات
  // ============================================================

  Widget _buildInfoRow(
    IconData icon,
    String label,
    dynamic value,
  ) {
    if (value == null || value.toString().trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppColors.goldDark,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                value.toString(),
                textAlign: TextAlign.start,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // لا يوجد ملف
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.borderLight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_off_outlined,
                  size: 38,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'لا توجد بيانات للملف الشخصي',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'لم يتم العثور على بيانات مرتبطة بهذا الحساب.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // حساب العمر
  // ============================================================

  String _calculateAge(dynamic birthDate) {
  if (birthDate == null) return 'غير محدد';

  try {
    final date = DateTime.tryParse(birthDate.toString());
    if (date == null) return 'غير محدد';

    final now = DateTime.now();

    int age = now.year - date.year;

    if (now.month < date.month ||
        (now.month == date.month && now.day < date.day)) {
      age--;
    }

    return '$age سنة';
  } catch (e) {
    debugPrint('Age calculation error: $e');
    return 'غير محدد';
  }
}
}