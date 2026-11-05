// lib/screens/work/service_editor_screen.dart
// ============================================================
// محرّر خدمة المزوّد — يتكيّف مع «ملف التسعير» للفئة والفئة الفرعية:
//   • نماذج التسعير المسموحة فقط (باقة/بالوحدة/بالمدة/عرض سعر)
//   • وحدة الكمية وحدودها ووحدة المدة تُملأ من الفئة
//   • الباقات والإضافات مع اقتراحات الفئة
//   • حقول الفئة الخاصة (يضيفها المشرف)
// ============================================================

import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

/// أنواع قطع الديكور التي يركّبها استوديو الديكور في مشهد القاعة.
const Map<String, (String, IconData)> kDecorPieces = {
  'kosha': ('كوشة', Icons.filter_vintage_outlined),
  'sofa': ('أريكة العروسين', Icons.weekend_outlined),
  'backdrop': ('خلفية', Icons.wallpaper_outlined),
  'table': ('طاولة', Icons.table_restaurant_outlined),
  'chair': ('كرسي', Icons.chair_outlined),
  'flowers': ('تنسيق ورد', Icons.local_florist_outlined),
  'candles': ('شموع وفوانيس', Icons.local_fire_department_outlined),
  'light': ('إضاءة / ثريا', Icons.light_outlined),
  'drapes': ('أقمشة سقف', Icons.waves_outlined),
  'aisle': ('ممر', Icons.linear_scale_rounded),
  'entrance': ('بوابة مدخل', Icons.door_sliding_outlined),
  'sign': ('لوحة ترحيب', Icons.signpost_outlined),
  'photo_booth': ('ركن تصوير', Icons.photo_camera_outlined),
  'cake': ('طاولة كيك', Icons.cake_outlined),
};

/// نوع القطعة المتوقع من اسم الفئة الفرعية (يُقترح تلقائياً ويمكن تغييره)
String? decorPieceForSubcategory(String name) {
  const map = <String, String>{
    'كوش': 'kosha',
    'أريك': 'sofa',
    'خلفي': 'backdrop',
    'ستائر': 'backdrop',
    'طاولات كيك': 'cake',
    'ضيافة': 'cake',
    'طاول': 'table',
    'مفارش': 'table',
    'كراسي': 'chair',
    'ورد': 'flowers',
    'شموع': 'candles',
    'فوانيس': 'candles',
    'ثريات': 'light',
    'إضاءة': 'light',
    'أقمشة سقف': 'drapes',
    'ممر': 'aisle',
    'سجاد': 'aisle',
    'بوابات': 'entrance',
    'مداخل': 'entrance',
    'لوحات': 'sign',
    'ركن': 'photo_booth',
  };
  for (final e in map.entries) {
    if (name.contains(e.key)) return e.value;
  }
  return null;
}

String decorPieceUrl(String path) =>
    Supabase.instance.client.storage.from('decor-pieces').getPublicUrl(path);

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

  String? _piece;
  String? _piecePath;
  bool _uploadingPiece = false;

  bool _loadingProfile = false;
  bool _saving = false;

  bool get _isDecor {
    final c = widget.categories.where((c) => c['id'] == _categoryId).firstOrNull;
    return (c?['name']?.toString() ?? '').contains('ديكور');
  }

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
    _piece = _e['preview_piece']?.toString();
    _piecePath = _e['preview_image_path']?.toString();
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
      if (_isDecor) ...{
        'preview_piece': _piece,
        'preview_image_path': _piecePath,
      },
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

  Future<void> _pickPiece() async {
    if (_uploadingPiece) return;
    try {
      final files = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: const ['png', 'webp'],
      );
      if (files.isEmpty) return;
      final f = files.first;
      final ext = f.name.split('.').last.toLowerCase();
      if (ext != 'png' && ext != 'webp') {
        if (mounted) showAppSnack(context, 'اختر صورة PNG أو WebP', tone: FeedbackTone.error);
        return;
      }
      final bytes = await f.xFile.readAsBytes();
      if (bytes.isEmpty) {
        if (mounted) showAppSnack(context, 'اختر صورة PNG أو WebP', tone: FeedbackTone.error);
        return;
      }
      if (bytes.length > 5 * 1024 * 1024) {
        if (mounted) showAppSnack(context, 'حجم الصورة أكبر من 5 ميغابايت', tone: FeedbackTone.error);
        return;
      }
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      setState(() => _uploadingPiece = true);
      // بلا ضغط: الضغط إلى JPG يُفقد الشفافية
      final path = '$uid/piece_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await Supabase.instance.client.storage.from('decor-pieces').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: ext == 'png' ? 'image/png' : 'image/webp', upsert: false),
          );
      setState(() => _piecePath = path);
    } catch (e) {
      if (mounted) showAppSnack(context, 'تعذّر رفع الصورة', tone: FeedbackTone.error);
    }
    if (mounted) setState(() => _uploadingPiece = false);
  }

  Widget _decorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'المعاينة في استوديو الديكور', icon: Icons.view_in_ar_outlined),
        Text(
          'ارفع صورة القطعة مفرّغة الخلفية (PNG شفاف) ليراها العميل مركّبة في مشهد القاعة كما هي في الواقع.',
          style: AppText.caption,
        ),
        const SizedBox(height: Space.sm),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final e in kDecorPieces.entries)
              ChoiceChip(
                avatar: Icon(e.value.$2, size: 18),
                label: Text(e.value.$1),
                selected: _piece == e.key,
                onSelected: (on) => setState(() => _piece = on ? e.key : null),
              ),
          ],
        ),
        const SizedBox(height: Space.sm),
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _CheckerPainter(),
                  child: _uploadingPiece
                      ? const Center(child: CircularProgressIndicator())
                      : _piecePath == null
                          ? const Center(child: Icon(Icons.image_outlined, size: 36, color: Colors.black38))
                          : Image.network(
                              decorPieceUrl(_piecePath!),
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image_outlined)),
                            ),
                ),
              ),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                    onPressed: _uploadingPiece ? null : _pickPiece,
                    icon: const Icon(Icons.upload_rounded),
                    label: Text(_piecePath == null ? 'رفع صورة القطعة' : 'تغيير الصورة'),
                  ),
                  if (_piecePath != null)
                    TextButton.icon(
                      onPressed: () => setState(() => _piecePath = null),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('إزالة الصورة'),
                    ),
                  const SizedBox(height: Space.xs),
                  Text('نصيحة: صوّر القطعة من الأمام وأزل الخلفية (remove.bg مثلاً).', style: AppText.caption),
                ],
              ),
            ),
          ],
        ),
        if (_piecePath != null && _piece == null)
          Padding(
            padding: const EdgeInsets.only(top: Space.xs),
            child: Text('حدّد نوع القطعة ليعرف الاستوديو أين يضعها', style: AppText.caption.copyWith(color: AppPalette.error)),
          ),
      ],
    );
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
          if (widget.categories.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: Text(
                'لم تُربط أي فئة بحسابك بعد. تواصل مع الإدارة لتحديد فئات عملك.',
                style: AppText.caption.copyWith(color: AppPalette.error),
              ),
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
                setState(() {
                  _subId = v;
                  if (_isDecor && _piece == null && v != null) {
                    final sub = _subs.where((x) => x['id'].toString() == v).firstOrNull;
                    _piece = decorPieceForSubcategory(sub?['name']?.toString() ?? '');
                  }
                });
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
            if (_isDecor) _decorSection(),
            if (_fields.isNotEmpty) ...[
              const SectionHeader(title: 'تفاصيل خاصة بالفئة', icon: Icons.tune_rounded),
              for (final f in _fields)
                Padding(padding: const EdgeInsets.only(bottom: Space.sm), child: _fieldInput(f)),
            ],
            if (_model == 'fixed_package')
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

/// خلفية مربّعات تُظهر شفافية صورة القطعة المفرّغة.
class _CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const s = 12.0;
    final a = Paint()..color = const Color(0xFFEDEDED);
    final b = Paint()..color = const Color(0xFFFFFFFF);
    for (var y = 0.0; y < size.height; y += s) {
      for (var x = 0.0; x < size.width; x += s) {
        final odd = ((x / s).floor() + (y / s).floor()).isOdd;
        canvas.drawRect(Rect.fromLTWH(x, y, s, s), odd ? a : b);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
