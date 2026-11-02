// تفاصيل طلب مناسبة + رد على عرض السعر

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../services/api_exceptions.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';
import '../widgets/islamic_decorations.dart';
import 'contact_admin_screen.dart';

class OccasionRequestDetailScreen extends StatefulWidget {
  const OccasionRequestDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  State<OccasionRequestDetailScreen> createState() =>
      _OccasionRequestDetailScreenState();
}

class _OccasionRequestDetailScreenState
    extends State<OccasionRequestDetailScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _request;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _quotes = [];

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
      final data =
          await ApiService.getOccasionRequestDetails(widget.requestId);
      if (!mounted) return;
      setState(() {
        _request = data['request'] is Map
            ? Map<String, dynamic>.from(data['request'] as Map)
            : null;
        _items = (data['items'] is List)
            ? (data['items'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        _quotes = (data['quotes'] is List)
            ? (data['quotes'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.userMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر تحميل التفاصيل';
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
      case 'confirmed':
        return 'مؤكد';
      case 'closed':
        return 'مغلق';
      default:
        return s ?? '-';
    }
  }

  Map<String, dynamic>? get _activeQuote {
    for (final q in _quotes) {
      if (q['status']?.toString() == 'sent') return q;
    }
    return null;
  }

  Future<void> _decide(String action) async {
    final quote = _activeQuote;
    if (quote == null) return;
    String? note;
    if (action == 'request_change' || action == 'reject') {
      final ctrl = TextEditingController();
      note = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(action == 'reject' ? 'رفض العرض' : 'طلب تعديل'),
          content: TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: action == 'reject'
                  ? 'سبب الرفض (اختياري)'
                  : 'ما التعديل المطلوب؟',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      );
      if (action == 'request_change' && (note == null || note.length < 3)) {
        return;
      }
      if (note == null && action == 'reject') note = '';
      if (note == null) return;
    }

    setState(() => _busy = true);
    try {
      final res = await ApiService.decideOccasionQuote(
        requestId: widget.requestId,
        quoteId: quote['id']?.toString() ?? '',
        action: action,
        note: note,
      );
      if (!mounted) return;
      ErrorHandler.showSuccess(
        context,
        res['message']?.toString() ?? 'تم تنفيذ الإجراء',
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e, customMessage: e.userMessage);
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quote = _activeQuote;
    final status = _request?['status']?.toString();

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: IslamicScaffold(
        appBar: IslamicAppBar(
          title: 'تفاصيل طلب المناسبة',
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _load,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      IslamicCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'الحالة: ${_statusLabel(status)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('المحافظة: ${_request?['governorate'] ?? '-'}'),
                            Text(
                              'التاريخ: ${_request?['occasion_date'] ?? 'غير محدد'}',
                            ),
                            Text('واتساب: ${_request?['whatsapp'] ?? '-'}'),
                            if ((_request?['notes']?.toString() ?? '')
                                .isNotEmpty)
                              Text('ملاحظاتك: ${_request?['notes']}'),
                            Text(
                              'تكلفة تقديرية أولية: ${_request?['estimated_priced_subtotal'] ?? 0} \$',
                              style: const TextStyle(color: AppColors.goldDark),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'الأسعار والتوافر يخضعان لمراجعة الإدارة قبل التأكيد.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'الخدمات',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._items.map(
                        (it) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: IslamicCard(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  it['service_name']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${it['category_name'] ?? ''} · كمية ${it['quantity']} ${it['unit_label'] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  it['needs_manual_quote'] == true
                                      ? 'بانتظار التسعير'
                                      : 'تقديري: ${it['line_total_snapshot'] ?? '-'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: it['needs_manual_quote'] == true
                                        ? AppColors.goldDark
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (quote != null) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'عرض السعر',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        IslamicCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'الإجمالي النهائي: ${quote['total']} \$',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              if ((quote['client_message']?.toString() ?? '')
                                  .isNotEmpty)
                                Text('رسالة الإدارة: ${quote['client_message']}'),
                              if ((quote['terms']?.toString() ?? '').isNotEmpty)
                                Text('الشروط: ${quote['terms']}'),
                              if (quote['valid_until'] != null)
                                Text(
                                  'صالح حتى: ${quote['valid_until']}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              if (status == 'awaiting_client') ...[
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _decide('accept'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('أوافق على العرض'),
                                ),
                                OutlinedButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _decide('request_change'),
                                  child: const Text('أطلب تعديلاً'),
                                ),
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _decide('reject'),
                                  child: const Text(
                                    'أرفض العرض',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ContactAdminScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.support_agent_outlined),
                        label: const Text(
                          'تواصل مع الإدارة (الموافقات داخل التطبيق)',
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
