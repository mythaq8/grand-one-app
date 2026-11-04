// lib/widgets/role_account_menu.dart
// ============================================================
// قائمة «حسابي» لحسابات المزوّد والمنظّم: الإشعارات، بيانات التواصل،
// الدعم، الإعدادات، والخروج بتأكيد. كانت هذه الشاشات غير متاحة لهما.
// ============================================================

import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../design/typography.dart';
import '../screens/notifications_screen.dart';
import '../services/api_exceptions.dart';
import '../services/api_service.dart';
import '../ui/kit/kit.dart';

class RoleAccountButton extends StatelessWidget {
  const RoleAccountButton({
    super.key,
    required this.onSignOut,
    this.isProvider = false,
    this.onContactUpdated,
  });

  final Future<void> Function() onSignOut;
  final bool isProvider;
  final VoidCallback? onContactUpdated;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'حسابي',
      icon: const Icon(Icons.account_circle_outlined),
      onPressed: () => _open(context),
    );
  }

  Future<void> _open(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      // بلا هذا يُقصّ آخر بند (الخروج) على الشاشات القصيرة
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: Space.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _tile(sheet, Icons.notifications_none_rounded, 'الإشعارات', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              }),
              if (isProvider)
                _tile(sheet, Icons.contact_phone_outlined, 'أرقام التواصل', () {
                  _editProviderContact(context);
                }),
              _tile(sheet, Icons.support_agent_rounded, 'التواصل مع الإدارة', () {
                Navigator.pushNamed(context, '/contact-admin');
              }),
              _tile(sheet, Icons.settings_outlined, 'الإعدادات العامة', () {
                Navigator.pushNamed(context, '/settings');
              }),
              const Divider(height: Space.lg),
              _tile(
                sheet,
                Icons.logout_rounded,
                'تسجيل الخروج',
                () async {
                  final ok = await confirmAction(
                    context,
                    title: 'تسجيل الخروج',
                    message: 'هل تريد تسجيل الخروج من حسابك؟',
                    confirmLabel: 'خروج',
                    destructive: true,
                  );
                  if (ok) await onSignOut();
                },
                color: AppPalette.error,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext sheet,
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppPalette.navy),
      title: Text(label, style: AppText.title.copyWith(color: color)),
      onTap: () {
        Navigator.pop(sheet);
        onTap();
      },
    );
  }

  Future<void> _editProviderContact(BuildContext context) async {
    Map<String, dynamic> provider = const {};
    try {
      final res = await ApiService.getProviderMe();
      if (res['provider'] is Map) {
        provider = Map<String, dynamic>.from(res['provider'] as Map);
      }
    } catch (_) {}
    if (!context.mounted) return;
    final phone = TextEditingController(text: provider['phone']?.toString() ?? '');
    final whatsapp =
        TextEditingController(text: provider['whatsapp']?.toString() ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('أرقام التواصل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تظهر للعميل بعد تأكيد عربونه فقط.',
              style: AppText.bodySecondary,
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: whatsapp,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'واتساب',
                hintText: '9639xxxxxxxx',
              ),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'هاتف',
                hintText: '09xxxxxxxx',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () async {
              try {
                await ApiService.updateProviderMe({
                  'phone': phone.text.trim(),
                  'whatsapp': whatsapp.text.trim(),
                });
                if (ctx.mounted) Navigator.pop(ctx, true);
              } on ApiException catch (e) {
                if (ctx.mounted) {
                  showAppSnack(ctx, e.message, tone: FeedbackTone.error);
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (saved == true && context.mounted) {
      showAppSnack(context, 'تم حفظ أرقام التواصل', tone: FeedbackTone.success);
      onContactUpdated?.call();
    }
  }
}
