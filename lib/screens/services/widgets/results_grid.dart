// lib/screens/services/widgets/results_grid.dart
// ============================================================
// شبكة نتائج الخدمات/المزوّدين — متجاوبة
// ------------------------------------------------------------
// سابقاً: قائمة عمودية واحدة على كل المقاسات. على التابلت
// تصبح البطاقة بعرض 900px وفيها سطران فقط — مساحة مهدرة.
// الآن: عمود على الهاتف، عمودان على التابلت، ثلاثة على العريض،
// مع الحفاظ على تمرير لانهائي وحالة تحميل الصفحة التالية.
// ============================================================

import 'package:flutter/material.dart';

import '../../../design/tokens.dart';
import '../../../ui/kit/kit.dart';
import '../../../ui/layout/responsive.dart';

class ResultsGrid extends StatelessWidget {
  const ResultsGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onRefresh,
    this.controller,
    this.header,
    this.isLoadingMore = false,
    this.minItemWidth = 260,
    this.maxColumns = 3,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Future<void> Function() onRefresh;
  final ScrollController? controller;

  /// عنصر يُثبَّت أعلى القائمة (شريط النوع مثلاً).
  final Widget? header;

  final bool isLoadingMore;
  final double minItemWidth;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    final footerCount = isLoadingMore ? 1 : 0;

    return RefreshIndicator(
      color: AppPalette.green,
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = Responsive.gridColumns(
            constraints.maxWidth - Space.screenH * 2,
            minItemWidth: minItemWidth,
            max: maxColumns,
          );
          final single = columns == 1;

          // ارتفاع الخلية يتضخّم مع تكبير الخط، وإلا انضغط النص
          // داخل البطاقة على الهواتف بإعدادات إتاحة كبيرة.
          final textScale =
              MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
          final cellExtent = 260 * textScale;

          return CustomScrollView(
            controller: controller,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              if (header != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.screenH,
                      Space.xs,
                      Space.screenH,
                      Space.sm,
                    ),
                    child: header,
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  Space.screenH,
                  Space.xs,
                  Space.screenH,
                  Space.xxl,
                ),
                // عمود واحد (الهاتف): قائمة بارتفاع المحتوى بلا فراغات.
                // الشبكة للشاشات العريضة فقط.
                sliver: single
                    ? SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: Space.md),
                            child: itemBuilder(context, index),
                          ),
                          childCount: itemCount,
                        ),
                      )
                    : SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: Space.md,
                          mainAxisSpacing: Space.md,
                          // البطاقة الشبكية تحتاج ارتفاعاً يسمح بسطرين للاسم وشريط سعر
                          mainAxisExtent: cellExtent,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => itemBuilder(context, index),
                          childCount: itemCount,
                        ),
                      ),
              ),
              if (footerCount == 1)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: Space.xxl),
                    child: LoadingState(padding: EdgeInsets.all(Space.lg)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
