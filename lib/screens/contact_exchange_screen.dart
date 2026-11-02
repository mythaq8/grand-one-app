// شاشة دفع رسوم تبادل التواصل + عرض الأرقام بعد موافقة المشرف
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_colors.dart';
import '../services/api_exceptions.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';
import '../widgets/islamic_decorations.dart';

class ContactExchangeScreen extends StatefulWidget {
  final String proposalId;
  final bool isBrideParty;

  const ContactExchangeScreen({
    super.key,
    required this.proposalId,
    required this.isBrideParty,
  });

  @override
  State<ContactExchangeScreen> createState() =>
      _ContactExchangeScreenState();
}

class _ContactExchangeScreenState extends State<ContactExchangeScreen> {
  static const String _shamCashId = 'ce40f4497f5429b1db116eb9cdf4c307';
  static const String _amountUsd = '1';

  bool _loading = true;
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _proposal;
  Map<String, dynamic>? _contact;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _refresh();
    _poll = Timer.periodic(const Duration(seconds: 12), (_) {
      if (mounted && !_busy) _refresh(silent: true);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final list = await ApiService.getProposals();
      final match = list.cast<Map<String, dynamic>?>().firstWhere(
            (p) => p?['id']?.toString() == widget.proposalId,
            orElse: () => null,
          );
      if (!mounted) return;
      if (match == null) {
        setState(() {
          _loading = false;
          _error = 'الطلب غير موجود';
          _proposal = null;
        });
        return;
      }

      Map<String, dynamic>? contact;
      final status = match['status']?.toString() ?? '';
      if (status == 'matched' && match['admin_approved'] == true) {
        try {
          final c = await ApiService.getProposalMatchedContact(
            widget.proposalId,
          );
          if (c['success'] == true) contact = c;
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _proposal = match;
        _contact = contact;
        _loading = false;
        _error = null;
      });

      final party = widget.isBrideParty ? 'bride' : 'groom';
      final notifiedCol = party == 'bride'
          ? 'bride_payment_notified_at'
          : 'groom_payment_notified_at';
      if ((status == 'pending_payment' || status == 'pending_admin_review') &&
          match[notifiedCol] == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showPaymentDialog();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (!silent) _error = 'تعذر تحميل حالة الطلب';
      });
    }
  }

  Future<void> _showPaymentDialog() async {
    if (!mounted || _busy) return;
    final party = widget.isBrideParty ? 'bride' : 'groom';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Column(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 48,
                  color: AppColors.gold,
                ),
                SizedBox(height: 10),
                Text(
                  'رسوم تبادل التواصل',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.goldSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'المبلغ المطلوب منك',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '$_amountUsd \$',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.goldDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'حوّل المبلغ إلى حساب شام كاش التالي:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            _shamCashId,
                            textDirection: ui.TextDirection.ltr,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(
                              const ClipboardData(text: _shamCashId),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم نسخ الرقم'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.copy_rounded,
                              size: 18,
                              color: AppColors.goldDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'ادفع من حساب شام كاش مسجّل باسمك الحقيقي. '
                    'أرقام التواصل تظهر بعد تأكيد دفع الطرفين وموافقة المشرف.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.5,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('حسنًا، سأدفع الآن'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await ApiService.recordProposalPaymentNotified(
        widget.proposalId,
        party: party,
      );
      await _refresh();
    } on ApiException catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending_payment':
        return 'بانتظار دفع الطرفين';
      case 'pending_admin_review':
        return 'بانتظار مراجعة المشرف';
      case 'matched':
        return 'تم تبادل التواصل';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _proposal?['status']?.toString() ?? '';
    final otherCode = widget.isBrideParty
        ? (_proposal?['groom_code']?.toString() ?? '')
        : (_proposal?['bride_code']?.toString() ?? '');

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('تبادل معلومات التواصل'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        IslamicCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                widget.isBrideParty
                                    ? 'شاب: $otherCode'
                                    : 'فتاة: $otherCode',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _statusLabel(status),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (status == 'pending_payment' ||
                            status == 'pending_admin_review') ...[
                          IslamicCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text(
                                  'أكمل الدفع عبر شام كاش ثم انتظر موافقة المشرف.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(height: 1.5),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _busy ? null : _showPaymentDialog,
                                  icon: const Icon(Icons.payments_outlined),
                                  label: const Text('عرض بيانات الدفع'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (status == 'matched' && _contact != null) ...[
                          IslamicCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'معلومات التواصل',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _contact!['type'] == 'guardian'
                                      ? 'ولي الأمر: ${_contact!['name'] ?? ''}'
                                      : 'الشاب: ${_contact!['name'] ?? ''}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 6),
                                SelectableText(
                                  _contact!['phone']?.toString() ?? '',
                                  textDirection: ui.TextDirection.ltr,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (status == 'matched' && _contact == null)
                          const IslamicCard(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'تمت الموافقة. جاري جلب بيانات التواصل...',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (status == 'rejected')
                          const IslamicCard(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'رُفض طلب تبادل التواصل من المشرف.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
