// lib/screens/groom_profile_screen.dart
// ============================================================
// GroomProfileScreen — عرض ملف الشاب
// ============================================================

import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';
import '../widgets/islamic_decorations.dart';

class GroomProfileScreen extends StatefulWidget {
  const GroomProfileScreen({super.key});

  @override
  State<GroomProfileScreen> createState() => _GroomProfileScreenState();
}

class _GroomProfileScreenState extends State<GroomProfileScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  Future<String?>? _photoUrlFuture;

  // ------------------------------------------------------------
  // القوائم المستخدمة في عرض المجالات
  // ------------------------------------------------------------

  static const List<String> _heightRanges = [
    '130-140',
    '140-150',
    '150-160',
    '160-170',
    '170-180',
    '180-190',
    '190-200',
  ];

  static const List<String> _weightRanges = [
    '50-60',
    '60-70',
    '70-80',
    '80-90',
    '90-100',
    '100-110',
    '110-120',
  ];

  // ============================================================
  // Lifecycle
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ============================================================
  // تحميل الملف
  // ============================================================

  Future<void> _loadProfile() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final userId = _client.auth.currentUser?.id;

      if (userId == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      // ═══ استخدام RPC المحصّن ═══
      final result = await _client.rpc('get_my_groom_profile');

      if (!mounted) return;

      final data = result is Map
          ? Map<String, dynamic>.from(result)
          : null;

      // احتياط إن كانت دالة القاعدة ما زالت تحذف personal_photo
      if (data != null &&
          (data['personal_photo'] == null ||
              data['personal_photo'].toString().trim().isEmpty)) {
        try {
          final photoRow = await _client
              .from('grooms')
              .select('personal_photo')
              .eq('user_id', userId)
              .maybeSingle();
          final path = photoRow?['personal_photo']?.toString().trim();
          if (path != null && path.isNotEmpty) {
            data['personal_photo'] = path;
          }
        } catch (e) {
          debugPrint('⚠️ personal_photo fallback: $e');
        }
      }

      if (!mounted) return;

      setState(() {
        _profile = data;
        _isLoading = false;
        _photoUrlFuture = data == null ? null : _resolvePersonalPhotoUrl(data);
      });
    } catch (e) {
      debugPrint('🔴 Load groom profile error: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _photoUrlFuture = null;
      });

      ErrorHandler.showError(context, e);
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
        appBar: IslamicAppBar(
          title: tr('profile'),
          actions: [
            IconButton(
              tooltip: 'تعديل الملف',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                Navigator.pushNamed(context, '/edit-groom-profile');
              },
            ),
            IconButton(
              tooltip: 'الإعدادات',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (_profile == null) {
      return _buildEmptyProfile();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileHeader(),

            const SizedBox(height: 18),

            _buildSection(
              icon: Icons.person_outline_rounded,
              title: 'المعلومات الشخصية',
              children: [
                _buildInfoRow(
                  Icons.badge_outlined,
                  'الاسم الكامل',
                  _profile?['full_name'],
                ),
                _buildInfoRow(
                  Icons.person_outline_rounded,
                  'اسم الأب',
                  _profile?['father_name'],
                ),
                _buildInfoRow(
                  Icons.person_2_outlined,
                  'اسم الأم',
                  _profile?['mother_name'],
                ),
                _buildInfoRow(
                  Icons.qr_code_2_outlined,
                  'رمز الشاب',
                  _profile?['groom_code'],
                ),
                _buildInfoRow(
                  Icons.phone_outlined,
                  'رقم الجوال',
                  _profile?['phone_number'],
                ),
                _buildInfoRow(
                  Icons.cake_outlined,
                  'العمر',
                  _calculateAge(_profile?['birth_date']),
                ),
                _buildInfoRow(
                  Icons.location_on_outlined,
                  'المحافظة',
                  _profile?['governorate'],
                ),
                _buildInfoRow(
                  Icons.home_work_outlined,
                  'مكان الولادة / الإقامة',
                  _profile?['place_of_birth'] ??
                      _profile?['residence'],
                ),
                if ((_profile?['social_status']?.toString().trim().isNotEmpty ??
                    false))
                  _buildInfoRow(
                    Icons.favorite_border_rounded,
                    'الحالة الاجتماعية',
                    _profile?['social_status'],
                  ),
              ],
            ),

            const SizedBox(height: 12),

            _buildSection(
              icon: Icons.school_outlined,
              title: 'التعليم والعمل',
              children: [
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
                  Icons.work_outline_rounded,
                  'المهنة',
                  _profile?['job_title'],
                ),
                _buildInfoRow(
                  Icons.payments_outlined,
                  'الدخل',
                  _profile?['income'],
                ),
                _buildInfoRow(
                  Icons.account_balance_wallet_outlined,
                  'الحالة المادية',
                  _profile?['financial_status'],
                ),
                _buildInfoRow(
                  Icons.home_outlined,
                  'السكن',
                  _profile?['housing_type'],
                ),
                _buildInfoRow(
                  Icons.event_available_outlined,
                  'الجاهزية للزواج',
                  _profile?['marriage_ready'],
                ),
                _buildInfoRow(
                  Icons.inventory_2_outlined,
                  'الممتلكات',
                  _profile?['properties'],
                ),
              ],
            ),

            const SizedBox(height: 12),

            _buildSection(
              icon: Icons.health_and_safety_outlined,
              title: 'الصحة والعادات',
              children: [
                _buildInfoRow(
                  Icons.smoking_rooms_outlined,
                  'التدخين',
                  _profile?['smoking'],
                ),
                _buildInfoRow(
                  Icons.air_outlined,
                  'النرجيلة',
                  _profile?['hookah'],
                ),
                _buildInfoRow(
                  Icons.mosque_outlined,
                  'الالتزام الديني',
                  _profile?['religious_commitment'],
                ),
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
                  Icons.height_rounded,
                  'الطول',
                  _heightDisplay(),
                ),
                _buildInfoRow(
                  Icons.monitor_weight_outlined,
                  'الوزن',
                  _weightDisplay(),
                ),
                _buildInfoRow(
                  Icons.palette_outlined,
                  'لون البشرة',
                  _profile?['skin_color'],
                ),
              ],
            ),

            const SizedBox(height: 12),

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
                  Icons.language_outlined,
                  'اللغات',
                  _profile?['languages'],
                ),
              ],
            ),

            const SizedBox(height: 8),

            _buildBottomNote(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // رأس الملف الشخصي
  // ============================================================

  Widget _buildProfileHeader() {
    final fullName = _profile?['full_name']?.toString().trim();

    return IslamicCard(
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -25,
              top: -30,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: -35,
              bottom: -45,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
              child: Column(
                children: [
                  _buildProfileImage(),

                  const SizedBox(height: 14),

                  Text(
                    fullName?.isNotEmpty == true
                        ? fullName!
                        : 'غير محدد',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.goldLight
                            .withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 16,
                          color: AppColors.goldLight,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'الملف الشخصي',
                          style: TextStyle(
                            color: AppColors.goldLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // صورة الملف
  // ============================================================

  Widget _buildProfileImage() {
    final future = _photoUrlFuture;
    if (future == null) return _buildDefaultAvatarWrapped();

    return FutureBuilder<String?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildAvatarLoading();
        }

        if (snapshot.hasError) {
          debugPrint('Signed URL error: ${snapshot.error}');
          return _buildDefaultAvatarWrapped();
        }

        final imageUrl = snapshot.data;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return Container(
            width: 126,
            height: 126,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 14,
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
                  debugPrint('⚠️ Image.network failed: $error');
                  return _buildDefaultAvatar();
                },
              ),
            ),
          );
        }

        return _buildDefaultAvatarWrapped();
      },
    );
  }

  // ============================================================
  // Signed URL للصورة
  // ============================================================

  Future<String?> _resolvePersonalPhotoUrl(Map<String, dynamic> profile) async {
    // 1) مسار الخادم الخاص بصورة صاحب الحساب
    final fromApi = await ApiService.getMyPersonalPhotoUrl();
    if (fromApi != null && fromApi.isNotEmpty) {
      debugPrint('✅ personal photo via /api/account/personal-photo');
      return fromApi;
    }

    // 2) مسار موجود أصلاً في الإنتاج ويوقّع الصورة للشاب نفسه
    final code = profile['groom_code']?.toString().trim();
    if (code != null && code.isNotEmpty) {
      try {
        final details = await ApiService.getGroomDetails(code);
        final signed = details['personal_photo_signed_url']?.toString().trim();
        if (signed != null && signed.isNotEmpty) {
          debugPrint('✅ personal photo via /api/groom-details');
          return signed;
        }
        debugPrint(
          '⚠️ groom-details بدون رابط صورة. path=${details['personal_photo']}',
        );
      } catch (e) {
        debugPrint('⚠️ groom-details photo error: $e');
      }
    }

    // 3) توقيع مباشر من التخزين (يحتاج سياسة SELECT)
    final photo = profile['personal_photo']?.toString().trim();
    if (photo == null || photo.isEmpty) {
      debugPrint('⚠️ لا يوجد personal_photo في الملف');
      return null;
    }

    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      return photo;
    }

    try {
      final url = await _client.storage
          .from('profile_photos')
          .createSignedUrl(photo, 3600);
      debugPrint('✅ personal photo via createSignedUrl');
      return url;
    } catch (e) {
      debugPrint('⚠️ Signed URL error for "$photo": $e');
      return null;
    }
  }

  // ============================================================
  // Avatars
  // ============================================================

  Widget _buildAvatarLoading() {
    return Container(
      width: 126,
      height: 126,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.gold,
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primarySoft,
        ),
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
      ),
    );
  }

  Widget _buildDefaultAvatarWrapped() {
    return Container(
      width: 126,
      height: 126,
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.gold,
      ),
      child: ClipOval(
        child: _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    final name = _profile?['full_name']?.toString().trim();

    String letter = '?';

    if (name != null && name.isNotEmpty) {
      letter = name.characters.first;
    }

    return Container(
      color: AppColors.primarySoft,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 46,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
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
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: IslamicCard(
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
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              height: 1,
              color: AppColors.divider,
            ),

            const SizedBox(height: 5),

            ...children,
          ],
        ),
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppColors.primaryLight,
            ),
          ),

          const SizedBox(width: 10),

          SizedBox(
            width: 105,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 34,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceGreen,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // تحويل الطول المخزن إلى مجال
  // ============================================================

  String? _heightDisplay() {
    final value = _profile?['height_cm'];

    if (value == null) return null;

    final stored = int.tryParse(value.toString());

    if (stored == null) return value.toString();

    for (final range in _heightRanges) {
      final parts = range.split('-');

      if (parts.length == 2) {
        final start = int.tryParse(parts[0]);

        if (start == stored) {
          return '$range سم';
        }
      }
    }

    return '$stored سم';
  }

  // ============================================================
  // تحويل الوزن المخزن إلى مجال
  // ============================================================

  String? _weightDisplay() {
    final value = _profile?['weight_kg'];

    if (value == null) return null;

    final stored = int.tryParse(value.toString());

    if (stored == null) return value.toString();

    for (final range in _weightRanges) {
      final parts = range.split('-');

      if (parts.length == 2) {
        final start = int.tryParse(parts[0]);

        if (start == stored) {
          return '$range كغ';
        }
      }
    }

    return '$stored كغ';
  }

  // ============================================================
  // حساب العمر
  // ============================================================

  String _calculateAge(dynamic birthDate) {
    if (birthDate == null) return 'غير محدد';

    final date = DateTime.tryParse(birthDate.toString());
    if (date == null) return 'غير محدد';

    final now = DateTime.now();

    int age = now.year - date.year;

    if (now.month < date.month ||
        (now.month == date.month && now.day < date.day)) {
      age--;
    }

    return '$age سنة';
  }

  // ============================================================
  // لا يوجد ملف
  // ============================================================

  Widget _buildEmptyProfile() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: IslamicCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_off_outlined,
                  size: 34,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'لا توجد بيانات للملف الشخصي',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
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
  // ملاحظة أسفل الصفحة
  // ============================================================

  Widget _buildBottomNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 19,
            color: AppColors.goldDark,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'يتم عرض معلومات الملف وفق إعدادات الخصوصية المعتمدة في منصة ميثاق.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textOnGold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}