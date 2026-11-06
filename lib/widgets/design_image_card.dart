// lib/widgets/design_image_card.dart
// صورة تصميم الديكور في طلب التنظيم، تُكبَّر عند الضغط.

import 'package:flutter/material.dart';

class DesignImageCard extends StatelessWidget {
  const DesignImageCard({super.key, required this.url});

  final String url;

  void _openFull(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              maxScale: 5,
              child: Image.network(url, fit: BoxFit.contain),
            ),
            PositionedDirectional(
              top: 4,
              end: 4,
              child: IconButton.filledTonal(
                tooltip: 'إغلاق',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('صورة تصميم الديكور', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _openFull(context),
            borderRadius: BorderRadius.circular(10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: Color(0x11000000),
                    child: Center(child: Text('تعذّر تحميل الصورة')),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
