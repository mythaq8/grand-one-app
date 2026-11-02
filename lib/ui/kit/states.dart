// lib/ui/kit/states.dart
// ============================================================
// حالات الشاشة: تحميل / فراغ / خطأ
// ------------------------------------------------------------
// كانت كل شاشة ترسم «لا توجد بيانات» و«حدث خطأ» بطريقتها.
// هنا شكل واحد، مع زر إعادة محاولة اختياري.
// ============================================================

import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';

/// حالة تحميل موحّدة.
class LoadingState extends StatelessWidget {
  const LoadingState({
    super.key,
    this.message,
    this.padding = const EdgeInsets.all(Space.huge),
  });

  final String? message;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              color: AppPalette.navy,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: Space.lg),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppText.bodySecondary,
            ),
          ],
        ],
      ),
    );
  }
}

/// حالة فراغ: أيقونة + عنوان + شرح + إجراء اختياري.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.body,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.all(Space.huge),
  });

  final String title;
  final String? body;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppPalette.navySoft,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppPalette.gold.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(icon, size: Sizes.iconXl, color: AppPalette.navy),
          ),
          const SizedBox(height: Space.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.title.copyWith(color: AppPalette.textPrimary),
          ),
          if (body != null) ...[
            const SizedBox(height: Space.sm),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: AppText.bodySecondary,
            ),
          ],
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: Space.xl),
            SizedBox(
              width: 220,
              child: FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// حالة خطأ موحّدة، مع إعادة محاولة.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.title = 'تعذّر تحميل البيانات',
    this.onRetry,
    this.retryLabel = 'إعادة المحاولة',
    this.padding = const EdgeInsets.all(Space.huge),
  });

  final String message;
  final String title;
  final VoidCallback? onRetry;
  final String retryLabel;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppPalette.errorLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppPalette.error.withValues(alpha: 0.25),
              ),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              size: Sizes.iconXl,
              color: AppPalette.error,
            ),
          ),
          const SizedBox(height: Space.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.title.copyWith(color: AppPalette.textPrimary),
          ),
          const SizedBox(height: Space.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.bodySecondary,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: Space.xl),
            SizedBox(
              width: 200,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: Sizes.iconMd),
                label: Text(retryLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
