import '../ui/kit/kit.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../design/tokens.dart';
import '../design/typography.dart';
import '../services/api_exceptions.dart';
import '../services/api_service.dart';
import 'intro_screen.dart';
import 'work/work_dashboard_tab.dart';
import 'work/work_formatters.dart';
import '../ui/kit/status_pill.dart';

/// لوحة المزوّد — طلبات / خدمات / تقويم
class ProviderShellScreen extends StatefulWidget {
  const ProviderShellScreen({super.key});

  @override
  State<ProviderShellScreen> createState() => _ProviderShellScreenState();
}

class _ProviderShellScreenState extends State<ProviderShellScreen> {
  int _tab = 0;
  int _pendingCount = 0;
  String? _providerName;
  bool _bootLoading = true;
  String? _bootError;

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  Future<void> _loadMe() async {
    setState(() {
      _bootLoading = true;
      _bootError = null;
    });
    try {
      final res = await ApiService.getProviderMe();
      final provider = res['provider'];
      if (provider is Map) {
        _providerName = provider['name']?.toString();
      }
    } on ApiException catch (e) {
      _bootError = e.message;
    } catch (_) {
      _bootError = 'تعذر تحميل حساب المزوّد. تأكد من ربط الحساب ونشر الـ API.';
    }
    if (mounted) setState(() => _bootLoading = false);
    _refreshPending();
  }

  /// عدد الطلبات الجديدة التي تنتظر ردّ المزوّد (شارة على تبويب الطلبات)
  Future<void> _refreshPending() async {
    try {
      final res = await ApiService.getProviderBookings(status: 'pending', limit: 50);
      final data = res['data'];
      if (mounted) setState(() => _pendingCount = data is List ? data.length : 0);
    } catch (_) {
      // الشارة اختيارية؛ نتجاهل الفشل
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const IntroScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: Text(
          _providerName == null || _providerName!.isEmpty
              ? '${AppConfig.appName} — مزوّد'
              : _providerName!,
        ),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _bootLoading
          ? const Center(child: CircularProgressIndicator())
          : _bootError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(Space.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_bootError!, textAlign: TextAlign.center),
                        const SizedBox(height: Space.md),
                        FilledButton(
                          onPressed: _loadMe,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                )
              : IndexedStack(
                  index: _tab,
                  children: [
                    const WorkDashboardTab(isProvider: true),
                    const _ProviderBookingsTab(),
                    const _ProviderServicesTab(),
                    const _ProviderAvailabilityTab(),
                  ],
                ),
      bottomNavigationBar: _bootError != null
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) {
                setState(() => _tab = i);
                _refreshPending();
              },
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'لوحتي',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: _pendingCount > 0,
                    label: Text('$_pendingCount'),
                    child: const Icon(Icons.inbox_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: _pendingCount > 0,
                    label: Text('$_pendingCount'),
                    child: const Icon(Icons.inbox),
                  ),
                  label: 'الطلبات',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.miscellaneous_services_outlined),
                  selectedIcon: Icon(Icons.miscellaneous_services),
                  label: 'خدماتي',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: 'التقويم',
                ),
              ],
            ),
    );
  }
}

class _ProviderBookingsTab extends StatefulWidget {
  const _ProviderBookingsTab();

  @override
  State<_ProviderBookingsTab> createState() => _ProviderBookingsTabState();
}

class _ProviderBookingsTabState extends State<_ProviderBookingsTab> {
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
      final res = await ApiService.getProviderBookings(limit: 50, excludeClosed: true);
      final data = res['data'];
      if (data is List) {
        _items = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        // الطلبات التي تنتظر ردّك أولاً، ثم الأقرب موعداً
        int rank(Map<String, dynamic> b) {
          switch (b['status']?.toString()) {
            case 'pending':
            case 'quote_requested':
              return 0;
            case 'modification_proposed':
              return 1;
            default:
              return 2;
          }
        }
        _items.sort((a, b) {
          final r = rank(a).compareTo(rank(b));
          return r != 0
              ? r
              : (a['booking_date']?.toString() ?? '')
                  .compareTo(b['booking_date']?.toString() ?? '');
        });
      } else {
        _items = [];
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'تعذر جلب الطلبات';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _respond(String id, String action) async {
    try {
      await ApiService.respondProviderBooking(bookingId: id, action: action);
      if (!mounted) return;
      showAppSnack(context, action == 'confirm' ? 'تم التأكيد' : 'تم الرفض', tone: FeedbackTone.success);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppSnack(context, e.message, tone: FeedbackTone.error);
    }
  }

  Future<void> _proposeModification(Map<String, dynamic> booking) async {
    final id = booking['id'].toString();
    final pricingModel = booking['pricing_model']?.toString();
    final qtyLabel = pricingModel == 'per_unit'
        ? 'كمية بديلة (اختياري)'
        : pricingModel == 'per_duration'
            ? 'مدة بديلة (اختياري)'
            : null;
    DateTime? date;
    TimeOfDay? time;
    final qtyCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('اقتراح تعديل'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: Text(date == null
                      ? 'تاريخ بديل (اختياري)'
                      : '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}'),
                  onTap: () async {
                    final now = DateTime.now();
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: date ?? now,
                      firstDate: now,
                      lastDate: DateTime(now.year + 2),
                    );
                    if (d != null) setLocal(() => date = d);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: Text(time == null
                      ? 'وقت بديل (اختياري)'
                      : time!.format(ctx)),
                  onTap: () async {
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime: time ?? const TimeOfDay(hour: 18, minute: 0),
                    );
                    if (t != null) setLocal(() => time = t);
                  },
                ),
                if (qtyLabel != null)
                  TextField(
                    controller: qtyCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: qtyLabel,
                      helperText: 'الحالية: ${pricingModel == 'per_unit' ? booking['quantity'] : booking['duration_value']} — يُعاد التسعير ويرى العميل السعر الجديد',
                    ),
                  ),
                TextField(
                  controller: noteCtrl,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة للعميل *',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final qtyValue = double.tryParse(qtyCtrl.text.trim());
                if (noteCtrl.text.trim().length < 3 ||
                    (date == null && time == null && qtyValue == null)) {
                  showAppSnack(ctx, 'اقترح تاريخاً أو وقتاً وأضف ملاحظة');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
    final note = noteCtrl.text.trim();
    final qtyValue = double.tryParse(qtyCtrl.text.trim());
    noteCtrl.dispose();
    qtyCtrl.dispose();
    if (submitted != true) return;

    try {
      await ApiService.respondProviderBooking(
        bookingId: id,
        action: 'modify',
        note: note,
        newDate: date == null
            ? null
            : '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}',
        newTime: time == null
            ? null
            : '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}',
        newQuantity: pricingModel == 'per_unit' ? qtyValue : null,
        newDurationValue: pricingModel == 'per_duration' ? qtyValue : null,
      );
      if (!mounted) return;
      showAppSnack(context, 'أُرسل اقتراح التعديل للعميل', tone: FeedbackTone.success);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppSnack(context, e.message, tone: FeedbackTone.error);
    }
  }

  /// نص المهلة المتبقية (ساعات) أو null.
  String? _dueLabel(dynamic raw, String prefix) {
    final due = DateTime.tryParse(raw?.toString() ?? '');
    if (due == null) return null;
    final left = due.difference(DateTime.now());
    if (left.isNegative) return '$prefix: انتهت المهلة';
    final hours = left.inHours;
    return hours >= 1 ? '$prefix: $hours ساعة' : '$prefix: أقل من ساعة';
  }

  /// صفوف العرض: ترويسة لكل مجموعة (أكثر من طلب من فعالية واحدة) ثم أعضاؤها.
  List<Map<String, dynamic>> _displayRows() {
    final byGroup = <String, List<Map<String, dynamic>>>{};
    for (final b in _items) {
      final g = b['group_id']?.toString();
      if (g != null && g.isNotEmpty) {
        byGroup.putIfAbsent(g, () => []).add(b);
      }
    }
    final rows = <Map<String, dynamic>>[];
    final shown = <String>{};
    for (final b in _items) {
      final g = b['group_id']?.toString();
      if (g != null && (byGroup[g]?.length ?? 0) > 1 && shown.add(g)) {
        rows.add({'kind': 'group', 'id': g, 'members': byGroup[g]!});
      }
      rows.add({'kind': 'single', 'b': b});
    }
    return rows;
  }

  bool _isRespondable(String status) =>
      const ['pending', 'quote_requested', 'quoted', 'deposit_rejected']
          .contains(status);

  Future<void> _respondGroup(String groupId, String action) async {
    try {
      final res = await ApiService.respondProviderBookingGroup(
        groupId: groupId,
        action: action,
      );
      if (!mounted) return;
      showAppSnack(context, action == 'confirm'
                ? 'تم تأكيد ${res['updated'] ?? 0} طلب'
                : 'تم رفض ${res['updated'] ?? 0} طلب', tone: FeedbackTone.success);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppSnack(context, e.message, tone: FeedbackTone.error);
    }
  }

  Widget _groupHeader(Map<String, dynamic> row) {
    final members = (row['members'] as List).cast<Map<String, dynamic>>();
    final open = members
        .where((b) => _isRespondable(b['status']?.toString() ?? ''))
        .length;
    final due = members
        .map((b) => b['provider_response_due_at'])
        .whereType<String>()
        .toList()
      ..sort();
    final dueLabel = due.isEmpty ? null : _dueLabel(due.first, 'المتبقي للرد');
    return Card(
      color: AppPalette.goldSoft,
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('طلب فعالية يضم ${members.length} خدمات', style: AppText.section),
            if (dueLabel != null) Text(dueLabel, style: AppText.caption),
            if (open > 0) ...[
              const SizedBox(height: Space.sm),
              Row(
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                    onPressed: () =>
                        _respondGroup(row['id'].toString(), 'confirm'),
                    child: Text('تأكيد الكل ($open)'),
                  ),
                  const SizedBox(width: Space.sm),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                    onPressed: () =>
                        _respondGroup(row['id'].toString(), 'reject'),
                    child: const Text('رفض الكل'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('إعادة')),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Text('لا طلبات حالياً', style: AppText.caption),
      );
    }

    final rows = _displayRows();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(Space.md),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
        itemBuilder: (context, i) {
          final row = rows[i];
          if (row['kind'] == 'group') return _groupHeader(row);
          final b = row['b'] as Map<String, dynamic>;
          final service = b['services'];
          final serviceName = service is Map
              ? (service['name']?.toString() ?? 'خدمة')
              : 'خدمة';
          final status = b['status']?.toString() ?? '';
          final date = b['booking_date']?.toString() ?? '';
          final time = b['booking_time']?.toString() ?? '';
          final canRespond = status == 'pending' ||
              status == 'quote_requested' ||
              status == 'quoted' ||
              status == 'deposit_rejected';

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(serviceName, style: AppText.section),
                  const SizedBox(height: 4),
                  Text('$date  ${time.isEmpty ? '' : time}'),
                  Text('الحالة: ${StatusPillFromCode.describe(status).label}'),
                  if (b['total_price'] != null)
                    Text('السعر: ${workMoney(b['total_price'])}'),
                  if (status == 'pending' || status == 'quote_requested')
                    if (_dueLabel(b['provider_response_due_at'], 'المتبقي للرد') case final l?)
                      Text(l, style: AppText.caption),
                  if (status == 'modification_proposed')
                    if (_dueLabel(b['customer_response_due_at'], 'بانتظار رد العميل') case final l?)
                      Text(l, style: AppText.caption),
                  if (b['customer_contact_hidden'] == true)
                    Text(
                      'رقم العميل مخفي حتى تحقق العربون',
                      style: AppText.caption,
                    ),
                  if (canRespond) ...[
                    const SizedBox(height: Space.sm),
                    Row(
                      children: [
                        // بعد رفض إشعار الدفع ينتظر الطلب إعادة رفع العميل؛ للمزوّد الاعتذار فقط
                        if (status != 'deposit_rejected') ...[
                          FilledButton(
                            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                            onPressed: () =>
                                _respond(b['id'].toString(), 'confirm'),
                            child: const Text('تأكيد'),
                          ),
                          const SizedBox(width: Space.sm),
                        ],
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                          onPressed: () =>
                              _respond(b['id'].toString(), 'reject'),
                          child: const Text('رفض'),
                        ),
                        if (status == 'pending' || status == 'quote_requested') ...[
                          const SizedBox(width: Space.sm),
                          TextButton(
                            onPressed: () =>
                                _proposeModification(b),
                            child: const Text('اقتراح تعديل'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProviderServicesTab extends StatefulWidget {
  const _ProviderServicesTab();

  @override
  State<_ProviderServicesTab> createState() => _ProviderServicesTabState();
}

class _ProviderServicesTabState extends State<_ProviderServicesTab> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _categories = [];

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
      final services = ApiService.getProviderServices();
      final cats = ApiService.getServiceCategories();
      _items = await services;
      _categories = await cats;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'تعذر جلب الخدمات';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _upsert({Map<String, dynamic>? existing}) async {
    final nameCtrl = TextEditingController(
      text: existing?['name']?.toString() ?? '',
    );
    final descCtrl = TextEditingController(
      text: existing?['description']?.toString() ?? '',
    );
    final priceCtrl = TextEditingController(
      text: (existing?['base_price'] ?? '').toString(),
    );
    String? categoryId = existing?['category_id']?.toString();
    var isActive = existing?['is_active'] != false;
    var isBookable = existing?['is_bookable'] == true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: Text(existing == null ? 'خدمة جديدة' : 'تعديل الخدمة'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'اسم الخدمة *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                  DropdownButtonFormField<String>(
                    value: categoryId,
                    decoration: const InputDecoration(
                      labelText: 'التصنيف *',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((c) {
                      final id = c['id']?.toString() ?? '';
                      return DropdownMenuItem(
                        value: id,
                        child: Text(c['name']?.toString() ?? id),
                      );
                    }).toList(),
                    onChanged: (v) => setLocal(() => categoryId = v),
                  ),
                  const SizedBox(height: Space.sm),
                  TextField(
                    controller: priceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'السعر الأساسي (\$)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'الوصف',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('نشطة'),
                    value: isActive,
                    onChanged: (v) => setLocal(() => isActive = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('قابلة للحجز المباشر'),
                    value: isBookable,
                    onChanged: (v) => setLocal(() => isBookable = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );

    final name = nameCtrl.text.trim();
    final desc = descCtrl.text.trim();
    final price = num.tryParse(priceCtrl.text.trim());
    nameCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    if (ok != true) return;

    if (name.isEmpty || categoryId == null || categoryId!.isEmpty) {
      if (!mounted) return;
      showAppSnack(context, 'الاسم والتصنيف مطلوبان');
      return;
    }

    final fields = <String, dynamic>{
      'name': name,
      'category_id': categoryId,
      'description': desc.isEmpty ? null : desc,
      'base_price': price,
      'is_active': isActive,
      'is_bookable': isBookable,
      'pricing_model': existing?['pricing_model'] ?? 'fixed_package',
    };

    try {
      if (existing == null) {
        await ApiService.createProviderService(fields);
      } else {
        await ApiService.updateProviderService(
          serviceId: existing['id'].toString(),
          fields: fields,
        );
      }
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppSnack(context, e.message, tone: FeedbackTone.error);
    }
  }

  Future<void> _delete(Map<String, dynamic> service) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الخدمة؟'),
        content: Text('سيتم أرشفة «${service['name'] ?? ''}» وإيقافها.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.deleteProviderService(service['id'].toString());
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppSnack(context, e.message, tone: FeedbackTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('إعادة')),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _upsert(),
        icon: const Icon(Icons.add),
        label: const Text('خدمة جديدة'),
      ),
      body: _items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(Space.lg),
                child: Text(
                  'لا خدمات بعد. أضف خدمتك الأولى من الزر أدناه.',
                  style: AppText.caption,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  Space.md,
                  Space.md,
                  Space.md,
                  88,
                ),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
                itemBuilder: (context, i) {
                  final s = _items[i];
                  return ListTile(
                    tileColor: AppPalette.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(s['name']?.toString() ?? 'خدمة'),
                    subtitle: Text(
                      'السعر: ${s['base_price'] ?? '-'} · '
                      '${s['is_active'] == true ? 'نشطة' : 'متوقفة'} · '
                      '${s['is_bookable'] == true ? 'حجز مباشر' : 'عبر منظّم/عرض'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'تعديل',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _upsert(existing: s),
                        ),
                        IconButton(
                          tooltip: 'حذف',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(s),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _ProviderAvailabilityTab extends StatefulWidget {
  const _ProviderAvailabilityTab();

  @override
  State<_ProviderAvailabilityTab> createState() =>
      _ProviderAvailabilityTabState();
}

class _ProviderAvailabilityTabState extends State<_ProviderAvailabilityTab> {
  static const _dayNames = [
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  bool _loading = true;
  bool _saving = false;
  String? _error;
  /// weekday -> enabled
  final Map<int, bool> _open = {for (var i = 0; i < 7; i++) i: false};
  final Map<int, TimeOfDay> _start = {
    for (var i = 0; i < 7; i++) i: const TimeOfDay(hour: 10, minute: 0),
  };
  final Map<int, TimeOfDay> _end = {
    for (var i = 0; i < 7; i++) i: const TimeOfDay(hour: 22, minute: 0),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  TimeOfDay _parse(String? raw, TimeOfDay fallback) {
    if (raw == null || raw.isEmpty) return fallback;
    final parts = raw.split(':');
    if (parts.length < 2) return fallback;
    final h = int.tryParse(parts[0]) ?? fallback.hour;
    final m = int.tryParse(parts[1]) ?? fallback.minute;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.getProviderAvailability();
      final rules = res['rules'];
      if (rules is List) {
        for (final r in rules.whereType<Map>()) {
          final day = int.tryParse(r['weekday']?.toString() ?? '');
          if (day == null || day < 0 || day > 6) continue;
          _open[day] = r['is_open'] != false;
          _start[day] = _parse(r['start_time']?.toString(), _start[day]!);
          _end[day] = _parse(r['end_time']?.toString(), _end[day]!);
        }
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'تعذر جلب التقويم';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pick(int day, bool isStart) async {
    final initial = isStart ? _start[day]! : _end[day]!;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start[day] = picked;
      } else {
        _end[day] = picked;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final rules = <Map<String, dynamic>>[];
      for (var d = 0; d < 7; d++) {
        if (_open[d] != true) continue;
        rules.add({
          'weekday': d,
          'start_time': _fmt(_start[d]!),
          'end_time': _fmt(_end[d]!),
          'is_open': true,
        });
      }
      await ApiService.saveProviderAvailability(rules: rules);
      if (!mounted) return;
      showAppSnack(context, 'تم حفظ ساعات العمل', tone: FeedbackTone.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppSnack(context, e.message, tone: FeedbackTone.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('إعادة')),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(Space.md),
      children: [
        Text(
          'حدّد أيام وساعات العمل بدقة. إن لم تضبط أي يوم، النظام يسمح بالحجز مع فحص التعارض فقط.',
          style: AppText.caption,
        ),
        const SizedBox(height: Space.md),
        for (var d = 0; d < 7; d++) ...[
          SwitchListTile(
            title: Text(_dayNames[d]),
            value: _open[d] == true,
            onChanged: (v) => setState(() => _open[d] = v),
          ),
          if (_open[d] == true)
            Padding(
              padding: const EdgeInsets.only(right: Space.lg, bottom: Space.sm),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => _pick(d, true),
                    child: Text('من ${_fmt(_start[d]!).substring(0, 5)}'),
                  ),
                  TextButton(
                    onPressed: () => _pick(d, false),
                    child: Text('إلى ${_fmt(_end[d]!).substring(0, 5)}'),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: Space.md),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'جاري الحفظ...' : 'حفظ التقويم'),
        ),
      ],
    );
  }
}
