// lib/screens/source_screen.dart
// ============================================================
// SourceScreen — كيف تعرفت على ميثاق؟
// ============================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/islamic_decorations.dart';
import '../app_colors.dart';
import '../ui/shell/app_shell.dart';

class SourceScreen extends StatefulWidget {
  const SourceScreen({Key? key}) : super(key: key);

  @override
  State<SourceScreen> createState() => _SourceScreenState();
}

class _SourceScreenState extends State<SourceScreen> {
  final _client = Supabase.instance.client;

  String? _selectedSource;
  bool _isLoading = false;

  final List<String> _sources = [
    'وسائل التواصل',
    'متجر جوجل',
    'أحد العلماء',
    'العائلة أو الأصدقاء',
  ];

  // ============================================================
  // أيقونات المصادر
  // ============================================================

  IconData _getSourceIcon(String source) {
    switch (source) {
      case 'وسائل التواصل':
        return Icons.campaign_outlined;
      case 'متجر جوجل':
        return Icons.smartphone_outlined;
      case 'أحد العلماء':
        return Icons.menu_book_outlined;
      case 'العائلة أو الأصدقاء':
        return Icons.people_outline_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  // ============================================================
  // رسائل SnackBar موحّدة
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  void _showWarning(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ============================================================
  // ترجمة الأخطاء
  // ============================================================

  String _translateError(dynamic e) {
    final msg = e.toString().toLowerCase();

    if (msg.contains('jwt') ||
        msg.contains('session') ||
        msg.contains('expired') ||
        msg.contains('authentication required')) {
      return 'انتهت جلسة الدخول. يرجى تسجيل الدخول مجدداً.';
    }

    if (msg.contains('duplicate') ||
        msg.contains('unique') ||
        msg.contains('already exists')) {
      return 'تم حفظ مصدرك مسبقاً.';
    }

    if (msg.contains('permission denied') ||
        msg.contains('row-level security') ||
        msg.contains('violates row-level') ||
        msg.contains('policy')) {
      return 'لا يمكن حفظ اختيارك. يرجى التواصل مع الإدارة.';
    }

    if (msg.contains('network') ||
        msg.contains('timeout') ||
        msg.contains('connection') ||
        msg.contains('failed host lookup')) {
      return 'تعذر الاتصال بالإنترنت. تحقق من اتصالك.';
    }

    if (msg.contains('profile') ||
        msg.contains('لم يتم العثور على ملف الحساب')) {
      return 'لم يتم العثور على ملف الحساب. يرجى التواصل مع الإدارة.';
    }

    if (msg.contains('نوع الحساب غير محدد') ||
        msg.contains('نوع الحساب غير معروف')) {
      return 'نوع الحساب غير محدد. يرجى التواصل مع الإدارة.';
    }

    return 'حدث خطأ أثناء حفظ البيانات. يرجى المحاولة لاحقاً.';
  }

  // ============================================================
  // حفظ المصدر والمتابعة
  // ============================================================

  Future<void> _submit() async {
    if (!mounted) return;
    if (_isLoading) return;

    if (_selectedSource == null ||
        _selectedSource!.trim().isEmpty) {
      _showWarning(
        'يرجى اختيار الطريقة التي تعرفت من خلالها على ميثاق',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ============================================================
      // 1. التأكد من وجود مستخدم مسجل الدخول
      // ============================================================

      final user = _client.auth.currentUser;

      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً لإتمام هذه الخطوة.');
      }

      // ============================================================
      // 2. التأكد من وجود ملف المستخدم ومعرفة نوع الحساب
      // ============================================================

      final profile = await _client
          .from('profiles')
          .select('id, role')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (profile == null) {
        throw Exception('لم يتم العثور على ملف الحساب.');
      }

      final role = profile['role']?.toString().trim();

      if (role == null || role.isEmpty) {
        throw Exception('نوع الحساب غير محدد.');
      }

      // ============================================================
      // 3. حفظ مصدر التعرف
      // (created_at تُضاف تلقائياً بواسطة DB)
      // ============================================================

      await _client.from('user_sources').insert({
        'identifier': user.id,
        'source': _selectedSource!.trim(),
      });

      if (!mounted) return;

      // ============================================================
      // 4. الانتقال إلى الخطوة التالية حسب نوع الحساب
      // ============================================================

      if (role == 'services_only') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AppShell(),
          ),
        );
        return;
      }

      if (role == 'groom') {
        Navigator.pushReplacementNamed(
          context,
          '/terms-groom',
        );
        return;
      }

      if (role == 'bride') {
        Navigator.pushReplacementNamed(
          context,
          '/terms-bride',
        );
        return;
      }

      throw Exception('نوع الحساب غير معروف: $role');
    } catch (e, stackTrace) {
      debugPrint('🔴 Source save error: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      _showError(_translateError(e));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return IslamicScaffold(
      appBar: const IslamicAppBar(
        title: 'خطوة أخيرة قبل البدء',
      ),
      body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 650 : 600,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    24,
                    20,
                    28,
                  ),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildSourceCard(),
                      const SizedBox(height: 24),
                      IslamicButton(
                        label: 'متابعة',
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _isLoading ? null : _submit,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'اختيارك يساعدنا على تحسين تجربة ميثاق',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 11,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      
    );
  }

  // ============================================================
  // رأس الصفحة
  // ============================================================

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.65),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Icon(
            Icons.explore_outlined,
            size: 40,
            color: AppColors.goldLight,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'كيف تعرفت على ميثاق؟',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 23,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 1,
              color: AppColors.gold.withValues(alpha: 0.45),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.auto_awesome,
              size: 14,
              color: AppColors.gold,
            ),
            const SizedBox(width: 8),
            Container(
              width: 26,
              height: 1,
              color: AppColors.gold.withValues(alpha: 0.45),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'نرغب في معرفة الطريقة التي وصلت بها إلى ميثاق، '
          'وذلك لمساعدتنا على تطوير خدماتنا والوصول إلى من يبحث '
          'عن الزواج الجاد والشرعي.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 13,
            height: 1.8,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // بطاقة المصادر
  // ============================================================

  Widget _buildSourceCard() {
    return IslamicCard(
      padding: const EdgeInsets.fromLTRB(
        16,
        20,
        16,
        18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'اختر الطريقة المناسبة',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ..._sources.map(
            (source) => _buildSourceOption(source),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // خيار مصدر
  // ============================================================

  Widget _buildSourceOption(String source) {
    final isSelected = _selectedSource == source;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading
              ? null
              : () {
                  setState(() {
                    _selectedSource = source;
                  });
                },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primarySoft
                  : AppColors.surfaceGreen,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.borderLight,
                width: isSelected ? 1.4 : 0.9,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Icon(
                    _getSourceIcon(source),
                    size: 23,
                    color: isSelected
                        ? AppColors.goldLight
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    source,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppColors.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
                      width: isSelected ? 1.5 : 1.2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}