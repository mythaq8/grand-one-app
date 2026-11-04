import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../design/tokens.dart';
import '../design/typography.dart';
import '../services/api_exceptions.dart';
import '../services/api_service.dart';
import 'intro_screen.dart';
import 'work/work_dashboard_tab.dart';
import 'organizer_rentals_screen.dart';
import 'organizer_request_providers_screen.dart';

/// لوحة المنظّم — طلبات المناسبات / عروض / خدمات خاصة
class OrganizerShellScreen extends StatefulWidget {
  const OrganizerShellScreen({super.key});

  @override
  State<OrganizerShellScreen> createState() => _OrganizerShellScreenState();
}

class _OrganizerShellScreenState extends State<OrganizerShellScreen> {
  int _tab = 0;
  String? _organizerName;
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
      final res = await ApiService.getOrganizerMe();
      final organizer = res['organizer'];
      if (organizer is Map) {
        _organizerName = organizer['display_name']?.toString();
      }
    } on ApiException catch (e) {
      _bootError = e.message;
    } catch (_) {
      _bootError =
          'تعذر تحميل حساب المنظّم. تأكد من ربط الحساب ونشر الـ API وتطبيق SQL.';
    }
    if (mounted) setState(() => _bootLoading = false);
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
          _organizerName == null || _organizerName!.isEmpty
              ? '${AppConfig.appName} — منظّم'
              : _organizerName!,
        ),
        actions: [
          IconButton(
            tooltip: 'التأجير بين المنظّمين',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OrganizerRentalsScreen()),
            ),
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
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
                    const WorkDashboardTab(isProvider: false),
                    const _OrganizerRequestsTab(),
                    const _OrganizerOwnedServicesTab(),
                    const _OrganizerAvailabilityTab(),
                  ],
                ),
      bottomNavigationBar: _bootError != null
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'لوحتي',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inbox_outlined),
                  selectedIcon: Icon(Icons.inbox),
                  label: 'الطلبات',
                ),
                NavigationDestination(
                  icon: Icon(Icons.miscellaneous_services_outlined),
                  selectedIcon: Icon(Icons.miscellaneous_services),
                  label: 'خدماتي',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: 'التقويم',
                ),
              ],
            ),
    );
  }
}

String _statusAr(String? s) {
  switch (s) {
    case 'new':
      return 'جديد';
    case 'in_review':
      return 'قيد المراجعة';
    case 'awaiting_client':
      return 'بانتظار العميل';
    case 'awaiting_deposit':
      return 'بانتظار العربون';
    case 'confirmed':
      return 'مؤكد';
    case 'closed':
      return 'مغلق';
    default:
      return s ?? '-';
  }
}

class _OrganizerRequestsTab extends StatefulWidget {
  const _OrganizerRequestsTab();

  @override
  State<_OrganizerRequestsTab> createState() => _OrganizerRequestsTabState();
}

class _OrganizerRequestsTabState extends State<_OrganizerRequestsTab> {
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
      final res = await ApiService.getOrganizerRequests(limit: 50);
      final data = res['data'];
      if (data is List) {
        _items = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
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
        child: Text(
          'لا توجد طلبات مسندة بعد',
          style: AppText.caption,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(Space.md),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
        itemBuilder: (context, i) {
          final r = _items[i];
          final id = r['id']?.toString() ?? '';
          final type = r['occasion_type']?.toString() ?? '';
          final status = r['status']?.toString();
          final date = r['occasion_date']?.toString() ?? 'بدون تاريخ';
          final gov = r['governorate']?.toString() ?? '';
          return Card(
            child: ListTile(
              title: Text('$type · $gov'),
              subtitle: Text('$date · ${_statusAr(status)}'),
              trailing: const Icon(Icons.chevron_left),
              onTap: id.isEmpty
                  ? null
                  : () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              _OrganizerRequestDetailScreen(requestId: id),
                        ),
                      );
                      if (mounted) _load();
                    },
            ),
          );
        },
      ),
    );
  }
}

class _OrganizerRequestDetailScreen extends StatefulWidget {
  const _OrganizerRequestDetailScreen({required this.requestId});

  final String requestId;

  @override
  State<_OrganizerRequestDetailScreen> createState() =>
      _OrganizerRequestDetailScreenState();
}

class _OrganizerRequestDetailScreenState
    extends State<_OrganizerRequestDetailScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _request;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _quotes = [];

  final _feePctCtrl = TextEditingController(text: '10');
  final _extraCtrl = TextEditingController(text: '0');
  final _msgCtrl = TextEditingController();
  final Map<String, TextEditingController> _priceCtrls = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _feePctCtrl.dispose();
    _extraCtrl.dispose();
    _msgCtrl.dispose();
    for (final c in _priceCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res =
          await ApiService.getOrganizerRequestDetails(widget.requestId);
      final req = res['request'];
      _request = req is Map ? Map<String, dynamic>.from(req) : null;
      final items = res['items'];
      _items = items is List
          ? items
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : [];
      final quotes = res['quotes'];
      _quotes = quotes is List
          ? quotes
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : [];
      for (final it in _items) {
        final id = it['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        final snap = it['unit_price_snapshot'] ?? it['line_total_snapshot'];
        _priceCtrls.putIfAbsent(
          id,
          () => TextEditingController(text: '${snap ?? ''}'),
        );
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'تعذر تحميل الطلب';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _sendQuote({required bool send}) async {
    if (_busy) return;
    final feePct = double.tryParse(_feePctCtrl.text.trim()) ?? -1;
    final extra = double.tryParse(_extraCtrl.text.trim()) ?? -1;
    if (feePct < 0 || feePct > 100 || extra < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تحقق من نسبة الرسوم والرسوم الإضافية')),
      );
      return;
    }

    final quoteItems = <Map<String, dynamic>>[];
    for (final it in _items) {
      final id = it['id']?.toString() ?? '';
      final title = it['service_name']?.toString() ?? 'خدمة';
      final qtyRaw = it['quantity'];
      final qty = qtyRaw is num
          ? qtyRaw.toDouble()
          : double.tryParse('${qtyRaw ?? 1}') ?? 1;
      final priceText = _priceCtrls[id]?.text.trim() ?? '';
      final unit = double.tryParse(priceText);
      if (unit == null || unit < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('سعر غير صالح لـ $title')),
        );
        return;
      }
      quoteItems.add({
        'title': title,
        'quantity': qty,
        'unit_label': it['unit_label'],
        'unit_price': unit,
        'service_id': it['service_id'],
        'source_type': 'marketplace',
        'availability_status': 'pending_provider',
      });
    }
    if (quoteItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد بنود')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await ApiService.createOrganizerQuote(
        requestId: widget.requestId,
        items: quoteItems,
        organizerFeePct: feePct,
        extraFees: extra,
        clientMessage: _msgCtrl.text.trim(),
        send: send,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(send ? 'تم إرسال العرض للعميل' : 'تم حفظ مسودة العرض'),
        ),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ العرض')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _request?['status']?.toString();
    final canQuote = status == 'new' ||
        status == 'in_review' ||
        status == 'awaiting_client';
    final contactHidden = _request?['client_contact_hidden'] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الطلب'),
        actions: [
          IconButton(
            tooltip: 'المزوّدون',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OrganizerRequestProvidersScreen(
                  requestId: widget.requestId,
                ),
              ),
            ),
            icon: const Icon(Icons.groups_2_outlined),
          ),
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(Space.md),
                  children: [
                    Text(
                      'الحالة: ${_statusAr(status)}',
                      style: AppText.section,
                    ),
                    const SizedBox(height: Space.sm),
                    Text(
                      'المحافظة: ${_request?['governorate'] ?? '-'}',
                    ),
                    Text(
                      'التاريخ: ${_request?['occasion_date'] ?? 'غير محدد'}'
                      '${_request?['occasion_date_end'] != null ? ' → ${_request!['occasion_date_end']}' : ''}',
                    ),
                    Text(
                      contactHidden
                          ? 'واتساب العميل: مخفي حتى تحقق العربون'
                          : 'واتساب: ${_request?['whatsapp'] ?? '-'}',
                    ),
                    if (_request?['deposit_amount'] != null)
                      Text(
                        'عربون: ${_request?['deposit_amount']} \$',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    const SizedBox(height: Space.md),
                    Text('بنود الطلب', style: AppText.section),
                    const SizedBox(height: Space.sm),
                    ..._items.map((it) {
                      final id = it['id']?.toString() ?? '';
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(Space.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                it['service_name']?.toString() ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'كمية ${it['quantity']} ${it['unit_label'] ?? ''}',
                              ),
                              if (canQuote) ...[
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _priceCtrls[id],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'سعر الوحدة (\$)',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                    if (_quotes.isNotEmpty) ...[
                      const SizedBox(height: Space.md),
                      Text('العروض السابقة', style: AppText.section),
                      ..._quotes.map(
                        (q) => ListTile(
                          dense: true,
                          title: Text(
                            'v${q['version']} · ${q['status']} · ${q['total']} \$',
                          ),
                          subtitle: q['deposit_amount'] != null
                              ? Text('عربون ${q['deposit_amount']} \$')
                              : null,
                        ),
                      ),
                    ],
                    if (canQuote) ...[
                      const SizedBox(height: Space.md),
                      Text('إنشاء عرض', style: AppText.section),
                      const SizedBox(height: Space.sm),
                      TextField(
                        controller: _feePctCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'رسوم المنظّم %',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: Space.sm),
                      TextField(
                        controller: _extraCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'رسوم إضافية \$',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: Space.sm),
                      TextField(
                        controller: _msgCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'رسالة للعميل (اختياري)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: Space.md),
                      FilledButton(
                        onPressed: _busy ? null : () => _sendQuote(send: true),
                        child: const Text('إرسال العرض للعميل'),
                      ),
                      TextButton(
                        onPressed:
                            _busy ? null : () => _sendQuote(send: false),
                        child: const Text('حفظ كمسودة'),
                      ),
                      const Text(
                        'العربون يُحسب تلقائياً 20٪ من الإجمالي عند الإرسال.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
    );
  }
}

class _OrganizerOwnedServicesTab extends StatefulWidget {
  const _OrganizerOwnedServicesTab();

  @override
  State<_OrganizerOwnedServicesTab> createState() =>
      _OrganizerOwnedServicesTabState();
}

class _OrganizerOwnedServicesTabState
    extends State<_OrganizerOwnedServicesTab> {
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
      final services = ApiService.getOrganizerOwnedServices();
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
    var rentable = existing?['rentable'] == true;
    final rentalCtrl = TextEditingController(
      text: existing?['rental_price']?.toString() ?? '',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: Text(
              existing == null ? 'خدمة منظّم جديدة' : 'تعديل خدمة المنظّم',
            ),
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
                    value: (categoryId == null || categoryId!.isEmpty)
                        ? ''
                        : categoryId,
                    decoration: const InputDecoration(
                      labelText: 'التصنيف',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('بدون تصنيف'),
                      ),
                      ..._categories.map((c) {
                        final id = c['id']?.toString() ?? '';
                        return DropdownMenuItem(
                          value: id,
                          child: Text(c['name']?.toString() ?? id),
                        );
                      }),
                    ],
                    onChanged: (v) =>
                        setLocal(() => categoryId = (v == null || v.isEmpty) ? null : v),
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
                    title: const Text('متاحة للتأجير لمنظّمين آخرين'),
                    value: rentable,
                    onChanged: (v) => setLocal(() => rentable = v),
                  ),
                  if (rentable)
                    TextField(
                      controller: rentalCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'سعر التأجير لليوم (\$) *',
                        border: OutlineInputBorder(),
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
    final rentalPrice = num.tryParse(rentalCtrl.text.trim());
    rentalCtrl.dispose();
    nameCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    if (ok != true) return;

    if (name.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اسم الخدمة مطلوب')),
      );
      return;
    }

    final fields = <String, dynamic>{
      'name': name,
      'description': desc.isEmpty ? null : desc,
      'base_price': price,
      'is_active': isActive,
      'capacity_mode': existing?['capacity_mode'] ?? 'exclusive',
      'rentable': rentable,
      'rental_price': rentable ? rentalPrice : null,
      if (categoryId != null && categoryId!.isNotEmpty)
        'category_id': categoryId,
    };

    try {
      if (existing == null) {
        await ApiService.createOrganizerOwnedService(fields);
      } else {
        await ApiService.updateOrganizerOwnedService(
          serviceId: existing['id'].toString(),
          fields: fields,
        );
      }
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _delete(Map<String, dynamic> service) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إيقاف الخدمة؟'),
        content: Text('سيتم إيقاف «${service['name'] ?? ''}».'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إيقاف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.deleteOrganizerOwnedService(service['id'].toString());
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
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
                  'لا توجد خدمات خاصة بعد. أضف خدمة تستخدمها في عروض المناسبات.',
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
                separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
                itemBuilder: (context, i) {
                  final s = _items[i];
                  return Card(
                    child: ListTile(
                      title: Text(s['name']?.toString() ?? ''),
                      subtitle: Text(
                        '${s['base_price'] ?? '-'} \$ · '
                        '${s['is_active'] == true ? 'نشط' : 'متوقف'}',
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
                            tooltip: 'إيقاف',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _delete(s),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _OrganizerAvailabilityTab extends StatefulWidget {
  const _OrganizerAvailabilityTab();

  @override
  State<_OrganizerAvailabilityTab> createState() =>
      _OrganizerAvailabilityTabState();
}

class _OrganizerAvailabilityTabState extends State<_OrganizerAvailabilityTab> {
  final List<Map<String, dynamic>> _exceptions = [];
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
      final res = await ApiService.getOrganizerAvailability();
      final ex = res['exceptions'];
      _exceptions
        ..clear()
        ..addAll(ex is List
            ? ex.whereType<Map>().map((e) => Map<String, dynamic>.from(e))
            : const <Map<String, dynamic>>[]);
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

  Future<void> _saveExceptions() async {
    try {
      await ApiService.saveOrganizerAvailability(
        exceptions: [
          for (final e in _exceptions)
            {
              'exception_date': e['exception_date'].toString().substring(0, 10),
              'is_closed': true,
              if (e['note'] != null) 'note': e['note'],
            },
        ],
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
      await _load();
    }
  }

  Future<void> _addClosedDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 2, now.month, now.day),
      helpText: 'إغلاق تاريخ أمام العملاء',
    );
    if (picked == null) return;
    final iso =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    if (_exceptions.any((e) => e['exception_date'].toString().startsWith(iso))) {
      return;
    }
    setState(() {
      _exceptions.add({'exception_date': iso, 'is_closed': true});
      _exceptions.sort((a, b) =>
          a['exception_date'].toString().compareTo(b['exception_date'].toString()));
    });
    await _saveExceptions();
  }

  Future<void> _removeClosedDay(Map<String, dynamic> e) async {
    setState(() => _exceptions.remove(e));
    await _saveExceptions();
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
      await ApiService.saveOrganizerAvailability(rules: rules);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التقويم')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر الحفظ')),
      );
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
        for (var d = 0; d < 7; d++)
          Card(
            child: SwitchListTile(
              title: Text(_dayNames[d]),
              subtitle: _open[d] == true
                  ? Text(
                      '${_fmt(_start[d]!).substring(0, 5)} — ${_fmt(_end[d]!).substring(0, 5)}',
                    )
                  : const Text('مغلق'),
              value: _open[d] == true,
              onChanged: (v) => setState(() => _open[d] = v),
              secondary: _open[d] == true
                  ? IconButton(
                      icon: const Icon(Icons.schedule),
                      onPressed: () async {
                        await _pick(d, true);
                        await _pick(d, false);
                      },
                    )
                  : null,
            ),
          ),
        const SizedBox(height: Space.md),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'جاري الحفظ...' : 'حفظ التقويم'),
        ),
        const SizedBox(height: Space.xl),
        Row(
          children: [
            Expanded(child: Text('أيام مغلقة أمام العملاء', style: AppText.section)),
            TextButton.icon(
              onPressed: _addClosedDay,
              icon: const Icon(Icons.event_busy),
              label: const Text('إغلاق تاريخ'),
            ),
          ],
        ),
        if (_exceptions.isEmpty)
          Text('لا أيام مغلقة.', style: AppText.caption),
        for (final e in _exceptions)
          Card(
            child: ListTile(
              leading: const Icon(Icons.block),
              title: Text(e['exception_date'].toString().substring(0, 10)),
              subtitle: e['note'] == null ? null : Text(e['note'].toString()),
              trailing: IconButton(
                tooltip: 'فتح التاريخ',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _removeClosedDay(e),
              ),
            ),
          ),
      ],
    );
  }
}
