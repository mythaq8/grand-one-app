import '../ui/kit/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../design/tokens.dart';
import '../design/typography.dart';
import '../services/api_exceptions.dart';
import '../services/api_service.dart';
import '../ui/kit/states.dart';
import 'work/work_formatters.dart';

/// متابعة مزوّدي طلب مناسبة: مزوّدو التطبيق وحالة توفر كل بند، ومزوّدون
/// من خارج التطبيق (اسم ورقم ومبلغ ومدفوع)، مع المدفوع والمتبقي الإجمالي.
/// أرقام مزوّدي التطبيق تظهر بعد تحقق عربون الطلب.
class OrganizerRequestProvidersScreen extends StatefulWidget {
  const OrganizerRequestProvidersScreen({super.key, required this.requestId});

  final String requestId;

  @override
  State<OrganizerRequestProvidersScreen> createState() =>
      _OrganizerRequestProvidersScreenState();
}

class _OrganizerRequestProvidersScreenState
    extends State<OrganizerRequestProvidersScreen> {
  static const _avail = {
    'confirmed_available': 'متاح',
    'pending_provider': 'بانتظار المزوّد',
    'unavailable': 'غير متاح',
  };
  static const _extStatus = {
    'planned': 'مخطَّط',
    'confirmed': 'مؤكد',
    'done': 'تم',
    'cancelled': 'ملغى',
  };

  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = const {};

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
      _data = await ApiService.getRequestProviders(widget.requestId);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'تعذر التحميل';
    }
    if (mounted) setState(() => _loading = false);
  }

  void _toast(String m) =>
      showAppSnack(context, m);

  Future<void> _editExternal([Map<String, dynamic>? existing]) async {
    final name = TextEditingController(text: existing?['name']?.toString() ?? '');
    final phone = TextEditingController(text: existing?['phone']?.toString() ?? '');
    final label = TextEditingController(text: existing?['service_label']?.toString() ?? '');
    final amount = TextEditingController(text: existing == null ? '' : '${existing['amount_usd']}');
    final paid = TextEditingController(text: existing == null ? '' : '${existing['paid_usd']}');
    var status = existing?['status']?.toString() ?? 'planned';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'مزوّد من خارج التطبيق' : 'تعديل المزوّد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم *')),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'الرقم'),
                ),
                TextField(
                  controller: label,
                  decoration: const InputDecoration(labelText: 'الخدمة (تصوير، ديكور…)'),
                ),
                TextField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'المبلغ المتفق (\$)'),
                ),
                TextField(
                  controller: paid,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'المدفوع (\$)'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'الحالة'),
                  items: [
                    for (final e in _extStatus.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) => setLocal(() => status = v ?? status),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
          ],
        ),
      ),
    );

    final body = <String, dynamic>{
      'name': name.text.trim(),
      'phone': phone.text.trim(),
      'service_label': label.text.trim(),
      'amount_usd': num.tryParse(amount.text.trim()) ?? 0,
      'paid_usd': num.tryParse(paid.text.trim()) ?? 0,
      'status': status,
    };
    for (final c in [name, phone, label, amount, paid]) {
      c.dispose();
    }
    if (ok != true) return;

    try {
      if (existing == null) {
        await ApiService.addExternalProvider(widget.requestId, body);
      } else {
        await ApiService.updateExternalProvider(
            widget.requestId, existing['id'].toString(), body);
      }
      _load();
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _deleteExternal(Map<String, dynamic> e) async {
    try {
      await ApiService.deleteExternalProvider(widget.requestId, e['id'].toString());
      _load();
    } on ApiException catch (err) {
      _toast(err.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final providers = _list(_data['providers']);
    final external = _list(_data['external']);
    final totals = _data['totals'] is Map
        ? Map<String, dynamic>.from(_data['totals'] as Map)
        : const <String, dynamic>{};
    final revealed = _data['contacts_revealed'] == true;

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(title: const Text('مزوّدو الطلب')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editExternal(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('مزوّد خارجي'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, 96),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(Space.lg),
                        decoration: BoxDecoration(
                          color: AppPalette.surface,
                          borderRadius: BorderRadius.circular(Radii.md),
                          border: Border.all(color: AppPalette.goldLighter),
                        ),
                        child: Column(
                          children: [
                            _total('إجمالي الاتفاقات', workMoney(totals['grand_total'] ?? 0)),
                            _total('المدفوع', workMoney(totals['paid'] ?? 0)),
                            _total('المتبقي', workMoney(totals['remaining'] ?? 0), bold: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: Space.xl),
                      Text('مزوّدو التطبيق', style: AppText.section),
                      if (!revealed)
                        Text('تظهر أرقامهم بعد تحقق عربون الطلب.', style: AppText.caption),
                      const SizedBox(height: Space.sm),
                      if (providers.isEmpty)
                        Text('لا بنود بعد في عرض هذا الطلب.', style: AppText.bodySecondary),
                      for (final p in providers)
                        Card(
                          child: ListTile(
                            title: Text(p['title']?.toString() ?? ''),
                            subtitle: Text(
                              '${p['provider_name'] ?? (p['source'] == 'owned' ? 'خدمتك' : 'مزوّد')}'
                              ' • ${_avail[p['availability']] ?? p['availability']}'
                              ' • ${workMoney(p['amount'])}',
                            ),
                            trailing: (p['phone'] ?? p['whatsapp']) == null
                                ? null
                                : IconButton(
                                    tooltip: 'نسخ الرقم',
                                    icon: const Icon(Icons.copy, size: 18),
                                    onPressed: () async {
                                      await Clipboard.setData(ClipboardData(
                                          text: '${p['whatsapp'] ?? p['phone']}'));
                                      _toast('تم نسخ الرقم');
                                    },
                                  ),
                          ),
                        ),
                      const SizedBox(height: Space.xl),
                      Text('مزوّدون من خارج التطبيق', style: AppText.section),
                      const SizedBox(height: Space.sm),
                      if (external.isEmpty)
                        Text('أضف مزوّداً تتعامل معه خارج التطبيق لتتابع كل شيء هنا.',
                            style: AppText.bodySecondary),
                      for (final e in external)
                        Card(
                          child: ListTile(
                            onTap: () => _editExternal(e),
                            title: Text(
                              '${e['name']}${(e['service_label'] ?? '').toString().isEmpty ? '' : ' — ${e['service_label']}'}',
                            ),
                            subtitle: Text(
                              '${_extStatus[e['status']] ?? e['status']}'
                              ' • ${workMoney(e['paid_usd'])} من ${workMoney(e['amount_usd'])}'
                              '${(e['phone'] ?? '').toString().isEmpty ? '' : ' • ${e['phone']}'}',
                            ),
                            trailing: IconButton(
                              tooltip: 'حذف',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteExternal(e),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _total(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.bodySecondary)),
          Text(value,
              style: AppText.body.copyWith(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              )),
        ],
      ),
    );
  }
}
