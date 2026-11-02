// lib/screens/exploration/widgets/bride_result_card.dart
// ============================================================
// بطاقة نتيجة البحث عن شريكة
// ------------------------------------------------------------
// مستخرجة من exploration_screen (كانت ~200 سطر داخل الشاشة)،
// لأنها أكبر عنصر متكرر في المسار وأصعب شيء في اختباره.
//
// تحسين مهم في هذه النسخة:
//   سابقاً كانت البطاقة تعرض 8 رقائق ثابتة، ومعظمها نص
//   «غير محدد» حين لا تكون البيانات متوفرة. فيغرق ما هو مهم
//   (العمر، الطول، الالتزام) في ضجيج. الآن تُعرض القيم
//   المعلومة فقط، ويُذكر عدد ما لم يُذكر في سطر واحد هادئ.
//
// لم يتغيّر أي منطق: الاختيار للحصة (bCode) ونفس السلوك.
// ============================================================

import 'package:flutter/material.dart';

import '../../../design/tokens.dart';
import '../../../design/typography.dart';

/// وصفة رقاقة معلومات صغيرة.
class BrideChipData {
  const BrideChipData({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class BrideResultCard extends StatelessWidget {
  const BrideResultCard({
    super.key,
    required this.code,
    required this.location,
    required this.details,
    required this.selected,
    required this.onToggle,
    required this.onOpenProfile,
    this.features = const [],
    this.unknownCount = 0,
  });

  /// رمز العروس المجهول (لا اسم ولا رقم).
  final String code;

  /// المحافظة ومنطقة الإقامة.
  final String location;

  /// القيم المعروفة فقط. لا تُمرّر «غير محدد» هنا.
  final List<BrideChipData> details;

  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onOpenProfile;

  /// وسوم الميزات (تقبل التعدد، حافظة للقرآن...).
  final List<({String label, Color bg, Color fg})> features;

  /// عدد الحقول التي لم تُذكر — يُلخّص في سطر واحد.
  final int unknownCount;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Motion.fast,
      curve: Motion.curve,
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: Radii.brLg,
        border: Border.all(
          color: selected ? AppPalette.green : AppPalette.borderLight,
          width: selected ? 1.6 : 1,
        ),
        boxShadow: selected ? AppShadows.soft : AppShadows.subtle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: Radii.brLg,
          child: Padding(
            padding: const EdgeInsets.all(Space.md + 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: Space.sm + 2),
                  Wrap(
                    spacing: Space.xs + 2,
                    runSpacing: Space.xs + 2,
                    children: [
                      for (final d in details) _infoChip(d),
                    ],
                  ),
                ],
                if (features.isNotEmpty) ...[
                  const SizedBox(height: Space.sm),
                  Wrap(
                    spacing: Space.xs + 2,
                    runSpacing: Space.xs + 2,
                    children: [
                      for (final f in features)
                        _featureChip(f.label, f.bg, f.fg),
                    ],
                  ),
                ],
                if (unknownCount > 0) ...[
                  const SizedBox(height: Space.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 12,
                        color: AppPalette.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$unknownCount معلومة لم تُذكر بعد',
                          style: AppText.micro.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppPalette.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: selected ? AppPalette.goldSoft : AppPalette.greenSoft,
            borderRadius: Radii.brSm,
          ),
          child: Icon(
            selected ? Icons.check_rounded : Icons.person_outline_rounded,
            size: Sizes.iconMd,
            color: selected ? AppPalette.goldDark : AppPalette.green,
          ),
        ),
        const SizedBox(width: Space.sm + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'رمز العروس: $code',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.buttonSmall.copyWith(
                  fontSize: 13,
                  color: AppPalette.green,
                ),
              ),
              if (location.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption,
                ),
              ],
            ],
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.visibility_outlined,
            size: Sizes.iconMd,
            color: AppPalette.greenLight,
          ),
          onPressed: onOpenProfile,
          tooltip: 'عرض الملف الكامل',
        ),
      ],
    );
  }

  Widget _infoChip(BrideChipData d) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 4),
      decoration: BoxDecoration(
        color: AppPalette.surfaceTint,
        borderRadius: Radii.brXs,
        border: Border.all(color: AppPalette.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(d.icon, size: 12, color: AppPalette.textTertiary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              d.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.micro.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppPalette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureChip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: Radii.brXs),
      child: Text(
        text,
        style: AppText.micro.copyWith(fontSize: 9.5, color: fg),
      ),
    );
  }
}
