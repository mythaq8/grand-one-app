import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../services/api_exceptions.dart';
import '../../services/api_service.dart';
import '../../ui/kit/states.dart';

/// قائمة جاهزية حجز واحد: [kind] = external | booking | occasion.
class WorkChecklistScreen extends StatefulWidget {
  const WorkChecklistScreen({
    super.key,
    required this.kind,
    required this.refId,
    required this.title,
  });

  final String kind;
  final String refId;
  final String title;

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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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

  @override
  Widget build(BuildContext context) {
    final done = _items.where((i) => i['is_done'] == true).length;
    final total = _items.length;
    final percent = total == 0 ? 0.0 : done / total;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: AppPalette.background,
        appBar: AppBar(title: Text(widget.title)),
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
                            Text('الجاهزية: $done من $total',
                                style: AppText.subtitle),
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
