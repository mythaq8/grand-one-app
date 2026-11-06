// تفاصيل طلب مناسبة + رد على عرض السعر

import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import '../widgets/design_image_card.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../services/api_exceptions.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';
import '../widgets/brand_decorations.dart';
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
  bool _uploadingDeposit = false;
  String? _error;
  Map<String, dynamic>? _request;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _quotes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _uploadDepositProof() async {
    if (_uploadingDeposit || _busy) return;
    try {
      final files = await fp.FilePicker.pickFiles(type: fp.FileType.image);
      if (files.isEmpty) return;
      final file = files.first;
      setState(() => _uploadingDeposit = true);

      var bytes = await file.xFile.readAsBytes();
      try {
        final compressed = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 800,
          minHeight: 800,
          quality: 70,
        );
        if (compressed.isNotEmpty) bytes = compressed;
      } catch (_) {}

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('يجب تسجيل الدخول');

      final path =
          '$userId/occasion_deposit_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage
          .from('booking_deposits')
          .uploadBinary(path, bytes);

      await ApiService.uploadOccasionDeposit(
        requestId: widget.requestId,
        proofPath: path,
      );
      if (!mounted) return;
      ErrorHandler.showSuccess(
        context,
        'تم رفع إثبات العربون. بانتظار تحقق الإدارة.',
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e, customMessage: e.userMessage);
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e, customMessage: 'تعذر رفع الإثبات');
    } finally {
      if (mounted) setState(() => _uploadingDeposit = false);
    }
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
      case 'awaiting_deposit':
        return 'بانتظار دفع العربون';
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

  /// يحوّل نص ISO القادم من الخادم إلى «2026-11-07 16:47» بالتوقيت المحلي
  String _friendlyDateTime(dynamic raw) {
    final text = raw?.toString() ?? '';
    final dt = DateTime.tryParse(text)?.toLocal();
    if (dt == null) return text;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final quote = _activeQuote;
    final status = _request?['status']?.toString();

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: BrandScaffold(
        appBar: BrandAppBar(
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
                      BrandCard(
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
                            if ((_request?['design_image_url']?.toString() ?? '').startsWith('http'))
                              DesignImageCard(url: _request!['design_image_url'].toString()),
                            if ((_request?['notes']?.toString() ?? '')
                                .isNotEmpty)
                              Text('ملاحظاتك: ${_request?['notes']}'),
                            Text(
                              'تكلفة تقديرية أولية: ${_request?['estimated_priced_subtotal'] ?? 0} \$',
                              style: const TextStyle(color: AppColors.goldDark),
                            ),
                            if (_request?['deposit_amount'] != null)
                              Text(
                                'العربون المطلوب: ${_request?['deposit_amount']} \$',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            if (status == 'awaiting_deposit') ...[
                              const SizedBox(height: 8),
                              Text(
                                _request?['deposit_due_at'] != null
                                    ? 'ادفع العربون قبل: ${_friendlyDateTime(_request?['deposit_due_at'])}'
                                    : 'ادفع العربون خلال المهلة المحددة لتثبيت الحجز.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.warningDark,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (_request?['deposit_submitted_at'] != null)
                                const Text(
                                  'تم استلام إثبات العربون — بانتظار تحقق الإدارة.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.success,
                                  ),
                                )
                              else
                                ElevatedButton.icon(
                                  onPressed: (_busy || _uploadingDeposit)
                                      ? null
                                      : _uploadDepositProof,
                                  icon: _uploadingDeposit
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.upload_file),
                                  label: Text(
                                    _uploadingDeposit
                                        ? 'جاري الرفع...'
                                        : 'رفع إثبات العربون',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                            ],
                            const SizedBox(height: 8),
                            const Text(
                              'الأسعار والتوافر يخضعان لمراجعة المنظّم قبل التأكيد. بعد الموافقة يُطلب عربون 20٪.',
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
                          child: BrandCard(
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
                        BrandCard(
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
                              if (quote['deposit_amount'] != null)
                                Text(
                                  'العربون (20٪): ${quote['deposit_amount']} \$',
                                ),
                              if (quote['organizer_fee_amount'] != null)
                                Text(
                                  'رسوم المنظّم: ${quote['organizer_fee_amount']} \$',
                                ),
                              if ((quote['client_message']?.toString() ?? '')
                                  .isNotEmpty)
                                Text('رسالة المنظّم: ${quote['client_message']}'),
                              if ((quote['terms']?.toString() ?? '').isNotEmpty)
                                Text('الشروط: ${quote['terms']}'),
                              if (quote['valid_until'] != null)
                                Text(
                                  'صالح حتى: ${_friendlyDateTime(quote['valid_until'])}',
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
