// شاشة مراجعة صورة الفتاة بعد موافقتها (awaiting_groom)
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../design/tokens.dart';
import '../ui/kit/kit.dart';
import '../services/api_exceptions.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';
import '../utils/profile_fields.dart';
import '../widgets/islamic_decorations.dart';
import 'contact_exchange_screen.dart';
import 'exploration_screen.dart';

class GroomBrideReviewScreen extends StatefulWidget {
  const GroomBrideReviewScreen({super.key});

  @override
  State<GroomBrideReviewScreen> createState() => _GroomBrideReviewScreenState();
}

class _GroomBrideReviewScreenState extends State<GroomBrideReviewScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _awaiting = [];
  List<Map<String, dynamic>> _otherOpen = [];
  bool _busy = false;

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
      final list = await ApiService.getProposals();
      final awaiting = <Map<String, dynamic>>[];
      final other = <Map<String, dynamic>>[];
      for (final p in list) {
        final status = p['status']?.toString() ?? '';
        if (status == 'awaiting_groom') {
          awaiting.add(p);
        } else if (ApiService.proposalBlocksGroomSearch(p)) {
          other.add(p);
        }
      }
      if (!mounted) return;
      setState(() {
        _awaiting = awaiting;
        _otherOpen = other;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException
            ? e.userMessage
            : 'تعذر تحميل الطلبات. تحقق من الإنترنت.';
      });
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'waiting':
        return 'في الطابور';
      case 'pending':
        return 'بانتظار رد الفتاة';
      case 'awaiting_groom':
        return 'وافقت — بانتظار رؤيتك للصورة';
      case 'accepted':
        return 'تم التأكيد — المحادثة متاحة';
      case 'matched':
        return 'تم التطابق';
      default:
        return status ?? 'غير معروف';
    }
  }

  Future<void> _openPreview(Map<String, dynamic> proposal) async {
    if (_busy) return;
    final proposalId = proposal['id']?.toString() ?? '';
    final brideCode = proposal['bride_code']?.toString() ?? '';
    if (proposalId.isEmpty) return;

    setState(() => _busy = true);
    final navigator = Navigator.of(context, rootNavigator: true);
    var loaderShown = false;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        loaderShown = true;
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      },
    );

    Map<String, dynamic> preview = {};
    Object? previewError;
    try {
      preview = await ApiService.getBridePreviewForProposal(proposalId);
    } on ApiException catch (e) {
      previewError = e;
    } catch (e) {
      previewError = e;
    } finally {
      if (loaderShown && mounted) navigator.pop();
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;

    final bride = preview['bride'];
    if (bride is! Map || preview.isEmpty) {
      final msg = previewError is ApiException
          ? previewError.userMessage
          : (preview['error']?.toString() ??
              'تعذر تحميل صورة الفتاة. أعد المحاولة.');
      ErrorHandler.showError(context, previewError, customMessage: msg);
      return;
    }

    final brideMap = Map<String, dynamic>.from(bride);
    final photoUrl = brideMap['personal_photo_signed_url']?.toString();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              'صورة الفتاة وملفها',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: (MediaQuery.sizeOf(dialogContext).height * 0.5)
                  .clamp(220.0, 480.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (photoUrl != null && photoUrl.isNotEmpty)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            photoUrl,
                            height: 240,
                            width: 190,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 160,
                              color: AppColors.primarySoft,
                              child: const Icon(Icons.person, size: 64),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 120,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'لا تتوفر صورة شخصية حالياً',
                          style: TextStyle(color: AppColors.goldDark),
                        ),
                      ),
                    const SizedBox(height: 12),
                    _row('الرمز', brideMap['anonymous_code'] ?? brideCode),
                    _row('العمر', ageLabel(brideMap['birth_date'])),
                    _row('المحافظة', brideMap['current_governorate']),
                    _row('الإقامة', brideMap['current_residence']),
                    _row('التعليم', brideMap['education_level']),
                    _row('الحالة الاجتماعية', brideMap['social_status']),
                    _row('الحجاب', brideMap['hijab_status']),
                    _row('الالتزام', brideMap['religious_commitment']),
                    _row('صف نفسها', brideMap['interests']),
                    const SizedBox(height: 8),
                    const Text(
                      'بالموافقة تُفتح المحادثة للطرفين.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              SizedBox(
                width: double.maxFinite,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        await _confirm(proposalId, brideCode);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('موافقة وفتح الدردشة'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('لاحقاً'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        await _reject(proposalId);
                      },
                      child: const Text(
                        'رفض وحذف',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(String proposalId, String brideCode) async {
    setState(() => _busy = true);
    try {
      final result = await ApiService.confirmProposal(proposalId);
      if (!mounted) return;
      if (result['success'] != true) {
        ErrorHandler.showError(
          context,
          null,
          customMessage: result['message']?.toString() ?? 'تعذر التأكيد',
        );
        return;
      }

      ErrorHandler.showSuccess(
        context,
        'تم التأكيد — ادفع رسوم تبادل التواصل',
      );

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ContactExchangeScreen(
            proposalId: proposalId,
            isBrideParty: false,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e);
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject(String proposalId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الرفض'),
          content: const Text(
            'سيتم حذف الطلب نهائياً. هل أنت متأكد؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('حذف نهائياً'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final result = await ApiService.rejectProposalByGroom(proposalId);
      if (!mounted) return;
      if (result['success'] != true) {
        ErrorHandler.showError(
          context,
          null,
          customMessage: result['message']?.toString() ?? 'تعذر الرفض',
        );
        return;
      }
      ErrorHandler.showSuccess(context, 'تم حذف الطلب');
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: IslamicScaffold(
        appBar: const IslamicAppBar(title: 'عرض صورة الفتاة'),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _load,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const LoadingState(message: 'جارٍ تحميل الطلبات...');
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(Space.xxl),
        children: [
          ErrorState(
            message: _error!,
            onRetry: _load,
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        IslamicCard(
          padding: const EdgeInsets.all(14),
          child: const Text(
            'بعد موافقة الفتاة على طلب الخطوبة تظهر هنا. اضغط «عرض الصورة» ثم وافق لفتح المحادثة أو ارفض.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_awaiting.isEmpty) ...[
          IslamicCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(
                  Icons.photo_camera_front_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                const Text(
                  'لا توجد فتاة بانتظار مراجعتك الآن',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'عندما توافق فتاة على طلبك ستظهر هنا مباشرة. اسحب للأسفل للتحديث.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ExplorationScreen(isGroomRole: true),
                      ),
                    );
                  },
                  child: const Text('العودة لمتابعة الرغبات'),
                ),
              ],
            ),
          ),
        ] else ...[
          const Text(
            'بانتظار رؤيتك',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          ..._awaiting.map((p) {
            final brideCode = p['bride_code']?.toString() ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: IslamicCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      brideCode.isEmpty ? 'فتاة وافقت على طلبك' : 'الفتاة: $brideCode',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusLabel(p['status']?.toString()),
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _busy ? null : () => _openPreview(p),
                      icon: const Icon(Icons.photo_camera_front_outlined),
                      label: const Text(
                        'عرض صورة الفتاة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
        if (_otherOpen.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text(
            'رغبات أخرى نشطة',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ..._otherOpen.map((p) {
            final brideCode = p['bride_code']?.toString() ?? '';
            final status = p['status']?.toString() ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: IslamicCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brideCode.isEmpty ? 'طلب' : 'الفتاة: $brideCode',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusLabel(status),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
