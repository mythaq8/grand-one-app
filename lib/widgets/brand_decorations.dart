// lib/widgets/brand_decorations.dart
// زخارف وودجات واجهة GRAND ONE
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'screen_fit.dart';
import '../app_colors.dart';
import '../design/tokens.dart';
import '../design/typography.dart';

// ============================================================
// 1. زخرفة هندسية خفيفة
// ============================================================

class GeometricPatternPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double strokeWidth;
  final bool drawConnectingLines;

  GeometricPatternPainter({
    this.color = AppColors.patternGold,
    this.spacing = 60,
    this.strokeWidth = 0.7,
    this.drawConnectingLines = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      for (double y = -spacing; y < size.height + spacing; y += spacing) {
        _drawStar(canvas, Offset(x, y), spacing * 0.22, paint);

        if (drawConnectingLines) {
          _drawConnectingDiamond(
            canvas,
            Offset(x + spacing / 2, y + spacing / 2),
            spacing * 0.15,
            paint,
          );
        }
      }
    }
  }

  void _drawStar(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    final path = Path();
    const points = 8;

    for (int i = 0; i < points; i++) {
      final outerAngle = (i * math.pi / 4) - math.pi / 2;
      final innerAngle = outerAngle + math.pi / 8;

      final outer = Offset(
        center.dx + radius * math.cos(outerAngle),
        center.dy + radius * math.sin(outerAngle),
      );

      final inner = Offset(
        center.dx + radius * 0.42 * math.cos(innerAngle),
        center.dy + radius * 0.42 * math.sin(innerAngle),
      );

      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
      } else {
        path.lineTo(outer.dx, outer.dy);
      }

      path.lineTo(inner.dx, inner.dy);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawConnectingDiamond(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius, center.dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant GeometricPatternPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.spacing != spacing ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.drawConnectingLines != drawConnectingLines;
  }
}

// ============================================================
// 2. الخلفية الإسلامية (محسّنة)
// ============================================================

class BrandBackground extends StatelessWidget {
  final Widget child;
  final bool showPattern;
  final Color? patternColor;
  final double patternSpacing;

  const BrandBackground({
    super.key,
    required this.child,
    this.showPattern = false,
    this.patternColor,
    this.patternSpacing = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.primarySoft),
      child: Stack(
        children: [
          const Positioned(
            top: -140,
            left: -40,
            right: -40,
            height: 320,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppGradients.glowGold),
              ),
            ),
          ),
          const Positioned(
            right: -120,
            bottom: -140,
            width: 320,
            height: 320,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppGradients.glowNavy),
              ),
            ),
          ),
          if (showPattern)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: GeometricPatternPainter(
                      color: patternColor ?? AppPalette.patternGoldStrong,
                      spacing: patternSpacing,
                      strokeWidth: 0.55,
                    ),
                    isComplex: true,
                    willChange: false,
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

// ============================================================
// 3. Scaffold إسلامي
// ============================================================

class BrandScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final bool showPattern;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const BrandScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.showPattern = false,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        top: appBar == null,
        child: BrandBackground(
          showPattern: showPattern,
          child: ScreenFrame(child: body),
        ),
      ),
    );
  }
}

// ============================================================
// 4. AppBar مزخرف (محسّن)
// ============================================================

class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Color? accentColor;
  final Widget? leading;
  final bool showGoldLine;

  const BrandAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.accentColor,
    this.leading,
    this.showGoldLine = true,
  });

  double get _titleScale {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return 1;
    final scale = MediaQueryData.fromView(views.first).textScaler.scale(1);
    return scale.clamp(1.0, 1.6);
  }

  @override
  Size get preferredSize {
    final bar = subtitle != null ? 70.0 : 58.0;
    return Size.fromHeight(bar * _titleScale + 2);
  }

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    final toolbarHeight = (subtitle != null ? 70.0 : 58.0) * scale;

    return Container(
      decoration: BoxDecoration(
        gradient: accentColor == null
            ? AppGradients.sheen
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(color, Colors.white, 0.18)!,
                  color,
                  Color.lerp(color, Colors.black, 0.18)!,
                ],
              ),
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: toolbarHeight,
        centerTitle: true,
        leading: leading,
        actions: actions,
        title: subtitle != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              )
            : Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.title.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
        bottom: showGoldLine
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2.5),
                child: SizedBox(
                  height: 2.5,
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: AppGradients.gold),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

// ============================================================
// 5. فاصل ذهبي مزخرف
// ============================================================

class OrnamentDivider extends StatelessWidget {
  final double width;
  final Color? color;

  const OrnamentDivider({
    super.key,
    this.width = 120,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.gold;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final resolved = available.isFinite && available < width
            ? available
            : width;
        return SizedBox(
      width: resolved,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    c.withValues(alpha: 0.0),
                    c.withValues(alpha: 0.42),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.auto_awesome, size: 12, color: c.withValues(alpha: 0.85)),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    c.withValues(alpha: 0.42),
                    c.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
        );
      },
    );
  }
}

// ============================================================
// 6. بطاقة اقتباس / رسالة
// ============================================================

class BrandQuoteCard extends StatelessWidget {
  final String ayah;
  final String reference;
  final bool showOrnament;

  const BrandQuoteCard({
    super.key,
    required this.ayah,
    required this.reference,
    this.showOrnament = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: AppColors.spaceSm),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradientSoft,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: AppColors.shadowSubtle,
      ),
      child: Stack(
        children: [
          // زخرفة خلفية
          if (showOrnament)
            Positioned(
              top: -20,
              left: -20,
              child: Icon(
                Icons.auto_awesome,
                size: 60,
                color: AppColors.gold.withValues(alpha: 0.08),
              ),
            ),
          Positioned(
            bottom: -20,
            right: -20,
            child: Icon(
              Icons.auto_awesome,
              size: 60,
              color: AppColors.gold.withValues(alpha: 0.08),
            ),
          ),

          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.format_quote_rounded,
                  size: 20,
                  color: AppColors.goldDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                ayah,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  height: 2.1,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              OrnamentDivider(width: 80),
              const SizedBox(height: 8),
              Text(
                reference,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11,
                  color: AppColors.goldDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 7. شعار GRAND ONE
// ============================================================

class BrandLogoFrame extends StatelessWidget {
  final double size;
  final bool showTitle;
  final String? subtitle;
  final bool showOrnamentalRing;

  const BrandLogoFrame({
    super.key,
    this.size = 120,
    this.showTitle = true,
    this.subtitle,
    this.showOrnamentalRing = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.24;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (showOrnamentalRing)
              Container(
                width: size + 16,
                height: size + 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
              ),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: AppColors.gold,
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius - 2),
                child: Image.asset(
                  AppAssets.monogram,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.diamond_outlined,
                        color: AppColors.gold,
                        size: size * 0.42,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        if (showTitle) ...[
          const SizedBox(height: 18),
          const Text(
            'GRAND ONE',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 2.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'كل ما تحتاجه، في وجهة واحدة',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================
// 8. بطاقة بوابة العلامة
// ============================================================

class BrandGatewayCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;
  final String? badge;

  const BrandGatewayCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final darkerAccent = Color.lerp(accentColor, Colors.black, 0.18)!;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppColors.radiusLg),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: AppColors.shadowSoft,
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, darkerAccent],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: AppColors.goldLight,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.errorLight,
                              borderRadius:
                                  BorderRadius.circular(AppColors.radiusRound),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 9. شريط مراحل التسجيل (محسّن)
// ============================================================

class BrandStepBanner extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String title;
  final String? subtitle;

  const BrandStepBanner({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final safeTotal = totalSteps <= 0 ? 1 : totalSteps;
    final safeCurrent = currentStep.clamp(0, safeTotal);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradientSoft,
        border: Border(
          bottom: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: AppColors.goldDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle ?? 'المرحلة $safeCurrent من $safeTotal',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppColors.radiusRound),
                ),
                child: Text(
                  '${(safeCurrent / safeTotal * 100).round()}%',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              safeTotal,
              (i) {
                final isCompleted = i < safeCurrent;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 6,
                    margin: EdgeInsets.only(left: i > 0 ? 6 : 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: isCompleted
                          ? AppColors.goldGradient
                          : null,
                      color: isCompleted
                          ? null
                          : AppColors.gold.withValues(alpha: 0.18),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 10. بطاقة عامة
// ============================================================

class BrandCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool showShadow;
  final double radius;

  const BrandCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.showShadow = true,
    this.radius = AppColors.radiusLg,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? AppColors.borderLight,
          width: 0.8,
        ),
        boxShadow: showShadow ? AppColors.shadowSoft : null,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}

// ============================================================
// 11. زر أساسي
// ============================================================

class _ShineButton extends StatelessWidget {
  const _ShineButton({required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final radius = BorderRadius.circular(AppColors.radiusMd);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: enabled ? AppShadows.goldGlow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: enabled ? AppGradients.sheen : null,
            color: enabled ? null : AppColors.border,
            borderRadius: radius,
            border: Border.all(
              color: enabled
                  ? AppPalette.goldLight.withValues(alpha: 0.85)
                  : AppColors.border,
            ),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: IconTheme(
                  data: IconThemeData(
                    color: enabled ? AppPalette.goldLight : AppColors.mutedText,
                    size: 20,
                  ),
                  child: DefaultTextStyle(
                    style: AppText.button.copyWith(
                      color: enabled ? Colors.white : AppColors.mutedText,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BrandButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isLoading;
  final Widget? icon;
  final bool isOutlined;
  final bool isFullWidth;

  const BrandButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.isLoading = false,
    this.icon,
    this.isOutlined = false,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final btnColor = color ?? AppColors.primary;

    final button = isOutlined
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: btnColor,
              side: BorderSide(color: btnColor, width: 1.5),
              minimumSize: const Size(0, 52),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusMd),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: _buildChild(btnColor, isOutlined: true),
          )
        : _ShineButton(
            onPressed: isLoading ? null : onPressed,
            child: _buildChild(btnColor),
          );

    return isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }

  Widget _buildChild(Color btnColor, {bool isOutlined = false}) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          color: isOutlined ? btnColor : Colors.white,
          strokeWidth: 2,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.maxWidth.isFinite;
        final labelText = Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        );
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 8),
            ],
            if (bounded) Flexible(child: labelText) else labelText,
          ],
        );
      },
    );
  }
}

// ============================================================
// 12. مؤشر تحميل مزخرف
// ============================================================

class BrandLoadingIndicator extends StatelessWidget {
  final String? message;

  const BrandLoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// 13. حالة فارغة موحّدة
// ============================================================

class BrandEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const BrandEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 46,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                height: 1.7,
                color: AppColors.textSecondary,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              BrandButton(
                label: actionLabel!,
                onPressed: onAction,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 14. إطار القوس (Mihrab) — من صور الهوية
// ------------------------------------------------------------
// الشكل المعماري الإسلامي المميّز: قوس مدبّب في الأعلى.
// يُستخدم لتأطير الصور في المقدمة والشاشات التعريفية،
// بدل الصور المستطيلة العادية.
//
// التنفيذ بـ ClipPath حقيقي (لا صورة خلفية)، فيبقى حاداً
// على كل كثافة شاشة ولا يحتاج أصولاً إضافية.
// ============================================================

class ArchFrame extends StatelessWidget {
  const ArchFrame({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderColor,
    this.borderWidth = 1.6,
    this.padding = 0,
    this.backgroundColor,
  });

  final Widget child;
  final double? width;
  final double? height;
  final Color? borderColor;
  final double borderWidth;
  final double padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final gold = borderColor ?? AppColors.gold;

    final framed = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        border: Border.all(
          color: gold.withValues(alpha: 0.55),
          width: borderWidth,
        ),
        boxShadow: AppColors.shadowSubtle,
      ),
      child: ClipPath(
        clipper: const ArchClipper(),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: child,
        ),
      ),
    );

    if (width == null && height == null) return framed;

    return SizedBox(width: width, height: height, child: framed);
  }
}

/// يرسم قوس المحراب: جوانب مستقيمة ثم قوس مدبّب أعلى.
class ArchClipper extends CustomClipper<Path> {
  const ArchClipper({this.shoulderRatio = 0.58});

  /// ارتفاع بداية القوس نسبةً إلى ارتفاع العنصر.
  final double shoulderRatio;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final shoulder = h * shoulderRatio;
    final apex = h * 0.02;

    return Path()
      ..moveTo(0, h)
      ..lineTo(0, shoulder)
      // القوس يدور من الجانب إلى القمة ثم ينزل للجانب الآخر
      ..quadraticBezierTo(
        w * 0.06,
        apex + (shoulder - apex) * 0.16,
        w * 0.5,
        apex,
      )
      ..quadraticBezierTo(
        w * 0.94,
        apex + (shoulder - apex) * 0.16,
        w,
        shoulder,
      )
      ..lineTo(w, h)
      ..close();
  }

  @override
  bool shouldReclip(covariant ArchClipper oldClipper) {
    return oldClipper.shoulderRatio != shoulderRatio;
  }
}
