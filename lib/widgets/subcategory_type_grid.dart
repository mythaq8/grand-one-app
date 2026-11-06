import 'package:flutter/material.dart';

import '../app_colors.dart';

/// شبكة اختيار نوع ضمن تصنيف، مثل أنواع الديكور.
class SubcategoryTypeGrid extends StatelessWidget {
  const SubcategoryTypeGrid({
    super.key,
    required this.subcategories,
    required this.coverFor,
    required this.onPick,
  });

  final List<Map<String, dynamic>> subcategories;
  final String? Function(String subcategoryId) coverFor;
  final void Function(String? subcategoryId) onPick;

  bool get _anyImage => subcategories.any((sub) {
        final id = sub['id']?.toString() ?? '';
        return id.isNotEmpty && (coverFor(id)?.trim() ?? '').startsWith('http');
      });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      // بلا صور تكفي بطاقة مدمجة، بدل مربعات كبيرة فارغة
      childAspectRatio: _anyImage ? 1.05 : 2.5,
      children: [
        _TypeTile(
          title: 'كل الأنواع',
          imageUrl: null,
          icon: Icons.apps_rounded,
          compact: !_anyImage,
          onTap: () => onPick(null),
        ),
        ...subcategories.map((sub) {
          final id = sub['id']?.toString() ?? '';
          return _TypeTile(
            title: sub['name']?.toString() ?? '',
            imageUrl: id.isEmpty ? null : coverFor(id),
            icon: Icons.category_outlined,
            compact: !_anyImage,
            onTap: id.isEmpty ? null : () => onPick(id),
          );
        }),
      ],
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.title,
    required this.imageUrl,
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  final String title;
  final String? imageUrl;
  final IconData icon;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact();
    final url = imageUrl?.trim() ?? '';
    final hasImage = url.startsWith('http');
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: AppColors.shadowSubtle,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: hasImage
                      ? Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _iconFallback(icon),
                        )
                      : _iconFallback(icon),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompact() {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: AppColors.shadowSubtle,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 19),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconFallback(IconData icon) {
    return ColoredBox(
      color: AppColors.primarySoft,
      child: Icon(icon, color: AppColors.primary, size: 36),
    );
  }
}
