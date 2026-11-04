import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../services/api_exceptions.dart';
import '../../services/api_service.dart';
import '../../ui/kit/states.dart';
import 'work_booking_form_screen.dart';
import 'work_checklist_screen.dart';
import 'work_formatters.dart';

/// لوحة أداة تنظيم العمل: كل الحجوزات القادمة (من التطبيق ومن خارجه)
/// مرتبة بالتاريخ، وعلى كل بطاقة المتبقي ونسبة الجاهزية.
class WorkDashboardTab extends StatefulWidget {
  const WorkDashboardTab({super.key, required this.isProvider});

  /// المزوّد يستطيع إغلاق تاريخ الحجز الخارجي أمام عملاء التطبيق.
  final bool isProvider;

  @override
  State<WorkDashboardTab> createState() => _WorkDashboardTabState();
}

class _WorkDashboardTabState extends State<WorkDashboardTab> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic> _summary = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.getWorkBookings();
      final data = res['data'];
      _items = data is List
          ? data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];
      final summary = res['summary'];
      _summary = summary is Map ? Map<String, dynamic>.from(summary) : const {};
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'تعذر تحميل الحجوزات';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openForm([Map<String, dynamic>? existing]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WorkBookingFormScreen(
          existing: existing,
          canBlockCalendar: true,
        ),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _openChecklist(Map<String, dynamic> item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WorkChecklistScreen(
          kind: item['kind'].toString(),
          refId: item['id'].toString(),
          title: item['customer_name']?.toString() ??
              item['title']?.toString() ??
              'الجاهزية',
        ),
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الحجز'),
        content: const Text('سيُحذف الحجز الخارجي وقائمة جاهزيته.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.deleteWorkBooking(item['id'].toString());
      _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        tooltip: 'إضافة حجز',
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(children: [
                          EmptyState(
                            title: 'لا توجد حجوزات قادمة',
                            body:
                                'أضف حجوزاتك من خارج التطبيق بالضغط على +، وستظهر هنا مع حجوزات التطبيق.',
                            icon: Icons.event_available_outlined,
                            actionLabel: 'إضافة حجز',
                            onAction: () => _openForm(),
                          ),
                        ])
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                              Space.lg, Space.lg, Space.lg, 96),
                          children: [
                            _SummaryCard(summary: _summary),
                            const SizedBox(height: Space.md),
                            for (final item in _items)
                              _BookingCard(
                                item: item,
                                onTap: () => _openChecklist(item),
                                onEdit: item['source'] == 'external'
                                    ? () => _openForm(item)
                                    : null,
                                onDelete: item['source'] == 'external'
                                    ? () => _delete(item)
                                    : null,
                              ),
                          ],
                        ),
                ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});
  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final conflicts = (summary['conflicts'] as num?)?.toInt() ?? 0;
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppPalette.goldLighter),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _Stat(
                    label: 'حجوزات قادمة', value: '${summary['count'] ?? 0}'),
              ),
              Expanded(
                child: _Stat(
                    label: 'إجمالي المتبقي',
                    value: workMoney(summary['remaining_total'] ?? 0)),
              ),
            ],
          ),
          if (conflicts > 0) ...[
            const SizedBox(height: Space.md),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 20),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    'لديك $conflicts ${conflicts == 1 ? 'يوم' : 'أيام'} فيها أكثر من حجز.',
                    style: AppText.bodySecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption),
          const SizedBox(height: Space.xs),
          Text(value, style: AppText.number),
        ],
      );
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.item,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isExternal = item['source'] == 'external';
    final readiness = item['readiness'] is Map
        ? Map<String, dynamic>.from(item['readiness'] as Map)
        : const <String, dynamic>{};
    final total = (readiness['total'] as num?)?.toInt() ?? 0;
    final percent = (readiness['percent'] as num?)?.toInt() ?? 0;
    final title = isExternal
        ? (item['customer_name']?.toString() ?? '')
        : (item['title']?.toString() ?? '');
    final subtitle = isExternal ? item['title']?.toString() : null;
    final time = workTime(item['event_time']?.toString());

    return Card(
      margin: const EdgeInsets.only(bottom: Space.md),
      color: AppPalette.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${workDate(item['event_date']?.toString())}${time.isEmpty ? '' : ' • $time'}',
                      style: AppText.subtitle,
                    ),
                  ),
                  if (item['conflict'] == true)
                    const Tooltip(
                      message: 'تعارض: أكثر من حجز في هذا اليوم',
                      child: Icon(Icons.warning_amber_rounded,
                          color: Colors.orange, size: 20),
                    ),
                  _SourceChip(isExternal: isExternal),
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<String>(
                      tooltip: 'خيارات',
                      onSelected: (v) => v == 'edit' ? onEdit?.call() : onDelete?.call(),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('تعديل')),
                        PopupMenuItem(value: 'delete', child: Text('حذف')),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: Space.xs),
              Text(title, style: AppText.title),
              if (subtitle != null && subtitle.isNotEmpty)
                Text(subtitle, style: AppText.bodySecondary),
              const SizedBox(height: Space.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'المتبقي: ${workMoney(item['remaining_amount'])} من ${workMoney(item['total_amount'])}',
                      style: AppText.body,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.sm),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.pill),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : percent / 100,
                        minHeight: 6,
                        color: AppPalette.gold,
                        backgroundColor: AppPalette.goldSoft,
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Text(total == 0 ? 'لا مهام' : 'جاهز $percent%',
                      style: AppText.caption),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.isExternal});
  final bool isExternal;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsetsDirectional.only(start: Space.sm),
        padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 2),
        decoration: BoxDecoration(
          color: isExternal ? AppPalette.goldSoft : AppPalette.navySoft,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Text(isExternal ? 'خارجي' : 'من التطبيق', style: AppText.micro),
      );
}
