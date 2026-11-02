// lib/screens/intro_screen.dart
// ============================================================
// IntroScreen — شاشة تعريف واحدة
// الصفحة الأولى فقط: الشعار والاسم والآية، مع ملخص قصير
// لما كانت تشرحه الصفحات التالية (الزواج، المسار، خدمات العرس).
// الزر ينقل مباشرة إلى AuthScreen.
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
                    'ابدأ بخطوة جادة نحو زواج مبارك',
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

    return _IntroPageFrame(
      badge: 'أهلاً بك',
      archFraction: 0.32,
      arch: const _BrandArchPanel(),
      children: [
        const Text(
          UiCopy.introWelcomeTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: 1.2,
            color: AppPalette.green,
          ),
        ),
        const SizedBox(height: Space.xs),
        const Text(
          UiCopy.introWelcomeTagline,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: AppPalette.goldDark,
          ),
        ),
        const SizedBox(height: Space.md),
        const Center(child: OrnamentDivider(width: 90)),
        const SizedBox(height: Space.sm),
        const AyahCard(
          ayah: UiCopy.ayahNikah,
          reference: UiCopy.ayahNikahRef,
        ),
        const SizedBox(height: Space.md),
        Text(
          UiCopy.introSummary,
          textAlign: TextAlign.center,
          style: AppText.body.copyWith(color: AppPalette.textSecondary),
        ),
        const SizedBox(height: Space.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final tag in tags) _TagPill(label: tag),
          ],
        ),
      ],
    );
  }
}

class _IntroPageFrame extends StatelessWidget {
  const _IntroPageFrame({
    required this.arch,
    required this.children,
    this.badge,
    this.archFraction = 0.40,
  });

  final double archFraction;
  final Widget arch;
  final String? badge;
  final List<Widget> children;

  static const double _archAspect = 0.86;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxHeight;
        final archHeight = available.isFinite
            ? (available * archFraction).clamp(140.0, 360.0)
            : 240.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Space.xxl,
            Space.sm,
            Space.xxl,
            Space.lg,
          ),
          child: ContentMaxWidth(
            maxWidth: Sizes.formMax,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: Space.md),
                      child: Align(
                        child: SizedBox(
                          height: archHeight,
                          child: AspectRatio(
                            aspectRatio: _archAspect,
                            child: ArchFrame(padding: 6, child: arch),
                          ),
                        ),
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.md,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.surface,
                          borderRadius: Radii.brPill,
                          border: Border.all(
                            color: AppPalette.gold.withValues(alpha: 0.55),
                          ),
                          boxShadow: AppShadows.subtle,
                        ),
                        child: Text(
                          badge!,
                          style: AppText.micro.copyWith(
                            color: AppPalette.goldDeep,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: Space.lg),
                ...children,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BrandArchPanel extends StatelessWidget {
  const _BrandArchPanel();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppPalette.background),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: GeometricPatternPainter(
                color: AppPalette.gold.withValues(alpha: 0.18),
                spacing: 46,
              ),
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: w * 0.95,
                  height: w * 0.95,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppPalette.gold.withValues(alpha: 0.22),
                        AppPalette.gold.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: w * 0.10),
                  child: BrandMark(size: w * 0.76, framed: false),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md + 2,
        vertical: Space.sm - 1,
      ),
      decoration: BoxDecoration(
        color: AppPalette.goldSoft,
        borderRadius: Radii.brPill,
        border: Border.all(color: AppPalette.gold.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppText.buttonSmall.copyWith(
          fontSize: 12.5,
          color: AppPalette.goldDeep,
        ),
      ),
    );
  }
}
