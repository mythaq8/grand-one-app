// lib/ui/kit/tiles.dart
// ============================================================
// عناصر قوائم موحّدة: سطر معلومات / زر إجراء / بطاقة إحصاء
// ------------------------------------------------------------
// تُستخدم في شاشات التفاصيل والقوائم، بدل تكرار صفوف
// «عنوان + قيمة» بأحجام وألوان مختلفة في كل شاشة.
// ============================================================

import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';

/// سطر «عنوان : قيمة» لتفاصيل قابلة للقراءة بسرعة.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.dense = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? Space.xs : Space.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: Sizes.iconSm + 2, color: AppPalette.textTertiary),
            const SizedBox(width: Space.sm),
          ],
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: AppText.bodySecondary.copyWith(
                color: AppPalette.textTertiary,
              ),
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.start,
              style: AppText.body.copyWith(
                color: valueColor ?? AppPalette.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// صف إجراء داخل قائمة (أيقونة + عنوان + شرح + سهم).
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.accent = AppPalette.navy,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  /// عنصر إضافي قبل السهم (نص حالة، شارة عدد...).
  final Widget? trailing;

  final Color accent;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.brMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: Space.md,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: Radii.brSm,
                ),
                child: Icon(icon, size: Sizes.iconMd, color: accent),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppText.title.copyWith(
                        fontSize: 15,
                        color: AppPalette.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppText.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: Space.sm),
                trailing!,
              ],
              if (showChevron) ...[
                const SizedBox(width: Space.xs),
                Icon(
                  Icons.chevron_left_rounded,
                  size: Sizes.iconMd,
                  color: accent.withValues(alpha: 0.55),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// بطاقة إحصاء صغيرة (عدد الطلبات، عدد الحجوزات...).
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.accent = AppPalette.navy,
    this.onTap,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.surface,
      borderRadius: Radii.brMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.brMd,
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: Space.md,
          ),
          decoration: BoxDecoration(
            borderRadius: Radii.brMd,
            border: Border.all(color: AppPalette.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: Sizes.iconMd, color: accent),
                const SizedBox(height: Space.sm),
              ],
              Text(
                value,
                style: AppText.number.copyWith(
                  fontSize: 20,
                  color: AppPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppText.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
