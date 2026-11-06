// lib/widgets/form_fields.dart
// ============================================================
// أدوات مشتركة لحقول GRAND ONE
// ============================================================

import 'package:flutter/material.dart';
import '../app_colors.dart';

// ============================================================
// ثوابت مساعدة
// ============================================================

const double _fieldRadius = 14.0;

const EdgeInsets _fieldPadding = EdgeInsets.symmetric(
  horizontal: 16,
  vertical: 16,
);

const TextStyle _fieldLabelStyle = TextStyle(
  fontFamily: 'Tajawal',
  fontSize: 14,
  fontWeight: FontWeight.w700,
  color: AppColors.textPrimary,
);

const TextStyle _fieldInputStyle = TextStyle(
  fontFamily: 'Tajawal',
  fontSize: 14,
  color: AppColors.textPrimary,
);

const TextStyle _fieldDialogTitleStyle = TextStyle(
  fontFamily: 'Tajawal',
  fontWeight: FontWeight.w700,
  color: AppColors.textPrimary,
);

const TextStyle _fieldOptionTextStyle = TextStyle(
  fontFamily: 'Tajawal',
  fontSize: 14,
  color: AppColors.textPrimary,
);

const TextStyle _fieldHintStyle = TextStyle(
  fontFamily: 'Tajawal',
  fontSize: 13,
  height: 1.45,
  fontWeight: FontWeight.w700,
  color: AppColors.goldDeep,
);

/// توضيح ظاهر تحت عنوان الحقل (خلفية ذهبية خفيفة + أيقونة).
Widget? _fieldHintWidget(String? hint) {
  if (hint == null || hint.trim().isEmpty) return null;
  return Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 4),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: AppColors.goldDark,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(hint, style: _fieldHintStyle),
            ),
          ],
        ),
      ),
    ),
  );
}

// ============================================================
// InputDecoration موحّد
// ============================================================

InputDecoration _brandFieldDecoration({
  required String hintText,
  Widget? suffixIcon,
  Widget? prefixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: _fieldPadding,
    prefixIcon: prefixIcon,
    prefixIconColor: AppColors.primary,
    suffixIcon: suffixIcon,
    suffixIconColor: AppColors.primary,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_fieldRadius),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_fieldRadius),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_fieldRadius),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_fieldRadius),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_fieldRadius),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    hintStyle: const TextStyle(
      fontFamily: 'Tajawal',
      fontSize: 13,
      color: AppColors.mutedText,
    ),
  );
}

// ============================================================
// 1. AppTextField
// ============================================================

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool isNumber;
  final bool required;
  final int? maxLines;
  final TextInputAction? textInputAction;
  final List<String>? autofillHints;
  final bool autocorrect;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.isNumber = false,
    this.required = true,
    this.maxLines = 1,
    this.textInputAction,
    this.autofillHints,
    this.autocorrect = true,
  });

  @override
  Widget build(BuildContext context) {
    final hintWidget = _fieldHintWidget(hint);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            required ? '$label *' : label,
            style: _fieldLabelStyle,
          ),
          if (hintWidget != null) hintWidget,
          const SizedBox(height: 7),
          TextFormField(
            controller: controller,
            keyboardType:
                isNumber ? TextInputType.number : TextInputType.text,
            maxLines: maxLines,
            textInputAction: textInputAction,
            autocorrect: autocorrect,
            autofillHints: autofillHints,
            style: _fieldInputStyle,
            decoration: _brandFieldDecoration(
              hintText: required ? 'مطلوب' : 'اختياري',
            ),
            validator: required
                ? (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'مطلوب';
                    }
                    return null;
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 2. AppDropdown
// ============================================================

class AppDropdown extends StatelessWidget {
  final String label;
  final String? hint;
  final List<String> items;
  final String? current;
  final ValueChanged<String?> onChange;
  final bool required;

  const AppDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.current,
    required this.onChange,
    this.hint,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    final hintWidget = _fieldHintWidget(hint);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            required ? '$label *' : label,
            style: _fieldLabelStyle,
          ),
          if (hintWidget != null) hintWidget,
          const SizedBox(height: 7),
          DropdownButtonFormField<String>(
            initialValue: current,
            isExpanded: true,
            style: _fieldInputStyle,
            decoration: _brandFieldDecoration(
              hintText: required ? 'اختر $label' : 'اختياري',
              suffixIcon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 22,
              ),
            ),
            items: items.map((e) {
              return DropdownMenuItem<String>(
                value: e,
                child: Text(
                  e,
                  overflow: TextOverflow.ellipsis,
                  style: _fieldOptionTextStyle,
                ),
              );
            }).toList(),
            onChanged: onChange,
            validator: required
                ? (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'مطلوب';
                    }
                    return null;
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 3. AppMultiSelect (موحّد)
// ============================================================

class AppMultiSelect extends StatelessWidget {
  final String label;
  final String? hint;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final bool required;
  final IconData icon;
  final String? dialogTitle;
  final String emptyText;

  const AppMultiSelect({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.hint,
    this.required = true,
    this.icon = Icons.checklist_rounded,
    this.dialogTitle,
    this.emptyText = 'اختر من القائمة',
  });

  // ═══════════════════════════════════════════════════════════
  // 🔧 النسخة المُحسّنة من _openPicker
  // ═══════════════════════════════════════════════════════════

  Future<void> _openPicker(BuildContext context) async {
    final temp = List<String>.from(selected);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final viewHeight = MediaQuery.sizeOf(dialogContext).height;
            final listHeight = (viewHeight * 0.42).clamp(160.0, 380.0);
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: Text(
                  dialogTitle ?? label,
                  style: _fieldDialogTitleStyle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: listHeight,
                  child: ListView.builder(
                    // ═══ استخدام ListView.builder بدلاً من separated ═══
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = temp.contains(option);

                      return CheckboxListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        dense: true,
                        activeColor: AppColors.primary,
                        title: Text(
                          option,
                          style: _fieldOptionTextStyle,
                        ),
                        value: isSelected,
                        onChanged: (checked) {
                          setDialogState(() {
                            if (checked == true) {
                              if (!temp.contains(option)) {
                                temp.add(option);
                              }
                            } else {
                              temp.remove(option);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                actionsPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                actions: [
                  TextButton.icon(
                    onPressed: () {
                      setDialogState(() {
                        temp.clear();
                      });
                    },
                    icon: const Icon(
                      Icons.clear_all_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    label: const Text(
                      'مسح الكل',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      onChanged(List<String>.from(temp));
                      Navigator.pop(dialogContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 42),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'تم',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = selected.isNotEmpty;
    final hintWidget = _fieldHintWidget(hint);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            required ? '$label *' : label,
            style: _fieldLabelStyle,
          ),
          if (hintWidget != null) hintWidget,
          const SizedBox(height: 7),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(_fieldRadius),
              onTap: () {
                _openPicker(context);
              },
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(_fieldRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 21,
                      color: hasSelection
                          ? AppColors.primary
                          : AppColors.mutedText,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        hasSelection
                            ? selected.join('، ')
                            : emptyText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          color: hasSelection
                              ? AppColors.textPrimary
                              : AppColors.mutedText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 4. AppLanguagePicker (استخدام AppMultiSelect)
// ============================================================

class AppLanguagePicker extends StatelessWidget {
  final List<String> selected;
  final List<String> options;
  final ValueChanged<List<String>> onChanged;
  final String? hint;

  const AppLanguagePicker({
    super.key,
    required this.selected,
    required this.options,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return AppMultiSelect(
      label: 'اللغات',
      hint: hint,
      options: options,
      selected: selected,
      onChanged: onChanged,
      required: true,
      icon: Icons.language_rounded,
      dialogTitle: 'اختر اللغات',
      emptyText: 'اختر اللغات',
    );
  }
}