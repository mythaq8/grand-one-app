// lib/widgets/ux_helpers.dart
// ============================================================
// ودجات توضيح تجربة المستخدم (InfoBanner / SectionHint / Help)
// ============================================================

import 'package:flutter/material.dart';

import '../app_colors.dart';

enum InfoBannerTone { info, tip, warning, success }

/// شريط توضيحي أعلى الشاشة أو أعلى قسم.
class InfoBanner extends StatelessWidget {
  final String message;
  final InfoBannerTone tone;
  final IconData? icon;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onHelp;

  const InfoBanner({
    super.key,
    required this.message,
    this.tone = InfoBannerTone.info,
    this.icon,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 8),
    this.onHelp,
  });

  Color get _bg {
    switch (tone) {
      case InfoBannerTone.tip:
        return AppColors.goldSoft;
      case InfoBannerTone.warning:
        return AppColors.warningLight;
      case InfoBannerTone.success:
        return AppColors.successLight;
      case InfoBannerTone.info:
        return AppColors.infoLight;
    }
  }

  Color get _fg {
    switch (tone) {
      case InfoBannerTone.tip:
        return AppColors.goldDeep;
      case InfoBannerTone.warning:
        return AppColors.warningDark;
      case InfoBannerTone.success:
        return AppColors.successDark;
      case InfoBannerTone.info:
        return AppColors.infoDark;
    }
  }

  IconData get _defaultIcon {
    switch (tone) {
      case InfoBannerTone.tip:
        return Icons.lightbulb_outline_rounded;
      case InfoBannerTone.warning:
        return Icons.info_outline_rounded;
      case InfoBannerTone.success:
        return Icons.check_circle_outline_rounded;
      case InfoBannerTone.info:
        return Icons.tips_and_updates_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _fg.withValues(alpha: 0.18)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon ?? _defaultIcon, color: _fg, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: _fg,
                  ),
                ),
              ),
              if (onHelp != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onHelp,
                  tooltip: 'المزيد',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.help_outline_rounded, color: _fg, size: 20),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// جملة قصيرة تحت عنوان قسم.
class SectionHint extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;

  const SectionHint(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(4, 0, 4, 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 13,
          height: 1.4,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// زر مساعدة يفتح ورقة شرح.
class HelpIconButton extends StatelessWidget {
  final String title;
  final String body;
  final Color? color;

  const HelpIconButton({
    super.key,
    required this.title,
    required this.body,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'شرح',
      onPressed: () => showHelpSheet(
        context,
        title: title,
        body: body,
      ),
      icon: Icon(
        Icons.help_outline_rounded,
        color: color ?? AppColors.primary,
        size: 22,
      ),
    );
  }
}

Future<void> showHelpSheet(
  BuildContext context, {
  required String title,
  required String body,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    body,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 15,
                      height: 1.55,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('حسنًا، فهمت'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// بطاقة مسار في الصفحة الرئيسية مع عنوان ووصف وزر.
class JourneyCard extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final String actionLabel;

  const JourneyCard({
    super.key,
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.actionLabel = 'متابعة',
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: AppColors.shadowSubtle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: accent, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        actionLabel,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left_rounded, color: accent.withValues(alpha: 0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
