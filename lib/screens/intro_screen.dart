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
import '../widgets/islamic_decorations.dart';
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
    return IslamicScaffold(
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
                  IslamicButton(
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: Space.xxxl,
                horizontal: Space.lg,
              ),
              decoration: BoxDecoration(
                gradient: AppGradients.splash,
                borderRadius: Radii.brXl,
                border: Border.all(
                  color: AppPalette.gold.withValues(alpha: 0.35),
                ),
                boxShadow: AppShadows.medium,
              ),
              child: Column(
                children: [
                  const BrandMark(
                    size: 96,
                    framed: false,
                    onDark: true,
                  ),
                  const SizedBox(height: Space.xl),
                  const BrandWordmark(
                    fontSize: 28,
                    showTagline: true,
                  ),
                  const SizedBox(height: Space.md),
                  Text(
                    UiCopy.brandTaglineAr,
                    textAlign: TextAlign.center,
                    style: AppText.subtitle.copyWith(
                      color: AppPalette.goldLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.xxl),
            Text(
              UiCopy.brandMessage,
              textAlign: TextAlign.center,
              style: AppText.section.copyWith(
                color: AppPalette.textPrimary,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: Space.md),
            Text(
              UiCopy.introSummary,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(
                color: AppPalette.textSecondary,
              ),
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
                      color: AppPalette.navySoft,
                      borderRadius: Radii.brPill,
                      border: Border.all(color: AppPalette.borderLight),
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
