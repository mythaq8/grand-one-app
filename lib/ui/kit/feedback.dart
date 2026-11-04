// lib/ui/kit/feedback.dart
// ============================================================
// رسائل تنبيه وحوارات تأكيد موحّدة (بدل SnackBar/AlertDialog متفرقة).
// ============================================================

import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';

enum FeedbackTone { info, success, error }

/// رسالة سفلية قصيرة بلون يدل على النتيجة.
void showAppSnack(
  BuildContext context,
  String message, {
  FeedbackTone tone = FeedbackTone.info,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final (IconData icon, Color color) = switch (tone) {
    FeedbackTone.success => (Icons.check_circle_rounded, AppPalette.success),
    FeedbackTone.error => (Icons.error_rounded, AppPalette.error),
    FeedbackTone.info => (Icons.info_rounded, AppPalette.gold),
  };
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color, size: Sizes.iconMd),
            const SizedBox(width: Space.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

/// حوار تأكيد بزرّين متناسقين. يعيد true عند التأكيد.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  String? message,
  String confirmLabel = 'تأكيد',
  String cancelLabel = 'إلغاء',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(
        Space.lg,
        0,
        Space.lg,
        Space.md,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            backgroundColor: destructive ? AppPalette.error : AppPalette.navy,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel, style: AppText.button),
        ),
      ],
    ),
  );
  return result ?? false;
}
