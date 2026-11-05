import '../../ui/kit/kit.dart';
import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../services/api_exceptions.dart';
import '../../services/api_service.dart';
import 'work_formatters.dart';

/// قائمة جاهزية حجز واحد: [kind] = external | booking | occasion.
class WorkChecklistScreen extends StatefulWidget {
  const WorkChecklistScreen({
    super.key,
    required this.kind,
    required this.refId,
    required this.title,
    this.embedded = false,
  });

  final String kind;
  final String refId;
  final String title;

  /// داخل تبويب (مساحة عمل المناسبة): بلا شريط عنوان ولا اعتراض للرجوع
  final bool embedded;

  @override
  State<WorkChecklistScreen> createState() => _WorkChecklistScreenState();
}

class _WorkChecklistScreenState extends State<WorkChecklistScreen> {
  final TextEditingController _newItem = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _newItem.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _items = await ApiService.getWorkChecklist(widget.kind, widget.refId);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'تعذر تحميل القائمة';
    }
    if (mounted) setState(() => _loading = false);
  }

  void _toast(String message) {
    showAppSnack(context, message);
  }

  Future<void> _toggle(Map<String, dynamic> item, bool value) async {
    final previous = item['is_done'] == true;
    setState(() => item['is_done'] = value);
    try {
      await ApiService.updateWorkChecklistItem(
          item['id'].toString(), {'is_done': value});
      _changed = true;
    } on ApiException catch (e) {
      if (mounted) setState(() => item['is_done'] = previous);
      _toast(e.message);
    }
  }

  Future<void> _add() async {
    final title = _newItem.text.trim();
    if (title.isEmpty) return;
    try {
      final res = await ApiService.addWorkChecklistItem(
          widget.kind, widget.refId, title);
      final item = res['item'];
      if (item is Map) _items.add(Map<String, dynamic>.from(item));
      _newItem.clear();
      _changed = true;
      if (mounted) setState(() {});
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _remove(Map<String, dynamic> item) async {
    try {
      await ApiService.deleteWorkChecklistItem(item['id'].toString());
      _items.remove(item);
      _changed = true;
      if (mounted) setState(() {});
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  /// موعد الخطوة: «متأخرة» بالأحمر، «اليوم» بالذهبي، وإلا التاريخ
  Widget? _dueText(Map<String, dynamic> item, bool isDone) {
    final due = item['due_date']?.toString();
    if (due == null || due.length < 10) return null;
    final now = DateTime.now();
    final today = workIsoDate(DateTime(now.year, now.month, now.day));
    final overdue = !isDone && due.compareTo(today) < 0;
    final isToday = due == today;
    return Text(
      overdue
          ? 'متأخرة — كانت مستحقة ${workDate(due)}'
          : isToday
              ? 'مستحقة اليوم'
              : 'مستحقة ${workDate(due)}',
      style: AppText.caption.copyWith(
        color: overdue
            ? AppPalette.error
            : isToday
                ? AppPalette.goldDeep
                : AppPalette.textTertiary,
        fontWeight: overdue || isToday ? FontWeight.w700 : null,
      ),
    );
  }

  Future<void> _applyType() async {
    List<Map<String, dynamic>> types = [];
    try {
      final res = await ApiService.getWorkTypes();
      final list = res['types'] is List ? res['types'] as List : const [];
      types = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {}
    if (!mounted) return;
    if (types.isEmpty) {
      showAppSnack(context, 'لم تعرّف أنواع أعمالك بعد؛ أضفها من «الإدارة ← أنواع أعمالي».');
      return;
    }
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final t in types)
                ListTile(
                  leading: const Icon(Icons.account_tree_outlined),
                  title: Text(t['name']?.toString() ?? ''),
                  subtitle: Text('${(t['steps'] as List?)?.length ?? 0} خطوات'),
                  onTap: () => Navigator.pop(ctx, t['id']?.toString()),
                ),
            ],
          ),
        ),
      ),
    );
    if (chosen == null) return;
    try {
      final res = await ApiService.applyWorkType(kind: widget.kind, refId: widget.refId, workTypeId: chosen);
      _changed = true;
      await _load();
      if (mounted) {
        showAppSnack(context, 'أُضيفت ${res['added'] ?? 0} خطوة', tone: FeedbackTone.success);
      }
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, tone: FeedbackTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _items.where((i) => i['is_done'] == true).length;
    final total = _items.length;
    final percent = total == 0 ? 0.0 : done / total;

    return PopScope(
      canPop: widget.embedded,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !widget.embedded) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: AppPalette.background,
        appBar: widget.embedded ? null : AppBar(title: Text(widget.title)),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ErrorState(message: _error!, onRetry: _load)
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(Space.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text('الجاهزية: $done من $total',
                                      style: AppText.subtitle),
                                ),
                                TextButton.icon(
                                  onPressed: _applyType,
                                  icon: const Icon(Icons.account_tree_outlined, size: 18),
                                  label: const Text('إضافة خطوات نوع'),
                                ),
                              ],
                            ),
                            const SizedBox(height: Space.sm),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(Radii.pill),
                              child: LinearProgressIndicator(
                                value: percent,
                                minHeight: 8,
                                color: AppPalette.gold,
                                backgroundColor: AppPalette.goldSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _items.isEmpty
                            ? const EmptyState(
                                title: 'لا توجد مهام',
                                body: 'أضف أول مهمة للتجهيز لهذا الحجز.',
                                icon: Icons.checklist_outlined,
                              )
                            : ListView.builder(
                                itemCount: _items.length,
                                itemBuilder: (context, i) {
                                  final item = _items[i];
                                  final isDone = item['is_done'] == true;
                                  return CheckboxListTile(
                                    value: isDone,
                                    onChanged: (v) => _toggle(item, v ?? false),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    title: Text(
                                      item['title']?.toString() ?? '',
                                      style: AppText.body.copyWith(
                                        decoration: isDone
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    subtitle: _dueText(item, isDone),
                                    secondary: IconButton(
                                      tooltip: 'حذف',
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _remove(item),
                                    ),
                                  );
                                },
                              ),
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.all(Space.md),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _newItem,
                                  maxLength: 160,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _add(),
                                  decoration: const InputDecoration(
                                    hintText: 'مهمة جديدة',
                                    counterText: '',
                                  ),
                                ),
                              ),
                              const SizedBox(width: Space.sm),
                              IconButton.filled(
                                tooltip: 'إضافة',
                                // قالب الأزرار يجعل الأيقونة كحلية؛ هنا الخلفية كحلية
                                style: IconButton.styleFrom(
                                  backgroundColor: AppPalette.navy,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _add,
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
