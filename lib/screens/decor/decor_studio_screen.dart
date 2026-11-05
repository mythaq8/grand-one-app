// lib/screens/decor/decor_studio_screen.dart
// ============================================================
// «استوديو الديكور»: يضع المستخدم الديكور في مكان حفله الحقيقي (قاعة أو
// مطعم أو مزرعة اختارها، أو صورة يرفعها)، أو في مشهد مرسوم يختار خلفيته.
// يركّب قطع المزوّدين الحقيقية بصورها، ويكمل الباقي بالرسم، ويُرسل وصف
// التصميم مع طلب التنظيم ليراه المنظّم.
// ============================================================

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../services/api_service.dart';
import '../../ui/kit/kit.dart';
import 'decor_models.dart';
import 'decor_painter.dart';

export 'decor_models.dart';

/// نتيجة الاستوديو: وصف التصميم والخدمات المختارة لإضافتها لطلب التنظيم
class DecorStudioResult {
  DecorStudioResult(this.description, this.services);
  final String description;
  final List<Map<String, dynamic>> services;
}

class DecorStudioScreen extends StatefulWidget {
  const DecorStudioScreen({
    super.key,
    required this.categoryId,
    this.chosenServices = const [],
  });

  final String categoryId;

  /// خدمات اختارها المستخدم في طلبه؛ منها تُقترح قاعته تلقائياً
  final List<Map<String, dynamic>> chosenServices;

  @override
  State<DecorStudioScreen> createState() => _DecorStudioScreenState();
}

String _pieceUrl(String path) => Supabase.instance.client.storage.from('decor-pieces').getPublicUrl(path);

String? _serviceImageUrl(Map<String, dynamic> service) {
  String? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final signed = raw['signed_url']?.toString().trim() ?? '';
    if (signed.startsWith('http')) return signed;
    final url = raw['image_url']?.toString().trim() ?? '';
    return url.startsWith('http') ? url : null;
  }

  final cover = fromMap(service['cover_image']);
  if (cover != null) return cover;
  final images = service['images'];
  if (images is List) {
    for (final img in images) {
      final url = fromMap(img);
      if (url != null) return url;
    }
  }
  return null;
}

/// مكان الحفل: صورة خدمة (قاعة/مطعم/مزرعة) أو صورة رفعها المستخدم
class _Venue {
  const _Venue({required this.name, this.url, this.bytes, this.inOrder = false});
  final String name;
  final String? url;
  final Uint8List? bytes;
  final bool inOrder;
  bool get uploaded => bytes != null;
}

class _DecorStudioScreenState extends State<DecorStudioScreen> {
  final DecorDesign _d = DecorDesign();
  List<Map<String, dynamic>> _services = [];
  bool _loading = true;
  final Set<String> _picked = {};

  /// القطعة الحقيقية المختارة لكل نوع (نوع ← خدمة)
  final Map<String, Map<String, dynamic>> _real = {};

  List<_Venue> _venues = [];
  _Venue? _uploaded;
  _Venue? _venue;

  static const _venueCategoryNames = ['القاعات', 'المطاعم', 'المزارع'];

  static final _elements = <(String, RegExp)>[
    ('الكوشة والأرائك', RegExp('كوش|قوس|منصة|أريك')),
    ('الطاولات والمفارش', RegExp('طاول|مفرش|مفارش')),
    ('الكراسي', RegExp('كرسي|كراسي')),
    ('الورد', RegExp('ورد|زهور|زهر')),
    ('الإضاءة والشموع', RegExp('إضاء|اضاء|ليد|إنارة|ثري|شموع|فوانيس')),
    ('الأقمشة والخلفيات', RegExp('قماش|أقمشة|ستائر|ستار|خلفي')),
    ('الممرات والمداخل', RegExp('ممر|سجاد|مدخل|بوابة|بوابات')),
    ('البالونات والنباتات', RegExp('بالون|نبات|أشجار|شجر')),
    ('ركن التصوير والضيافة', RegExp('تصوير|لوح|ترحيب|كيك|ضيافة')),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([_loadServices(), _loadVenues()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadServices() async {
    try {
      final resp = await ApiService.getServices(categoryId: widget.categoryId, forOccasion: true, limit: 60, offset: 0);
      final raw = resp['data'];
      _services = raw is List ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
    } catch (_) {}
  }

  /// أماكن الحفل التي لها صور: ما اختاره المستخدم أولاً ثم بقية القاعات والمطاعم والمزارع
  Future<void> _loadVenues() async {
    try {
      final cats = await ApiService.getServiceCategories();
      final ids = cats
          .where((c) => _venueCategoryNames.contains(c['name']?.toString()))
          .map((c) => c['id'].toString())
          .toSet();
      final out = <String, _Venue>{};
      for (final s in widget.chosenServices) {
        final url = _serviceImageUrl(s);
        if (url != null && ids.contains(s['category_id']?.toString())) {
          out[s['id'].toString()] = _Venue(name: '${s['name']}', url: url, inOrder: true);
        }
      }
      final lists = await Future.wait(
        ids.map((id) => ApiService.getServices(categoryId: id, forOccasion: true, limit: 30, offset: 0)),
      );
      for (final resp in lists) {
        final raw = resp['data'];
        if (raw is! List) continue;
        for (final s in raw.whereType<Map>()) {
          final m = Map<String, dynamic>.from(s);
          final url = _serviceImageUrl(m);
          final id = m['id'].toString();
          if (url != null && !out.containsKey(id)) out[id] = _Venue(name: '${m['name']}', url: url);
        }
      }
      _venues = out.values.toList();
      // قاعة الطلب تُعرض مباشرة
      final inOrder = _venues.where((v) => v.inOrder).firstOrNull;
      if (inOrder != null && _venue == null && mounted) _selectVenue(inOrder);
    } catch (_) {}
  }

  void _selectVenue(_Venue? v) {
    setState(() {
      final wasNull = _venue == null;
      _venue = v;
      // صورة المكان فيها إضاءتها: لا نضيف ثريات مرسومة فوقها تلقائياً
      if (v != null && wasNull) _d.fixture = 'none';
      if (v == null) {
        _d.horizon = 0.55;
        if (_d.fixture == 'none') _d.fixture = 'chandelier';
      }
    });
  }

  Future<void> _uploadVenue() async {
    try {
      final files = await fp.FilePicker.pickFiles(type: fp.FileType.image);
      if (files.isEmpty) return;
      final bytes = await files.first.xFile.readAsBytes();
      if (bytes.isEmpty) return;
      if (bytes.length > 15 * 1024 * 1024) {
        if (mounted) showAppSnack(context, 'حجم الصورة أكبر من 15 ميغابايت', tone: FeedbackTone.error);
        return;
      }
      final v = _Venue(name: 'صورة مكاني', bytes: bytes);
      _uploaded = v;
      _selectVenue(v);
    } catch (_) {
      if (mounted) showAppSnack(context, 'تعذّرت قراءة الصورة', tone: FeedbackTone.error);
    }
  }

  bool _hasPiece(Map<String, dynamic> s) =>
      kRealPieces.containsKey(s['preview_piece']) && (s['preview_image_path']?.toString() ?? '').isNotEmpty;

  List<Map<String, dynamic>> _piecesOf(String type) =>
      _services.where((s) => _hasPiece(s) && s['preview_piece'] == type).toList();

  /// الخدمات بلا صورة قطعة تُعرض كخيارات نصية
  List<Map<String, dynamic>> _matches(RegExp re) => _services.where((s) => !_hasPiece(s) && re.hasMatch(_text(s))).toList();

  String _text(Map<String, dynamic> s) => '${s['name'] ?? ''} ${s['description'] ?? ''} ${s['subcategory_name'] ?? ''}';

  void _toggleReal(String type, Map<String, dynamic> s) {
    setState(() {
      final id = s['id'].toString();
      final prev = _real[type];
      if (prev != null) _picked.remove(prev['id'].toString());
      if (prev?['id'].toString() == id) {
        _real.remove(type);
      } else {
        _real[type] = s;
        _picked.add(id);
      }
    });
  }

  String _describe() {
    final lines = <String>[];
    final v = _venue;
    if (v != null) {
      lines.add(v.uploaded ? 'المكان: صورة رفعها العميل (للمعاينة عنده فقط، اطلبها منه عند الحاجة)' : 'المكان: ${v.name}');
    }
    if (_real.isNotEmpty) {
      lines.add('قطع مختارة من المزوّدين:');
      for (final e in kRealPieces.entries) {
        final s = _real[e.key];
        if (s != null) lines.add('• ${e.value}: ${s['name']}');
      }
    }
    for (final l in _d.describeLines(hasVenue: v != null)) {
      if (l.$1 == null || !_real.containsKey(l.$1)) lines.add(l.$2);
    }
    final extras = [
      for (final e in kExtras.entries)
        if (_d.extras.contains(e.key) && !_real.containsKey(e.key)) e.value.$1,
    ];
    if (extras.isNotEmpty) lines.add('عناصر إضافية: ${extras.join('، ')}');
    return lines.join('\n');
  }

  // ── أدوات الواجهة ─────────────────────────────────────

  Widget _swatches(List<DecorPalette> list, int selected, ValueChanged<int> onPick) {
    return Wrap(
      spacing: Space.sm,
      runSpacing: Space.sm,
      children: [
        for (var i = 0; i < list.length; i++)
          Tooltip(
            message: list[i].name,
            child: InkWell(
              onTap: () => onPick(i),
              customBorder: const CircleBorder(),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: list[i].color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: i == selected ? AppPalette.navy : AppPalette.borderStrong,
                    width: i == selected ? 3 : 1,
                  ),
                ),
                child: i == selected
                    ? Icon(Icons.check, size: 16, color: list[i].color.computeLuminance() > 0.5 ? AppPalette.navy : Colors.white)
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  Widget _choices<T>(Map<T, String> options, T selected, ValueChanged<T> onPick) {
    return Wrap(
      spacing: Space.sm,
      runSpacing: Space.sm,
      children: [
        for (final e in options.entries)
          ChoiceChip(label: Text(e.value), selected: selected == e.key, onSelected: (_) => onPick(e.key)),
      ],
    );
  }

  Widget _group(String title, Widget child) => Padding(
        padding: const EdgeInsets.only(top: Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.title),
            const SizedBox(height: Space.sm),
            child,
          ],
        ),
      );

  Widget _thumb({required Widget image, required String label, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: Radii.brMd,
      onTap: onTap,
      child: Container(
        width: 104,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppPalette.surface,
          borderRadius: Radii.brMd,
          border: Border.all(color: selected ? AppPalette.navy : AppPalette.borderStrong, width: selected ? 2.5 : 1),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: image),
                  if (selected)
                    const Align(
                      alignment: AlignmentDirectional.topEnd,
                      child: Icon(Icons.check_circle, color: AppPalette.navy, size: 20),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: AppText.caption),
          ],
        ),
      ),
    );
  }

  Widget _strip(List<Widget> children) => SizedBox(
        height: 128,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: children.length,
          separatorBuilder: (_, _) => const SizedBox(width: Space.sm),
          itemBuilder: (_, i) => children[i],
        ),
      );

  /// مكان الحفل: مشهد مرسوم، أو صورة مرفوعة، أو قاعة/مطعم/مزرعة
  Widget _venueSection() {
    final all = [if (_uploaded != null) _uploaded!, ..._venues];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'مكان الحفل',
          subtitle: 'اختر قاعتك أو ارفع صورة المكان ليصبح هو الخلفية والأرضية',
          icon: Icons.place_outlined,
        ),
        _strip([
          _thumb(
            image: const ColoredBox(color: AppPalette.background, child: Icon(Icons.add_a_photo_outlined, size: 34, color: AppPalette.navy)),
            label: 'رفع صورة المكان',
            selected: false,
            onTap: _uploadVenue,
          ),
          _thumb(
            image: const ColoredBox(color: AppPalette.background, child: Icon(Icons.brush_outlined, size: 34, color: AppPalette.navy)),
            label: 'مشهد مرسوم',
            selected: _venue == null,
            onTap: () => _selectVenue(null),
          ),
          for (final v in all)
            _thumb(
              image: v.bytes != null
                  ? Image.memory(v.bytes!, fit: BoxFit.cover)
                  : Image.network(v.url!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined)),
              label: v.inOrder ? '${v.name} (في طلبك)' : v.name,
              selected: identical(_venue, v),
              onTap: () => _selectVenue(v),
            ),
        ]),
        if (_venue != null) ...[
          const SizedBox(height: Space.sm),
          Text('طابق القطع مع صورتك: حرّك خط الأرضية إلى حيث يلتقي الجدار بالأرض، ثم اضبط الحجم.', style: AppText.caption),
          _slider('خط الأرضية', _d.horizon, 0.3, 0.85, (v) => setState(() => _d.horizon = v)),
        ],
      ],
    );
  }

  Widget _slider(String label, double value, double min, double max, ValueChanged<double> onChanged) => Row(
        children: [
          SizedBox(width: 88, child: Text(label, style: AppText.body)),
          Expanded(child: Slider(value: value, min: min, max: max, onChanged: onChanged)),
        ],
      );

  /// شريط بطاقات القطع الحقيقية لنوع واحد
  Widget _pieceStrip(String type, String title) {
    final items = _piecesOf(type);
    if (items.isEmpty) return const SizedBox.shrink();
    final sel = _real[type]?['id'].toString();
    return Padding(
      padding: const EdgeInsets.only(top: Space.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.subtitle),
          const SizedBox(height: Space.xs),
          _strip([
            for (final s in items)
              _thumb(
                image: Image.network(
                  _pieceUrl(s['preview_image_path'].toString()),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
                ),
                label: '${s['name']}',
                selected: s['id'].toString() == sel,
                onTap: () => _toggleReal(type, s),
              ),
          ]),
        ],
      ),
    );
  }

  // ── تركيب المشهد ─────────────────────────────────────

  Widget _img(Map<String, dynamic>? s, {BoxFit fit = BoxFit.contain, Alignment align = Alignment.bottomCenter}) {
    if (s == null) return const SizedBox.shrink();
    return Image.network(
      _pieceUrl(s['preview_image_path'].toString()),
      fit: fit,
      alignment: align,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }

  /// ظل تماس بيضاوي تحت القطعة ليبدو أنها تقف على الأرضية
  Widget _contactShadow(double cx, double y, double width) {
    final h = width * 0.26;
    return Positioned(
      left: cx - width / 2,
      top: y - h / 2,
      width: width,
      height: h,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(colors: [Color(0x66000000), Color(0x00000000)]),
        ),
      ),
    );
  }

  Widget _venueImage(_Venue v) => v.bytes != null
      ? Image.memory(v.bytes!, fit: BoxFit.cover, gaplessPlayback: true)
      : Image.network(v.url!, fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: (_, _, _) => const ColoredBox(color: Colors.black12));

  Widget _layer(String name, Set<String> realKeys) =>
      Positioned.fill(child: CustomPaint(painter: DecorPainter(_d, layer: name, real: realKeys)));

  Widget _scene() {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth, h = c.maxHeight;
      final realKeys = _real.keys.toSet();
      final k = _d.scale;
      final horizon = h * _d.horizon;
      final table = _real['table'], chair = _real['chair'], flowers = _real['flowers'], candles = _real['candles'];
      final slots = tableSlots(_d, w, h);
      Positioned at(double cx, double bottom, double width, double height, Widget child) =>
          Positioned(left: cx - width / 2, top: bottom - height, width: width, height: height, child: child);

      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // المكان: صورة حقيقية كاملة، أو خلفية وأرضية مرسومتان
          if (_venue != null)
            Positioned.fill(child: _venueImage(_venue!))
          else ...[
            _layer('bg', realKeys),
            if (_real['backdrop'] != null)
              Positioned(left: 0, top: 0, width: w, height: horizon + h * 0.01, child: _img(_real['backdrop'], fit: BoxFit.cover, align: Alignment.center)),
          ],
          _layer('ceiling', realKeys),
          if (_real['drapes'] != null)
            Positioned(left: 0, top: 0, width: w, height: h * 0.3, child: _img(_real['drapes'], fit: BoxFit.fill, align: Alignment.topCenter)),
          if (_real['light'] != null)
            for (final x in const [0.2, 0.5, 0.8])
              Positioned(left: w * x - w * 0.1 * k, top: 0, width: w * 0.2 * k, height: h * 0.22 * k, child: _img(_real['light'], align: Alignment.topCenter)),
          // عناصر خلفية بصورها الحقيقية أو مرسومة
          _layer('back', realKeys),
          if (_real['photo_booth'] != null) at(w * 0.1, horizon + h * 0.02, w * 0.18 * k, h * 0.42 * k, _img(_real['photo_booth'])),
          if (_real['cake'] != null) at(w * 0.9, horizon + h * 0.05, w * 0.16 * k, h * 0.34 * k, _img(_real['cake'])),
          if (_real['plants'] != null)
            for (final x in const [0.2, 0.8]) at(w * x, horizon + h * 0.015, w * 0.14 * k, h * 0.36 * k, _img(_real['plants'])),
          if (_real['balloons'] != null)
            for (final x in const [0.27, 0.73]) at(w * x, horizon + h * 0.02, w * 0.16 * k, h * 0.44 * k, _img(_real['balloons'])),
          _layer('aisle', realKeys),
          if (_real['aisle'] != null)
            Positioned(left: w * 0.38, top: horizon, width: w * 0.24, height: h - horizon, child: _img(_real['aisle'], fit: BoxFit.fill)),
          if (_real['kosha'] != null)
            at(w / 2, horizon + h * 0.05, w * 0.56 * k, h * 0.54 * k, _img(_real['kosha'])),
          _layer('kosha', realKeys),
          if (_real['sofa'] != null && _real['kosha'] == null)
            at(w / 2, horizon, w * 0.26 * k, h * 0.2 * k, _img(_real['sofa'])),
          // الأجزاء المرسومة من الطاولات، ثم الصور الحقيقية لكل طاولة بالعمق
          _layer('tables', realKeys),
          for (final (p, size) in slots) ...[
            if (chair != null)
              for (final dx in const [-0.24, 0.24]) ...[
                _contactShadow(p.dx + size * dx, p.dy + size * 0.03, size * 0.3),
                at(p.dx + size * dx, p.dy + size * 0.04, size * 0.3, size * 0.5, _img(chair)),
              ],
            if (table != null) ...[
              _contactShadow(p.dx, p.dy + size * 0.22, size * 0.85),
              at(p.dx, p.dy + size * 0.24, size * 0.85, size * 0.56, _img(table)),
            ],
            if (flowers != null) at(p.dx, p.dy + (table != null ? -size * 0.1 : size * 0.01), size * 0.34, size * 0.34, _img(flowers)),
            if (candles != null)
              for (final dx in const [-0.18, 0.18]) at(p.dx + size * dx, p.dy + size * 0.01, size * 0.13, size * 0.24, _img(candles)),
            if (chair != null)
              for (final dx in const [-0.44, 0.44]) ...[
                _contactShadow(p.dx + size * dx, p.dy + size * 0.27, size * 0.3),
                at(p.dx + size * dx, p.dy + size * 0.28, size * 0.3, size * 0.52, _img(chair)),
              ],
          ],
          _layer('front', realKeys),
          if (_real['entrance'] != null)
            for (final x in const [0.05, 0.95]) at(w * x, h * 0.99, w * 0.16 * k, h * 0.7 * k, _img(_real['entrance'])),
          if (_real['sign'] != null) at(w * 0.62, h * 0.985, w * 0.14 * k, h * 0.3 * k, _img(_real['sign'])),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasReal = kRealPieces.keys.any((k) => _piecesOf(k).isNotEmpty);
    final others = _services.where((s) => !_hasPiece(s) && _elements.every((e) => !e.$2.hasMatch(_text(s)))).toList();
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(title: const Text('استوديو الديكور')),
      body: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 820;
          final preview = AspectRatio(
            aspectRatio: 16 / 10,
            child: ClipRRect(
              borderRadius: Radii.brLg,
              child: _scene(),
            ),
          );
          final controls = ListView(
            padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, 120),
            children: [
              _venueSection(),
              _slider('حجم القطع', _d.scale, 0.6, 1.5, (v) => setState(() => _d.scale = v)),
              if (_loading) const LinearProgressIndicator(),
              if (hasReal) ...[
                const SectionHeader(title: 'قطع حقيقية من المزوّدين', subtitle: 'اضغط القطعة لتركيبها في المشهد', icon: Icons.photo_library_outlined),
                for (final e in kRealPieces.entries) _pieceStrip(e.key, e.value),
              ],
              const SectionHeader(title: 'صمّم بنفسك', subtitle: 'تصوّر تقريبي لما لم تختر له قطعة حقيقية', icon: Icons.palette_outlined),
              if (!_real.containsKey('kosha'))
                _group('شكل الكوشة', _choices(kKoshaStyles, _d.kosha, (v) => setState(() => _d.kosha = v))),
              _group('لون الورد', _swatches(kFlowerColors, _d.flower, (v) => setState(() => _d.flower = v))),
              _group('الطاولات', Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_real.containsKey('table')) _choices(kTableShapes, _d.table, (v) => setState(() => _d.table = v)),
                  Row(
                    children: [
                      Text('العدد: ${_d.tables}', style: AppText.body),
                      Expanded(
                        child: Slider(
                          value: _d.tables.toDouble(),
                          min: 2,
                          max: 12,
                          divisions: 10,
                          onChanged: (v) => setState(() => _d.tables = v.round()),
                        ),
                      ),
                    ],
                  ),
                ],
              )),
              if (!_real.containsKey('table'))
                _group('لون المفارش', _swatches(kClothColors, _d.cloth, (v) => setState(() => _d.cloth = v))),
              if (!_real.containsKey('chair'))
                _group('الكراسي', _choices({for (final e in kChairStyles.entries) e.key: e.value.$1}, _d.chair, (v) => setState(() => _d.chair = v))),
              if (!_real.containsKey('light')) _group('الثريات', _choices(kFixtures, _d.fixture, (v) => setState(() => _d.fixture = v))),
              _group('لون الإضاءة', _choices({for (final e in kLights.entries) e.key: e.value.$1}, _d.light, (v) => setState(() => _d.light = v))),
              _group('عناصر إضافية', Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  for (final e in kExtras.entries)
                    if (!_real.containsKey(e.key))
                      FilterChip(
                        avatar: Icon(e.value.$2, size: 18),
                        label: Text(e.value.$1),
                        selected: _d.extras.contains(e.key),
                        onSelected: (on) => setState(() => on ? _d.extras.add(e.key) : _d.extras.remove(e.key)),
                      ),
                ],
              )),
              if (_venue == null) ...[
                _group('الأرضية', _swatches(kFloors, _d.floor, (v) => setState(() => _d.floor = v))),
                if (!_real.containsKey('backdrop')) ...[
                  _group('الخلفية', _choices(kBackdropStyles, _d.backdrop, (v) => setState(() => _d.backdrop = v))),
                  _group('لون الخلفية', _swatches(kWallColors, _d.wall, (v) => setState(() => _d.wall = v))),
                ],
              ],
              const SectionHeader(title: 'خدمات تحقق تصميمك', subtitle: 'اختر ما تريد إضافته لطلبك', icon: Icons.storefront_outlined),
              if (_services.isEmpty)
                Text(
                  _loading ? 'جارٍ تحميل الخدمات...' : 'لا خدمات ديكور منشورة بعد؛ سيُرسَل تصميمك للمنظّم ليجهّزه.',
                  style: AppText.bodySecondary,
                )
              else ...[
                for (final el in _elements)
                  if (_matches(el.$2).isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: Space.sm, bottom: Space.xs),
                      child: Text(el.$1, style: AppText.subtitle),
                    ),
                    _serviceChips(_matches(el.$2)),
                  ],
                if (others.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: Space.sm, bottom: Space.xs),
                    child: Text('خدمات ديكور أخرى', style: AppText.subtitle),
                  ),
                  _serviceChips(others),
                ],
              ],
            ],
          );
          // على الشاشات الضيقة يبقى المشهد ثابتاً أعلى الشاشة ليظهر أثر كل اختيار فوراً
          if (!wide) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, Space.xs),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: c.maxHeight * 0.38),
                    child: Center(child: preview),
                  ),
                ),
                Expanded(child: controls),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: Padding(padding: const EdgeInsets.all(Space.lg), child: preview)),
              Expanded(flex: 4, child: controls),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: FilledButton.icon(
            onPressed: () => Navigator.pop(
              context,
              DecorStudioResult(
                _describe(),
                _services.where((s) => _picked.contains(s['id'].toString())).toList(),
              ),
            ),
            icon: const Icon(Icons.check_rounded),
            label: Text(_picked.isEmpty ? 'اعتماد التصميم' : 'اعتماد التصميم وإضافة ${_picked.length} خدمة'),
          ),
        ),
      ),
    );
  }

  Widget _serviceChips(List<Map<String, dynamic>> list) => Wrap(
        spacing: Space.sm,
        runSpacing: Space.sm,
        children: [
          for (final s in list)
            FilterChip(
              label: Text('${s['name']}'),
              selected: _picked.contains(s['id'].toString()),
              onSelected: (on) => setState(() => on ? _picked.add(s['id'].toString()) : _picked.remove(s['id'].toString())),
            ),
        ],
      );
}
