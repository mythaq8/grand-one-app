// lib/screens/decor/decor_models.dart
// ============================================================
// بيانات استوديو الديكور: الألوان والأنماط، وتصميم المستخدم،
// ومواضع العناصر في المشهد (مشتركة بين الرسم وتركيب الصور الحقيقية).
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

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
const kFixtures = {
  'chandelier': 'ثريات',
  'bulbs': 'مصابيح معلّقة',
  'lanterns': 'فوانيس',
  'none': 'بدون',
};
const kBackdropStyles = {
  'hall': 'قاعة',
  'plain': 'لون سادة',
  'curtain': 'ستائر',
  'panels': 'جدار كلاسيكي',
  'garden': 'حديقة',
  'stars': 'سماء ليلية',
};
const kWallColors = [
  DecorPalette('رمادي دافئ', Color(0xFF6B6459)),
  DecorPalette('عاجي', Color(0xFFE8DFCB)),
  DecorPalette('زهري غامق', Color(0xFFB9707F)),
  DecorPalette('عنابي', Color(0xFF6A1F2E)),
  DecorPalette('كحلي', Color(0xFF1F2F57)),
  DecorPalette('أخضر زيتي', Color(0xFF55633E)),
  DecorPalette('بنفسجي', Color(0xFF5B4A7E)),
  DecorPalette('أسود', Color(0xFF1E1D22)),
];
const kFloors = [
  DecorPalette('رخام أبيض', Color(0xFFF1EEE9)),
  DecorPalette('رخام داكن', Color(0xFF3A3638)),
  DecorPalette('سجاد أحمر', Color(0xFF9E2235)),
  DecorPalette('خشب', Color(0xFFA8794F)),
  DecorPalette('عشب صناعي', Color(0xFF6E9A4E)),
];

/// العناصر التي يضيفها المستخدم إلى المشهد (مرسومة، أو بصورة قطعة حقيقية إن اختارها)
const kExtras = <String, (String, IconData)>{
  'aisle': ('ممر وسجادة', Icons.linear_scale_rounded),
  'drapes': ('أقمشة سقف', Icons.waves_outlined),
  'entrance': ('بوابة مدخل', Icons.door_sliding_outlined),
  'candles': ('شموع على الطاولات', Icons.local_fire_department_outlined),
  'sign': ('لوحة ترحيب', Icons.signpost_outlined),
  'photo_booth': ('ركن تصوير', Icons.photo_camera_outlined),
  'cake': ('طاولة كيك', Icons.cake_outlined),
};

/// القطع الحقيقية بترتيب العرض (المفتاح = services.preview_piece)
const kRealPieces = <String, String>{
  'kosha': 'الكوشة',
  'sofa': 'أريكة العروسين',
  'backdrop': 'الخلفية',
  'table': 'الطاولات',
  'chair': 'الكراسي',
  'flowers': 'تنسيق الورد',
  'candles': 'الشموع والفوانيس',
  'light': 'الإضاءة والثريات',
  'drapes': 'أقمشة السقف',
  'aisle': 'الممر',
  'entrance': 'بوابة المدخل',
  'sign': 'لوحة الترحيب',
  'photo_booth': 'ركن التصوير',
  'cake': 'طاولة الكيك',
};

class DecorDesign {
  String kosha = 'arch';
  int flower = 2;
  int cloth = 0;
  String chair = 'gold';
  String table = 'round';
  String light = 'warm';
  String fixture = 'chandelier';
  int floor = 0;
  String backdrop = 'hall';
  int wall = 0;
  int tables = 6;
  final Set<String> extras = {};

  /// خط التقاء الأرضية بالجدار (نسبة من ارتفاع المشهد)؛ يُضبط مع صور الأماكن
  double horizon = 0.55;

  /// مقياس القطع لتناسب حجم المكان في الصورة
  double scale = 1;

  /// الأسطر المرسومة: (مفتاح القطعة التي تستبدلها، النص)
  List<(String?, String)> describeLines({required bool hasVenue}) => [
        ('kosha', 'الكوشة: ${kKoshaStyles[kosha]} بورد ${kFlowerColors[flower].name}'),
        ('table', 'الطاولات: $tables ${kTableShapes[table]} بمفارش ${kClothColors[cloth].name}'),
        ('chair', 'الكراسي: ${kChairStyles[chair]!.$1}'),
        ('flowers', 'الورد على الطاولات: ${kFlowerColors[flower].name}'),
        ('light', 'الإضاءة: ${kLights[light]!.$1}، ${kFixtures[fixture]}'),
        if (!hasVenue) (null, 'الأرضية: ${kFloors[floor].name}'),
        if (!hasVenue) ('backdrop', 'الخلفية: ${kBackdropStyles[backdrop]} بلون ${kWallColors[wall].name}'),
      ];

  String visualKey() => [
        kosha, flower, cloth, chair, table, light, fixture, floor, backdrop, wall, tables,
        (extras.toList()..sort()).join(','),
      ].join('|');
}

/// مواضع الطاولات (مركز الطاولة وحجمها) ضمن الأرضية الممتدة من الأفق إلى أسفل المشهد
List<(Offset, double)> tableSlots(DecorDesign d, double w, double h) {
  // حتى 4 طاولات في الصف، موزّعة بالتساوي على جانبي الممر؛ الباقي للصف الخلفي
  final n = d.tables;
  final rows = math.min(3, (n / 4).ceil());
  final counts = List<int>.filled(rows, 0);
  var left = n;
  for (var r = rows - 1; r >= 0; r--) {
    counts[r] = r == 0 ? left : math.min(4, left);
    left -= counts[r];
  }
  // نسب الصفوف داخل الأرضية: 0 عند الأفق و1 عند الحافة السفلى
  const ys = {
    1: [0.47],
    2: [0.27, 0.62],
    3: [0.18, 0.4, 0.69],
  };
  const scales = {
    1: [1.0],
    2: [0.8, 1.0],
    3: [0.64, 0.8, 1.0],
  };
  const aisle = 0.1; // نصف عرض الممر من عرض المشهد
  final out = <(Offset, double)>[];
  for (var r = 0; r < rows; r++) {
    final count = counts[r];
    final leftSide = (count / 2).ceil();
    final rightSide = count - leftSide;
    final scale = scales[rows]![r];
    final size = math.min(0.2, (0.5 - aisle) / math.max(leftSide, 1)) * w * scale * 1.05 * d.scale;
    final y = h * (d.horizon + (1 - d.horizon) * ys[rows]![r]);
    // تضيق الصفوف الخلفية نحو نقطة التلاشي لتبدو بمنظور
    final span = (0.5 - aisle) * (0.72 + 0.28 * scale);
    for (var i = 0; i < leftSide; i++) {
      final t = (i + 0.5) / leftSide;
      out.add((Offset(w * (0.5 - aisle - span * (1 - t)), y), size));
    }
    for (var i = 0; i < rightSide; i++) {
      final t = (i + 0.5) / rightSide;
      out.add((Offset(w * (0.5 + aisle + span * t), y), size));
    }
  }
  return out;
}
