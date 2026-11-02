import 'package:flutter/material.dart';

/// أسماء الأيقونات في `service_categories.icon` هي مفاتيح Material
/// (مثل photo_camera) وليست نصاً للعرض بجانب الاسم العربي.
IconData serviceCategoryIcon(String? raw) {
  final key = (raw ?? '').trim().toLowerCase();
  if (key.isEmpty) return Icons.category_outlined;

  switch (key) {
    case 'palette':
      return Icons.palette_outlined;
    case 'celebration':
      return Icons.celebration_outlined;
    case 'photo_camera':
      return Icons.photo_camera_outlined;
    case 'camera_alt':
      return Icons.camera_alt_outlined;
    case 'music_note':
      return Icons.music_note_outlined;
    case 'hotel':
      return Icons.hotel_outlined;
    case 'park':
      return Icons.park_outlined;
    case 'restaurant':
      return Icons.restaurant_outlined;
    case 'beach_access':
      return Icons.beach_access_outlined;
    case 'lightbulb':
      return Icons.lightbulb_outline;
    case 'queue_music':
      return Icons.queue_music_outlined;
    case 'privacy_tip':
      return Icons.privacy_tip_outlined;
    case 'store':
    case 'storefront':
      return Icons.storefront_outlined;
    case 'spa':
      return Icons.spa_outlined;
    case 'local_florist':
      return Icons.local_florist_outlined;
    case 'cake':
      return Icons.cake_outlined;
    case 'directions_car':
      return Icons.directions_car_outlined;
    case 'mic':
      return Icons.mic_outlined;
    default:
      return Icons.category_outlined;
  }
}

/// إن كانت القيمة رمزاً/إيموجي نعرضه كنص؛ أسماء Material لا تُعرض.
String? serviceCategoryIconEmoji(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) return null;
  final looksLikeMaterialKey = RegExp(r'^[a-z0-9_]+$', caseSensitive: false)
      .hasMatch(value);
  if (looksLikeMaterialKey) return null;
  return value;
}
