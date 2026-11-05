// lib/screens/my_occasion_requests_screen.dart
// طلبات تنظيم المناسبة للمستخدم

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../services/api_exceptions.dart';
import '../services/api_service.dart';
import '../widgets/brand_decorations.dart';
import 'occasion_organize_screen.dart';
import 'occasion_request_detail_screen.dart';

class MyOccasionRequestsScreen extends StatefulWidget {
  const MyOccasionRequestsScreen({super.key, this.embedded = false});

  /// عند العرض داخل تبويب «طلباتي» لا نعيد شريط عنوان.
  final bool embedded;

  @override
  State<MyOccasionRequestsScreen> createState() =>
      _MyOccasionRequestsScreenState();
}

class _MyOccasionRequestsScreenState extends State<MyOccasionRequestsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getMyOccasionRequests();
      final raw = data['data'];
      final list = raw is List
          ? raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.userMessage;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر تحميل الطلبات';
      });
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'new':
        return 'جديد';
      case 'in_review':
        return 'قيد المراجعة';
      case 'awaiting_client':
        return 'بانتظار موافقتك';
      case 'awaiting_deposit':
        return 'بانتظار العربون';
      case 'confirmed':
        return 'مؤكد';
      case 'closed':
        return 'مغلق';
      default:
        return s ?? '-';
    }
  }

  String _typeLabel(String? t) {
    switch (t) {
      case 'wedding':
        return 'عرس';
      case 'engagement':
        return 'خطبة';
      case 'birthday':
        return 'عيد ميلاد';
      case 'graduation':
        return 'تخرج';
      default:
        return 'أخرى';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: BrandScaffold(
        appBar: widget.embedded
            ? null
            : BrandAppBar(
                title: 'طلبات تنظيم المناسبة',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'طلب جديد',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OccasionOrganizeScreen(),
                        ),
                      ).then((_) => _load());
                    },
                  ),
                ],
              ),
        // داخل تبويب «طلباتي» لا شريط علوي؛ زر عائم لطلب جديد
        floatingActionButton: widget.embedded && _items.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OccasionOrganizeScreen()),
                  ).then((_) => _load());
                },
                icon: const Icon(Icons.add),
                label: const Text('تنظيم مناسبة'),
              )
            : null,
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _load,
          child: _loading
              ? ListView(
                  children: const [
                    SizedBox(height: 120),
                    Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ],
                )
              : _error != null
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _load,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    )
                  : _items.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            const SizedBox(height: 40),
                            const Text(
                              'لا توجد طلبات بعد',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'ابدأ بطلب تنظيم مناسبة واختر الخدمات التي تحتاجها.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const OccasionOrganizeScreen(),
                                  ),
                                ).then((_) => _load());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('تنظيم مناسبة'),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final r = _items[i];
                            final est = r['estimated_priced_subtotal'];
                            final id = r['id']?.toString() ?? '';
                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: id.isEmpty
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              OccasionRequestDetailScreen(
                                            requestId: id,
                                          ),
                                        ),
                                      ).then((_) => _load());
                                    },
                              child: BrandCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _typeLabel(
                                            r['occasion_type']?.toString(),
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primarySoft,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _statusLabel(
                                            r['status']?.toString(),
                                          ),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'المحافظة: ${r['governorate'] ?? '-'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (est != null)
                                    Text(
                                      'تقديري: $est \$',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.goldDark,
                                      ),
                                    ),
                                  Text(
                                    'تاريخ الإنشاء: ${r['created_at']?.toString().substring(0, 10) ?? '-'}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}
