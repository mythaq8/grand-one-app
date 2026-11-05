// lib/screens/decor/decor_studio_screen.dart
// ============================================================
// «استوديو الديكور»: يختار المستخدم الكوشة والطاولات والكراسي والورد
// والإضاءة والأرضية بألوانها، فيرى مشهد القاعة كاملاً يتغيّر مباشرة.
// يعرض خدمات الديكور المطابقة لكل عنصر ليضيفها، ويُرسَل وصف التصميم
// مع طلب التنظيم ليراه المنظّم.
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../services/api_service.dart';
import '../../ui/kit/kit.dart';

class DecorPalette {
  const DecorPalette(this.name, this.color);
  final String name;
  final Color color;
}

const kFlowerColors = [
  DecorPalette('أبيض', Color(0xFFF8F5EF)),
  DecorPalette('زهري فاتح', Color(0xFFF3B6C6)),
  DecorPalette('أحمر', Color(0xFFC0263A)),
  DecorPalette('عنابي', Color(0xFF7A1E2E)),
  DecorPalette('بنفسجي', Color(0xFF8E6BB8)),
  DecorPalette('خوخي', Color(0xFFF4B48C)),
  DecorPalette('أصفر', Color(0xFFF2CF5B)),
  DecorPalette('أزرق سماوي', Color(0xFF8EC5E8)),
];
const kClothColors = [
  DecorPalette('أبيض', Color(0xFFFFFFFF)),
  DecorPalette('عاجي', Color(0xFFF4ECD8)),
  DecorPalette('ذهبي', Color(0xFFD7B56D)),
  DecorPalette('فضي', Color(0xFFC9CED6)),
  DecorPalette('زهري', Color(0xFFF2C9D4)),
  DecorPalette('كحلي', Color(0xFF1F2F57)),
  DecorPalette('أخضر زيتي', Color(0xFF6F7D4E)),
  DecorPalette('عنابي', Color(0xFF7A1E2E)),
];
const kChairStyles = {
  'gold': ('كرسي ذهبي (شيافاري)', Color(0xFFC9A35A)),
  'white': ('كرسي أبيض', Color(0xFFF4F4F4)),
  'clear': ('كرسي شفاف', Color(0x99D8E6F0)),
  'wood': ('كرسي خشبي', Color(0xFF8B5E3C)),
  'covered': ('كرسي بغطاء وفيونكة', Color(0xFFFFFFFF)),
};
const kKoshaStyles = {
  'arch': 'قوس ورد',
  'round': 'دائرة ذهبية',
  'panel': 'جدار ورد كامل',
  'drape': 'ستائر وأقمشة',
};
const kTableShapes = {'round': 'دائرية', 'long': 'طويلة (ملكية)'};
const kLights = {
  'warm': ('دافئة', Color(0xFFFFD58A)),
  'cool': ('بيضاء', Color(0xFFEAF4FF)),
  'pink': ('زهرية', Color(0xFFFFB3D1)),
  'purple': ('بنفسجية', Color(0xFFC6A8FF)),
};
const kFloors = [
  DecorPalette('رخام أبيض', Color(0xFFF1EEE9)),
  DecorPalette('سجاد أحمر', Color(0xFF9E2235)),
  DecorPalette('خشب', Color(0xFFA8794F)),
  DecorPalette('عشب صناعي', Color(0xFF6E9A4E)),
];

class DecorDesign {
  String kosha = 'arch';
  int flower = 2;
  int cloth = 0;
  String chair = 'gold';
  String table = 'round';
  String light = 'warm';
  int floor = 0;
  int tables = 6;

  String describe() => [
        'الكوشة: ${kKoshaStyles[kosha]} بورد ${kFlowerColors[flower].name}',
        'الطاولات: $tables ${kTableShapes[table]} بمفارش ${kClothColors[cloth].name}',
        'الكراسي: ${kChairStyles[chair]!.$1}',
        'الورد على الطاولات: ${kFlowerColors[flower].name}',
        'الإضاءة: ${kLights[light]!.$1}',
        'الأرضية: ${kFloors[floor].name}',
      ].join('\n');
}

/// نتيجة الاستوديو: وصف التصميم والخدمات المختارة لإضافتها لطلب التنظيم
class DecorStudioResult {
  DecorStudioResult(this.description, this.services);
  final String description;
  final List<Map<String, dynamic>> services;
}

class DecorStudioScreen extends StatefulWidget {
  const DecorStudioScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  State<DecorStudioScreen> createState() => _DecorStudioScreenState();
}

/// أنواع القطع الحقيقية بترتيب العرض (المفتاح = services.preview_piece)
const kRealPieces = <String, String>{
  'kosha': 'الكوشة',
  'backdrop': 'الخلفية',
  'table': 'الطاولات',
  'chair': 'الكراسي',
  'flowers': 'تنسيق الورد',
  'light': 'الإضاءة والثريات',
  'aisle': 'الممر',
};

String _pieceUrl(String path) => Supabase.instance.client.storage.from('decor-pieces').getPublicUrl(path);

/// مواضع الطاولات في المشهد (مركز الطاولة وحجمها) — مشتركة بين الرسم والصور
List<(Offset, double)> tableSlots(DecorDesign d, double w, double h) {
  final n = d.tables;
  final rows = n <= 6 ? 1 : 2;
  final perRow = (n / rows).ceil();
  final out = <(Offset, double)>[];
  for (var r = 0; r < rows; r++) {
    final y = h * (rows == 1 ? 0.8 : (r == 0 ? 0.7 : 0.9));
    final scale = rows == 1 ? 1.0 : (r == 0 ? 0.85 : 1.1);
    final count = math.min(perRow, n - out.length);
    for (var i = 0; i < count; i++) {
      // نترك ممراً في الوسط أمام الكوشة
      final slots = count + 1;
      final slot = i < count / 2 ? i : i + 1;
      final x = w * (slot + 0.5) / slots;
      out.add((Offset(x, y), w / (perRow + 2.2) * scale));
    }
  }
  return out;
}

class _DecorStudioScreenState extends State<DecorStudioScreen> {
  final DecorDesign _d = DecorDesign();
  List<Map<String, dynamic>> _services = [];
  final Set<String> _picked = {};

  /// القطعة الحقيقية المختارة لكل نوع (نوع ← خدمة)
  final Map<String, Map<String, dynamic>> _real = {};

  static final _elements = <(String, String, RegExp)>[
    ('kosha', 'الكوشة', RegExp('كوش|قوس|منصة')),
    ('tables', 'الطاولات والمفارش', RegExp('طاول|مفرش|مفارش')),
    ('chairs', 'الكراسي', RegExp('كرسي|كراسي')),
    ('flowers', 'الورد', RegExp('ورد|زهور|زهر')),
    ('light', 'الإضاءة', RegExp('إضاء|اضاء|ليد|إنارة')),
  ];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final resp = await ApiService.getServices(categoryId: widget.categoryId, forOccasion: true, limit: 60, offset: 0);
      final raw = resp['data'];
      _services = raw is List ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
      if (mounted) setState(() {});
    } catch (_) {}
  }

  bool _hasPiece(Map<String, dynamic> s) =>
      kRealPieces.containsKey(s['preview_piece']) && (s['preview_image_path']?.toString() ?? '').isNotEmpty;

  List<Map<String, dynamic>> _piecesOf(String type) =>
      _services.where((s) => _hasPiece(s) && s['preview_piece'] == type).toList();

  /// الخدمات بلا صورة قطعة تُعرض كخيارات نصية كما سابقاً
  List<Map<String, dynamic>> _matches(RegExp re) => _services.where((s) {
        if (_hasPiece(s)) return false;
        final text = '${s['name'] ?? ''} ${s['description'] ?? ''} ${s['subcategory_name'] ?? ''}';
        return re.hasMatch(text);
      }).toList();

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
    if (_real.isNotEmpty) {
      lines.add('قطع مختارة من المزوّدين:');
      for (final e in kRealPieces.entries) {
        final s = _real[e.key];
        if (s != null) lines.add('• ${e.value}: ${s['name']}');
      }
    }
    final painted = _d.describe().split('\n');
    // الأسطر المرسومة فقط للعناصر التي لم تُستبدل بقطعة حقيقية
    final skip = <String>{
      if (_real.containsKey('kosha')) 'الكوشة',
      if (_real.containsKey('chair')) 'الكراسي',
      if (_real.containsKey('flowers')) 'الورد على الطاولات',
      if (_real.containsKey('light')) 'الإضاءة',
    };
    lines.addAll(painted.where((l) => !skip.any((k) => l.startsWith('$k:'))));
    return lines.join('\n');
  }

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
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: Space.sm),
              itemBuilder: (_, i) {
                final s = items[i];
                final on = s['id'].toString() == sel;
                return InkWell(
                  borderRadius: Radii.brMd,
                  onTap: () => _toggleReal(type, s),
                  child: Container(
                    width: 104,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppPalette.surface,
                      borderRadius: Radii.brMd,
                      border: Border.all(color: on ? AppPalette.navy : AppPalette.borderStrong, width: on ? 2.5 : 1),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                _pieceUrl(s['preview_image_path'].toString()),
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
                              ),
                              if (on)
                                const Align(
                                  alignment: AlignmentDirectional.topEnd,
                                  child: Icon(Icons.check_circle, color: AppPalette.navy, size: 20),
                                ),
                            ],
                          ),
                        ),
                        Text('${s['name']}', maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: AppText.caption),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── تركيب المشهد ─────────────────────────────────────────

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

  Widget _scene() {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth, h = c.maxHeight;
      final realKeys = _real.keys.toSet();
      final table = _real['table'], chair = _real['chair'], flowers = _real['flowers'];
      final slots = tableSlots(_d, w, h);
      Positioned at(double cx, double bottom, double width, double height, Widget child) =>
          Positioned(left: cx - width / 2, top: bottom - height, width: width, height: height, child: child);

      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(child: CustomPaint(painter: _HallPainter(_d, layer: 'bg', real: realKeys))),
          if (_real['backdrop'] != null)
            Positioned(left: 0, top: 0, width: w, height: h * 0.56, child: _img(_real['backdrop'], fit: BoxFit.cover, align: Alignment.center)),
          if (_real['light'] != null)
            for (final x in const [0.2, 0.5, 0.8])
              Positioned(left: w * x - w * 0.1, top: 0, width: w * 0.2, height: h * 0.22, child: _img(_real['light'], align: Alignment.topCenter)),
          if (_real['aisle'] != null)
            Positioned(left: w * 0.4, top: h * 0.55, width: w * 0.2, height: h * 0.45, child: _img(_real['aisle'], fit: BoxFit.fill)),
          if (_real['kosha'] != null)
            at(w / 2, h * 0.56, w * 0.5, h * 0.48, _img(_real['kosha']))
          else
            Positioned.fill(child: CustomPaint(painter: _HallPainter(_d, layer: 'kosha', real: realKeys))),
          // الأجزاء المرسومة من الطاولات (ما لم يُستبدل بصور)
          Positioned.fill(child: CustomPaint(painter: _HallPainter(_d, layer: 'tables', real: realKeys))),
          // الصور الحقيقية لكل طاولة بالعمق: كراسٍ خلفية ← طاولة ← ورد ← كراسٍ جانبية
          for (final (p, size) in slots) ...[
            if (chair != null)
              for (final dx in const [-0.2, 0.2]) at(p.dx + size * dx, p.dy - size * 0.02, size * 0.26, size * 0.38, _img(chair)),
            if (table != null) at(p.dx, p.dy + size * 0.14, size * 0.78, size * 0.5, _img(table)),
            if (flowers != null) at(p.dx, p.dy - (table != null ? size * 0.12 : size * 0.02), size * 0.3, size * 0.34, _img(flowers)),
            if (chair != null)
              for (final dx in const [-0.44, 0.44]) at(p.dx + size * dx, p.dy + size * 0.2, size * 0.3, size * 0.44, _img(chair)),
          ],
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasReal = kRealPieces.keys.any((k) => _piecesOf(k).isNotEmpty);
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
              child: TweenAnimationBuilder<double>(
                key: ValueKey('${_d.describe()}|${_real.values.map((s) => s['id']).join(',')}'),
                tween: Tween(begin: 0.6, end: 1),
                duration: const Duration(milliseconds: 350),
                builder: (_, t, child) => Opacity(opacity: t, child: child),
                child: _scene(),
              ),
            ),
          );
          final controls = ListView(
            padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, 120),
            children: [
              if (!wide) ...[preview, const SizedBox(height: Space.sm)],
              Text(
                hasReal
                    ? 'اختر قطعاً حقيقية من المزوّدين لتظهر في القاعة بصورها، وأكمل الباقي بالألوان.'
                    : 'غيّر أي عنصر وشاهد القاعة تتغيّر مباشرة. المعاينة تقريبية لتصوّر الفكرة.',
                style: AppText.caption,
              ),
              if (hasReal) ...[
                const SectionHeader(title: 'قطع حقيقية من المزوّدين', subtitle: 'اضغط القطعة لتركيبها في المشهد', icon: Icons.photo_library_outlined),
                for (final e in kRealPieces.entries) _pieceStrip(e.key, e.value),
              ],
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
              _group('الإضاءة', _choices({for (final e in kLights.entries) e.key: e.value.$1}, _d.light, (v) => setState(() => _d.light = v))),
              _group('الأرضية', _swatches(kFloors, _d.floor, (v) => setState(() => _d.floor = v))),
              const SectionHeader(title: 'خدمات تحقق تصميمك', subtitle: 'اختر ما تريد إضافته لطلبك', icon: Icons.storefront_outlined),
              if (_services.isEmpty)
                Text('لا خدمات ديكور منشورة بعد؛ سيُرسَل تصميمك للمنظّم ليجهّزه.', style: AppText.bodySecondary)
              else ...[
                for (final el in _elements) ...[
                  if (_matches(el.$3).isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: Space.sm, bottom: Space.xs),
                      child: Text(el.$2, style: AppText.subtitle),
                    ),
                    Wrap(
                      spacing: Space.sm,
                      runSpacing: Space.sm,
                      children: [
                        for (final s in _matches(el.$3))
                          FilterChip(
                            label: Text('${s['name']}'),
                            selected: _picked.contains(s['id'].toString()),
                            onSelected: (on) => setState(() => on ? _picked.add(s['id'].toString()) : _picked.remove(s['id'].toString())),
                          ),
                      ],
                    ),
                  ],
                ],
                // خدمات لا تطابق أي عنصر ولا تملك صورة قطعة
                if (_services.where((s) => !_hasPiece(s) && _elements.every((e) => !e.$3.hasMatch('${s['name'] ?? ''} ${s['description'] ?? ''} ${s['subcategory_name'] ?? ''}'))).isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: Space.sm, bottom: Space.xs),
                    child: Text('خدمات ديكور أخرى', style: AppText.subtitle),
                  ),
                  Wrap(
                    spacing: Space.sm,
                    runSpacing: Space.sm,
                    children: [
                      for (final s in _services.where((s) => !_hasPiece(s) && _elements.every((e) => !e.$3.hasMatch('${s['name'] ?? ''} ${s['description'] ?? ''} ${s['subcategory_name'] ?? ''}'))))
                        FilterChip(
                          label: Text('${s['name']}'),
                          selected: _picked.contains(s['id'].toString()),
                          onSelected: (on) => setState(() => on ? _picked.add(s['id'].toString()) : _picked.remove(s['id'].toString())),
                        ),
                    ],
                  ),
                ],
              ],
            ],
          );
          if (!wide) return controls;
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
}

// ── رسم القاعة ───────────────────────────────────────────────

class _HallPainter extends CustomPainter {
  _HallPainter(this.d, {this.layer = 'all', this.real = const {}});
  final DecorDesign d;

  /// 'bg' الجدار والأرضية والإضاءة، 'kosha' الكوشة، 'tables' الطاولات، 'all' الكل
  final String layer;

  /// أنواع القطع المستبدلة بصور حقيقية (لا تُرسم)
  final Set<String> real;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final light = kLights[d.light]!.$2;
    final flower = kFlowerColors[d.flower].color;
    final cloth = kClothColors[d.cloth].color;
    final floor = kFloors[d.floor].color;
    if (layer == 'kosha') {
      _kosha(canvas, Offset(w / 2, h * 0.5), w, h, flower, light);
      return;
    }
    if (layer == 'tables') {
      _tables(canvas, w, h, cloth, flower);
      return;
    }

    // الجدار مع توهّج الإضاءة
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.55),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(const Color(0xFF2B2A33), light, 0.25)!, Color.lerp(const Color(0xFF4A4552), light, 0.45)!],
        ).createShader(Rect.fromLTWH(0, 0, w, h * 0.55)),
    );
    // الأرضية بمنظور
    final floorPath = Path()
      ..moveTo(0, h * 0.55)
      ..lineTo(w, h * 0.55)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      floorPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(floor, Colors.black, 0.25)!, floor],
        ).createShader(Rect.fromLTWH(0, h * 0.55, w, h * 0.45)),
    );
    // بقع الضوء
    final glow = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    for (var i = 0; i < (real.contains('light') ? 0 : 5); i++) {
      final x = w * (0.1 + i * 0.2);
      canvas.drawCircle(Offset(x, h * 0.08), 26, glow..color = light.withValues(alpha: 0.55));
      canvas.drawLine(Offset(x, 0), Offset(x, h * 0.06), Paint()..color = light..strokeWidth = 1.5);
      canvas.drawCircle(Offset(x, h * 0.07), 4, Paint()..color = light);
    }

    if (layer == 'bg') return;
    _kosha(canvas, Offset(w / 2, h * 0.5), w, h, flower, light);
    _tables(canvas, w, h, cloth, flower);
  }

  void _flowerCluster(Canvas c, Offset center, double r, Color color, {int count = 9, int seed = 1}) {
    final rnd = math.Random(seed);
    for (var i = 0; i < count; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final dist = rnd.nextDouble() * r;
      final p = center + Offset(math.cos(a) * dist, math.sin(a) * dist * 0.7);
      final rr = r * (0.28 + rnd.nextDouble() * 0.22);
      c.drawCircle(p, rr, Paint()..color = Color.lerp(color, Colors.white, rnd.nextDouble() * 0.25)!);
      c.drawCircle(p, rr * 0.45, Paint()..color = Color.lerp(color, Colors.black, 0.18)!);
    }
    // أوراق خضراء
    for (var i = 0; i < 4; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final p = center + Offset(math.cos(a) * r, math.sin(a) * r * 0.6);
      c.drawOval(Rect.fromCenter(center: p, width: r * 0.6, height: r * 0.28), Paint()..color = const Color(0xFF5E7F4A));
    }
  }

  void _kosha(Canvas c, Offset base, double w, double h, Color flower, Color light) {
    final kh = h * 0.44;
    final kw = math.min(w * 0.42, kh * 1.15);
    final top = base.dy - kh;
    // منصة
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(base.dx, base.dy + 6), width: kw * 1.15, height: 16), const Radius.circular(6)),
      Paint()..color = const Color(0xFFF2EBDD),
    );
    switch (d.kosha) {
      case 'round':
        c.drawCircle(Offset(base.dx, top + kh * 0.5), kh * 0.48, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..color = const Color(0xFFD7B56D));
        // عنقودان: أسفل اليمين وأعلى اليسار (كما في الكوش الدائرية المعتادة)
        for (var i = 0; i < 16; i++) {
          final a = i < 9 ? math.pi * (0.15 + i * 0.07) : math.pi * (1.1 + (i - 9) * 0.07);
          final p = Offset(base.dx + math.cos(a) * kh * 0.48, top + kh * 0.5 + math.sin(a) * kh * 0.48);
          _flowerCluster(c, p, 12, flower, count: 4, seed: i + 3);
        }
        break;
      case 'panel':
        c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(base.dx - kw / 2, top, kw, kh), const Radius.circular(10)),
          Paint()..color = Color.lerp(flower, Colors.white, 0.55)!,
        );
        for (var y = 0; y < 5; y++) {
          for (var x = 0; x < 7; x++) {
            _flowerCluster(c, Offset(base.dx - kw / 2 + kw * (x + 0.5) / 7, top + kh * (y + 0.5) / 5), 11, flower, count: 3, seed: x * 7 + y);
          }
        }
        break;
      case 'drape':
        for (var i = 0; i < 6; i++) {
          final x = base.dx - kw / 2 + kw * i / 5;
          final path = Path()
            ..moveTo(x, top)
            ..quadraticBezierTo(x + kw / 10, top + kh * 0.5, x, base.dy);
          c.drawPath(path, Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = kw / 7
            ..color = Color.lerp(const Color(0xFFF7F2EA), light, 0.2)!.withValues(alpha: 0.85));
        }
        _flowerCluster(c, Offset(base.dx - kw / 2, top + 10), 22, flower, count: 8, seed: 11);
        _flowerCluster(c, Offset(base.dx + kw / 2, top + 10), 22, flower, count: 8, seed: 12);
        break;
      default: // arch
        // نصف دائرة قمّتها عند أعلى الكوشة تماماً (لا تُقصّ)
        final r = kw / 2;
        final cy = math.max(top + r, top + kh * 0.45);
        final arch = Path()
          ..moveTo(base.dx - r, base.dy)
          ..lineTo(base.dx - r, cy)
          ..arcToPoint(Offset(base.dx + r, cy), radius: Radius.circular(r))
          ..lineTo(base.dx + r, base.dy);
        c.drawPath(arch, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = const Color(0xFFD7B56D));
        for (var i = 0; i <= 12; i++) {
          final t = i / 12;
          final a = math.pi + t * math.pi;
          final p = Offset(base.dx + math.cos(a) * r, cy + math.sin(a) * r);
          _flowerCluster(c, p, 14, flower, count: 5, seed: i + 20);
        }
        _flowerCluster(c, Offset(base.dx - kw / 2, base.dy - 14), 18, flower, count: 7, seed: 40);
        _flowerCluster(c, Offset(base.dx + kw / 2, base.dy - 14), 18, flower, count: 7, seed: 41);
    }
    // أريكة العروسين
    final sofa = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(base.dx, base.dy - 14), width: kw * 0.42, height: 30),
      const Radius.circular(10),
    );
    c.drawRRect(sofa, Paint()..color = const Color(0xFFF7F1E6));
    c.drawRRect(sofa, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFD7B56D));
  }

  void _chair(Canvas c, Offset p, double s) {
    final style = kChairStyles[d.chair]!;
    final color = style.$2;
    final seat = Paint()..color = color;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: s, height: s * 1.3), Radius.circular(s * 0.2)), seat);
    if (d.chair == 'gold' || d.chair == 'wood') {
      for (var i = 1; i < 4; i++) {
        c.drawLine(Offset(p.dx - s / 2 + s * i / 4, p.dy - s * 0.6), Offset(p.dx - s / 2 + s * i / 4, p.dy + s * 0.2),
            Paint()..color = Color.lerp(color, Colors.black, 0.3)!..strokeWidth = 1);
      }
    }
    if (d.chair == 'covered') {
      c.drawCircle(Offset(p.dx, p.dy + s * 0.15), s * 0.22, Paint()..color = kFlowerColors[d.flower].color);
    }
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: s, height: s * 1.3), Radius.circular(s * 0.2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black.withValues(alpha: 0.18),
    );
  }

  void _tables(Canvas c, double w, double h, Color cloth, Color flower) {
    final slots = tableSlots(d, w, h);
    for (var i = 0; i < slots.length; i++) {
      _table(c, slots[i].$1, slots[i].$2, cloth, flower, i);
    }
  }

  void _table(Canvas c, Offset p, double size, Color cloth, Color flower, int seed) {
    final chairS = size * 0.16;
    final drawChairs = !real.contains('chair');
    final drawTable = !real.contains('table');
    final drawFlowers = !real.contains('flowers');
    if (d.table == 'long' && drawTable) {
      final rect = Rect.fromCenter(center: p, width: size * 1.05, height: size * 0.32);
      if (drawChairs) {
        for (var i = 0; i < 4; i++) {
          _chair(c, Offset(rect.left + rect.width * (i + 0.5) / 4, rect.top - chairS * 0.5), chairS);
        }
      }
      c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), Paint()..color = cloth);
      c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.black.withValues(alpha: 0.12));
      if (drawFlowers) _flowerCluster(c, Offset(p.dx, p.dy - size * 0.05), size * 0.1, flower, count: 5, seed: seed + 60);
      return;
    }
    // دائرية مع كراسٍ حولها (أو كراسٍ مرسومة حول صورة طاولة حقيقية)
    if (drawChairs) {
      for (var i = 0; i < 6; i++) {
        final a = -math.pi + i * math.pi / 5;
        _chair(c, p + Offset(math.cos(a) * size * 0.42, math.sin(a) * size * 0.22 - chairS * 0.2), chairS);
      }
    }
    if (!drawTable) return; // صورة الطاولة والورد تُركَّب فوق الرسم
    c.drawOval(Rect.fromCenter(center: p + const Offset(0, 6), width: size * 0.7, height: size * 0.3), Paint()..color = Colors.black.withValues(alpha: 0.15));
    c.drawOval(Rect.fromCenter(center: p, width: size * 0.7, height: size * 0.3), Paint()..color = cloth);
    c.drawOval(Rect.fromCenter(center: p, width: size * 0.7, height: size * 0.3), Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black.withValues(alpha: 0.12));
    if (drawFlowers) _flowerCluster(c, Offset(p.dx, p.dy - size * 0.05), size * 0.09, flower, count: 5, seed: seed + 80);
  }

  @override
  bool shouldRepaint(covariant _HallPainter old) => true;
}
