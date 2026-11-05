// lib/screens/decor/decor_painter.dart
// ============================================================
// رسم مشهد الديكور على طبقات، لتتداخل مع صور القطع الحقيقية بالعمق الصحيح:
//   bg      الجدار والأرضية (لا تُرسم فوق صورة مكان حقيقية)
//   ceiling الثريات وأقمشة السقف
//   back    النباتات والبالونات وركن التصوير وطاولة الكيك
//   aisle   الممر
//   kosha   الكوشة والمنصة والأريكة
//   tables  الطاولات والكراسي وما عليها
//   front   بوابة المدخل ولوحة الترحيب
// كل الأحجام نسبية للمشهد لتبقى متناسبة على كل الشاشات.
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'decor_models.dart';

const _gold = Color(0xFFD7B56D);
const _goldDark = Color(0xFF9C7A35);
const _goldLight = Color(0xFFF2DFA8);
const _ivory = Color(0xFFF7F1E6);

class DecorPainter extends CustomPainter {
  DecorPainter(this.d, {required this.layer, this.real = const {}});
  final DecorDesign d;
  final String layer;

  /// أنواع القطع المستبدلة بصور حقيقية (لا تُرسم)
  final Set<String> real;

  Color get _flower => kFlowerColors[d.flower].color;
  Color get _light => kLights[d.light]!.$2;
  Color get _cloth => kClothColors[d.cloth].color;
  bool _on(String k) => d.extras.contains(k) && !real.contains(k);

  @override
  void paint(Canvas c, Size size) {
    final w = size.width, h = size.height;
    switch (layer) {
      case 'bg':
        _wall(c, w, h);
        _floor(c, w, h);
      case 'ceiling':
        if (_on('drapes')) _drapes(c, w, h);
        if (!real.contains('light')) _fixtures(c, w, h);
      case 'back':
        final y = h * d.horizon;
        final k = d.scale;
        if (_on('photo_booth')) _photoBooth(c, Offset(w * 0.1, y + h * 0.02), h * 0.36 * k);
        if (_on('cake')) _cakeTable(c, Offset(w * 0.9, y + h * 0.05), h * 0.3 * k);
        if (_on('plants')) {
          _plant(c, Offset(w * 0.2, y + h * 0.015), h * 0.32 * k, 3);
          _plant(c, Offset(w * 0.8, y + h * 0.015), h * 0.32 * k, 9);
        }
        if (_on('balloons')) {
          _balloons(c, Offset(w * 0.27, y + h * 0.02), h * 0.42 * k, 5);
          _balloons(c, Offset(w * 0.73, y + h * 0.02), h * 0.42 * k, 13);
        }
      case 'aisle':
        if (_on('aisle')) _aisle(c, w, h);
      case 'kosha':
        _kosha(c, w, h);
      case 'tables':
        final slots = tableSlots(d, w, h);
        for (var i = 0; i < slots.length; i++) {
          _table(c, slots[i].$1, slots[i].$2, i);
        }
      case 'front':
        if (_on('entrance')) {
          _entrancePillar(c, Offset(w * 0.04, h * 0.99), h * 0.62 * d.scale, 1);
          _entrancePillar(c, Offset(w * 0.96, h * 0.99), h * 0.62 * d.scale, 2);
        }
        if (_on('sign')) _sign(c, Offset(w * 0.62, h * 0.985), h * 0.27 * d.scale);
    }
  }

  // ── الورد ─────────────────────────────────────────────

  /// وردة ببتلات متراكبة ومركز ملتف
  void _rose(Canvas c, Offset p, double r, Color color, int seed) {
    if (r < 2.2) {
      c.drawCircle(p, r, Paint()..color = color);
      return;
    }
    final rnd = math.Random(seed);
    final turn = rnd.nextDouble() * math.pi;
    final dark = Color.lerp(color, Colors.black, 0.22)!;
    final mid = Color.lerp(color, Colors.black, 0.08)!;
    final light = Color.lerp(color, Colors.white, 0.28)!;
    c.drawCircle(p + Offset(0, r * 0.14), r * 1.02, Paint()..color = Colors.black.withValues(alpha: 0.2));
    for (var i = 0; i < 6; i++) {
      final a = turn + i * math.pi / 3;
      c.drawCircle(p + Offset(math.cos(a), math.sin(a)) * (r * 0.5), r * 0.56, Paint()..color = i.isEven ? mid : color);
    }
    for (var i = 0; i < 5; i++) {
      final a = turn + 0.5 + i * math.pi * 0.4;
      c.drawCircle(p + Offset(math.cos(a), math.sin(a)) * (r * 0.27), r * 0.42, Paint()..color = i.isEven ? light : color);
    }
    c.drawCircle(p, r * 0.33, Paint()..color = mid);
    c.drawArc(
      Rect.fromCircle(center: p, radius: r * 0.2),
      turn,
      4.4,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, r * 0.08)
        ..color = dark,
    );
  }

  void _leaf(Canvas c, Offset p, double angle, double len, int seed) {
    c.save();
    c.translate(p.dx, p.dy);
    c.rotate(angle);
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(len * 0.5, -len * 0.42, len, 0)
      ..quadraticBezierTo(len * 0.5, len * 0.42, 0, 0);
    c.drawPath(path, Paint()..color = seed.isEven ? const Color(0xFF4F7A3F) : const Color(0xFF3F6636));
    c.drawLine(Offset.zero, Offset(len * 0.9, 0), Paint()
      ..color = const Color(0xFF7FA565)
      ..strokeWidth = math.max(0.4, len * 0.04));
    c.restore();
  }

  void _cluster(Canvas c, Offset center, double r, Color color, {int count = 7, int seed = 1}) {
    final rnd = math.Random(seed);
    for (var i = 0; i < 6; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      _leaf(c, center + Offset(math.cos(a), math.sin(a)) * (r * 0.55), a, r * 0.95, seed + i);
    }
    for (var i = 0; i < count; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final dist = i == 0 ? 0.0 : (0.35 + rnd.nextDouble() * 0.6) * r;
      final tone = Color.lerp(color, Colors.white, rnd.nextDouble() * 0.2)!;
      _rose(c, center + Offset(math.cos(a), math.sin(a) * 0.8) * dist, r * (0.34 + rnd.nextDouble() * 0.18), tone, seed * 31 + i);
    }
  }

  // ── الخلفية والأرضية ───────────────────────────────────

  void _wall(Canvas c, double w, double h) {
    final rect = Rect.fromLTWH(0, 0, w, h * d.horizon);
    final base = kWallColors[d.wall].color;
    final u = h / 415;
    Color shade(double t) => Color.lerp(base, t < 0 ? Colors.black : Colors.white, t.abs())!;

    c.save();
    c.clipRect(rect);
    c.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(shade(-0.35), _light, 0.08)!, Color.lerp(base, _light, 0.22)!],
        ).createShader(rect),
    );

    switch (d.backdrop) {
      case 'hall':
        const n = 6;
        final bay = w / n;
        final inset = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [shade(-0.3), shade(-0.08)],
          ).createShader(rect);
        for (var i = 0; i < n; i++) {
          final x = i * bay + bay * 0.14;
          final bw = bay * 0.72;
          final top = rect.height * 0.3;
          final r = bw / 2;
          final arch = Path()
            ..moveTo(x, rect.bottom)
            ..lineTo(x, top + r)
            ..arcToPoint(Offset(x + bw, top + r), radius: Radius.circular(r))
            ..lineTo(x + bw, rect.bottom)
            ..close();
          c.drawPath(arch, inset);
          c.drawPath(arch, Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5 * u
            ..color = shade(0.3).withValues(alpha: 0.6));
          // عمود بين الأقواس
          c.drawRect(
            Rect.fromLTWH(i * bay - bay * 0.05, rect.height * 0.08, bay * 0.1, rect.height),
            Paint()..color = shade(0.1).withValues(alpha: 0.55),
          );
        }
        c.drawRect(Rect.fromLTWH(0, 0, w, 12 * u), Paint()..color = shade(0.22));
        c.drawRect(Rect.fromLTWH(0, 12 * u, w, 2 * u), Paint()..color = _gold);
      case 'curtain':
        final pleats = (w / (22 * u)).ceil();
        final pw = w / pleats;
        for (var i = 0; i < pleats; i++) {
          final r = Rect.fromLTWH(i * pw, 0, pw + 0.5, rect.height);
          c.drawRect(
            r,
            Paint()..shader = LinearGradient(colors: [shade(-0.38), shade(0.14), shade(-0.32)]).createShader(r),
          );
        }
        c.drawRect(Rect.fromLTWH(0, 0, w, 10 * u), Paint()..color = _gold);
      case 'panels':
        const n = 5;
        final pw = w / n;
        for (var i = 0; i < n; i++) {
          c.drawRect(
            Rect.fromLTWH(i * pw + pw * 0.1, rect.height * 0.14, pw * 0.8, rect.height * 0.76),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2 * u
              ..color = shade(0.28).withValues(alpha: 0.75),
          );
          c.drawRect(
            Rect.fromLTWH(i * pw + pw * 0.17, rect.height * 0.2, pw * 0.66, rect.height * 0.64),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1 * u
              ..color = shade(0.28).withValues(alpha: 0.75),
          );
        }
      case 'garden':
        c.drawRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [shade(0.25), shade(0.75)],
            ).createShader(rect),
        );
        final rnd = math.Random(7);
        for (var i = 0; i < 9; i++) {
          final x = w * (i + 0.5) / 9;
          final tr = (34 + rnd.nextDouble() * 20) * u;
          final y = rect.bottom - tr * (1.3 + rnd.nextDouble() * 0.5);
          c.drawCircle(Offset(x, y), tr, Paint()..color = Color.lerp(const Color(0xFF3F6B3A), const Color(0xFF5E8A48), rnd.nextDouble())!);
          c.drawCircle(Offset(x - tr * 0.3, y - tr * 0.3), tr * 0.55, Paint()..color = const Color(0xFF6E9A55).withValues(alpha: 0.7));
        }
        c.drawRect(Rect.fromLTWH(0, rect.bottom - 26 * u, w, 26 * u), Paint()..color = const Color(0xFF3B5F35));
      case 'stars':
        c.drawRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.lerp(base, Colors.black, 0.72)!, Color.lerp(base, Colors.black, 0.4)!],
            ).createShader(rect),
        );
        final rnd = math.Random(11);
        for (var i = 0; i < 90; i++) {
          c.drawCircle(
            Offset(rnd.nextDouble() * w, rnd.nextDouble() * rect.height),
            (0.5 + rnd.nextDouble()) * u,
            Paint()..color = Colors.white.withValues(alpha: 0.35 + rnd.nextDouble() * 0.6),
          );
        }
        for (var s = 0; s < 3; s++) {
          final y0 = rect.height * (0.12 + s * 0.16);
          for (var i = 0; i <= 24; i++) {
            final t = i / 24;
            final p = Offset(w * t, y0 + math.sin(t * math.pi) * 26 * u);
            c.drawCircle(p, 3 * u, Paint()
              ..color = _light.withValues(alpha: 0.5)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
            c.drawCircle(p, 1.2 * u, Paint()..color = _light);
          }
        }
      default:
        break;
    }
    c.restore();
  }

  void _floor(Canvas c, double w, double h) {
    final top = h * d.horizon;
    final rect = Rect.fromLTWH(0, top, w, h - top);
    final floor = kFloors[d.floor].color;
    c.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(floor, Colors.black, 0.25)!, floor],
        ).createShader(rect),
    );
    c.save();
    c.clipRect(rect);
    final dark = floor.computeLuminance() < 0.25;
    final line = Paint()
      ..color = (dark ? Colors.white : Colors.black).withValues(alpha: 0.1)
      ..strokeWidth = 1;
    final vanish = Offset(w / 2, top - h * 0.1);
    final name = kFloors[d.floor].name;
    if (name.contains('رخام') || name.contains('خشب')) {
      final many = name.contains('خشب');
      for (var i = many ? -24 : -10; i <= (many ? 24 : 10); i++) {
        c.drawLine(vanish, Offset(w / 2 + i * w * (many ? 0.075 : 0.18), h), line);
      }
    }
    if (name.contains('رخام')) {
      for (var i = 1; i <= 9; i++) {
        final t = i / 9;
        final y = top + (h - top) * t * t;
        c.drawLine(Offset(0, y), Offset(w, y), line);
      }
    }
    c.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.6),
          radius: 0.9,
          colors: [Colors.white.withValues(alpha: 0.16), Colors.white.withValues(alpha: 0)],
        ).createShader(rect),
    );
    final band = Rect.fromLTWH(0, top, w, h * 0.07);
    c.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.34), Colors.black.withValues(alpha: 0)],
        ).createShader(band),
    );
    c.restore();
  }

  // ── السقف ─────────────────────────────────────────────

  void _fixtures(Canvas c, double w, double h) {
    final u = h / 415 * d.scale;
    switch (d.fixture) {
      case 'chandelier':
        for (final x in const [0.18, 0.5, 0.82]) {
          _chandelier(c, Offset(w * x, 0), 58 * u);
        }
      case 'bulbs':
        for (var i = 0; i < 7; i++) {
          final x = w * (i + 0.5) / 7;
          final y = h * (i.isEven ? 0.1 : 0.15);
          c.drawLine(Offset(x, 0), Offset(x, y), Paint()
            ..color = const Color(0xFF3A3530)
            ..strokeWidth = 1);
          c.drawCircle(Offset(x, y), 16 * u, Paint()
            ..color = _light.withValues(alpha: 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
          c.drawCircle(Offset(x, y), 4.5 * u, Paint()..color = Color.lerp(_light, Colors.white, 0.5)!);
        }
      case 'lanterns':
        for (var i = 0; i < 6; i++) {
          _lantern(c, Offset(w * (i + 0.5) / 6, h * (i.isEven ? 0.1 : 0.16)), 26 * u);
        }
      default:
        break;
    }
  }

  void _chandelier(Canvas c, Offset top, double s) {
    final cy = top.dy + s * 0.62;
    c.drawCircle(Offset(top.dx, cy), s * 0.95, Paint()
      ..color = _light.withValues(alpha: 0.35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.45));
    final gold = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, s * 0.035)
      ..strokeCap = StrokeCap.round;
    c.drawLine(top, Offset(top.dx, cy), gold);
    c.drawOval(Rect.fromCenter(center: Offset(top.dx, cy), width: s * 0.26, height: s * 0.34), Paint()..color = _gold);
    // ذراعان في طبقتين بمصابيح وكريستال
    for (final tier in const [(0.95, 0.0), (0.58, -0.2)]) {
      final rx = s * tier.$1, dy = s * tier.$2;
      for (var i = 0; i < 7; i++) {
        final t = i / 6;
        final x = top.dx - rx + 2 * rx * t;
        final arm = Path()
          ..moveTo(top.dx, cy + dy)
          ..quadraticBezierTo(x, cy + dy + s * 0.34, x, cy + dy + s * 0.04);
        c.drawPath(arm, gold);
        final bulb = Offset(x, cy + dy - s * 0.04);
        c.drawCircle(bulb, s * 0.09, Paint()
          ..color = _light.withValues(alpha: 0.7)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.06));
        c.drawCircle(bulb, s * 0.035, Paint()..color = Colors.white);
        for (var j = 0; j < 3; j++) {
          c.drawCircle(
            Offset(x + (j - 1) * s * 0.02, cy + dy + s * (0.12 + j * 0.07)),
            math.max(0.5, s * 0.016),
            Paint()..color = Colors.white.withValues(alpha: 0.85),
          );
        }
      }
    }
    c.drawCircle(Offset(top.dx, cy + s * 0.34), s * 0.05, Paint()..color = _goldLight);
  }

  void _lantern(Canvas c, Offset p, double s) {
    c.drawLine(Offset(p.dx, 0), Offset(p.dx, p.dy - s / 2), Paint()
      ..color = _goldDark
      ..strokeWidth = 1);
    c.drawCircle(p, s * 0.9, Paint()
      ..color = _light.withValues(alpha: 0.45)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.5));
    final body = Path()
      ..moveTo(p.dx, p.dy - s * 0.55)
      ..lineTo(p.dx + s * 0.32, p.dy - s * 0.2)
      ..lineTo(p.dx + s * 0.32, p.dy + s * 0.3)
      ..lineTo(p.dx - s * 0.32, p.dy + s * 0.3)
      ..lineTo(p.dx - s * 0.32, p.dy - s * 0.2)
      ..close();
    c.drawPath(body, Paint()..color = Color.lerp(_light, Colors.white, 0.3)!);
    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..color = _goldDark
      ..strokeWidth = math.max(0.8, s * 0.05);
    c.drawPath(body, frame);
    c.drawLine(Offset(p.dx, p.dy - s * 0.55), Offset(p.dx, p.dy + s * 0.3), frame);
    c.drawLine(Offset(p.dx - s * 0.32, p.dy + s * 0.05), Offset(p.dx + s * 0.32, p.dy + s * 0.05), frame);
  }

  void _drapes(Canvas c, double w, double h) {
    final deep = h * 0.17;
    final fabric = Color.lerp(Colors.white, _light, 0.25)!;
    final center = Offset(w / 2, 0);
    for (var i = 0; i < 4; i++) {
      final x = w * i / 3;
      final next = x == 0 ? w / 2 : (x > w / 2 ? w : w / 2);
      if (x == w / 2) continue;
      final path = Path()
        ..moveTo(center.dx, 0)
        ..quadraticBezierTo((center.dx + x) / 2, deep * (0.9 + i * 0.12), x, 0)
        ..close();
      c.drawPath(path, Paint()..color = fabric.withValues(alpha: 0.36));
      c.drawPath(
        Path()
          ..moveTo(center.dx, 0)
          ..quadraticBezierTo((center.dx + x) / 2, deep * (0.9 + i * 0.12), x, 0),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.55),
      );
      if (next == w) continue;
    }
    _cluster(c, Offset(w / 2, h * 0.015), h * 0.03, _flower, count: 5, seed: 77);
  }

  // ── العناصر الخلفية ────────────────────────────────────

  void _plant(Canvas c, Offset base, double height, int seed) {
    final potH = height * 0.2, potW = height * 0.2;
    c.drawOval(Rect.fromCenter(center: base, width: potW * 1.7, height: potW * 0.4), Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, height * 0.02));
    c.drawLine(base - Offset(0, potH), base - Offset(0, height * 0.62), Paint()
      ..color = const Color(0xFF6B4A2E)
      ..strokeWidth = height * 0.025);
    final pot = Path()
      ..moveTo(base.dx - potW / 2, base.dy - potH)
      ..lineTo(base.dx + potW / 2, base.dy - potH)
      ..lineTo(base.dx + potW * 0.34, base.dy)
      ..lineTo(base.dx - potW * 0.34, base.dy)
      ..close();
    c.drawPath(pot, Paint()..color = _gold);
    final ball = base - Offset(0, height * 0.72);
    final r = height * 0.28;
    final rnd = math.Random(seed);
    c.drawCircle(ball, r, Paint()..color = const Color(0xFF3F6636));
    for (var i = 0; i < 26; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      _leaf(c, ball + Offset(math.cos(a), math.sin(a)) * (r * rnd.nextDouble() * 0.9), a, r * 0.42, seed + i);
    }
    for (var i = 0; i < 5; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      _rose(c, ball + Offset(math.cos(a), math.sin(a)) * (r * rnd.nextDouble() * 0.7), r * 0.17, _flower, seed * 3 + i);
    }
  }

  void _balloons(Canvas c, Offset base, double height, int seed) {
    final rnd = math.Random(seed);
    final colors = [_flower, Colors.white, _gold, Color.lerp(_flower, Colors.white, 0.45)!];
    final r = height * 0.1;
    final anchor = base - Offset(0, height * 0.05);
    c.drawCircle(anchor, height * 0.02, Paint()..color = _goldDark);
    final pts = <Offset>[];
    for (var i = 0; i < 12; i++) {
      pts.add(base - Offset((rnd.nextDouble() - 0.5) * r * 3.6, height * (0.5 + rnd.nextDouble() * 0.45)));
    }
    pts.sort((a, b) => a.dy.compareTo(b.dy));
    for (final p in pts) {
      c.drawLine(anchor, p, Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..strokeWidth = 0.7);
    }
    for (var i = 0; i < pts.length; i++) {
      final color = colors[i % colors.length];
      final rect = Rect.fromCenter(center: pts[i], width: r * 1.7, height: r * 2);
      c.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.45),
            radius: 0.9,
            colors: [Color.lerp(color, Colors.white, 0.6)!, color, Color.lerp(color, Colors.black, 0.25)!],
            stops: const [0, 0.55, 1],
          ).createShader(rect),
      );
    }
  }

  void _photoBooth(Canvas c, Offset base, double height) {
    final bw = height * 0.72;
    final rect = Rect.fromLTWH(base.dx - bw / 2, base.dy - height, bw, height);
    c.drawOval(Rect.fromCenter(center: base, width: bw * 1.2, height: height * 0.08), Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, height * 0.02));
    c.drawRRect(
      RRect.fromRectAndCorners(rect, topLeft: Radius.circular(bw * 0.5), topRight: Radius.circular(bw * 0.5)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(_flower, Colors.white, 0.72)!, Color.lerp(_flower, Colors.white, 0.45)!],
        ).createShader(rect),
    );
    c.drawRRect(
      RRect.fromRectAndCorners(rect, topLeft: Radius.circular(bw * 0.5), topRight: Radius.circular(bw * 0.5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = height * 0.018
        ..color = _gold,
    );
    _cluster(c, Offset(rect.left + bw * 0.14, rect.top + height * 0.2), height * 0.09, _flower, count: 7, seed: 41);
    _cluster(c, Offset(rect.right - bw * 0.1, base.dy - height * 0.08), height * 0.08, _flower, count: 6, seed: 43);
    // إطار صورة في الوسط
    c.drawRect(
      Rect.fromCenter(center: Offset(base.dx, base.dy - height * 0.5), width: bw * 0.42, height: height * 0.3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = height * 0.014
        ..color = _goldDark,
    );
  }

  void _cakeTable(Canvas c, Offset base, double height) {
    final tw = height * 0.72;
    final th = height * 0.42;
    c.drawOval(Rect.fromCenter(center: base, width: tw * 1.2, height: height * 0.09), Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, height * 0.02));
    final skirt = Rect.fromLTWH(base.dx - tw / 2, base.dy - th, tw, th);
    c.drawRect(
      skirt,
      Paint()
        ..shader = LinearGradient(
          colors: [Color.lerp(_cloth, Colors.black, 0.2)!, _cloth, Color.lerp(_cloth, Colors.black, 0.1)!, _cloth, Color.lerp(_cloth, Colors.black, 0.2)!],
        ).createShader(skirt),
    );
    c.drawOval(Rect.fromCenter(center: Offset(base.dx, base.dy - th), width: tw, height: tw * 0.2), Paint()..color = Color.lerp(_cloth, Colors.white, 0.3)!);
    var y = base.dy - th - tw * 0.03;
    for (final tier in const [(0.56, 0.17), (0.4, 0.15), (0.26, 0.13)]) {
      final cw = tw * tier.$1, ch = height * tier.$2;
      final r = Rect.fromLTWH(base.dx - cw / 2, y - ch, cw, ch);
      c.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(cw * 0.06)),
        Paint()
          ..shader = LinearGradient(
            colors: [const Color(0xFFD9CDB8), Colors.white, const Color(0xFFE6DDCE)],
          ).createShader(r),
      );
      c.drawLine(Offset(r.left, r.bottom - ch * 0.12), Offset(r.right, r.bottom - ch * 0.12), Paint()
        ..color = _gold
        ..strokeWidth = math.max(0.8, ch * 0.08));
      _rose(c, Offset(r.right - cw * 0.08, r.top + ch * 0.45), ch * 0.3, _flower, 90 + (cw * 10).toInt());
      y -= ch;
    }
    _cluster(c, Offset(base.dx, y - height * 0.02), height * 0.05, _flower, count: 4, seed: 55);
  }

  // ── الممر ─────────────────────────────────────────────

  void _aisle(Canvas c, double w, double h) {
    final top = h * d.horizon;
    final carpet = Path()
      ..moveTo(w * 0.455, top)
      ..lineTo(w * 0.545, top)
      ..lineTo(w * 0.62, h)
      ..lineTo(w * 0.38, h)
      ..close();
    final rect = Rect.fromLTWH(w * 0.38, top, w * 0.24, h - top);
    final tone = Color.lerp(Colors.white, _flower, 0.18)!;
    c.drawPath(
      carpet,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(tone, Colors.black, 0.18)!, tone],
        ).createShader(rect),
    );
    c.drawPath(carpet, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = _gold);
    final rnd = math.Random(23);
    for (var i = 0; i < 40; i++) {
      final t = rnd.nextDouble();
      final y = top + (h - top) * t;
      final half = w * (0.045 + 0.075 * t);
      c.drawOval(
        Rect.fromCenter(center: Offset(w / 2 + (rnd.nextDouble() * 2 - 1) * half, y), width: h * (0.004 + 0.008 * t), height: h * (0.002 + 0.005 * t)),
        Paint()..color = _flower,
      );
    }
    // منصات ورد على جانبي الممر بعمق متدرّج
    for (final t in const [0.22, 0.55, 0.9]) {
      final y = top + (h - top) * t;
      final half = w * (0.045 + 0.075 * t) + w * 0.012;
      final s = h * (0.1 + 0.13 * t) * d.scale;
      for (final side in const [-1.0, 1.0]) {
        final p = Offset(w / 2 + side * half, y);
        c.drawLine(p, p - Offset(0, s), Paint()
          ..color = _gold
          ..strokeWidth = math.max(1, s * 0.05));
        c.drawOval(Rect.fromCenter(center: p, width: s * 0.26, height: s * 0.07), Paint()..color = _goldDark);
        _cluster(c, p - Offset(0, s * 1.08), s * 0.23, _flower, count: 5, seed: (t * 100).toInt() + side.toInt());
      }
    }
  }

  // ── الكوشة ────────────────────────────────────────────

  void _kosha(Canvas c, double w, double h) {
    final drawKosha = !real.contains('kosha');
    final drawSofa = !real.contains('sofa') && !real.contains('kosha');
    if (!drawKosha && !drawSofa) return;
    final kh = h * 0.44 * d.scale;
    final kw = math.min(w * 0.42, kh * 1.15);
    final base = Offset(w / 2, h * (d.horizon - 0.03));
    final u = kh / 180;
    final top = base.dy - kh;

    if (drawKosha) {
      switch (d.kosha) {
        case 'round':
          _koshaRound(c, base, top, kw, kh, u);
        case 'panel':
          _koshaPanel(c, base, top, kw, kh, u);
        case 'drape':
          _koshaDrape(c, base, top, kw, kh, u);
        default:
          _koshaArch(c, base, top, kw, kh, u);
      }
      _platform(c, base, kw, u);
    }
    if (drawSofa) _sofa(c, Offset(base.dx, base.dy + 1 * u), kw * 0.5, u);
  }

  void _platform(Canvas c, Offset base, double kw, double u) {
    for (final step in const [(1.3, 12.0, 15.0), (1.14, 2.0, 12.0)]) {
      final r = Rect.fromCenter(center: Offset(base.dx, base.dy + step.$2 * u), width: kw * step.$1, height: step.$3 * u);
      c.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(3 * u)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_ivory, Color.lerp(_ivory, Colors.black, 0.2)!],
          ).createShader(r),
      );
      c.drawLine(Offset(r.left, r.top), Offset(r.right, r.top), Paint()
        ..color = _gold
        ..strokeWidth = 1.6 * u);
    }
  }

  void _sheer(Canvas c, Rect r) {
    c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.5),
            Colors.white.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.42),
            Colors.white.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.5),
          ],
        ).createShader(r),
    );
  }

  void _koshaArch(Canvas c, Offset base, double top, double kw, double kh, double u) {
    final r = kw / 2;
    final cy = math.max(top + r, top + kh * 0.45);
    final arch = Path()
      ..moveTo(base.dx - r, base.dy)
      ..lineTo(base.dx - r, cy)
      ..arcToPoint(Offset(base.dx + r, cy), radius: Radius.circular(r))
      ..lineTo(base.dx + r, base.dy);
    c.save();
    c.clipPath(Path.from(arch)..close());
    _sheer(c, Rect.fromLTWH(base.dx - r, top, kw, kh));
    c.restore();
    c.drawPath(arch, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7 * u
      ..color = _goldDark);
    c.drawPath(arch, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * u
      ..color = _goldLight);
    // ورد كثيف على النصف العلوي، أخف على الساقين
    for (var i = 0; i <= 15; i++) {
      final a = math.pi + (i / 15) * math.pi;
      _cluster(c, Offset(base.dx + math.cos(a) * r, cy + math.sin(a) * r), 15 * u, _flower, count: 6, seed: i + 20);
    }
    for (var i = 1; i <= 3; i++) {
      final y = cy + (base.dy - cy) * i / 4;
      _cluster(c, Offset(base.dx - r, y), 10 * u, _flower, count: 4, seed: i + 60);
      _cluster(c, Offset(base.dx + r, y), 10 * u, _flower, count: 4, seed: i + 70);
    }
    _cluster(c, Offset(base.dx - r, base.dy - 12 * u), 23 * u, _flower, count: 11, seed: 40);
    _cluster(c, Offset(base.dx + r, base.dy - 12 * u), 23 * u, _flower, count: 11, seed: 41);
  }

  void _koshaRound(Canvas c, Offset base, double top, double kw, double kh, double u) {
    final center = Offset(base.dx, top + kh * 0.5);
    final r = kh * 0.48;
    c.save();
    c.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
    _sheer(c, Rect.fromCircle(center: center, radius: r));
    c.restore();
    c.drawCircle(center, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 * u
      ..color = _goldDark);
    c.drawCircle(center, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * u
      ..color = _goldLight);
    for (var i = 0; i < 18; i++) {
      final a = i < 10 ? math.pi * (0.1 + i * 0.075) : math.pi * (1.1 + (i - 10) * 0.075);
      _cluster(c, center + Offset(math.cos(a), math.sin(a)) * r, 13 * u, _flower, count: 5, seed: i + 3);
    }
  }

  void _koshaPanel(Canvas c, Offset base, double top, double kw, double kh, double u) {
    final rect = Rect.fromLTWH(base.dx - kw / 2, top, kw, kh);
    c.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(8 * u)), Paint()..color = Color.lerp(_flower, Colors.black, 0.28)!);
    final rnd = math.Random(5);
    const cols = 11, rows = 8;
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final p = Offset(
          rect.left + kw * (x + 0.5 + (y.isEven ? 0.2 : -0.2)) / cols,
          rect.top + kh * (y + 0.5) / rows,
        );
        if (rnd.nextDouble() < 0.18) _leaf(c, p, rnd.nextDouble() * 6.3, 14 * u, x + y);
        final tone = Color.lerp(_flower, Colors.white, rnd.nextDouble() * 0.28)!;
        _rose(c, p, (10 + rnd.nextDouble() * 3) * u, tone, x * 13 + y);
      }
    }
    c.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(8 * u)), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * u
      ..color = _gold);
  }

  void _koshaDrape(Canvas c, Offset base, double top, double kw, double kh, double u) {
    final rect = Rect.fromLTWH(base.dx - kw / 2, top, kw, kh);
    final fabric = Color.lerp(const Color(0xFFF7F2EA), _light, 0.2)!;
    _sheer(c, rect);
    // ستارتان جانبيتان معقودتان
    for (final side in const [-1.0, 1.0]) {
      final outer = base.dx + side * kw / 2;
      final path = Path()
        ..moveTo(outer, top)
        ..lineTo(outer - side * kw * 0.36, top)
        ..quadraticBezierTo(outer - side * kw * 0.26, top + kh * 0.45, outer - side * kw * 0.04, top + kh * 0.6)
        ..quadraticBezierTo(outer - side * kw * 0.13, top + kh * 0.8, outer - side * kw * 0.12, base.dy)
        ..lineTo(outer, base.dy)
        ..close();
      c.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            colors: [fabric, Color.lerp(fabric, Colors.black, 0.16)!, fabric, Color.lerp(fabric, Colors.black, 0.12)!],
          ).createShader(rect),
      );
      _cluster(c, Offset(outer - side * kw * 0.05, top + kh * 0.6), 16 * u, _flower, count: 8, seed: side > 0 ? 12 : 13);
    }
    // ستارة علوية متموجة
    for (var i = 0; i < 3; i++) {
      final x0 = rect.left + kw * i / 3, x1 = rect.left + kw * (i + 1) / 3;
      c.drawPath(
        Path()
          ..moveTo(x0, top)
          ..quadraticBezierTo((x0 + x1) / 2, top + kh * 0.2, x1, top)
          ..close(),
        Paint()..color = Color.lerp(fabric, _flower, 0.22)!,
      );
    }
    c.drawLine(Offset(rect.left, top), Offset(rect.right, top), Paint()
      ..color = _gold
      ..strokeWidth = 4 * u);
    _cluster(c, Offset(rect.left, top + 4 * u), 20 * u, _flower, count: 9, seed: 11);
    _cluster(c, Offset(rect.right, top + 4 * u), 20 * u, _flower, count: 9, seed: 14);
  }

  void _sofa(Canvas c, Offset base, double sw, double u) {
    final sh = sw * 0.56;
    final left = base.dx - sw / 2;
    final top = base.dy - sh;
    c.drawOval(Rect.fromCenter(center: base + Offset(0, 1 * u), width: sw * 1.1, height: sh * 0.2), Paint()
      ..color = Colors.black.withValues(alpha: 0.26)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * u));
    // الأرجل الذهبية
    for (final x in const [0.12, 0.88]) {
      c.drawLine(Offset(left + sw * x, base.dy - sh * 0.2), Offset(left + sw * x, base.dy), Paint()
        ..color = _goldDark
        ..strokeWidth = 3 * u
        ..strokeCap = StrokeCap.round);
    }
    // الظهر المقوّس
    final back = Path()
      ..moveTo(left + sw * 0.08, base.dy - sh * 0.3)
      ..lineTo(left + sw * 0.08, top + sh * 0.3)
      ..cubicTo(left + sw * 0.2, top - sh * 0.08, left + sw * 0.8, top - sh * 0.08, left + sw * 0.92, top + sh * 0.3)
      ..lineTo(left + sw * 0.92, base.dy - sh * 0.3)
      ..close();
    final backRect = Rect.fromLTWH(left, top, sw, sh);
    c.drawPath(
      back,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_ivory, Color.lerp(_ivory, Colors.black, 0.1)!],
        ).createShader(backRect),
    );
    // تنجيد بأزرار
    for (var row = 0; row < 2; row++) {
      for (var i = 0; i < 6; i++) {
        c.drawCircle(
          Offset(left + sw * (0.2 + i * 0.12 + (row.isOdd ? 0.06 : 0)), top + sh * (0.22 + row * 0.2)),
          math.max(0.7, 1.1 * u),
          Paint()..color = _gold,
        );
      }
    }
    c.drawPath(back, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * u
      ..color = _gold);
    // المقعد
    final seat = Rect.fromLTWH(left + sw * 0.06, base.dy - sh * 0.38, sw * 0.88, sh * 0.2);
    c.drawRRect(RRect.fromRectAndRadius(seat, Radius.circular(4 * u)), Paint()..color = Color.lerp(_ivory, Colors.white, 0.4)!);
    c.drawRRect(RRect.fromRectAndRadius(seat, Radius.circular(4 * u)), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 * u
      ..color = _goldDark);
    // الذراعان
    for (final x in const [0.0, 0.88]) {
      final arm = Rect.fromLTWH(left + sw * x, base.dy - sh * 0.62, sw * 0.12, sh * 0.46);
      c.drawRRect(RRect.fromRectAndRadius(arm, Radius.circular(5 * u)), Paint()..color = _ivory);
      c.drawRRect(RRect.fromRectAndRadius(arm, Radius.circular(5 * u)), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * u
        ..color = _gold);
    }
  }

  // ── الكراسي والطاولات ──────────────────────────────────

  /// كرسي من الأمام؛ p مركز المقعد و s عرضه
  void _chair(Canvas c, Offset p, double s) {
    final style = kChairStyles[d.chair]!;
    final color = style.$2;
    final seatY = p.dy;
    final backTop = seatY - s * 1.1;
    final legEnd = seatY + s * 0.85;
    final hw = s / 2;
    if (d.chair == 'covered') {
      final body = Path()
        ..moveTo(p.dx - hw * 0.85, backTop + s * 0.1)
        ..quadraticBezierTo(p.dx, backTop - s * 0.1, p.dx + hw * 0.85, backTop + s * 0.1)
        ..lineTo(p.dx + hw * 1.05, legEnd)
        ..lineTo(p.dx - hw * 1.05, legEnd)
        ..close();
      final r = Rect.fromLTWH(p.dx - hw, backTop, s, legEnd - backTop);
      c.drawPath(
        body,
        Paint()
          ..shader = LinearGradient(
            colors: [const Color(0xFFDAD6CE), Colors.white, const Color(0xFFE6E2DA)],
          ).createShader(r),
      );
      c.drawLine(Offset(p.dx - hw, seatY), Offset(p.dx + hw, seatY), Paint()
        ..color = _flower
        ..strokeWidth = math.max(1, s * 0.14));
      _rose(c, Offset(p.dx, seatY), s * 0.17, _flower, 3);
      return;
    }
    final frame = Paint()
      ..color = d.chair == 'clear' ? Colors.white.withValues(alpha: 0.75) : Color.lerp(color, Colors.black, 0.12)!
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.9, s * 0.09);
    // ساقان خلفيتان وأماميتان
    c.drawLine(Offset(p.dx - hw * 0.75, seatY), Offset(p.dx - hw * 0.78, legEnd - s * 0.08), frame);
    c.drawLine(Offset(p.dx + hw * 0.75, seatY), Offset(p.dx + hw * 0.78, legEnd - s * 0.08), frame);
    c.drawLine(Offset(p.dx - hw * 0.95, seatY), Offset(p.dx - hw, legEnd), frame);
    c.drawLine(Offset(p.dx + hw * 0.95, seatY), Offset(p.dx + hw, legEnd), frame);
    c.drawLine(Offset(p.dx - hw * 0.97, seatY + s * 0.45), Offset(p.dx + hw * 0.97, seatY + s * 0.45), frame..strokeWidth = math.max(0.7, s * 0.05));
    // الظهر
    frame.strokeWidth = math.max(0.9, s * 0.09);
    c.drawLine(Offset(p.dx - hw * 0.78, seatY), Offset(p.dx - hw * 0.82, backTop), frame);
    c.drawLine(Offset(p.dx + hw * 0.78, seatY), Offset(p.dx + hw * 0.82, backTop), frame);
    c.drawLine(Offset(p.dx - hw * 0.82, backTop), Offset(p.dx + hw * 0.82, backTop), frame);
    c.drawLine(Offset(p.dx - hw * 0.8, backTop + s * 0.42), Offset(p.dx + hw * 0.8, backTop + s * 0.42), frame..strokeWidth = math.max(0.7, s * 0.05));
    if (d.chair == 'gold' || d.chair == 'wood' || d.chair == 'clear') {
      for (final x in const [-0.42, 0.0, 0.42]) {
        c.drawLine(Offset(p.dx + hw * x, backTop), Offset(p.dx + hw * x, backTop + s * 0.42), frame);
      }
    }
    // المقعد والوسادة
    final seat = Rect.fromCenter(center: Offset(p.dx, seatY), width: s * 1.04, height: s * 0.2);
    c.drawRRect(RRect.fromRectAndRadius(seat, Radius.circular(s * 0.08)), Paint()
      ..color = d.chair == 'gold' ? const Color(0xFFF6EFDF) : (d.chair == 'clear' ? Colors.white.withValues(alpha: 0.55) : Color.lerp(color, Colors.white, 0.25)!));
    c.drawRRect(RRect.fromRectAndRadius(seat, Radius.circular(s * 0.08)), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = Colors.black.withValues(alpha: 0.25));
  }

  void _shadowOval(Canvas c, Offset center, double w, double h, double blur) {
    c.drawOval(Rect.fromCenter(center: center, width: w, height: h), Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur));
  }

  void _table(Canvas c, Offset p, double size, int seed) {
    final drawChairs = !real.contains('chair');
    final drawTable = !real.contains('table');
    final drawFlowers = !real.contains('flowers');
    final drawCandles = _on('candles');
    final chairS = size * 0.17;
    final cloth = _cloth;
    final topW = size * (d.table == 'long' && drawTable ? 1.0 : 0.72);
    final topH = size * 0.24;
    final drop = size * 0.2;

    if (drawChairs) {
      // كراسٍ خلف الطاولة
      final n = d.table == 'long' && drawTable ? 4 : 3;
      for (var i = 0; i < n; i++) {
        final t = n == 1 ? 0.5 : i / (n - 1);
        final x = p.dx - topW * 0.38 + topW * 0.76 * t;
        _chair(c, Offset(x, p.dy - topH * 0.5), chairS);
      }
    }

    if (drawTable) {
      _shadowOval(c, p + Offset(0, drop), topW * 1.12, topH * 0.9, size * 0.03);
      final skirtRect = Rect.fromLTRB(p.dx - topW / 2, p.dy, p.dx + topW / 2, p.dy + drop + topH / 2);
      final List<Color> folds = [
        Color.lerp(cloth, Colors.black, 0.2)!,
        Color.lerp(cloth, Colors.black, 0.03)!,
        Color.lerp(cloth, Colors.black, 0.11)!,
        Color.lerp(cloth, Colors.black, 0.02)!,
        Color.lerp(cloth, Colors.black, 0.1)!,
        Color.lerp(cloth, Colors.black, 0.03)!,
        Color.lerp(cloth, Colors.black, 0.2)!,
      ];
      if (d.table == 'long') {
        // طاولة ملكية مستطيلة بمنظور
        final top = Path()
          ..moveTo(p.dx - topW * 0.44, p.dy - topH * 0.34)
          ..lineTo(p.dx + topW * 0.44, p.dy - topH * 0.34)
          ..lineTo(p.dx + topW / 2, p.dy + topH * 0.2)
          ..lineTo(p.dx - topW / 2, p.dy + topH * 0.2)
          ..close();
        c.drawRect(
          Rect.fromLTRB(p.dx - topW / 2, p.dy + topH * 0.2, p.dx + topW / 2, p.dy + topH * 0.2 + drop),
          Paint()..shader = LinearGradient(colors: folds).createShader(skirtRect),
        );
        c.drawPath(top, Paint()..color = cloth);
        // شريط وسط الطاولة
        c.drawRect(
          Rect.fromCenter(center: Offset(p.dx, p.dy - topH * 0.07), width: topW * 0.88, height: topH * 0.16),
          Paint()..color = _gold.withValues(alpha: 0.65),
        );
        for (var i = 0; i < 4; i++) {
          _plate(c, Offset(p.dx - topW * 0.33 + topW * 0.22 * i, p.dy + topH * 0.06), size * 0.05);
        }
      } else {
        final skirt = Path()
          ..moveTo(skirtRect.left, p.dy)
          ..lineTo(skirtRect.left, p.dy + drop)
          ..arcToPoint(Offset(skirtRect.right, p.dy + drop), radius: Radius.elliptical(topW / 2, topH / 2), clockwise: false)
          ..lineTo(skirtRect.right, p.dy)
          ..close();
        c.drawPath(skirt, Paint()..shader = LinearGradient(colors: folds).createShader(skirtRect));
        final top = Rect.fromCenter(center: p, width: topW, height: topH);
        c.drawOval(top, Paint()..color = Color.lerp(cloth, Colors.white, 0.18)!);
        c.drawOval(top, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..color = Colors.black.withValues(alpha: 0.14));
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3 + 0.5;
          _plate(c, p + Offset(math.cos(a) * topW * 0.36, math.sin(a) * topH * 0.34), size * 0.044);
        }
      }
    }

    if (drawFlowers) {
      final stem = p - Offset(0, size * 0.1);
      c.drawLine(p, stem, Paint()
        ..color = _gold
        ..strokeWidth = math.max(1, size * 0.018));
      _cluster(c, stem - Offset(0, size * 0.02), size * 0.085, _flower, count: 7, seed: seed + 80);
    }
    if (drawCandles) {
      for (final dx in const [-0.17, 0.17]) {
        _candle(c, p + Offset(size * dx, -size * 0.005), size * 0.1);
      }
    }

    if (drawChairs && drawTable && d.table != 'long') {
      // كرسيان أماميان جانبيان
      for (final side in const [-1.0, 1.0]) {
        _chair(c, Offset(p.dx + side * topW * 0.6, p.dy + topH * 0.45), chairS * 1.08);
      }
    } else if (drawChairs && !drawTable) {
      for (final side in const [-1.0, 1.0]) {
        _chair(c, Offset(p.dx + side * topW * 0.6, p.dy + topH * 0.3), chairS * 1.08);
      }
    }
  }

  void _plate(Canvas c, Offset p, double r) {
    final rect = Rect.fromCenter(center: p, width: r * 2, height: r * 0.95);
    c.drawOval(rect, Paint()..color = Colors.white);
    c.drawOval(rect, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.5, r * 0.1)
      ..color = _gold);
  }

  void _candle(Canvas c, Offset base, double height) {
    final cw = height * 0.26;
    c.drawRect(Rect.fromLTWH(base.dx - cw / 2, base.dy - height, cw, height), Paint()..color = const Color(0xFFFBF5E6));
    final flame = base - Offset(0, height * 1.16);
    c.drawCircle(flame, height * 0.42, Paint()
      ..color = const Color(0xFFFFC870).withValues(alpha: 0.65)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, height * 0.28));
    c.drawOval(Rect.fromCenter(center: flame, width: height * 0.18, height: height * 0.32), Paint()..color = const Color(0xFFFFE9A8));
  }

  // ── المقدمة ───────────────────────────────────────────

  void _entrancePillar(Canvas c, Offset base, double height, int seed) {
    final pw = height * 0.11;
    final rect = Rect.fromLTWH(base.dx - pw / 2, base.dy - height, pw, height);
    _shadowOval(c, base, pw * 2.6, pw * 0.55, height * 0.02);
    c.drawRect(
      rect,
      Paint()..shader = LinearGradient(colors: [_goldDark, _goldLight, _goldDark]).createShader(rect),
    );
    _cluster(c, Offset(base.dx, base.dy - height), height * 0.16, _flower, count: 12, seed: seed + 100);
    for (var i = 1; i <= 4; i++) {
      _cluster(c, Offset(base.dx, base.dy - height + height * 0.19 * i), height * (0.075 - i * 0.008), _flower, count: 5, seed: seed + 110 + i);
    }
    _cluster(c, Offset(base.dx, base.dy - height * 0.04), height * 0.1, _flower, count: 8, seed: seed + 120);
  }

  void _sign(Canvas c, Offset base, double height) {
    final bw = height * 0.68, bh = height * 0.74;
    final board = Rect.fromLTWH(base.dx - bw / 2, base.dy - height, bw, bh);
    final legs = Paint()
      ..color = _goldDark
      ..strokeWidth = math.max(1.2, height * 0.022)
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(base.dx - bw * 0.26, board.bottom - bh * 0.1), Offset(base.dx - bw * 0.4, base.dy), legs);
    c.drawLine(Offset(base.dx + bw * 0.26, board.bottom - bh * 0.1), Offset(base.dx + bw * 0.4, base.dy), legs);
    c.drawLine(Offset(base.dx, board.bottom - bh * 0.1), Offset(base.dx, base.dy), legs);
    c.drawRRect(RRect.fromRectAndRadius(board, Radius.circular(bw * 0.04)), Paint()..color = _ivory);
    c.drawRRect(RRect.fromRectAndRadius(board, Radius.circular(bw * 0.04)), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, height * 0.016)
      ..color = _gold);
    final text = TextPainter(
      text: TextSpan(
        text: 'أهلاً\nوسهلاً',
        style: TextStyle(fontFamily: 'Tajawal', fontSize: bw * 0.2, fontWeight: FontWeight.w800, color: const Color(0xFF3B2F1E), height: 1.15),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    )..layout(maxWidth: bw * 0.92);
    text.paint(c, Offset(base.dx - text.width / 2, board.center.dy - text.height / 2));
    _cluster(c, Offset(board.left + bw * 0.08, board.top + bh * 0.08), bw * 0.14, _flower, count: 6, seed: 61);
    _cluster(c, Offset(board.right - bw * 0.08, board.bottom - bh * 0.08), bw * 0.12, _flower, count: 5, seed: 62);
  }

  @override
  bool shouldRepaint(covariant DecorPainter old) => true;
}
