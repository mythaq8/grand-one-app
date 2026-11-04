import '../ui/kit/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:url_launcher/url_launcher.dart';

import '../design/tokens.dart';
import '../design/typography.dart';
import '../services/api_exceptions.dart';
import '../services/api_service.dart';
import '../ui/kit/states.dart';

/// كود الدعوة: خصم للطرفين. المدعو يحصل على خصمه عند استخدام الكود،
/// والداعي عند أول عربون مؤكد للمدعو.
class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final TextEditingController _redeem = TextEditingController();
  bool _loading = true;
  bool _redeeming = false;
  String? _error;
  Map<String, dynamic> _info = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _redeem.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _info = await ApiService.getInviteInfo();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'تعذر تحميل كود الدعوة';
    }
    if (mounted) setState(() => _loading = false);
  }

  void _toast(String m) =>
      showAppSnack(context, m);

  String get _code => _info['code']?.toString() ?? '';

  String get _shareText =>
      'جرّب تطبيق GRAND ONE لحجز خدمات فعاليتك، واستخدم كود الدعوة $_code لتحصل على خصم على أول حجز.';

  Future<void> _useCode() async {
    final code = _redeem.text.trim().toUpperCase();
    if (code.length < 6) {
      _toast('أدخل كوداً صحيحاً');
      return;
    }
    setState(() => _redeeming = true);
    try {
      final res = await ApiService.redeemInviteCode(code);
      _toast('تم! خصم ${res['percent'] ?? ''}% جاهز لأول حجز لك');
      _redeem.clear();
      await _load();
    } on ApiException catch (e) {
      _toast(e.message);
    }
    if (mounted) setState(() => _redeeming = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(title: const Text('كود الدعوة')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.all(Space.lg),
                  children: [
                    _codeCard(),
                    const SizedBox(height: Space.lg),
                    _discountCard(),
                    if (_info['redeemed_code'] == null) ...[
                      const SizedBox(height: Space.xl),
                      Text('لديك كود دعوة؟', style: AppText.section),
                      const SizedBox(height: Space.sm),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _redeem,
                              textCapitalization: TextCapitalization.characters,
                              maxLength: 10,
                              decoration: const InputDecoration(
                                hintText: 'مثال: AB12CD34',
                                counterText: '',
                              ),
                            ),
                          ),
                          const SizedBox(width: Space.sm),
                          FilledButton(
                            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                            onPressed: _redeeming ? null : _useCode,
                            child: _redeeming
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('استخدم'),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        'يعمل الكود للمستخدمين الجدد خلال 30 يوماً من التسجيل وقبل أول حجز.',
                        style: AppText.caption,
                      ),
                    ] else ...[
                      const SizedBox(height: Space.xl),
                      Text('استخدمت كود الدعوة ${_info['redeemed_code']}.',
                          style: AppText.bodySecondary),
                    ],
                  ],
                ),
    );
  }

  Widget _codeCard() {
    return Container(
      padding: const EdgeInsets.all(Space.xl),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppPalette.goldLighter),
      ),
      child: Column(
        children: [
          Text('كودك', style: AppText.caption),
          const SizedBox(height: Space.xs),
          SelectableText(_code, style: AppText.display),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _code));
                  _toast('تم نسخ الكود');
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('نسخ'),
              ),
              FilledButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse('https://wa.me/?text=${Uri.encodeComponent(_shareText)}'),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('شارك عبر واتساب'),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          Text(
            'يحصل صديقك على خصم عند استخدام كودك، وتحصل أنت على خصم عند تأكيد عربونه الأول.',
            textAlign: TextAlign.center,
            style: AppText.bodySecondary,
          ),
          const SizedBox(height: Space.sm),
          Text(
            'دعوتَ ${_info['invited'] ?? 0} • أكملوا حجزهم الأول ${_info['rewarded'] ?? 0}',
            style: AppText.caption,
          ),
        ],
      ),
    );
  }

  Widget _discountCard() {
    final d = _info['available_discount'];
    if (d is! Map) {
      return Text('لا يوجد خصم دعوة متاح حالياً.', style: AppText.bodySecondary);
    }
    final value = d['value'];
    final ends = d['ends_at']?.toString();
    final maxAmount = d['max_discount_amount'];
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: AppPalette.goldSoft,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer_outlined, color: AppPalette.goldDeep),
          const SizedBox(width: Space.md),
          Expanded(
            child: Text(
              'لديك خصم $value% على أول حجز'
              '${maxAmount != null ? ' (حتى $maxAmount \$)' : ''}'
              '${ends != null && ends.length >= 10 ? ' — ينتهي ${ends.substring(0, 10)}' : ''}. '
              'يُطبَّق تلقائياً عند الحجز.',
              style: AppText.body,
            ),
          ),
        ],
      ),
    );
  }
}
