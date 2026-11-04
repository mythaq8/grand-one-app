import '../../ui/kit/kit.dart';
import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../services/api_exceptions.dart';
import '../../services/api_service.dart';
import '../../ui/kit/states.dart';
import '../work/work_formatters.dart';

enum PlanFieldType { text, multiline, date, time, money, choice }

class PlanField {
  const PlanField(
    this.name,
    this.label, {
    this.type = PlanFieldType.text,
    this.required = false,
    this.choices = const {},
  });

  final String name;
  final String label;
  final PlanFieldType type;
  final bool required;

  /// للنوع choice: القيمة ← التسمية
  final Map<String, String> choices;
}

/// وصف نوع بند تخطيط (مهام/جدول/ميزانية/إلهام) تُبنى منه الشاشة كلها.
class PlanKind {
  const PlanKind({
    required this.key,
    required this.emptyTitle,
    required this.emptyBody,
    required this.icon,
    required this.fields,
    required this.titleOf,
    this.subtitleOf,
    this.checkField,
  });

  final String key;
  final String emptyTitle;
  final String emptyBody;
  final IconData icon;
  final List<PlanField> fields;
  final String Function(Map<String, dynamic>) titleOf;
  final String? Function(Map<String, dynamic>)? subtitleOf;

  /// حقل منطقي يظهر كمربع اختيار (is_done للمهام، is_paid للميزانية)
  final String? checkField;
}

const Map<String, String> kBudgetCategories = {
  'venue': 'المكان',
  'photo': 'التصوير',
  'decor': 'الديكور',
  'rental': 'التأجير',
  'gifts': 'الهدايا',
  'other': 'أخرى',
};

String _fmtNum(dynamic v) {
  final n = v is num ? v : num.tryParse('$v');
  if (n == null) return '';
  return n == n.roundToDouble() ? '${n.toInt()}' : n.toStringAsFixed(2);
}

final PlanKind kTasksKind = PlanKind(
  key: 'tasks',
  emptyTitle: 'لا توجد مهام',
  emptyBody: 'أضف مهام التجهيز لفعاليتك وتابع ما أُنجز.',
  icon: Icons.checklist_rounded,
  checkField: 'is_done',
  fields: const [
    PlanField('title', 'المهمة', required: true),
    PlanField('due_date', 'تاريخ الاستحقاق', type: PlanFieldType.date),
    PlanField('notes', 'ملاحظات', type: PlanFieldType.multiline),
  ],
  titleOf: (i) => i['title']?.toString() ?? '',
  subtitleOf: (i) => i['due_date'] == null ? null : 'قبل ${workDate(i['due_date'].toString())}',
);

final PlanKind kTimelineKind = PlanKind(
  key: 'timeline',
  emptyTitle: 'الجدول الزمني فارغ',
  emptyBody: 'رتّب فقرات يوم الفعالية بالساعة.',
  icon: Icons.schedule_rounded,
  fields: const [
    PlanField('start_time', 'الوقت', type: PlanFieldType.time, required: true),
    PlanField('title', 'الفقرة', required: true),
    PlanField('notes', 'ملاحظات', type: PlanFieldType.multiline),
  ],
  titleOf: (i) => '${workTime(i['start_time']?.toString())}  ${i['title'] ?? ''}',
  subtitleOf: (i) => i['notes']?.toString(),
);

final PlanKind kBudgetKind = PlanKind(
  key: 'budget',
  emptyTitle: 'لا بنود في الميزانية',
  emptyBody: 'سجّل تقديراتك لتعرف أين تقف من ميزانيتك.',
  icon: Icons.payments_outlined,
  checkField: 'is_paid',
  fields: [
    const PlanField('label', 'البند', required: true),
    const PlanField('category', 'الفئة', type: PlanFieldType.choice, choices: kBudgetCategories),
    const PlanField('estimated_usd', 'التقدير (\$)', type: PlanFieldType.money, required: true),
    const PlanField('actual_usd', 'الفعلي (\$)', type: PlanFieldType.money),
  ],
  titleOf: (i) => i['label']?.toString() ?? '',
  subtitleOf: (i) {
    final cat = kBudgetCategories[i['category']] ?? '';
    final est = _fmtNum(i['estimated_usd']);
    final act = i['actual_usd'] == null ? '' : ' • فعلي ${_fmtNum(i['actual_usd'])} \$';
    return '$cat • تقدير $est \$$act';
  },
);

final PlanKind kInspirationKind = PlanKind(
  key: 'inspiration',
  emptyTitle: 'لوحة الإلهام فارغة',
  emptyBody: 'احفظ أفكاراً وروابط تعجبك للديكور والتصوير وغيره.',
  icon: Icons.lightbulb_outline_rounded,
  fields: const [
    PlanField('title', 'الفكرة', required: true),
    PlanField('link_url', 'رابط (https://)'),
    PlanField('note', 'ملاحظة', type: PlanFieldType.multiline),
  ],
  titleOf: (i) => i['title']?.toString() ?? '',
  subtitleOf: (i) {
    final parts = [i['note']?.toString(), i['link_url']?.toString()]
        .whereType<String>()
        .where((s) => s.isNotEmpty);
    return parts.isEmpty ? null : parts.join('\n');
  },
);

/// قائمة بنود تخطيط لفعالية، بإضافة وتعديل وحذف.
class EventPlanningTab extends StatefulWidget {
  const EventPlanningTab({super.key, required this.eventId, required this.kind});

  final String eventId;
  final PlanKind kind;

  @override
  State<EventPlanningTab> createState() => _EventPlanningTabState();
}

class _EventPlanningTabState extends State<EventPlanningTab> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic>? _summary;

  PlanKind get _k => widget.kind;

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
      final res = await ApiService.listEventItems(widget.eventId, _k.key);
      final data = res['data'];
      _items = data is List
          ? data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];
      final s = res['summary'];
      _summary = s is Map ? Map<String, dynamic>.from(s) : null;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'تعذر التحميل';
    }
    if (mounted) setState(() => _loading = false);
  }

  void _toast(String m) =>
      showAppSnack(context, m);

  Future<void> _toggle(Map<String, dynamic> item, bool value) async {
    final field = _k.checkField!;
    final previous = item[field] == true;
    setState(() => item[field] = value);
    try {
      await ApiService.updateEventItem(
          widget.eventId, _k.key, item['id'].toString(), {field: value});
      if (_k.key == 'budget') _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => item[field] = previous);
      _toast(e.message);
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    try {
      await ApiService.deleteEventItem(widget.eventId, _k.key, item['id'].toString());
      _load();
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _edit([Map<String, dynamic>? existing]) async {
    final controllers = {
      for (final f in _k.fields)
        f.name: TextEditingController(text: existing?[f.name]?.toString() ?? ''),
    };
    final choices = <String, String>{
      for (final f in _k.fields.where((f) => f.type == PlanFieldType.choice))
        f.name: existing?[f.name]?.toString() ?? f.choices.keys.first,
    };

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'إضافة' : 'تعديل'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final f in _k.fields) _fieldWidget(ctx, f, controllers[f.name]!, choices, setLocal),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () {
                final missing = _k.fields.any(
                  (f) => f.required && controllers[f.name]!.text.trim().isEmpty,
                );
                if (missing) {
                  showAppSnack(ctx, 'أكمل الحقول الإلزامية');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    final body = <String, dynamic>{};
    for (final f in _k.fields) {
      final raw = controllers[f.name]!.text.trim();
      switch (f.type) {
        case PlanFieldType.choice:
          body[f.name] = choices[f.name];
        case PlanFieldType.money:
          body[f.name] = raw.isEmpty ? null : num.tryParse(raw);
        case PlanFieldType.date:
        case PlanFieldType.time:
        case PlanFieldType.text:
        case PlanFieldType.multiline:
          body[f.name] = raw.isEmpty ? null : raw;
      }
    }
    for (final c in controllers.values) {
      c.dispose();
    }
    if (saved != true) return;

    try {
      if (existing == null) {
        await ApiService.createEventItem(widget.eventId, _k.key, body);
      } else {
        await ApiService.updateEventItem(
            widget.eventId, _k.key, existing['id'].toString(), body);
      }
      _load();
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Widget _fieldWidget(
    BuildContext ctx,
    PlanField f,
    TextEditingController c,
    Map<String, String> choices,
    void Function(void Function()) setLocal,
  ) {
    switch (f.type) {
      case PlanFieldType.choice:
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: DropdownButtonFormField<String>(
            initialValue: choices[f.name],
            decoration: InputDecoration(labelText: f.label),
            items: [
              for (final e in f.choices.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => setLocal(() => choices[f.name] = v ?? choices[f.name]!),
          ),
        );
      case PlanFieldType.date:
        return TextField(
          controller: c,
          readOnly: true,
          decoration: InputDecoration(
            labelText: f.label,
            suffixIcon: c.text.isEmpty
                ? const Icon(Icons.event)
                : IconButton(icon: const Icon(Icons.clear), onPressed: () => setLocal(c.clear)),
          ),
          onTap: () async {
            final now = DateTime.now();
            final d = await showDatePicker(
              context: ctx,
              initialDate: now,
              firstDate: DateTime(now.year - 1),
              lastDate: DateTime(now.year + 3),
            );
            if (d != null) setLocal(() => c.text = workIsoDate(d));
          },
        );
      case PlanFieldType.time:
        return TextField(
          controller: c,
          readOnly: true,
          decoration: InputDecoration(labelText: f.label, suffixIcon: const Icon(Icons.schedule)),
          onTap: () async {
            final t = await showTimePicker(
              context: ctx,
              initialTime: const TimeOfDay(hour: 18, minute: 0),
            );
            if (t != null) {
              setLocal(() => c.text =
                  '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
            }
          },
        );
      case PlanFieldType.money:
        return TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: f.label),
        );
      case PlanFieldType.multiline:
        return TextField(
          controller: c,
          maxLines: 3,
          maxLength: 1000,
          decoration: InputDecoration(labelText: f.label),
        );
      case PlanFieldType.text:
        return TextField(
          controller: c,
          maxLength: 500,
          decoration: InputDecoration(labelText: f.label + (f.required ? ' *' : '')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        tooltip: 'إضافة',
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, 96),
                    children: [
                      if (_summary != null) _budgetSummary(_summary!),
                      if (_items.isEmpty)
                        EmptyState(
                          title: _k.emptyTitle,
                          body: _k.emptyBody,
                          icon: _k.icon,
                          actionLabel: 'إضافة',
                          onAction: () => _edit(),
                        ),
                      for (final item in _items) _tile(item),
                    ],
                  ),
                ),
    );
  }

  Widget _tile(Map<String, dynamic> item) {
    final sub = _k.subtitleOf?.call(item);
    final done = _k.checkField != null && item[_k.checkField] == true;
    return Card(
      margin: const EdgeInsets.only(bottom: Space.sm),
      child: ListTile(
        leading: _k.checkField == null
            ? Icon(_k.icon)
            : Checkbox(value: done, onChanged: (v) => _toggle(item, v ?? false)),
        title: Text(
          _k.titleOf(item),
          style: done && _k.key == 'tasks'
              ? AppText.body.copyWith(decoration: TextDecoration.lineThrough)
              : AppText.body,
        ),
        subtitle: sub == null || sub.isEmpty ? null : Text(sub),
        onTap: () => _edit(item),
        trailing: IconButton(
          tooltip: 'حذف',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _delete(item),
        ),
      ),
    );
  }

  Widget _budgetSummary(Map<String, dynamic> s) {
    final over = s['over_budget'] == true;
    final budget = s['budget'];
    return Container(
      margin: const EdgeInsets.only(bottom: Space.md),
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: over ? Colors.red : AppPalette.goldLighter),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line('تقديرات المخطط', workMoney(s['estimated'] ?? 0)),
          _line('محجوز عبر التطبيق', workMoney(s['booked_in_app'] ?? 0)),
          _line('إجمالي الالتزامات', workMoney(s['committed'] ?? 0), bold: true),
          if (budget != null) ...[
            const Divider(height: Space.lg),
            _line('الميزانية', workMoney(budget)),
            _line(
              over ? 'تجاوز الميزانية' : 'المتبقي',
              workMoney((s['remaining'] as num?)?.abs() ?? 0),
              color: over ? Colors.red : null,
              bold: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _line(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.bodySecondary)),
          Text(value,
              style: AppText.body.copyWith(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                color: color,
              )),
        ],
      ),
    );
  }
}
