// lib/screens/work/work_types_screen.dart
// ============================================================
// «أنواع أعمالي»: يعرّف المزوّد أو المنظّم أنواع عمله، ولكل نوع خطوات
// بموعد اختياري قبل الحدث. تُطبَّق تلقائياً على كل عمل جديد:
//   المنظّم ← حسب نوع المناسبة، المزوّد ← حسب الخدمة، الخارجي ← حسب اختياره
//   وإلا النوع الافتراضي.
// ============================================================

import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../services/api_exceptions.dart';
import '../../services/api_service.dart';
import '../../ui/kit/kit.dart';
import '../event/event_form_screen.dart' show kEventTypeLabels;

String daysBeforeLabel(dynamic d) {
  if (d == null) return 'بلا موعد';
  final n = d is num ? d.toInt() : int.tryParse('$d');
  if (n == null) return 'بلا موعد';
  if (n == 0) return 'يوم الحدث';
  if (n == 1) return 'قبل يوم';
  if (n == 2) return 'قبل يومين';
  if (n <= 10) return 'قبل $n أيام';
  return 'قبل $n يوماً';
}

class WorkTypesScreen extends StatefulWidget {
  const WorkTypesScreen({super.key});

  @override
  State<WorkTypesScreen> createState() => _WorkTypesScreenState();
}

class _WorkTypesScreenState extends State<WorkTypesScreen> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      _data = await ApiService.getWorkTypes();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'تعذّر التحميل';
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> _list(String key) {
    final v = _data?[key];
    return v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
  }

  Map<String, dynamic> get _suggestions =>
      _data?['suggestions'] is Map ? Map<String, dynamic>.from(_data!['suggestions']) : {};

  Future<void> _openEditor({Map<String, dynamic>? existing, Map<String, dynamic>? preset}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WorkTypeEditorScreen(
          existing: existing,
          preset: preset,
          isOrganizer: _data?['role'] == 'organizer',
          services: _list('services'),
          suggestedSteps: (_suggestions['steps'] is List ? _suggestions['steps'] as List : const [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
        ),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _pickPreset() async {
    final presets = (_suggestions['presets'] is List ? _suggestions['presets'] as List : const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final chosen = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('ابدأ من اقتراح أو من الصفر', style: AppText.section),
              const SizedBox(height: Space.md),
              for (final p in presets)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: ActionTile(
                    icon: Icons.auto_awesome_rounded,
                    title: p['name']?.toString() ?? '',
                    subtitle: '${(p['steps'] as List?)?.length ?? 0} خطوات جاهزة',
                    onTap: () => Navigator.pop(ctx, p),
                  ),
                ),
              ActionTile(
                icon: Icons.add_rounded,
                title: 'نوع فارغ',
                subtitle: 'أضف خطواتك بنفسك',
                onTap: () => Navigator.pop(ctx, <String, dynamic>{}),
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen == null) return;
    await _openEditor(preset: chosen.isEmpty ? null : chosen);
  }

  @override
  Widget build(BuildContext context) {
    final types = _list('types');
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(title: const Text('أنواع أعمالي وخطواتها')),
      floatingActionButton: _data == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _pickPreset,
              icon: const Icon(Icons.add),
              label: const Text('نوع جديد'),
            ),
      body: _loading
          ? const Center(child: LoadingState())
          : _error != null && _data == null
              ? Center(child: ErrorState(message: _error!, onRetry: _load))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, 96),
                    children: [
                      AppCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline_rounded, color: AppPalette.goldDeep),
                            const SizedBox(width: Space.sm),
                            Expanded(
                              child: Text(
                                _data?['role'] == 'organizer'
                                    ? 'لكل نوع مناسبة خطواته. عند وصول طلب زفاف مثلاً تُضاف خطوات «زفاف» تلقائياً بمواعيدها قبل الحفل.'
                                    : 'لكل نوع من عملك خطواته. اربط النوع بخدمة لتُضاف خطواته تلقائياً لحجوزاتها، أو اختره عند إضافة حجز خارجي.',
                                style: AppText.bodySecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Space.md),
                      if (types.isEmpty)
                        EmptyState(
                          icon: Icons.account_tree_outlined,
                          title: 'لم تعرّف أنواع أعمالك بعد',
                          body: 'ابدأ من اقتراح جاهز وعدّله على طريقتك.',
                          actionLabel: 'نوع جديد',
                          onAction: _pickPreset,
                        )
                      else
                        for (final t in types)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Space.sm),
                            child: AppCard(
                              accent: t['is_default'] == true ? AppPalette.gold : null,
                              onTap: () => _openEditor(existing: t),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(t['name']?.toString() ?? '', style: AppText.title),
                                        const SizedBox(height: 2),
                                        Text(
                                          [
                                            '${(t['steps'] as List?)?.length ?? 0} خطوات',
                                            if (t['is_default'] == true) 'افتراضي',
                                            if (t['occasion_type'] != null)
                                              'لمناسبات: ${kEventTypeLabels[t['occasion_type']] ?? t['occasion_type']}',
                                            if (t['service_id'] != null)
                                              'لخدمة: ${_list('services').firstWhere((s) => s['id'] == t['service_id'], orElse: () => {'name': '—'})['name']}',
                                          ].join(' • '),
                                          style: AppText.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_left_rounded),
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

// ── محرّر النوع ─────────────────────────────────────────────

class WorkTypeEditorScreen extends StatefulWidget {
  const WorkTypeEditorScreen({
    super.key,
    this.existing,
    this.preset,
    required this.isOrganizer,
    required this.services,
    required this.suggestedSteps,
  });

  final Map<String, dynamic>? existing;
  final Map<String, dynamic>? preset;
  final bool isOrganizer;
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> suggestedSteps;

  @override
  State<WorkTypeEditorScreen> createState() => _WorkTypeEditorScreenState();
}

class _StepDraft {
  _StepDraft(String title, this.daysBefore) : title = TextEditingController(text: title);
  final TextEditingController title;
  int? daysBefore;
}

class _WorkTypeEditorScreenState extends State<WorkTypeEditorScreen> {
  late final TextEditingController _name;
  final List<_StepDraft> _steps = [];
  String? _occasionType;
  String? _serviceId;
  bool _isDefault = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final src = widget.existing ?? widget.preset ?? const {};
    _name = TextEditingController(text: src['name']?.toString() ?? '');
    _occasionType = src['occasion_type']?.toString();
    _serviceId = src['service_id']?.toString();
    _isDefault = src['is_default'] == true;
    final steps = src['steps'] is List ? src['steps'] as List : const [];
    for (final s in steps.whereType<Map>()) {
      _steps.add(_StepDraft(s['title']?.toString() ?? '', (s['days_before'] as num?)?.toInt()));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    for (final s in _steps) {
      s.title.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDays(_StepDraft st) async {
    const options = [null, 0, 1, 2, 3, 5, 7, 10, 14, 21, 30, 45, 60, 90];
    final v = await showModalBottomSheet<int?>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          alignment: WrapAlignment.center,
          children: [
            for (final o in options)
              ChoiceChip(
                label: Text(daysBeforeLabel(o)),
                selected: st.daysBefore == o,
                onSelected: (_) => Navigator.pop(ctx, o ?? -1),
              ),
            const SizedBox(width: double.infinity, height: Space.lg),
          ],
        ),
      ),
    );
    if (v == null) return;
    setState(() => st.daysBefore = v == -1 ? null : v);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showAppSnack(context, 'اكتب اسم النوع', tone: FeedbackTone.error);
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService.saveWorkType(
        id: widget.existing?['id']?.toString(),
        body: {
          'name': name,
          'is_default': _isDefault,
          if (widget.isOrganizer) 'occasion_type': _occasionType,
          if (!widget.isOrganizer) 'service_id': _serviceId,
          'steps': [
            for (final s in _steps)
              if (s.title.text.trim().isNotEmpty)
                {'title': s.title.text.trim(), 'days_before': s.daysBefore},
          ],
        },
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, tone: FeedbackTone.error);
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _delete() async {
    final ok = await confirmAction(
      context,
      title: 'حذف النوع',
      message: 'لن تتأثر قوائم الأعمال الموجودة.',
      confirmLabel: 'حذف',
      destructive: true,
    );
    if (!ok) return;
    try {
      await ApiService.deleteWorkType(widget.existing!['id'].toString());
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, tone: FeedbackTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final have = _steps.map((s) => s.title.text.trim()).toSet();
    final suggestions = widget.suggestedSteps.where((s) => !have.contains(s['title'])).toList();
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: Text(widget.existing == null ? 'نوع جديد' : 'تعديل النوع'),
        actions: [
          if (widget.existing != null)
            IconButton(tooltip: 'حذف', onPressed: _delete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, 120),
        children: [
          TextField(
            controller: _name,
            maxLength: 80,
            decoration: InputDecoration(
              labelText: 'اسم النوع *',
              hintText: widget.isOrganizer ? 'زفاف كامل' : 'تصوير عرس كامل',
            ),
          ),
          if (widget.isOrganizer)
            DropdownButtonFormField<String?>(
              initialValue: _occasionType,
              decoration: const InputDecoration(labelText: 'يُطبَّق تلقائياً على مناسبات'),
              items: [
                const DropdownMenuItem(value: null, child: Text('لا يُطبَّق تلقائياً')),
                for (final e in kEventTypeLabels.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _occasionType = v),
            )
          else if (widget.services.isNotEmpty)
            DropdownButtonFormField<String?>(
              initialValue: widget.services.any((s) => s['id'] == _serviceId) ? _serviceId : null,
              decoration: const InputDecoration(labelText: 'يُطبَّق تلقائياً على حجوزات خدمة'),
              items: [
                const DropdownMenuItem(value: null, child: Text('لا يُطبَّق تلقائياً')),
                for (final s in widget.services)
                  DropdownMenuItem(value: s['id']?.toString(), child: Text(s['name']?.toString() ?? '')),
              ],
              onChanged: (v) => setState(() => _serviceId = v),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('النوع الافتراضي'),
            subtitle: const Text('يُطبَّق على أي عمل لا يطابق نوعاً آخر'),
            value: _isDefault,
            onChanged: (v) => setState(() => _isDefault = v),
          ),
          SectionHeader(
            title: 'الخطوات',
            subtitle: 'اسحب لإعادة الترتيب، واضغط الموعد لتغييره',
            icon: Icons.checklist_rounded,
          ),
          if (_steps.isEmpty)
            Text('لا خطوات بعد — أضف من الاقتراحات أو اكتب خطوتك.', style: AppText.bodySecondary),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: (a, b) => setState(() {
              if (b > a) b -= 1;
              _steps.insert(b, _steps.removeAt(a));
            }),
            children: [
              for (var i = 0; i < _steps.length; i++)
                Padding(
                  key: ObjectKey(_steps[i]),
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: AppCard(
                    padding: const EdgeInsets.fromLTRB(Space.xs, Space.xs, Space.xs, Space.xs),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: i,
                          child: const Padding(
                            padding: EdgeInsets.all(Space.sm),
                            child: Icon(Icons.drag_indicator_rounded, color: AppPalette.textTertiary),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _steps[i].title,
                            decoration: const InputDecoration(
                              hintText: 'الخطوة',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                            ),
                          ),
                        ),
                        ActionChip(
                          label: Text(daysBeforeLabel(_steps[i].daysBefore)),
                          onPressed: () => _pickDays(_steps[i]),
                        ),
                        IconButton(
                          tooltip: 'حذف',
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => setState(() => _steps.removeAt(i).title.dispose()),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => setState(() => _steps.add(_StepDraft('', null))),
              icon: const Icon(Icons.add),
              label: const Text('خطوة جديدة'),
            ),
          ),
          if (suggestions.isNotEmpty) ...[
            const SectionHeader(title: 'اقتراحات', subtitle: 'اضغط لإضافتها', icon: Icons.auto_awesome_rounded),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                for (final s in suggestions)
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 16),
                    label: Text('${s['title']} (${daysBeforeLabel(s['days_before'])})'),
                    onPressed: () => setState(() =>
                        _steps.add(_StepDraft(s['title'].toString(), (s['days_before'] as num?)?.toInt()))),
                  ),
              ],
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('حفظ النوع'),
          ),
        ),
      ),
    );
  }
}
