// lib/ui/kit/status_pill.dart
// ============================================================
// طابع الحالة — شكل واحد لكل الحالات في التطبيق
// ------------------------------------------------------------
// قبل هذا الملف كانت الحالة (قيد المراجعة / مقبول / مرفوض ...)
// تُرسم في كل شاشة بطريقة مختلفة، وبأسماء نصية متكررة.
// هنا مصدر واحد للشكل واللون والنص.
//
// أسماء الحالات مأخوذة من القيم الحقيقية في قاعدة البيانات
// والشاشات الموجودة (my_bookings / exploration / occasion).
// ============================================================

import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';

/// نبرة الحالة — تحدد اللون.
enum PillTone { neutral, info, success, warning, danger, gold }

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.tone = PillTone.neutral,
    this.icon,
    this.dense = false,
  });

  final String label;
  final PillTone tone;
  final IconData? icon;
  final bool dense;

  static ({Color fg, Color bg}) colorsFor(PillTone tone) {
    return switch (tone) {
      PillTone.neutral => (
          fg: AppPalette.textMuted,
          bg: AppPalette.surfaceTint,
        ),
      PillTone.info => (fg: AppPalette.infoDark, bg: AppPalette.infoLight),
      PillTone.success => (
          fg: AppPalette.successDark,
          bg: AppPalette.successLight,
        ),
      PillTone.warning => (
          fg: AppPalette.warningDark,
          bg: AppPalette.warningLight,
        ),
      PillTone.danger => (fg: AppPalette.errorDark, bg: AppPalette.errorLight),
      PillTone.gold => (fg: AppPalette.goldDeep, bg: AppPalette.goldSoft),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = colorsFor(tone);

    // الطابع يُوضع عادةً داخل Row بجانب نص آخر، فيأتيه عرض غير
    // محدود. بدون حد أقصى يفيض عند تكبير الخط. نحدّه بنسبة من
    // عرض الشاشة فيصمد في كل السياقات.
    final maxWidth = MediaQuery.sizeOf(context).width * 0.62;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? Space.sm : Space.md,
          vertical: dense ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: Radii.brPill,
          border: Border.all(color: c.fg.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: dense ? 12 : 13, color: c.fg),
              const SizedBox(width: Space.xs),
            ],
            Flexible(
              child: Text(
                label,
                style: (dense ? AppText.micro : AppText.caption).copyWith(
                  color: c.fg,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// يبني طابعاً من اسم حالة خام قادمة من الخادم.
///
/// لا تُضاف حالات جديدة هنا إلا إن كانت موجودة فعلاً في
/// قاعدة البيانات أو في منطق الشاشات.
class StatusPillFromCode extends StatelessWidget {
  const StatusPillFromCode({
    super.key,
    required this.code,
    this.dense = false,
  });

  final String code;
  final bool dense;

  static ({String label, PillTone tone, IconData icon}) describe(String code) {
    switch (code) {
      // ── حجوزات ──
      case 'pending':
        return (
          label: 'قيد المراجعة',
          tone: PillTone.warning,
          icon: Icons.schedule_rounded,
        );
      case 'quote_requested':
        return (
          label: 'طلب عرض سعر',
          tone: PillTone.info,
          icon: Icons.request_quote_outlined,
        );
      case 'quoted':
        return (
          label: 'عرض سعر جاهز',
          tone: PillTone.gold,
          icon: Icons.price_change_outlined,
        );
      case 'approved':
        return (
          label: 'مقبول',
          tone: PillTone.success,
          icon: Icons.check_circle_outline_rounded,
        );
      case 'awaiting_payment':
        return (
          label: 'بانتظار العربون',
          tone: PillTone.gold,
          icon: Icons.payment_outlined,
        );
      case 'paid_pending_verification':
        return (
          label: 'بانتظار تحقق الإدارة',
          tone: PillTone.info,
          icon: Icons.hourglass_top_rounded,
        );
      case 'deposit_rejected':
        return (
          label: 'إشعار الدفع مرفوض',
          tone: PillTone.danger,
          icon: Icons.error_outline_rounded,
        );
      case 'ready':
        return (
          label: 'جاهز للتنفيذ',
          tone: PillTone.gold,
          icon: Icons.event_available_rounded,
        );
      case 'completed':
        return (
          label: 'مكتمل',
          tone: PillTone.success,
          icon: Icons.verified_rounded,
        );
      case 'rejected':
        return (
          label: 'مرفوض',
          tone: PillTone.danger,
          icon: Icons.cancel_outlined,
        );
      case 'cancelled':
        return (
          label: 'ملغي',
          tone: PillTone.neutral,
          icon: Icons.block_rounded,
        );
      case 'modification_proposed':
        return (
          label: 'تعديل مقترح',
          tone: PillTone.gold,
          icon: Icons.edit_calendar_outlined,
        );
      case 'expired':
        return (
          label: 'انتهت المهلة',
          tone: PillTone.neutral,
          icon: Icons.timer_off_outlined,
        );

      // ── رغبات الزواج ──
      case 'awaiting_groom':
        return (
          label: 'بانتظار موافقة الشاب',
          tone: PillTone.gold,
          icon: Icons.visibility_outlined,
        );
      case 'awaiting_bride':
        return (
          label: 'بانتظار موافقة الفتاة',
          tone: PillTone.gold,
          icon: Icons.favorite_border_rounded,
        );
      case 'accepted':
        return (
          label: 'مقبول',
          tone: PillTone.success,
          icon: Icons.check_circle_outline_rounded,
        );
      case 'pending_payment':
        return (
          label: 'بانتظار الدفع',
          tone: PillTone.gold,
          icon: Icons.payments_outlined,
        );
      case 'pending_admin_review':
        return (
          label: 'بانتظار المشرف',
          tone: PillTone.gold,
          icon: Icons.hourglass_top_rounded,
        );
      case 'matched':
        return (
          label: 'تم تبادل التواصل',
          tone: PillTone.success,
          icon: Icons.favorite_rounded,
        );

      // ── طلبات المناسبات ──
      case 'new':
        return (
          label: 'جديد',
          tone: PillTone.info,
          icon: Icons.fiber_new_outlined,
        );

      default:
        return (
          label: code,
          tone: PillTone.neutral,
          icon: Icons.help_outline_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = describe(code);
    return StatusPill(
      label: d.label,
      tone: d.tone,
      icon: d.icon,
      dense: dense,
    );
  }
}
