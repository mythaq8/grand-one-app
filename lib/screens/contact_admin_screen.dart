// lib/screens/contact_admin_screen.dart
// ============================================================
// ContactAdminScreen — التواصل مع الإدارة
// ============================================================

import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_colors.dart';
import '../config.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';
import '../widgets/brand_decorations.dart';

class ContactAdminScreen extends StatefulWidget {
  const ContactAdminScreen({super.key});

  @override
  State<ContactAdminScreen> createState() =>
      _ContactAdminScreenState();
}

class _ContactAdminScreenState extends State<ContactAdminScreen> {
  final TextEditingController _messageController =
      TextEditingController();

  final SupabaseClient _client = Supabase.instance.client;

  bool _isLoading = false;

  static const int _maxMessageLength = 2000;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // ============================================================
  // سجل التدقيق
  // ============================================================

  Future<void> _logAudit({
    required String action,
    required bool success,
    required String details,
  }) async {
    final userId = _client.auth.currentUser?.id;
    await ApiService.logAuthEvent(
      kind: 'audit',
      identifier: userId ?? 'unknown',
      success: success,
      action: action,
      details: details,
    );
  }

  // ============================================================
  // إرسال الرسالة
  // ============================================================

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();

    // ═══ فحص الحقل الفارغ / الحد الأدنى ═══
    if (message.isEmpty) {
      ErrorHandler.showWarning(
        context,
        'الرجاء كتابة رسالتك',
      );
      return;
    }
    if (message.length < 10) {
      ErrorHandler.showWarning(
        context,
        'الرسالة قصيرة جداً. الحد الأدنى 10 أحرف.',
      );
      return;
    }

    // ═══ فحص الطول ═══
    if (message.length > _maxMessageLength) {
      ErrorHandler.showWarning(
        context,
        'الرسالة طويلة جداً. الحد الأقصى $_maxMessageLength حرف.',
      );
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _client.auth.currentUser?.id;

      if (userId == null) {
        if (!mounted) return;

        ErrorHandler.showError(
          context,
          null,
          customMessage: 'انتهت جلسة الدخول. يرجى تسجيل الدخول مجدداً.',
        );
        return;
      }

      final ok = await ApiService.contactAdmin({'message': message});
      if (!ok) {
        throw Exception('تعذر إرسال الرسالة');
      }

      if (!mounted) return;

      ErrorHandler.showSuccess(
        context,
        'تم إرسال رسالتك بنجاح',
      );

      _messageController.clear();

      // ═══ تأخير بسيط حتى يظهر SnackBar ═══
      await Future.delayed(
        const Duration(milliseconds: 800),
      );

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      debugPrint('🔴 Contact admin error: $e');

      // ═══ تسجيل الفشل ═══
      await _logAudit(
        action: 'contact_admin',
        success: false,
        details: 'Contact failed: $e',
      );

      if (!mounted) return;

      ErrorHandler.showError(
        context,
        e,
        customMessage: 'تعذر إرسال الرسالة. حاول مرة أخرى.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
      child: BrandScaffold(
        appBar: BrandAppBar(
          title: tr('contact_admin'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
          child: Column(
            children: [
              // ------------------------------------------------
              // واتساب الدعم (إن ضُبط الرقم من الخادم) بجانب نموذج الرسالة
              // ------------------------------------------------
              if (AppConfig.supportWhatsapp != null) ...[
                BrandCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_outlined, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'تواصل سريع عبر واتساب',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (AppConfig.supportHours != null)
                              Text(
                                AppConfig.supportHours!,
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                        onPressed: () => launchUrl(
                          Uri.parse('https://wa.me/${AppConfig.supportWhatsapp}'),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: const Text('فتح واتساب'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('أو اترك رسالة للإدارة:'),
                ),
                const SizedBox(height: 8),
              ],

              // ------------------------------------------------
              // رأس الصفحة
              // ------------------------------------------------
              BrandCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.gold
                              .withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      tr('contact_admin'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'نعمل على تسهيل تجربتك من البداية حتى النهاية',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'اكتب رسالتك بوضوح، وسيتولى فريق الإدارة مراجعتها والرد عند الحاجة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                        height: 1.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ------------------------------------------------
              // نموذج الرسالة
              // ------------------------------------------------
              BrandCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _buildIconBox(
                          Icons.edit_note_rounded,
                          AppColors.goldSoft,
                          AppColors.goldDark,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'اكتب رسالتك',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'يرجى توضيح طلبك أو استفسارك قدر الإمكان.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: _messageController,
                      maxLines: 8,
                      minLines: 6,
                      maxLength: _maxMessageLength,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        labelText: 'رسالتك',
                        hintText: 'اكتب رسالتك هنا...',
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 75),
                          child: Icon(
                            Icons.message_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ------------------------------------------------
                    // زر الإرسال
                    // ------------------------------------------------
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isLoading ? null : _sendMessage,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child:
                                    CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                size: 19,
                              ),
                        label: Text(
                          _isLoading
                              ? 'جاري الإرسال...'
                              : tr('send'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.primaryLight,
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ------------------------------------------------
              // ملاحظة
              // ------------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info
                        .withValues(alpha: 0.18),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppColors.info,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تأكد من كتابة المعلومات المهمة في رسالتك حتى تتمكن الإدارة من مساعدتك بشكل أفضل.',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.6,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // أيقونة صغيرة
  // ============================================================

  Widget _buildIconBox(
    IconData icon,
    Color background,
    Color foreground,
  ) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 22,
        color: foreground,
      ),
    );
  }
}