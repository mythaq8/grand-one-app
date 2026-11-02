// lib/ui/kit/section_header.dart
// ============================================================
// عناوين الأقسام — شكل واحد في كل التطبيق
// ------------------------------------------------------------
// الشاشات القديمة كانت ترسم العنوان بطرق مختلفة: شريط ذهبي هنا،
// أيقونة هناك، خط 4px في موضع آخر. هذا الملف يعطي شكلاً واحداً.
// ============================================================

import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.only(
      top: Space.xl,
      bottom: Space.md,
    ),
    this.accent = AppPalette.green,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// إجراء على اليسار (زر «عرض الكل» مثلاً).
  final Widget? trailing;

  final EdgeInsetsGeometry padding;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // شريط صغير بلون التمييز — علامة الهوية الثابتة.
          Container(
            width: 3,
            height: icon != null ? 20 : 17,
            decoration: BoxDecoration(
              color: AppPalette.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: Space.md),
          if (icon != null) ...[
            Icon(icon, size: Sizes.iconMd, color: accent),
            const SizedBox(width: Space.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppText.title.copyWith(color: AppPalette.textPrimary),
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
        ],
      ),
    );
  }
}
