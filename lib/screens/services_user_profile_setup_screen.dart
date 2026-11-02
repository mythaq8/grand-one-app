// lib/screens/services_user_profile_setup_screen.dart
// ============================================================
// ServicesUserProfileSetupScreen — إكمال ملف مستخدم الخدمات
// ============================================================

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_colors.dart';
import '../services/api_exceptions.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';
import '../widgets/islamic_decorations.dart';
import '../ui/shell/app_shell.dart';

class ServicesUserProfileSetupScreen extends StatefulWidget {
  const ServicesUserProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<ServicesUserProfileSetupScreen> createState() =>
      _ServicesUserProfileSetupScreenState();
}

class _ServicesUserProfileSetupScreenState
    extends State<ServicesUserProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _whatsappController = TextEditingController();

  String? _selectedGovernorate;
  bool _isSubmitting = false;

  static const List<String> _governorates = [
    'دمشق', 'ريف دمشق', 'حلب', 'حمص', 'حماة', 'اللاذقية', 'طرطوس',
    'إدلب', 'دير الزور', 'الرقة', 'الحسكة', 'درعا', 'السويداء', 'القنيطرة',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedGovernorate == null) {
      ErrorHandler.showWarning(
        context,
        'يرجى اختيار المحافظة',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ApiService.signupServicesUser(
        fullName: _fullNameController.text.trim(),
        governorate: _selectedGovernorate!,
        whatsapp: _whatsappController.text.trim(),
      );

      if (!mounted) return;

      ErrorHandler.showSuccess(
        context,
        'تم حفظ بياناتك بنجاح',
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AppShell(),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      ErrorHandler.showError(
        context,
        e,
        customMessage: e.userMessage,
      );
    } catch (e) {
      if (!mounted) return;

      ErrorHandler.showError(
        context,
        e,
        customMessage: 'فشل حفظ البيانات',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: IslamicScaffold(
        showPattern: true,
        appBar: IslamicAppBar(
          title: 'إكمال ملف الخدمات',
        ),
        body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  IslamicCard(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                    child: Column(
                      children: [
                        _buildTextField(
                          label: 'الاسم الكامل',
                          hint: 'أدخل اسمك الكامل',
                          icon: Icons.person_outline_rounded,
                          controller: _fullNameController,
                          validator: (v) {
                            final text = v?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'الاسم مطلوب';
                            }
                            if (text.length < 3) {
                              return 'الاسم قصير جدًا';
                            }
                            if (text.length > 100) {
                              return 'الاسم طويل جدًا';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildGovernorateDropdown(),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'رقم الواتساب',
                          hint: '09XXXXXXXX',
                          icon: Icons.chat_outlined,
                          controller: _whatsappController,
                          isPhone: true,
                          validator: (v) {
                            final text = v?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'رقم الواتساب مطلوب';
                            }
                            if (!RegExp(r'^09[0-9]{8}$').hasMatch(text)) {
                              return 'يجب أن يبدأ بـ 09 ويتكون من 10 أرقام';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _submit,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded, size: 20),
                            label: Text(
                              _isSubmitting
                                  ? 'جارٍ الحفظ...'
                                  : 'حفظ ومتابعة',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoNote(),
                ],
              ),
            ),
          ),
        
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.45),
            ),
          ),
          child: const Icon(
            Icons.business_center_outlined,
            color: AppColors.goldLight,
            size: 42,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'أكمل بياناتك',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'نحتاج هذه المعلومات لإكمال حسابك وتقديم خدماتنا لك',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 13,
            height: 1.7,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool isPhone = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      textDirection: isPhone ? TextDirection.ltr : TextDirection.rtl,
      textAlign: isPhone ? TextAlign.right : TextAlign.start,
      inputFormatters: isPhone
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ]
          : null,
      style: const TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
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
      ),
      validator: validator,
    );
  }

  Widget _buildGovernorateDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGovernorate,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'المحافظة',
        hintText: 'اختر المحافظة',
        prefixIcon: const Icon(
          Icons.location_on_outlined,
          color: AppColors.primary,
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
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
      ),
      items: _governorates.map((g) {
        return DropdownMenuItem<String>(
          value: g,
          child: Text(g),
        );
      }).toList(),
      onChanged: (v) => setState(() => _selectedGovernorate = v),
    );
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.25),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: AppColors.goldDark,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'رقم الواتساب سيُستخدم للتواصل معك بخصوص الطلبات والحجوزات.',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 11.5,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}