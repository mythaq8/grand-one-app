import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../services/api_exceptions.dart';
import '../../services/api_service.dart';
import '../../ui/kit/states.dart';
import '../../ui/kit/status_pill.dart';
import '../my_bookings_screen.dart';
import '../work/work_formatters.dart';
import 'event_form_screen.dart';
import 'event_planning_tab.dart';

/// صفحة الفعالية: الملخص، السلة وتسعيرها، حالة طلب كل مزوّد، والمجاميع.
class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _event;
  List<Map<String, dynamic>> _cart = [];
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _occasions = [];
  Map<String, dynamic> _totals = const {};
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<Map<String, dynamic>> _list(dynamic v) => v is List
      ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : <Map<String, dynamic>>[];

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.getActiveEvent();
      final ev = res['event'];
      _event = ev is Map ? Map<String, dynamic>.from(ev) : null;
      _cart = _list(res['cart']);
      _bookings = _list(res['bookings']);
      _occasions = _list(res['occasion_requests']);
      final t = res['totals'];
      _totals = t is Map ? Map<String, dynamic>.from(t) : const {};
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'تعذر تحميل الفعالية';
    }
    if (mounted) setState(() => _loading = false);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _create() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EventFormScreen()),
    );
    if (saved == true) _load();
  }

  bool get _hasLiveBookings => _bookings.any((b) => !const [
        'rejected',
        'cancelled',
        'expired',
        'completed',
      ].contains(b['status']?.toString()));

  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EventFormScreen(
          existing: _event,
          hasActiveBookings: _hasLiveBookings,
        ),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _close() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الفعالية'),
        content: const Text('ستُفرغ السلة وتُغلق الفعالية. لا يمكن التراجع.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('رجوع')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إلغاء الفعالية')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.closeEvent(_event!['id'].toString());
      _load();
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _removeItem(Map<String, dynamic> item) async {
    try {
      await ApiService.removeEventCartItem(
          _event!['id'].toString(), item['id'].toString());
      _load();
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _send() async {
    if (_cart.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final res = await ApiService.sendEventCart(_event!['id'].toString());
      final sent = (res['sent'] as num?)?.toInt() ?? 0;
      final failed = (res['failed'] as num?)?.toInt() ?? 0;
      String? firstError;
      final results = res['results'];
      if (results is List) {
        for (final r in results) {
          if (r is Map && r['ok'] != true) {
            firstError = r['error']?.toString();
            break;
          }
        }
      }
      _toast(failed == 0
          ? 'أُرسل $sent طلب إلى المزوّدين'
          : 'أُرسل $sent وتعذّر $failed${firstError == null ? '' : ': $firstError'}');
      await _load();
    } on ApiException catch (e) {
      _toast(e.message);
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasEvent = !_loading && _error == null && _event != null;
    final eventId = _event?['id']?.toString();

    final scaffold = Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: const Text('فعاليتي'),
        actions: [
          if (_event != null)
            PopupMenuButton<String>(
              onSelected: (v) => v == 'edit' ? _edit() : _close(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('تعديل الفعالية')),
                PopupMenuItem(value: 'close', child: Text('إلغاء الفعالية')),
              ],
            ),
        ],
        bottom: hasEvent
            ? const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'الملخص'),
                  Tab(text: 'المهام'),
                  Tab(text: 'الجدول'),
                  Tab(text: 'الميزانية'),
                  Tab(text: 'الإلهام'),
                ],
              )
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _event == null
                  ? EmptyState(
                      title: 'لا توجد فعالية نشطة',
                      body: 'أنشئ فعاليتك لتضيف الخدمات إلى سلتك وتتابع الطلبات.',
                      icon: Icons.celebration_outlined,
                      actionLabel: 'إنشاء فعالية',
                      onAction: _create,
                    )
                  : TabBarView(
                      children: [
                        RefreshIndicator(onRefresh: _load, child: _buildBody()),
                        EventPlanningTab(eventId: eventId!, kind: kTasksKind),
                        EventPlanningTab(eventId: eventId, kind: kTimelineKind),
                        EventPlanningTab(eventId: eventId, kind: kBudgetKind),
                        EventPlanningTab(eventId: eventId, kind: kInspirationKind),
                      ],
                    ),
    );

    return hasEvent ? DefaultTabController(length: 5, child: scaffold) : scaffold;
  }

  Widget _buildBody() {
    final e = _event!;
    final type = kEventTypeLabels[e['event_type']] ?? 'فعالية';
    final title = (e['title']?.toString() ?? '').isEmpty ? type : e['title'].toString();
    final budget = _totals['budget'];
    final bookedTotal = _totals['booked_total'] ?? 0;
    final overBudget = budget is num && (bookedTotal as num) > budget;

    return ListView(
      padding: const EdgeInsets.all(Space.lg),
      children: [
        Container(
          padding: const EdgeInsets.all(Space.lg),
          decoration: BoxDecoration(
            color: AppPalette.surface,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: AppPalette.goldLighter),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.title),
              const SizedBox(height: Space.xs),
              Text('$type • ${workDate(e['event_date']?.toString())}',
                  style: AppText.bodySecondary),
              if (e['guests_count'] != null)
                Text('المدعوون: ${e['guests_count']}', style: AppText.bodySecondary),
              if ((e['governorate']?.toString() ?? '').isNotEmpty)
                Text('المحافظة: ${e['governorate']}', style: AppText.bodySecondary),
              const Divider(height: Space.xl),
              _row('المحجوز', workMoney(_totals['booked_total'] ?? 0)),
              _row('العربون المدفوع', workMoney(_totals['deposit_paid'] ?? 0)),
              _row('المتبقي للمزوّدين', workMoney(_totals['remaining'] ?? 0)),
              if (budget is num)
                _row(
                  'الميزانية',
                  workMoney(budget),
                  warn: overBudget,
                  note: overBudget ? 'المحجوز يتجاوز الميزانية' : null,
                ),
            ],
          ),
        ),
        const SizedBox(height: Space.xl),
        Text('السلة', style: AppText.section),
        const SizedBox(height: Space.sm),
        if (_cart.isEmpty)
          Text('السلة فارغة. أضف خدمات من صفحة الخدمة.', style: AppText.bodySecondary)
        else ...[
          for (final item in _cart) _cartTile(item),
          const SizedBox(height: Space.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  'إجمالي السلة: ${workMoney(_totals['cart_total'] ?? 0)}'
                  '${((_totals['cart_items_needing_quote'] as num?) ?? 0) > 0 ? ' + بنود بعرض سعر' : ''}',
                  style: AppText.subtitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          FilledButton.icon(
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: const Text('إرسال الطلبات للمزوّدين'),
          ),
          const SizedBox(height: Space.xs),
          Text(
            'يُرسل لكل خدمة طلب إلى مزوّدها بتاريخ الفعالية، ولا يُدفع شيء الآن.',
            style: AppText.caption,
          ),
        ],
        const SizedBox(height: Space.xl),
        Text('طلباتي في هذه الفعالية', style: AppText.section),
        const SizedBox(height: Space.sm),
        if (_bookings.isEmpty && _occasions.isEmpty)
          Text('لم تُرسل أي طلبات بعد.', style: AppText.bodySecondary),
        for (final b in _bookings) _bookingTile(b),
        for (final o in _occasions) _occasionTile(o),
        if (_bookings.isNotEmpty) ...[
          const SizedBox(height: Space.sm),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
            ),
            child: const Text('إدارة حجوزاتي والدفع'),
          ),
        ],
      ],
    );
  }

  Widget _row(String label, String value, {bool warn = false, String? note}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppText.bodySecondary)),
              Text(value,
                  style: AppText.body.copyWith(
                    color: warn ? Colors.red : null,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
          if (note != null)
            Text(note, style: AppText.caption.copyWith(color: Colors.red)),
        ],
      ),
    );
  }

  Widget _cartTile(Map<String, dynamic> item) {
    final svc = item['services'] is Map ? item['services'] as Map : const {};
    final name = svc['name']?.toString() ?? 'خدمة';
    final quote = item['quote'] is Map ? item['quote'] as Map : null;
    String priceText;
    if (item['quote_error'] != null) {
      priceText = 'تعذّر التسعير';
    } else if (quote == null) {
      priceText = '';
    } else if (quote['is_quote_request'] == true) {
      priceText = 'بعرض سعر';
    } else {
      priceText = workMoney(quote['total'] ?? 0);
    }
    return Card(
      margin: const EdgeInsets.only(bottom: Space.sm),
      child: ListTile(
        title: Text(name),
        subtitle: priceText.isEmpty ? null : Text(priceText),
        trailing: IconButton(
          tooltip: 'إزالة',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _removeItem(item),
        ),
      ),
    );
  }

  Widget _bookingTile(Map<String, dynamic> b) {
    final svc = b['services'] is Map ? b['services'] as Map : const {};
    final status = b['status']?.toString() ?? '';
    final pill = StatusPillFromCode.describe(status);
    return Card(
      margin: const EdgeInsets.only(bottom: Space.sm),
      child: ListTile(
        title: Text(svc['name']?.toString() ?? 'خدمة'),
        subtitle: Text(
            '${workDate(b['booking_date']?.toString())} • ${workMoney(b['total_price'] ?? 0)}'),
        trailing: Text(pill.label, style: AppText.caption),
      ),
    );
  }

  Widget _occasionTile(Map<String, dynamic> o) {
    final status = o['status']?.toString() ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: Space.sm),
      child: ListTile(
        leading: const Icon(Icons.groups_2_outlined),
        title: Text('طلب تنظيم مناسبة'),
        subtitle: Text(workMoney(o['estimated_priced_subtotal'] ?? 0)),
        trailing: Text(status, style: AppText.caption),
      ),
    );
  }
}
