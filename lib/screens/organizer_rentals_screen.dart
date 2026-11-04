import '../ui/kit/kit.dart';
import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../design/typography.dart';
import '../services/api_exceptions.dart';
import '../services/api_service.dart';
import '../ui/kit/states.dart';
import 'work/work_formatters.dart';

/// التأجير بين المنظّمين: استعرض أصولاً يؤجّرها منظّمون آخرون واطلبها،
/// وردّ على طلبات الاستئجار الواردة على أصولك (24 ساعة).
class OrganizerRentalsScreen extends StatelessWidget {
  const OrganizerRentalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppPalette.background,
        appBar: AppBar(
          title: const Text('التأجير بين المنظّمين'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'متاح للاستئجار'),
              Tab(text: 'طلبات واردة'),
              Tab(text: 'طلباتي'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CatalogTab(),
            _RentalsBox(box: 'incoming'),
            _RentalsBox(box: 'outgoing'),
          ],
        ),
      ),
    );
  }
}

void _toast(BuildContext c, String m) =>
    showAppSnack(c, m);

class _CatalogTab extends StatefulWidget {
  const _CatalogTab();

  @override
  State<_CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<_CatalogTab> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

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
      _items = await ApiService.getRentalCatalog();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'تعذر التحميل';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _request(Map<String, dynamic> item) async {
    final qty = TextEditingController(text: '1');
    final note = TextEditingController();
    DateTime? from;
    DateTime? to;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('استئجار: ${item['name']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${workMoney(item['rental_price'])} لليوم للوحدة'),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: Text(from == null ? 'من تاريخ *' : workDate(workIsoDate(from!))),
                  onTap: () async {
                    final now = DateTime.now();
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: from ?? now,
                      firstDate: now,
                      lastDate: DateTime(now.year + 2),
                    );
                    if (d != null) setLocal(() => from = d);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_available),
                  title: Text(to == null ? 'إلى تاريخ (اختياري)' : workDate(workIsoDate(to!))),
                  onTap: () async {
                    final base = from ?? DateTime.now();
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: base,
                      firstDate: base,
                      lastDate: DateTime(base.year + 2),
                    );
                    if (d != null) setLocal(() => to = d);
                  },
                ),
                TextField(
                  controller: qty,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الكمية'),
                ),
                TextField(
                  controller: note,
                  maxLength: 500,
                  decoration: const InputDecoration(labelText: 'ملاحظة'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () {
                if (from == null) {
                  ScaffoldMessenger.of(ctx)
                      .showSnackBar(const SnackBar(content: Text('اختر تاريخ البداية')));
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('إرسال الطلب'),
            ),
          ],
        ),
      ),
    );
    final qtyValue = int.tryParse(qty.text.trim()) ?? 1;
    final noteValue = note.text.trim();
    qty.dispose();
    note.dispose();
    if (ok != true || from == null) return;

    try {
      final res = await ApiService.requestRental({
        'owned_service_id': item['id'],
        'rental_date': workIsoDate(from!),
        if (to != null) 'rental_date_end': workIsoDate(to!),
        'quantity': qtyValue,
        if (noteValue.isNotEmpty) 'note': noteValue,
      });
      final rental = res['rental'];
      if (mounted) {
        _toast(context,
            'أُرسل الطلب. السعر ${rental is Map ? workMoney(rental['agreed_price']) : ''}');
      }
    } on ApiException catch (e) {
      if (mounted) _toast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorState(message: _error!, onRetry: _load);
    if (_items.isEmpty) {
      return const EmptyState(
        title: 'لا أصول للاستئجار',
        body: 'لم يعرض منظّمون آخرون أصولاً للتأجير بعد.',
        icon: Icons.inventory_2_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(Space.md),
        children: [
          for (final it in _items)
            Card(
              child: ListTile(
                title: Text(it['name']?.toString() ?? ''),
                subtitle: Text(
                  '${(it['organizers'] is Map ? it['organizers']['display_name'] : null) ?? 'منظّم'}'
                  ' • ${workMoney(it['rental_price'])} لليوم',
                ),
                trailing: FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: () => _request(it),
                  child: const Text('استأجر'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RentalsBox extends StatefulWidget {
  const _RentalsBox({required this.box});
  final String box;

  @override
  State<_RentalsBox> createState() => _RentalsBoxState();
}

class _RentalsBoxState extends State<_RentalsBox> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  static const _status = {
    'pending': 'بانتظار الرد',
    'accepted': 'مقبول',
    'rejected': 'مرفوض',
    'cancelled': 'ملغى',
    'expired': 'انتهت المهلة',
  };

  bool get _incoming => widget.box == 'incoming';

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
      _items = await ApiService.getOrganizerRentals(widget.box);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'تعذر التحميل';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _act(Map<String, dynamic> r, String action) async {
    try {
      await ApiService.actOnRental(r['id'].toString(), action);
      _load();
    } on ApiException catch (e) {
      if (mounted) _toast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorState(message: _error!, onRetry: _load);
    if (_items.isEmpty) {
      return EmptyState(
        title: _incoming ? 'لا طلبات واردة' : 'لم تطلب استئجار شيء',
        icon: Icons.swap_horiz_rounded,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(Space.md),
        children: [
          for (final r in _items)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (r['organizer_owned_services'] is Map
                              ? r['organizer_owned_services']['name']
                              : null)
                          ?.toString() ??
                          'أصل',
                      style: AppText.section,
                    ),
                    Text(
                      _incoming
                          ? 'من: ${(r['requester'] is Map ? r['requester']['display_name'] : null) ?? ''}'
                          : 'المالك: ${(r['owner'] is Map ? r['owner']['display_name'] : null) ?? ''}',
                    ),
                    Text(
                      '${workDate(r['rental_date']?.toString())}'
                      '${r['rental_date_end'] != null ? ' → ${workDate(r['rental_date_end'].toString())}' : ''}'
                      ' • الكمية ${r['quantity']}',
                    ),
                    Text('السعر المتفق: ${workMoney(r['agreed_price'])}'),
                    if (r['note'] != null) Text('ملاحظة: ${r['note']}'),
                    Text('الحالة: ${_status[r['status']] ?? r['status']}',
                        style: AppText.caption),
                    if (r['status'] == 'pending') ...[
                      const SizedBox(height: Space.sm),
                      Row(
                        children: [
                          if (_incoming) ...[
                            FilledButton(
                                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                                onPressed: () => _act(r, 'accept'),
                                child: const Text('قبول')),
                            const SizedBox(width: Space.sm),
                            OutlinedButton(
                                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                                onPressed: () => _act(r, 'reject'),
                                child: const Text('رفض')),
                          ] else
                            OutlinedButton(
                                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                                onPressed: () => _act(r, 'cancel'),
                                child: const Text('إلغاء الطلب')),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
