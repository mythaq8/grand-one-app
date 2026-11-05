// lib/screens/work/service_editor_screen.dart
// ============================================================
// محرّر خدمة المزوّد — يتكيّف مع «ملف التسعير» للفئة والفئة الفرعية:
//   • نماذج التسعير المسموحة فقط (باقة/بالوحدة/بالمدة/عرض سعر)
//   • وحدة الكمية وحدودها ووحدة المدة تُملأ من الفئة
//   • الباقات والإضافات مع اقتراحات الفئة
//   • حقول الفئة الخاصة (يضيفها المشرف)
// ============================================================

import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../services/api_exceptions.dart';
import '../../services/api_service.dart';
import '../../ui/kit/kit.dart';

const Map<String, (String, String, IconData)> kPricingModels = {
  'fixed_package': ('باقة بسعر ثابت', 'سعر واحد للخدمة أو لكل باقة', Icons.inventory_2_outlined),
  'per_unit': ('بالوحدة', 'السعر × العدد (ضيف، قطعة، عنصر...)', Icons.groups_outlined),
  'per_duration': ('بالمدة', 'السعر × عدد الساعات أو الأيام', Icons.schedule_rounded),
  'quote_request': ('عرض سعر', 'يُحدَّد السعر بعد معرفة التفاصيل', Icons.request_quote_outlined),
};

const Map<String, String> kDurationUnits = {'hour': 'ساعة', 'day': 'يوم', 'night': 'ليلة'};

class _Row {
  _Row({String name = '', String price = '', this.mode = 'fixed', String description = ''})
      : name = TextEditingController(text: name),
        price = TextEditingController(text: price),
        description = TextEditingController(text: description);
  final TextEditingController name;
  final TextEditingController price;
  final TextEditingController description;
  String mode;
  void dispose() {
    name.dispose();
    price.dispose();
    description.dispose();
  }
}

class ServiceEditorScreen extends StatefulWidget {
  const ServiceEditorScreen({super.key, this.existing, required this.categories});

  final Map<String, dynamic>? existing;
  final List<Map<String, dynamic>> categories;

  @override
  State<ServiceEditorScreen> createState() => _ServiceEditorScreenState();
}

class _ServiceEditorScreenState extends State<ServiceEditorScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _unitLabel = TextEditingController();
  final _minQty = TextEditingController();
  final _maxQty = TextEditingController();
  final _capacity = TextEditingController();

  String? _categoryId;
  String? _subId;
  String _model = 'fixed_package';
  String _durationUnit = 'hour';
  bool _active = true;

  Map<String, dynamic> _profile = const {};
  List<Map<String, dynamic>> _subs = [];
  List<Map<String, dynamic>> _fields = [];
  final Map<String, dynamic> _fieldValues = {};
  final List<_Row> _packages = [];
  final List<_Row> _addons = [];

  bool _loadingProfile = false;
  bool _saving = false;

  Map<String, dynamic> get _e => widget.existing ?? const {};

  @override
  void initState() {
    super.initState();
    _name.text = _e['name']?.toString() ?? '';
    _desc.text = _e['description']?.toString() ?? '';
    _categoryId = _e['category_id']?.toString();
    _subId = _e['subcategory_id']?.toString();
    _model = _e['pricing_model']?.toString() ?? 'fixed_package';
    _durationUnit = _e['duration_unit']?.toString() ?? 'hour';
    _active = _e['is_active'] != false;
    _unitLabel.text = _e['unit_label']?.toString() ?? '';
    _minQty.text = _num(_e['min_qty']);
    _maxQty.text = _num(_e['max_qty']);
    _capacity.text = _num(_e['capacity']);
    _price.text = _num(_model == 'per_unit'
        ? (_e['unit_price'] ?? _e['base_price'])
        : _model == 'per_duration'
            ? (_e['duration_price'] ?? _e['base_price'])
            : _e['base_price']);
    if (_categoryId != null) _loadProfile(initial: true);
    if (_e['id'] != null) _loadExtras();
  }

  String _num(dynamic v) {
    if (v == null) return '';
    final n = v is num ? v : num.tryParse('$v');
    if (n == null) return '';
    return n == n.roundToDouble() ? n.toInt().toString() : n.toString();
  }

  @override
  void dispose() {
    for (final c in [_name, _desc, _price, _unitLabel, _minQty, _maxQty, _capacity]) {
      c.dispose();
    }
    for (final r in [..._packages, ..._addons]) {
      r.dispose();
    }
    super.dispose();
  }

  List<String> get _allowedModels {
    final m = _profile['pricing_models'];
    return m is List && m.isNotEmpty ? m.map((e) => e.toString()).toList() : kPricingModels.keys.toList();
  }

  Future<void> _loadProfile({bool initial = false}) async {
    if (_categoryId == null) return;
    setState(() => _loadingProfile = true);
    try {
      final res = await ApiService.getCategoryProfile(_categoryId!, subcategoryId: _subId);
      _profile = res['profile'] is Map ? Map<String, dynamic>.from(res['profile']) : {};
      _subs = (res['subcategories'] is List ? res['subcategories'] as List : const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _fields = (res['fields'] is List ? res['fields'] as List : const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (_subId != null && !_subs.any((s) => s['id'] == _subId)) _subId = null;
      // عند تغيير الفئة (لا عند فتح خدمة قائمة) نأخذ قيم الفئة الافتراضية
      if (!initial || widget.existing == null) {
        if (!_allowedModels.contains(_model)) {
          _model = _profile['default_pricing_model']?.toString() ?? _allowedModels.first;
        }
        if (_unitLabel.text.isEmpty) _unitLabel.text = _profile['unit_label']?.toString() ?? '';
        if (_minQty.text.isEmpty) _minQty.text = _num(_profile['min_qty']);
        if (_maxQty.text.isEmpty) _maxQty.text = _num(_profile['max_qty']);
        if (_profile['duration_unit'] != null) _durationUnit = _profile['duration_unit'].toString();
      }
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, tone: FeedbackTone.error);
    } catch (_) {}
    if (mounted) setState(() => _loadingProfile = false);
  }

  Future<void> _loadExtras() async {
    try {
      final res = await ApiService.getServiceExtras(_e['id'].toString());
      for (final p in (res['packages'] as List? ?? const []).whereType<Map>()) {
        _packages.add(_Row(name: '${p['name'] ?? ''}', price: _num(p['price']), description: '${p['description'] ?? ''}'));
      }
      for (final a in (res['addons'] as List? ?? const []).whereType<Map>()) {
        _addons.add(_Row(name: '${a['name'] ?? ''}', price: _num(a['price']), mode: '${a['pricing_mode'] ?? 'fixed'}'));
      }
      for (final v in (res['field_values'] as List? ?? const []).whereType<Map>()) {
        _fieldValues[v['field_id'].toString()] =
            v['value_text'] ?? v['value_number'] ?? v['value_boolean'] ?? v['value_date'] ?? v['value_json'];
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  List<Map<String, dynamic>> _suggest(String key) =>
      (_profile[key] is List ? _profile[key] as List : const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _categoryId == null) {
      showAppSnack(context, 'الاسم والتصنيف مطلوبان', tone: FeedbackTone.error);
      return;
    }
    final price = num.tryParse(_price.text.trim());
    if (_model != 'quote_request' && (price == null || price < 0)) {
      showAppSnack(context, 'أدخل السعر', tone: FeedbackTone.error);
      return;
    }
    for (final f in _fields.where((f) => f['is_required'] == true)) {
      final v = _fieldValues[f['id'].toString()];
      if (v == null || v == '' || (v is List && v.isEmpty)) {
        showAppSnack(context, 'الحقل «${f['field_name']}» مطلوب', tone: FeedbackTone.error);
        return;
      }
    }
    setState(() => _saving = true);
    final fields = <String, dynamic>{
      'name': name,
      'description': _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      'category_id': _categoryId,
      'subcategory_id': _subId,
      'pricing_model': _model,
      'is_active': _active,
      'base_price': _model == 'fixed_package' ? price : (price ?? 0),
      if (_model == 'per_unit') ...{
        'unit_price': price,
        'unit_label': _unitLabel.text.trim().isEmpty ? null : _unitLabel.text.trim(),
        'min_qty': num.tryParse(_minQty.text.trim()),
        'max_qty': num.tryParse(_maxQty.text.trim()),
      },
      if (_model == 'per_duration') ...{
        'duration_price': price,
        'duration_unit': _durationUnit,
      },
      if (num.tryParse(_capacity.text.trim()) != null) 'capacity': num.tryParse(_capacity.text.trim())!.toInt(),
    };
    try {
      String id;
      if (widget.existing == null) {
        final res = await ApiService.createProviderService(fields);
        id = (res['id'] ?? res['service']?['id']).toString();
      } else {
        id = _e['id'].toString();
        await ApiService.updateProviderService(serviceId: id, fields: fields);
      }
      await ApiService.saveServiceExtras(id, {
        'packages': [
          for (final p in _packages)
            if (p.name.text.trim().isNotEmpty)
              {'name': p.name.text.trim(), 'price': num.tryParse(p.price.text.trim()) ?? 0, 'description': p.description.text.trim()},
        ],
        'addons': [
          for (final a in _addons)
            if (a.name.text.trim().isNotEmpty)
              {'name': a.name.text.trim(), 'price': num.tryParse(a.price.text.trim()) ?? 0, 'pricing_mode': a.mode},
        ],
        'fields': _fieldValues,
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, tone: FeedbackTone.error);
    }
    if (mounted) setState(() => _saving = false);
  }

  // ── أجزاء الواجهة ─────────────────────────────────────────

  Widget _priceSection() {
    final unit = _unitLabel.text.trim().isEmpty ? 'وحدة' : _unitLabel.text.trim();
    final label = switch (_model) {
      'per_unit' => 'السعر لكل $unit (\$) *',
      'per_duration' => 'السعر لكل ${kDurationUnits[_durationUnit]} (\$) *',
      'quote_request' => 'سعر يبدأ من (\$) — اختياري',
      _ => 'سعر الخدمة (\$) *',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _price,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label),
        ),
        if (_model == 'per_unit') ...[
          const SizedBox(height: Space.sm),
          TextField(
            controller: _unitLabel,
            decoration: const InputDecoration(labelText: 'الوحدة', hintText: 'ضيف، قطعة، طاولة، عنصر...'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.sm),
          Row(
            children: [
              Expanded(child: TextField(controller: _minQty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'أقل عدد'))),
              const SizedBox(width: Space.sm),
              Expanded(child: TextField(controller: _maxQty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'أكبر عدد'))),
            ],
          ),
        ],
        if (_model == 'per_duration') ...[
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.sm,
            children: [
              for (final e in kDurationUnits.entries)
                ChoiceChip(
                  label: Text('بال${e.value}'),
                  selected: _durationUnit == e.key,
                  onSelected: (_) => setState(() => _durationUnit = e.key),
                ),
            ],
          ),
        ],
        const SizedBox(height: Space.sm),
        TextField(
          controller: _capacity,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'السعة القصوى (اختياري)', hintText: 'أقصى عدد ضيوف تخدمه'),
        ),
      ],
    );
  }

  Widget _listEditor({
    required String title,
    required IconData icon,
    required List<_Row> rows,
    required List<Map<String, dynamic>> suggestions,
    required bool isAddon,
  }) {
    final have = rows.map((r) => r.name.text.trim()).toSet();
    final left = suggestions.where((s) => !have.contains(s['name'])).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: title, icon: icon),
        for (var i = 0; i < rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: AppCard(
              padding: const EdgeInsets.all(Space.sm),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(controller: rows[i].name, decoration: InputDecoration(labelText: isAddon ? 'الإضافة' : 'اسم الباقة')),
                      ),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: rows[i].price,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'السعر \$'),
                        ),
                      ),
                      IconButton(
                        tooltip: 'حذف',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() => rows.removeAt(i).dispose()),
                      ),
                    ],
                  ),
                  if (isAddon)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Wrap(
                        spacing: Space.xs,
                        children: [
                          ChoiceChip(label: const Text('مبلغ ثابت'), selected: rows[i].mode == 'fixed', onSelected: (_) => setState(() => rows[i].mode = 'fixed')),
                          ChoiceChip(label: const Text('لكل وحدة'), selected: rows[i].mode == 'per_unit', onSelected: (_) => setState(() => rows[i].mode = 'per_unit')),
                        ],
                      ),
                    )
                  else
                    TextField(controller: rows[i].description, decoration: const InputDecoration(labelText: 'ماذا تشمل الباقة')),
                ],
              ),
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => setState(() => rows.add(_Row())),
            icon: const Icon(Icons.add),
            label: Text(isAddon ? 'إضافة جديدة' : 'باقة جديدة'),
          ),
        ),
        if (left.isNotEmpty)
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              for (final s in left)
                ActionChip(
                  avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: Text(isAddon && s['price'] != null ? '${s['name']} (${s['price']}\$)' : '${s['name']}'),
                  onPressed: () => setState(() => rows.add(_Row(
                        name: s['name'].toString(),
                        price: _num(s['price']),
                        mode: s['pricing_mode']?.toString() ?? 'fixed',
                        description: s['description']?.toString() ?? '',
                      ))),
                ),
            ],
          ),
      ],
    );
  }

  Widget _fieldInput(Map<String, dynamic> f) {
    final id = f['id'].toString();
    final label = '${f['field_name']}${f['is_required'] == true ? ' *' : ''}';
    final type = f['field_type']?.toString() ?? 'text';
    final value = _fieldValues[id];
    final options = (f['options'] is List ? f['options'] as List : const []).whereType<Map>().toList();
    switch (type) {
      case 'boolean':
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          value: value == true,
          onChanged: (v) => setState(() => _fieldValues[id] = v),
        );
      case 'select':
        return DropdownButtonFormField<String>(
          initialValue: options.any((o) => o['option_value'] == value) ? value as String : null,
          decoration: InputDecoration(labelText: label),
          items: [
            for (final o in options)
              DropdownMenuItem(value: o['option_value'].toString(), child: Text(o['option_label']?.toString() ?? o['option_value'].toString())),
          ],
          onChanged: (v) => setState(() => _fieldValues[id] = v),
        );
      case 'multiselect':
        final selected = value is List ? value.map((e) => e.toString()).toSet() : <String>{};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.subtitle),
            Wrap(
              spacing: Space.xs,
              children: [
                for (final o in options)
                  FilterChip(
                    label: Text(o['option_label']?.toString() ?? o['option_value'].toString()),
                    selected: selected.contains(o['option_value'].toString()),
                    onSelected: (on) => setState(() {
                      final s = {...selected};
                      on ? s.add(o['option_value'].toString()) : s.remove(o['option_value'].toString());
                      _fieldValues[id] = s.toList();
                    }),
                  ),
              ],
            ),
          ],
        );
      default:
        final numeric = ['integer', 'decimal', 'price', 'duration'].contains(type);
        return TextFormField(
          initialValue: value?.toString() ?? '',
          keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          maxLines: type == 'textarea' ? 3 : 1,
          decoration: InputDecoration(labelText: label, hintText: type == 'date' ? 'YYYY-MM-DD' : null),
          onChanged: (v) => _fieldValues[id] = numeric ? num.tryParse(v) : v,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowed = _allowedModels;
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(title: Text(widget.existing == null ? 'خدمة جديدة' : 'تعديل الخدمة')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, 120),
        children: [
          TextField(controller: _name, maxLength: 120, decoration: const InputDecoration(labelText: 'اسم الخدمة *')),
          DropdownButtonFormField<String>(
            initialValue: widget.categories.any((c) => c['id'] == _categoryId) ? _categoryId : null,
            decoration: const InputDecoration(labelText: 'التصنيف *'),
            items: [
              for (final c in widget.categories)
                DropdownMenuItem(
                  value: c['id'].toString(),
                  child: Text('${c['name']}${c['requires_organizer'] == true ? ' (عبر منظّم)' : ''}'),
                ),
            ],
            onChanged: (v) {
              setState(() {
                _categoryId = v;
                _subId = null;
                _fieldValues.clear();
              });
              _loadProfile();
            },
          ),
          if (_subs.isNotEmpty) ...[
            const SizedBox(height: Space.sm),
            DropdownButtonFormField<String?>(
              initialValue: _subId,
              decoration: const InputDecoration(labelText: 'الفئة الفرعية'),
              items: [
                const DropdownMenuItem(value: null, child: Text('بدون')),
                for (final s in _subs) DropdownMenuItem(value: s['id'].toString(), child: Text(s['name'].toString())),
              ],
              onChanged: (v) {
                setState(() => _subId = v);
                _loadProfile();
              },
            ),
          ],
          const SizedBox(height: Space.sm),
          TextField(controller: _desc, maxLines: 3, decoration: const InputDecoration(labelText: 'الوصف')),
          if (_loadingProfile) const LinearProgressIndicator(),
          if (_categoryId != null) ...[
            const SectionHeader(title: 'طريقة التسعير', icon: Icons.sell_outlined),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                for (final m in allowed)
                  if (kPricingModels[m] case final info?)
                    ChoiceChip(
                      avatar: Icon(info.$3, size: 18),
                      label: Text(info.$1),
                      selected: _model == m,
                      onSelected: (_) => setState(() => _model = m),
                    ),
              ],
            ),
            if (kPricingModels[_model] case final info?)
              Padding(
                padding: const EdgeInsets.only(top: Space.xs, bottom: Space.sm),
                child: Text(info.$2, style: AppText.caption),
              ),
            _priceSection(),
            if (_fields.isNotEmpty) ...[
              const SectionHeader(title: 'تفاصيل خاصة بالفئة', icon: Icons.tune_rounded),
              for (final f in _fields)
                Padding(padding: const EdgeInsets.only(bottom: Space.sm), child: _fieldInput(f)),
            ],
            if (_model != 'quote_request')
              _listEditor(
                title: 'الباقات (اختياري)',
                icon: Icons.inventory_2_outlined,
                rows: _packages,
                suggestions: _suggest('package_suggestions'),
                isAddon: false,
              ),
            _listEditor(
              title: 'الإضافات (اختياري)',
              icon: Icons.add_box_outlined,
              rows: _addons,
              suggestions: _suggest('addon_suggestions'),
              isAddon: true,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('الخدمة نشطة'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
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
            label: const Text('حفظ الخدمة'),
          ),
        ),
      ),
    );
  }
}
