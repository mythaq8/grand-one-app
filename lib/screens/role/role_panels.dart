// lib/screens/role/role_panels.dart
// ============================================================
// تبويبات «الرئيسية» و«المالية» للمزوّد والمنظّم.
// لكل دور عمل مختلف:
//   المزوّد: ينفّذ خدمة — يهمه الرد في الوقت، العربون، مواعيده، ومستحقاته.
//   المنظّم: يدير مناسبات كاملة — يهمه مسار الطلبات (عرض ← قبول ← عربون)
//            والمناسبات القادمة ورسومه.
// ============================================================

import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../services/api_exceptions.dart';
import '../../services/api_service.dart';
import '../../ui/kit/kit.dart';
import '../event/event_form_screen.dart' show kEventTypeLabels;
import '../work/work_checklist_screen.dart';
import '../work/work_formatters.dart';
import '../work/work_types_screen.dart';

/// مرشّح مرحلة يفتحه «الرئيسية» على تبويب طلبات المنظّم.
final ValueNotifier<String?> organizerStageFilter = ValueNotifier<String?>(null);

// ── أدوات مشتركة ─────────────────────────────────────────────

class _Loader extends StatefulWidget {
  const _Loader({required this.load, required this.builder});

  final Future<Map<String, dynamic>> Function() load;
  final Widget Function(BuildContext, Map<String, dynamic>, Future<void> Function()) builder;

  @override
  State<_Loader> createState() => _LoaderState();
}

class _LoaderState extends State<_Loader> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      _data = await widget.load();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'تعذّر تحميل البيانات';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: LoadingState());
    if (_error != null && _data == null) {
      return Center(child: ErrorState(message: _error!, onRetry: _reload));
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: widget.builder(context, _data ?? const {}, _reload),
    );
  }
}

num _n(dynamic v) => v is num ? v : num.tryParse('$v') ?? 0;

Widget _kpiGrid(List<Widget> tiles) {
  return LayoutBuilder(
    builder: (context, c) {
      final cols = c.maxWidth >= 700 ? 4 : 2;
      final w = (c.maxWidth - Space.sm * (cols - 1)) / cols;
      return Wrap(
        spacing: Space.sm,
        runSpacing: Space.sm,
        children: [for (final t in tiles) SizedBox(width: w, child: t)],
      );
    },
  );
}

Widget _alerts(dynamic list) {
  final items = list is List ? list.whereType<Map>().toList() : const <Map>[];
  if (items.isEmpty) return const SizedBox.shrink();
  return Column(
    children: [
      for (final a in items)
        Padding(
          padding: const EdgeInsets.only(bottom: Space.sm),
          child: AppCard(
            accent: AppPalette.warning,
            padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, Space.md),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppPalette.warningDark),
                const SizedBox(width: Space.sm),
                Expanded(child: Text(a['message']?.toString() ?? '', style: AppText.body)),
              ],
            ),
          ),
        ),
    ],
  );
}

String _dueIn(String? iso) {
  if (iso == null) return '';
  final t = DateTime.tryParse(iso);
  if (t == null) return '';
  final h = t.difference(DateTime.now()).inMinutes / 60;
  if (h <= 0) return 'انتهت المهلة';
  if (h < 1) return 'أقل من ساعة';
  return '${h.floor()} ساعة';
}

// ── مهامك القريبة (من كل الأعمال داخل التطبيق وخارجه) ─────────

class UpcomingTasksSection extends StatefulWidget {
  const UpcomingTasksSection({super.key});

  @override
  State<UpcomingTasksSection> createState() => _UpcomingTasksSectionState();
}

class _UpcomingTasksSectionState extends State<UpcomingTasksSection> {
  List<Map<String, dynamic>>? _tasks;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.getWorkTasks();
      final list = res['tasks'] is List ? res['tasks'] as List : const [];
      _tasks = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      _tasks = const [];
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _tasks;
    final overdue = tasks?.where((t) => t['overdue'] == true).length ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'مهامك القريبة',
          subtitle: overdue > 0 ? '$overdue مهمة متأخرة' : 'المتأخرة ومهام الأسبوعين القادمين',
          icon: Icons.checklist_rtl_rounded,
          accent: overdue > 0 ? AppPalette.error : AppPalette.navy,
          trailing: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WorkTypesScreen()),
            ),
            child: const Text('أنواع أعمالي'),
          ),
        ),
        if (tasks == null)
          const LoadingState(padding: EdgeInsets.all(Space.lg))
        else if (tasks.isEmpty)
          const EmptyState(
            icon: Icons.task_alt_rounded,
            title: 'لا مهام قريبة',
            body: 'عرّف «أنواع أعمالك» بخطوات ومواعيد، فتظهر هنا مهام كل حجز قبل موعده.',
            padding: EdgeInsets.all(Space.lg),
          )
        else
          for (final t in tasks.take(8))
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: AppCard(
                accent: t['overdue'] == true
                    ? AppPalette.error
                    : t['today'] == true
                        ? AppPalette.gold
                        : AppPalette.navyMuted,
                padding: const EdgeInsets.all(Space.md),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WorkChecklistScreen(
                        kind: t['ref_kind'].toString(),
                        refId: t['ref_id'].toString(),
                        title: t['ref_title']?.toString() ?? 'الجاهزية',
                      ),
                    ),
                  );
                  _load();
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t['title']?.toString() ?? '', style: AppText.title),
                          Text(
                            '${t['ref_title'] ?? ''} • الحدث ${workDate(t['ref_date']?.toString())}',
                            style: AppText.caption,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      t['overdue'] == true
                          ? 'متأخرة'
                          : t['today'] == true
                              ? 'اليوم'
                              : workDate(t['due_date']?.toString()),
                      style: AppText.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: t['overdue'] == true ? AppPalette.error : AppPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

// ── المزوّد: الرئيسية ────────────────────────────────────────

class ProviderHomeTab extends StatelessWidget {
  const ProviderHomeTab({super.key, required this.onNavigate});

  /// 1 الطلبات، 2 أعمالي، 3 المالية، 4 الإدارة
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return _Loader(
      load: ApiService.getProviderOverview,
      builder: (context, d, reload) {
        final k = d['kpis'] is Map ? Map<String, dynamic>.from(d['kpis']) : <String, dynamic>{};
        final upcoming = d['upcoming'] is List ? (d['upcoming'] as List).whereType<Map>().toList() : <Map>[];
        final awaiting = _n(k['awaiting_response']).toInt();
        // تنبيه الرقم الناقص يظهر أصلاً أعلى كل تبويبات المزوّد
        final alerts = (d['alerts'] is List ? d['alerts'] as List : const [])
            .where((a) => a is Map && a['code'] != 'missing_contact')
            .toList();
        return ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            _alerts(alerts),
            if (awaiting > 0)
              AppCard(
                accent: AppPalette.gold,
                onTap: () => onNavigate(1),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: AppPalette.goldDeep),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$awaiting طلب ينتظر ردّك', style: AppText.title),
                          if (_dueIn(k['next_response_due_at']?.toString()).isNotEmpty)
                            Text(
                              'أقرب مهلة: ${_dueIn(k['next_response_due_at']?.toString())}',
                              style: AppText.bodySecondary,
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left_rounded),
                  ],
                ),
              ),
            const SectionHeader(title: 'نظرة سريعة', icon: Icons.insights_rounded, padding: EdgeInsets.only(top: Space.lg, bottom: Space.md)),
            _kpiGrid([
              StatTile(value: '${_n(k['confirmed_upcoming']).toInt()}', label: 'حجوزات مؤكدة قادمة', icon: Icons.event_available_rounded, onTap: () => onNavigate(2)),
              StatTile(value: '${_n(k['awaiting_deposit']).toInt()}', label: 'بانتظار عربون العميل', icon: Icons.hourglass_top_rounded, accent: AppPalette.warningDark, onTap: () => onNavigate(1)),
              StatTile(value: workMoney(k['pending_payout']), label: 'مستحقات لم تُحوَّل', icon: Icons.account_balance_wallet_outlined, accent: AppPalette.success, onTap: () => onNavigate(3)),
              StatTile(value: workMoney(k['month_bookings_value']), label: 'قيمة حجوزات هذا الشهر', icon: Icons.trending_up_rounded),
              StatTile(
                value: k['rating_avg'] == null ? '—' : '${k['rating_avg']}',
                label: 'التقييم (${_n(k['rating_count']).toInt()})',
                icon: Icons.star_rounded,
                accent: AppPalette.goldDeep,
              ),
              StatTile(value: '${_n(k['active_services']).toInt()}', label: 'خدمات نشطة', icon: Icons.storefront_outlined, onTap: () => onNavigate(4)),
            ]),
            const UpcomingTasksSection(),
            SectionHeader(
              title: 'مواعيدك القادمة',
              icon: Icons.calendar_month_rounded,
              trailing: TextButton(onPressed: () => onNavigate(2), child: const Text('كل الأعمال')),
            ),
            if (upcoming.isEmpty)
              const EmptyState(
                icon: Icons.event_note_outlined,
                title: 'لا مواعيد قادمة',
                body: 'تظهر هنا حجوزات التطبيق المقبولة. أضف حجوزاتك الخارجية من «أعمالي».',
                padding: EdgeInsets.all(Space.lg),
              )
            else
              for (final b in upcoming)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: AppCard(
                    padding: const EdgeInsets.all(Space.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b['service_name']?.toString() ?? 'خدمة', style: AppText.title),
                              Text(
                                '${workDate(b['booking_date']?.toString())}  ${workTime(b['booking_time']?.toString())}',
                                style: AppText.bodySecondary,
                              ),
                            ],
                          ),
                        ),
                        StatusPillFromCode(code: b['status']?.toString() ?? ''),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: Space.xxl),
          ],
        );
      },
    );
  }
}

// ── المزوّد: المالية ─────────────────────────────────────────

class ProviderFinanceTab extends StatelessWidget {
  const ProviderFinanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return _Loader(
      load: ApiService.getProviderSettlements,
      builder: (context, d, reload) {
        final s = d['summary'] is Map ? Map<String, dynamic>.from(d['summary']) : <String, dynamic>{};
        final rows = d['data'] is List ? (d['data'] as List).whereType<Map>().toList() : <Map>[];
        return ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            _kpiGrid([
              StatTile(value: workMoney(s['pending']), label: 'مستحقات بانتظار التحويل', icon: Icons.schedule_rounded, accent: AppPalette.warningDark),
              StatTile(value: workMoney(s['released']), label: 'حُوِّل لك', icon: Icons.check_circle_outline_rounded, accent: AppPalette.success),
            ]),
            const SizedBox(height: Space.md),
            AppCard(
              padding: const EdgeInsets.all(Space.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppPalette.info),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      'يدفع العميل العربون للمنصة، وبعد إتمام الخدمة يُحوَّل لك العربون مخصوماً منه عمولة المنصة. باقي المبلغ يدفعه العميل لك مباشرة.',
                      style: AppText.bodySecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader(title: 'سجل التسويات', icon: Icons.receipt_long_rounded),
            if (rows.isEmpty)
              const EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: 'لا تسويات بعد',
                body: 'تُنشأ التسوية تلقائياً عند اكتمال كل حجز.',
                padding: EdgeInsets.all(Space.lg),
              )
            else
              for (final r in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: AppCard(
                    accent: r['status'] == 'released' ? AppPalette.success : AppPalette.warning,
                    padding: const EdgeInsets.all(Space.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                (r['bookings'] is Map && (r['bookings'] as Map)['services'] is Map)
                                    ? ((r['bookings'] as Map)['services'] as Map)['name']?.toString() ?? 'حجز'
                                    : 'حجز',
                                style: AppText.title,
                              ),
                            ),
                            Text(workMoney(r['provider_net']), style: AppText.number.copyWith(color: AppPalette.success)),
                          ],
                        ),
                        Text(
                          'الحجز: ${workMoney(r['total_price'])} • العربون: ${workMoney(r['deposit_amount'])} • العمولة: ${workMoney(r['commission_amount'])}',
                          style: AppText.caption,
                        ),
                        Text(
                          r['status'] == 'released'
                              ? 'حُوِّل ${workDate(r['released_at']?.toString())} • المرجع: ${r['payout_reference'] ?? '—'}'
                              : r['status'] == 'void'
                                  ? 'ملغاة'
                                  : 'بانتظار التحويل',
                          style: AppText.bodySecondary,
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: Space.xxl),
          ],
        );
      },
    );
  }
}

// ── المنظّم: الرئيسية ────────────────────────────────────────

class OrganizerHomeTab extends StatelessWidget {
  const OrganizerHomeTab({super.key, required this.onNavigate});

  /// 1 المناسبات، 2 أعمالي، 3 المالية، 4 الإدارة
  final ValueChanged<int> onNavigate;

  void _openStage(String? stage) {
    organizerStageFilter.value = stage;
    onNavigate(1);
  }

  @override
  Widget build(BuildContext context) {
    return _Loader(
      load: ApiService.getOrganizerOverview,
      builder: (context, d, reload) {
        final p = d['pipeline'] is Map ? Map<String, dynamic>.from(d['pipeline']) : <String, dynamic>{};
        final k = d['kpis'] is Map ? Map<String, dynamic>.from(d['kpis']) : <String, dynamic>{};
        final upcoming = d['upcoming'] is List ? (d['upcoming'] as List).whereType<Map>().toList() : <Map>[];
        Widget stage(String key, String label, IconData icon, Color color) => StatTile(
              value: '${_n(p[key]).toInt()}',
              label: label,
              icon: icon,
              accent: color,
              onTap: () => _openStage(key),
            );
        return ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            _alerts(d['alerts']),
            const SectionHeader(
              title: 'مسار المناسبات',
              subtitle: 'من الطلب إلى التأكيد — اضغط أي مرحلة لعرض طلباتها',
              icon: Icons.route_rounded,
              padding: EdgeInsets.only(top: Space.sm, bottom: Space.md),
            ),
            _kpiGrid([
              stage('new', 'جديدة — تنتظر عرضك', Icons.fiber_new_rounded, AppPalette.error),
              stage('in_review', 'قيد إعداد العرض', Icons.edit_note_rounded, AppPalette.info),
              stage('awaiting_client', 'عرض بانتظار العميل', Icons.mark_email_unread_outlined, AppPalette.goldDeep),
              stage('awaiting_deposit', 'بانتظار العربون', Icons.hourglass_top_rounded, AppPalette.warningDark),
              stage('confirmed', 'مؤكدة قادمة', Icons.verified_rounded, AppPalette.success),
            ]),
            const SectionHeader(title: 'هذا الشهر', icon: Icons.insights_rounded),
            _kpiGrid([
              StatTile(value: '${_n(k['accepted_this_month']).toInt()}', label: 'عروض مقبولة', icon: Icons.handshake_outlined),
              StatTile(value: workMoney(k['accepted_value_this_month']), label: 'قيمة العروض المقبولة', icon: Icons.trending_up_rounded),
              StatTile(value: workMoney(k['fees_this_month']), label: 'رسومك هذا الشهر', icon: Icons.payments_outlined, accent: AppPalette.success, onTap: () => onNavigate(3)),
              StatTile(value: workMoney(k['fees_total']), label: 'رسومك الإجمالية', icon: Icons.savings_outlined, accent: AppPalette.success, onTap: () => onNavigate(3)),
            ]),
            const UpcomingTasksSection(),
            SectionHeader(
              title: 'مناسباتك القادمة',
              icon: Icons.celebration_outlined,
              trailing: TextButton(onPressed: () => _openStage(null), child: const Text('كل الطلبات')),
            ),
            if (upcoming.isEmpty)
              const EmptyState(
                icon: Icons.event_note_outlined,
                title: 'لا مناسبات مؤكدة قادمة',
                body: 'تظهر هنا المناسبات بعد قبول العميل عرضك.',
                padding: EdgeInsets.all(Space.lg),
              )
            else
              for (final r in upcoming)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: AppCard(
                    padding: const EdgeInsets.all(Space.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${kEventTypeLabels[r['occasion_type']?.toString()] ?? r['occasion_type'] ?? 'مناسبة'} • ${r['governorate'] ?? ''}',
                                style: AppText.title,
                              ),
                              Text(workDate(r['occasion_date']?.toString()), style: AppText.bodySecondary),
                            ],
                          ),
                        ),
                        StatusPill(
                          label: r['status'] == 'confirmed' ? 'مؤكدة' : 'بانتظار العربون',
                          tone: r['status'] == 'confirmed' ? PillTone.success : PillTone.warning,
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: Space.xxl),
          ],
        );
      },
    );
  }
}

// ── المنظّم: المالية ─────────────────────────────────────────

class OrganizerFinanceTab extends StatelessWidget {
  const OrganizerFinanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return _Loader(
      load: ApiService.getOrganizerEarnings,
      builder: (context, d, reload) {
        final s = d['summary'] is Map ? Map<String, dynamic>.from(d['summary']) : <String, dynamic>{};
        final rows = d['data'] is List ? (d['data'] as List).whereType<Map>().toList() : <Map>[];
        return ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            _kpiGrid([
              StatTile(value: workMoney(s['accepted_value']), label: 'قيمة العروض المقبولة', icon: Icons.handshake_outlined),
              StatTile(value: workMoney(s['organizer_fees']), label: 'رسوم التنظيم', icon: Icons.payments_outlined, accent: AppPalette.success),
              StatTile(value: workMoney(s['platform_commission']), label: 'عمولة المنصّة', icon: Icons.percent_rounded, accent: AppPalette.warningDark),
            ]),
            const SectionHeader(title: 'العروض المقبولة', icon: Icons.receipt_long_rounded),
            if (rows.isEmpty)
              const EmptyState(
                icon: Icons.request_quote_outlined,
                title: 'لا عروض مقبولة بعد',
                body: 'عند قبول العميل عرضك يظهر هنا مع رسومك.',
                padding: EdgeInsets.all(Space.lg),
              )
            else
              for (final q in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: AppCard(
                    padding: const EdgeInsets.all(Space.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                () {
                                  final r = q['occasion_requests'] is Map ? q['occasion_requests'] as Map : const {};
                                  final t = kEventTypeLabels[r['occasion_type']?.toString()] ?? r['occasion_type'] ?? 'مناسبة';
                                  return '$t • ${workDate(r['occasion_date']?.toString())}';
                                }(),
                                style: AppText.title,
                              ),
                            ),
                            Text(workMoney(q['total']), style: AppText.number),
                          ],
                        ),
                        Text(
                          'رسومك: ${workMoney(q['organizer_fee_amount'])} • العربون: ${workMoney(q['deposit_amount'])} • عمولة المنصّة: ${workMoney(q['platform_commission'])}',
                          style: AppText.caption,
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: Space.xxl),
          ],
        );
      },
    );
  }
}
