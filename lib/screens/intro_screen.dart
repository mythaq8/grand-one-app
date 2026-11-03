// lib/screens/intro_screen.dart
// ============================================================
// IntroScreen — تعريف GRAND ONE
// ============================================================

import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../design/typography.dart';
import '../ui/layout/responsive.dart';
import '../ui_copy.dart';
import '../widgets/brand_mark.dart';
import '../widgets/brand_decorations.dart';
import 'auth_screen.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({Key? key}) : super(key: key);

  void _goAuth(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BrandScaffold(
      showPattern: true,
      body: Column(
        children: [
          const Expanded(child: _WelcomePage()),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.xxl,
              Space.md,
              Space.xxl,
              Space.xl,
            ),
            child: ContentMaxWidth(
              maxWidth: Sizes.formMax,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BrandButton(
                    label: UiCopy.introStartButton,
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppPalette.onPrimary,
                      size: Sizes.iconMd,
                    ),
                    onPressed: () => _goAuth(context),
                  ),
                  const SizedBox(height: Space.sm + 2),
                  Text(
                    UiCopy.introSecondaryHint,
                    textAlign: TextAlign.center,
                    style: AppText.micro.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final tags = UiCopy.introSummaryNote
        .split('•')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.xxl, Space.xl, Space.xxl, Space.md),
      child: ContentMaxWidth(
        maxWidth: Sizes.formMax,
        child: Column(
          children: [
            const SizedBox(height: Space.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                return BrandMark(
                  variant: BrandMarkVariant.lockup,
                  size: constraints.maxWidth,
                );
              },
            ),
            const SizedBox(height: Space.xxl),
            Text(
              UiCopy.brandMessage,
              textAlign: TextAlign.center,
              style: AppText.section,
            ),
            const SizedBox(height: Space.md),
            Text(
              UiCopy.introSummary,
              textAlign: TextAlign.center,
              style: AppText.bodySecondary.copyWith(fontSize: 14),
            ),
            const SizedBox(height: Space.xl),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                for (final tag in tags)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.md,
                      vertical: Space.sm,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppGradients.goldSoft,
                      borderRadius: Radii.brPill,
                      border: Border.all(
                        color: AppPalette.gold.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: AppText.caption.copyWith(
                        color: AppPalette.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
