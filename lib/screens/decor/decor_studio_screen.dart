// lib/screens/decor/decor_studio_screen.dart
// ============================================================
// «استوديو الديكور»: يختار المستخدم الكوشة والطاولات والكراسي والورد
// والإضاءة والأرضية بألوانها، فيرى مشهد القاعة كاملاً يتغيّر مباشرة.
// يعرض خدمات الديكور المطابقة لكل عنصر ليضيفها، ويُرسَل وصف التصميم
// مع طلب التنظيم ليراه المنظّم.
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

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

class _DecorStudioScreenState extends State<DecorStudioScreen> {
  final DecorDesign _d = DecorDesign();
  List<Map<String, dynamic>> _services = [];
  final Set<String> _picked = {};

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

  List<Map<String, dynamic>> _matches(RegExp re) => _services.where((s) {
        final text = '${s['name'] ?? ''} ${s['description'] ?? ''} ${s['subcategory_name'] ?? ''}';
        return re.hasMatch(text);
      }).toList();

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

  @override
  Widget build(BuildContext context) {
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
                key: ValueKey(_d.describe()),
                tween: Tween(begin: 0.6, end: 1),
                duration: const Duration(milliseconds: 350),
                builder: (_, t, _) => Opacity(
                  opacity: t,
                  child: CustomPaint(painter: _HallPainter(_d), child: const SizedBox.expand()),
                ),
              ),
            ),
          );
          final controls = ListView(
            padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, 120),
            children: [
              if (!wide) ...[preview, const SizedBox(height: Space.sm)],
              Text('غيّر أي عنصر وشاهد القاعة تتغيّر مباشرة. المعاينة تقريبية لتصوّر الفكرة.', style: AppText.caption),
              _group('شكل الكوشة', _choices(kKoshaStyles, _d.kosha, (v) => setState(() => _d.kosha = v))),
              _group('لون الورد', _swatches(kFlowerColors, _d.flower, (v) => setState(() => _d.flower = v))),
              _group('الطاولات', Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _choices(kTableShapes, _d.table, (v) => setState(() => _d.table = v)),
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
              _group('لون المفارش', _swatches(kClothColors, _d.cloth, (v) => setState(() => _d.cloth = v))),
              _group('الكراسي', _choices({for (final e in kChairStyles.entries) e.key: e.value.$1}, _d.chair, (v) => setState(() => _d.chair = v))),
              _group('الإضاءة', _choices({for (final e in kLights.entries) e.key: e.value.$1}, _d.light, (v) => setState(() => _d.light = v))),
              _group('الأرضية', _swatches(kFloors, _d.floor, (v) => setState(() => _d.floor = v))),
              const SectionHeader(title: 'خدمات تحقق تصميمك', subtitle: 'اختر ما تريد إضافته لطلبك', icon: Icons.storefront_outlined),
              if (_services.isEmpty)
                Text('لا خدمات ديكور منشورة بعد؛ سيُرسَل تصميمك للمنظّم ليجهّزه.', style: AppText.bodySecondary)
              else
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
              if (_services.isNotEmpty && _elements.every((e) => _matches(e.$3).isEmpty))
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: [
                    for (final s in _services)
                      FilterChip(
                        label: Text('${s['name']}'),
                        selected: _picked.contains(s['id'].toString()),
                        onSelected: (on) => setState(() => on ? _picked.add(s['id'].toString()) : _picked.remove(s['id'].toString())),
                      ),
                  ],
                ),
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
                _d.describe(),
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
  _HallPainter(this.d);
  final DecorDesign d;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final light = kLights[d.light]!.$2;
    final flower = kFlowerColors[d.flower].color;
    final cloth = kClothColors[d.cloth].color;
    final floor = kFloors[d.floor].color;

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
    for (var i = 0; i < 5; i++) {
      final x = w * (0.1 + i * 0.2);
      canvas.drawCircle(Offset(x, h * 0.08), 26, glow..color = light.withValues(alpha: 0.55));
      canvas.drawLine(Offset(x, 0), Offset(x, h * 0.06), Paint()..color = light..strokeWidth = 1.5);
      canvas.drawCircle(Offset(x, h * 0.07), 4, Paint()..color = light);
    }

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
    final n = d.tables;
    final rows = n <= 6 ? 1 : 2;
    final perRow = (n / rows).ceil();
    var drawn = 0;
    for (var r = 0; r < rows; r++) {
      final y = h * (rows == 1 ? 0.8 : (r == 0 ? 0.7 : 0.9));
      final scale = rows == 1 ? 1.0 : (r == 0 ? 0.85 : 1.1);
      final count = math.min(perRow, n - drawn);
      for (var i = 0; i < count; i++) {
        // نترك ممراً في الوسط أمام الكوشة
        final slots = count + 1;
        var slot = i < count / 2 ? i : i + 1;
        final x = w * (slot + 0.5) / (slots + 0.0);
        _table(c, Offset(x, y), w / (perRow + 2.2) * scale, cloth, flower, drawn);
        drawn++;
      }
    }
  }

  void _table(Canvas c, Offset p, double size, Color cloth, Color flower, int seed) {
    final chairS = size * 0.16;
    if (d.table == 'long') {
      final rect = Rect.fromCenter(center: p, width: size * 1.05, height: size * 0.32);
      for (var i = 0; i < 4; i++) {
        _chair(c, Offset(rect.left + rect.width * (i + 0.5) / 4, rect.top - chairS * 0.5), chairS);
      }
      c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), Paint()..color = cloth);
      c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.black.withValues(alpha: 0.12));
      _flowerCluster(c, Offset(p.dx, p.dy - size * 0.05), size * 0.1, flower, count: 5, seed: seed + 60);
      return;
    }
    // دائرية مع كراسٍ حولها
    for (var i = 0; i < 6; i++) {
      final a = -math.pi + i * math.pi / 5;
      _chair(c, p + Offset(math.cos(a) * size * 0.42, math.sin(a) * size * 0.22 - chairS * 0.2), chairS);
    }
    c.drawOval(Rect.fromCenter(center: p + const Offset(0, 6), width: size * 0.7, height: size * 0.3), Paint()..color = Colors.black.withValues(alpha: 0.15));
    c.drawOval(Rect.fromCenter(center: p, width: size * 0.7, height: size * 0.3), Paint()..color = cloth);
    c.drawOval(Rect.fromCenter(center: p, width: size * 0.7, height: size * 0.3), Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black.withValues(alpha: 0.12));
    _flowerCluster(c, Offset(p.dx, p.dy - size * 0.05), size * 0.09, flower, count: 5, seed: seed + 80);
  }

  @override
  bool shouldRepaint(covariant _HallPainter old) => true;
}
