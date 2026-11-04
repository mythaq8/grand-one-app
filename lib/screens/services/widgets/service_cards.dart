// lib/screens/services/widgets/service_cards.dart
// ============================================================
// بطاقات الخدمات والمزودين
// ------------------------------------------------------------
// كانت هذه البطاقات دوالاً خاصة داخل services_screen (سطر
// 918 و 1091) بلا إمكانية إعادة استخدام ولا اختبار.
// هنا صارت ودجات مستقلة:
//   • تعمل داخل قائمة عمودية وعلى شبكة متجاوبة،
//   • تتقبّل شكلين (compact للشبكة، horizontal للقائمة)،
//   • لا تغيّر أي منطق: نفس الحقول ونفس سلوك النقر.
// ============================================================

import 'package:flutter/material.dart';

import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import 'availability_badges.dart';

/// شارة التقييم بالنجوم — موحّدة للخدمة والمزود.
class RatingBadge extends StatelessWidget {
  const RatingBadge({
    super.key,
    required this.rating,
    this.reviewsCount = 0,
  });

  final double rating;
  final int reviewsCount;

  @override
  Widget build(BuildContext context) {
    // لا نعرض شارة لتقييم صفر — تبقى الواجهة أنظف.
    if (rating <= 0 && reviewsCount <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: const BoxDecoration(
        color: AppPalette.goldSoft,
        borderRadius: Radii.brXs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 14,
            color: AppPalette.goldDark,
          ),
          const SizedBox(width: 3),
          // بدون Flexible يفيض الصف عند تضييق الخلية أو تكبير الخط.
          Flexible(
            child: Text(
              rating.toStringAsFixed(1),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.micro.copyWith(color: AppPalette.goldDeep),
            ),
          ),
          if (reviewsCount > 0) ...[
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                '($reviewsCount)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.micro.copyWith(
                  color: AppPalette.goldDeep,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// صورة مصغّرة للبطاقة، مع بديل أنيق عند غياب الصورة.
class ServiceThumbnail extends StatelessWidget {
  const ServiceThumbnail({
    super.key,
    required this.url,
    this.size = 88,
    this.icon = Icons.business_center_outlined,
    this.radius = Radii.md,
    this.expand = false,
  });

  final String? url;
  final double size;
  final IconData icon;
  final double radius;

  /// داخل الشبكة نريد الصورة تملأ عرض البطاقة لا مربعاً ثابتاً.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final placeholder = Center(
      child: Icon(
        icon,
        size: size * 0.42,
        color: AppPalette.gold,
      ),
    );

    final image = (url == null || url!.isEmpty)
        ? placeholder
        : Image.network(
            url!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (_, _, _) => placeholder,
          );

    return Container(
      width: expand ? null : size,
      height: expand ? null : size,
      decoration: BoxDecoration(
        color: AppPalette.surfaceTint,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppPalette.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: image,
    );
  }
}

/// بطاقة خدمة.
///
/// [compact] للشبكة: صورة أعلى، ثم الاسم والسعر تحت.
/// وإلا: صف أفقي كما كان في القائمة.
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.name,
    required this.priceLabel,
    required this.onTap,
    this.governorate = '',
    this.location = '',
    this.coverUrl,
    this.rating = 0,
    this.reviewsCount = 0,
    this.isBookable = true,
    this.compact = false,
    this.badges = const [],
    this.availableOnDate,
  });

  final String name;
  final String priceLabel;
  final VoidCallback onTap;
  final String governorate;
  final String location;
  final String? coverUrl;
  final double rating;
  final int reviewsCount;
  final bool isBookable;
  final bool compact;
  final List<String> badges;
  final bool? availableOnDate;

  String get _place {
    if (governorate.isEmpty) return '';
    return location.isEmpty ? governorate : '$governorate - $location';
  }

  @override
  Widget build(BuildContext context) {
    return _withBadges(
      Material(
      color: AppPalette.surface,
      borderRadius: Radii.brLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.brLg,
        child: Ink(
          decoration: BoxDecoration(
            color: AppPalette.surface,
            borderRadius: Radii.brLg,
            border: Border.all(
              color: AppPalette.gold.withValues(alpha: 0.22),
            ),
            boxShadow: AppShadows.subtle,
          ),
          child: compact ? _buildCompact(context) : _buildRow(context),
        ),
      ),
      ),
    );
  }

  Widget _withBadges(Widget card) {
    if (badges.isEmpty && availableOnDate == null) return card;
    return Stack(
      children: [
        card,
        PositionedDirectional(
          top: 8,
          start: 8,
          end: 8,
          child: AvailabilityBadges(
            availableOnDate: availableOnDate,
            badges: badges,
          ),
        ),
      ],
    );
  }

  /// شكل الشبكة: صورة عريضة أعلى البطاقة.
  ///
  /// الصورة تأخذ المساحة المتبقية (Expanded) بعد النص، وليس نسبة
  /// ثابتة. هكذا لا تفيض البطاقة داخل خلية شبكة بارتفاع محدد،
  /// ولا تترك فراغاً كبيراً على الشاشات القصيرة.
  Widget _buildCompact(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(Radii.lg),
            ),
            child: ServiceThumbnail(url: coverUrl, expand: true, radius: 0),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.title.copyWith(fontSize: 15),
              ),
              if (_place.isNotEmpty) ...[
                const SizedBox(height: Space.xs),
                _placeRow(),
              ],
              const SizedBox(height: Space.sm),
              // نستخدم Wrap بدل Row: عند ضيق الخلية أو تكبير الخط
              // ينزل السعر إلى سطر ثانٍ بدل أن يفيض أفقياً.
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                spacing: Space.sm,
                runSpacing: Space.xs,
                children: [
                  RatingBadge(rating: rating, reviewsCount: reviewsCount),
                  if (priceLabel.isNotEmpty)
                    Text(
                      priceLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.number.copyWith(
                        fontSize: 13,
                        color: AppPalette.goldDeep,
                      ),
                    ),
                ],
              ),
              if (!isBookable) ...[
                const SizedBox(height: Space.xs + 2),
                _notBookable(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// شكل القائمة: صف أفقي.
  Widget _buildRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Space.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceThumbnail(url: coverUrl),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title.copyWith(fontSize: 15),
                ),
                if (_place.isNotEmpty) ...[
                  const SizedBox(height: Space.xs),
                  _placeRow(),
                ],
                const SizedBox(height: Space.sm),
                Row(
                  children: [
                    RatingBadge(rating: rating, reviewsCount: reviewsCount),
                    const Spacer(),
                    if (priceLabel.isNotEmpty)
                      Flexible(
                        child: Text(
                          priceLabel,
                          textAlign: TextAlign.left,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.number.copyWith(
                            fontSize: 13,
                            color: AppPalette.goldDeep,
                          ),
                        ),
                      ),
                  ],
                ),
                if (!isBookable) ...[
                  const SizedBox(height: Space.xs + 2),
                  _notBookable(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeRow() {
    return Row(
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 13,
          color: AppPalette.textTertiary,
        ),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            _place,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption,
          ),
        ),
      ],
    );
  }

  Widget _notBookable() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: const BoxDecoration(
        color: AppPalette.warningLight,
        borderRadius: Radii.brXs,
      ),
      child: Text(
        'غير متاح للحجز حالياً',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppText.micro.copyWith(
          fontSize: 10,
          color: AppPalette.warningDark,
        ),
      ),
    );
  }
}

/// بطاقة مزود خدمة.
class ProviderCard extends StatelessWidget {
  const ProviderCard({
    super.key,
    required this.name,
    required this.onTap,
    this.governorate = '',
    this.description = '',
    this.coverUrl,
    this.logoUrl,
    this.rating = 0,
    this.reviewsCount = 0,
    this.isVerified = false,
    this.badges = const [],
    this.availableOnDate,
  });

  final String name;
  final VoidCallback onTap;
  final String governorate;
  final String description;
  final String? coverUrl;
  final String? logoUrl;
  final double rating;
  final int reviewsCount;
  final bool isVerified;
  final List<String> badges;
  final bool? availableOnDate;

  @override
  Widget build(BuildContext context) {
    return _withBadges(
      Material(
      color: AppPalette.surface,
      borderRadius: Radii.brLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.brLg,
        child: Ink(
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            color: AppPalette.surface,
            borderRadius: Radii.brLg,
            border: Border.all(
              color: AppPalette.gold.withValues(alpha: 0.22),
            ),
            boxShadow: AppShadows.subtle,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ServiceThumbnail(
                url: (coverUrl != null && coverUrl!.isNotEmpty)
                    ? coverUrl
                    : logoUrl,
                icon: Icons.storefront_outlined,
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.title.copyWith(fontSize: 15),
                          ),
                        ),
                        if (isVerified)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Tooltip(
                              message: 'مزود موثّق',
                              child: Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: AppPalette.success,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: Space.xs),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodySecondary.copyWith(fontSize: 12),
                      ),
                    ],
                    if (governorate.isNotEmpty) ...[
                      const SizedBox(height: Space.xs + 1),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: AppPalette.textTertiary,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              governorate,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: Space.sm),
                    RatingBadge(
                      rating: rating,
                      reviewsCount: reviewsCount,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _withBadges(Widget card) {
    if (badges.isEmpty && availableOnDate == null) return card;
    return Stack(
      children: [
        card,
        PositionedDirectional(
          top: 8,
          start: 8,
          end: 8,
          child: AvailabilityBadges(
            availableOnDate: availableOnDate,
            badges: badges,
          ),
        ),
      ],
    );
  }
}
