// lib/screens/role/occasion_workspace_screen.dart
// ============================================================
// مساحة عمل المنظّم لمناسبة واحدة: كل ما يحتاجه لإدارتها في مكان واحد.
//   نظرة عامة — المرحلة، الخطوة التالية، العد التنازلي، الأرقام
//   العرض     — عروض السعر وبناؤها
//   الفريق    — المزوّدون الخارجيون وتكاليفهم
//   الجاهزية  — قائمة المهام قبل اليوم
//   البرنامج  — فقرات يوم المناسبة بأوقاتها والمسؤول عنها
//   ملاحظات   — ملاحظات خاصة لا يراها العميل
// ============================================================

import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../services/api_exceptions.dart';
import '../../services/api_service.dart';
import '../../ui/kit/kit.dart';
import '../../widgets/design_image_card.dart';
import '../event/event_form_screen.dart' show kEventTypeLabels;
import '../organizer_request_providers_screen.dart';
import '../organizer_shell_screen.dart' show OrganizerQuoteScreen;
import '../work/work_checklist_screen.dart';
import '../work/work_formatters.dart';

String _daysAr(int n) => n == 1
    ? 'يوم واحد'
    : n == 2
        ? 'يومين'
        : n <= 10
            ? '$n أيام'
            : '$n يوماً';

const _stages = <(String, String)>[
  ('new', 'طلب جديد'),
  ('in_review', 'إعداد العرض'),
  ('awaiting_client', 'عند العميل'),
  ('awaiting_deposit', 'العربون'),
  ('confirmed', 'مؤكدة'),
  ('closed', 'منتهية'),
];

class OccasionWorkspaceScreen extends StatefulWidget {
  const OccasionWorkspaceScreen({super.key, required this.requestId});

  final String requestId;

  @override
  State<OccasionWorkspaceScreen> createState() => _OccasionWorkspaceScreenState();
}

class _OccasionWorkspaceScreenState extends State<OccasionWorkspaceScreen> {
  Map<String, dynamic>? _ws;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _ws == null;
      _error = null;
    });
    try {
      _ws = await ApiService.getOccasionWorkspace(widget.requestId);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'تعذّر تحميل مساحة العمل';
    }
    if (mounted) setState(() => _loading = false);
  }

  Map<String, dynamic> get _req =>
      _ws?['request'] is Map ? Map<String, dynamic>.from(_ws!['request']) : {};

  String get _title {
    final t = _req['occasion_type']?.toString();
    final label = kEventTypeLabels[t] ?? t ?? 'مناسبة';
    return '$label • ${_req['governorate'] ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: AppPalette.background,
        appBar: AppBar(
          title: Text(_ws == null ? 'مساحة عمل المناسبة' : _title),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            // الشريط كحلي: التبويب المختار ذهبي والبقية فاتحة
            labelColor: AppPalette.gold,
            unselectedLabelColor: Color(0xCCFFFFFF),
            indicatorColor: AppPalette.gold,
            tabs: [
              Tab(text: 'نظرة عامة'),
              Tab(text: 'العرض'),
              Tab(text: 'الفريق'),
              Tab(text: 'الجاهزية'),
              Tab(text: 'البرنامج'),
              Tab(text: 'ملاحظات'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: LoadingState())
            : _error != null && _ws == null
                ? Center(child: ErrorState(message: _error!, onRetry: _load))
                : TabBarView(
                    children: [
                      _OverviewTab(ws: _ws!, onChanged: _load, requestId: widget.requestId),
                      _QuoteTab(ws: _ws!, requestId: widget.requestId, onChanged: _load),
                      _TeamTab(ws: _ws!, requestId: widget.requestId, onChanged: _load),
                      WorkChecklistScreen(
                        kind: 'occasion',
                        refId: widget.requestId,
                        title: 'جاهزية المناسبة',
                        embedded: true,
                      ),
                      _TimelineTab(ws: _ws!, requestId: widget.requestId, onChanged: _load),
                      _NotesTab(initial: _ws!['notes']?.toString() ?? '', requestId: widget.requestId),
                    ],
                  ),
      ),
    );
  }
}

// ── نظرة عامة ───────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.ws, required this.onChanged, required this.requestId});

  final Map<String, dynamic> ws;
  final Future<void> Function() onChanged;
  final String requestId;

  @override
  Widget build(BuildContext context) {
    final req = ws['request'] is Map ? Map<String, dynamic>.from(ws['request']) : <String, dynamic>{};
    final fin = ws['finance'] is Map ? Map<String, dynamic>.from(ws['finance']) : <String, dynamic>{};
    final team = ws['team'] is Map ? Map<String, dynamic>.from(ws['team']) : <String, dynamic>{};
    final stage = ws['stage']?.toString() ?? '';
    final days = ws['days_left'];
    final tl = ws['timeline'] is List ? (ws['timeline'] as List).length : 0;
    final stageIndex = _stages.indexWhere((s) => s.$1 == stage);

    return RefreshIndicator(
      onRefresh: onChanged,
      child: ListView(
        padding: const EdgeInsets.all(Space.lg),
        children: [
          // شريط المراحل
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: Space.md, horizontal: Space.sm),
            child: Row(
              children: [
                for (var i = 0; i < _stages.length; i++)
                  Expanded(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: i <= stageIndex ? AppPalette.navy : AppPalette.borderLight,
                          child: i < stageIndex
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : Text('${i + 1}',
                                  style: AppText.micro.copyWith(
                                    color: i <= stageIndex ? Colors.white : AppPalette.textMuted,
                                  )),
                        ),
                        const SizedBox(height: Space.xs),
                        Text(
                          _stages[i].$2,
                          textAlign: TextAlign.center,
                          style: AppText.micro.copyWith(
                            fontWeight: i == stageIndex ? FontWeight.w800 : FontWeight.w500,
                            color: i == stageIndex ? AppPalette.navy : AppPalette.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          if (ws['next_step'] != null)
            AppCard(
              accent: AppPalette.gold,
              child: Row(
                children: [
                  const Icon(Icons.flag_rounded, color: AppPalette.goldDeep),
                  const SizedBox(width: Space.sm),
                  Expanded(child: Text(ws['next_step'].toString(), style: AppText.title)),
                ],
              ),
            ),
          const SizedBox(height: Space.md),
          AppCard(
            child: Column(
              children: [
                InfoRow(
                  icon: Icons.event_rounded,
                  label: 'الموعد',
                  value: '${workDate(req['occasion_date']?.toString())}'
                      '${days is num ? (days > 0 ? ' • بعد ${_daysAr(days.toInt())}' : days == 0 ? ' • اليوم' : ' • مضى') : ''}',
                ),
                InfoRow(icon: Icons.place_outlined, label: 'المكان', value: '${req['governorate'] ?? '-'}${req['address'] != null ? ' — ${req['address']}' : ''}'),
                InfoRow(
                  icon: Icons.chat_outlined,
                  label: 'واتساب العميل',
                  value: req['client_contact_hidden'] == true
                      ? 'يظهر بعد تأكيد العربون'
                      : (req['whatsapp']?.toString() ?? '-'),
                ),
                if ((req['design_image_url']?.toString() ?? '').startsWith('http'))
                  DesignImageCard(url: req['design_image_url'].toString()),
                if ((req['notes']?.toString() ?? '').isNotEmpty)
                  InfoRow(icon: Icons.notes_rounded, label: 'ملاحظات العميل', value: req['notes'].toString()),
              ],
            ),
          ),
          const SectionHeader(title: 'الأرقام', icon: Icons.calculate_outlined),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              for (final t in [
                ('قيمة العرض', fin['quote_total'], AppPalette.navy),
                ('رسومك', fin['organizer_fee'], AppPalette.success),
                ('العربون', fin['deposit'], AppPalette.goldDeep),
                ('مستحق لمزوّدي التطبيق', fin['marketplace_due'], AppPalette.info),
                ('تكاليف الخارجيين', fin['external_cost'], AppPalette.warningDark),
                ('المتبقي للخارجيين', fin['external_remaining'], AppPalette.error),
                ('عمولة المنصّة', fin['platform_commission'], AppPalette.textSecondary),
                ('صافي تقديري لك', fin['estimated_margin'], AppPalette.success),
              ])
                SizedBox(
                  width: (MediaQuery.sizeOf(context).width - Space.lg * 2 - Space.sm) / 2,
                  child: StatTile(value: workMoney(t.$2), label: t.$1, accent: t.$3),
                ),
            ],
          ),
          const SectionHeader(title: 'التقدّم', icon: Icons.task_alt_rounded),
          AppCard(
            child: Column(
              children: [
                InfoRow(
                  icon: Icons.groups_2_outlined,
                  label: 'الفريق الخارجي',
                  value: '${team['external_confirmed'] ?? 0} مؤكَّد من ${team['external_count'] ?? 0}',
                ),
                InfoRow(
                  icon: Icons.schedule_rounded,
                  label: 'برنامج اليوم',
                  value: tl == 0 ? 'لم يُضف بعد' : '${ws['timeline_done'] ?? 0} منفَّذ من $tl فقرة',
                ),
              ],
            ),
          ),
          if (ws['can_complete'] == true) ...[
            const SizedBox(height: Space.lg),
            FilledButton.icon(
              onPressed: () async {
                final ok = await confirmAction(
                  context,
                  title: 'إنهاء المناسبة',
                  message: 'ستُسجَّل المناسبة مكتملة ويُبلَّغ العميل. لا يمكن التراجع.',
                  confirmLabel: 'إنهاء',
                );
                if (!ok) return;
                try {
                  await ApiService.completeOccasion(requestId);
                  if (context.mounted) {
                    showAppSnack(context, 'سُجّلت المناسبة مكتملة', tone: FeedbackTone.success);
                  }
                  await onChanged();
                } on ApiException catch (e) {
                  if (context.mounted) showAppSnack(context, e.message, tone: FeedbackTone.error);
                }
              },
              icon: const Icon(Icons.verified_rounded),
              label: const Text('تمت المناسبة — إنهاء'),
            ),
          ],
          const SizedBox(height: Space.xxl),
        ],
      ),
    );
  }
}

// ── العرض ───────────────────────────────────────────────────

class _QuoteTab extends StatelessWidget {
  const _QuoteTab({required this.ws, required this.requestId, required this.onChanged});

  final Map<String, dynamic> ws;
  final String requestId;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final q = ws['quote'] is Map ? Map<String, dynamic>.from(ws['quote']) : null;
    final stage = ws['stage']?.toString();
    final canEdit = stage == 'new' || stage == 'in_review' || stage == 'awaiting_client';
    return ListView(
      padding: const EdgeInsets.all(Space.lg),
      children: [
        if (q == null)
          const EmptyState(
            icon: Icons.request_quote_outlined,
            title: 'لا عرض مُرسَل بعد',
            body: 'سعّر بنود الطلب وأرسل العرض للعميل.',
            padding: EdgeInsets.all(Space.lg),
          )
        else
          AppCard(
            accent: q['status'] == 'accepted' ? AppPalette.success : AppPalette.gold,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('العرض رقم ${q['version']}', style: AppText.title)),
                    StatusPill(
                      label: q['status'] == 'accepted' ? 'مقبول' : 'عند العميل',
                      tone: q['status'] == 'accepted' ? PillTone.success : PillTone.warning,
                    ),
                  ],
                ),
                const SizedBox(height: Space.sm),
                InfoRow(label: 'الخدمات', value: workMoney(q['subtotal'])),
                InfoRow(label: 'رسوم التنظيم (${q['organizer_fee_pct'] ?? 0}%)', value: workMoney(q['organizer_fee_amount'])),
                InfoRow(label: 'رسوم إضافية', value: workMoney(q['extra_fees'])),
                InfoRow(label: 'الإجمالي', value: workMoney(q['total'])),
                InfoRow(label: 'العربون', value: workMoney(q['deposit_amount'])),
              ],
            ),
          ),
        const SizedBox(height: Space.lg),
        FilledButton.icon(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => OrganizerQuoteScreen(requestId: requestId)),
            );
            await onChanged();
          },
          icon: Icon(canEdit ? Icons.edit_note_rounded : Icons.visibility_outlined),
          label: Text(canEdit ? 'إعداد العرض وإرساله' : 'تفاصيل البنود والعروض'),
        ),
      ],
    );
  }
}

// ── الفريق ──────────────────────────────────────────────────

class _TeamTab extends StatelessWidget {
  const _TeamTab({required this.ws, required this.requestId, required this.onChanged});

  final Map<String, dynamic> ws;
  final String requestId;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final fin = ws['finance'] is Map ? Map<String, dynamic>.from(ws['finance']) : <String, dynamic>{};
    final team = ws['team'] is Map ? Map<String, dynamic>.from(ws['team']) : <String, dynamic>{};
    return ListView(
      padding: const EdgeInsets.all(Space.lg),
      children: [
        AppCard(
          child: Column(
            children: [
              InfoRow(icon: Icons.groups_2_outlined, label: 'مزوّدون خارجيون', value: '${team['external_count'] ?? 0}'),
              InfoRow(icon: Icons.verified_outlined, label: 'مؤكَّدون', value: '${team['external_confirmed'] ?? 0}'),
              InfoRow(icon: Icons.payments_outlined, label: 'التكلفة', value: workMoney(fin['external_cost'])),
              InfoRow(icon: Icons.check_circle_outline, label: 'دُفع لهم', value: workMoney(fin['external_paid'])),
              InfoRow(icon: Icons.pending_actions_outlined, label: 'المتبقي', value: workMoney(fin['external_remaining']), valueColor: AppPalette.error),
            ],
          ),
        ),
        const SizedBox(height: Space.md),
        Text(
          'مزوّدو التطبيق في بنود العرض، ومن تتعامل معهم خارج التطبيق تضيفهم هنا بتكلفتهم وما دفعته لهم.',
          style: AppText.bodySecondary,
        ),
        const SizedBox(height: Space.lg),
        FilledButton.icon(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => OrganizerRequestProvidersScreen(requestId: requestId)),
            );
            await onChanged();
          },
          icon: const Icon(Icons.manage_accounts_outlined),
          label: const Text('إدارة الفريق والمزوّدين'),
        ),
      ],
    );
  }
}

// ── البرنامج ────────────────────────────────────────────────

class _TimelineTab extends StatelessWidget {
  const _TimelineTab({required this.ws, required this.requestId, required this.onChanged});

  final Map<String, dynamic> ws;
  final String requestId;
  final Future<void> Function() onChanged;

  Future<void> _edit(BuildContext context, [Map<String, dynamic>? item]) async {
    final title = TextEditingController(text: item?['title']?.toString() ?? '');
    final start = TextEditingController(text: workTime(item?['start_time']?.toString()));
    final end = TextEditingController(text: workTime(item?['end_time']?.toString()));
    final owner = TextEditingController(text: item?['owner_label']?.toString() ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? 'فقرة جديدة' : 'تعديل الفقرة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'الفقرة *', hintText: 'دخول العروسين')),
              const SizedBox(height: Space.sm),
              Row(
                children: [
                  Expanded(child: TextField(controller: start, decoration: const InputDecoration(labelText: 'من *', hintText: '20:00'))),
                  const SizedBox(width: Space.sm),
                  Expanded(child: TextField(controller: end, decoration: const InputDecoration(labelText: 'إلى', hintText: '20:30'))),
                ],
              ),
              const SizedBox(height: Space.sm),
              TextField(controller: owner, decoration: const InputDecoration(labelText: 'المسؤول', hintText: 'المصوّر / فرقة الزفة')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () async {
              final body = {
                'title': title.text.trim(),
                'start_time': start.text.trim(),
                'end_time': end.text.trim().isEmpty ? null : end.text.trim(),
                'owner_label': owner.text.trim(),
              };
              try {
                if (item == null) {
                  await ApiService.addOccasionTimelineItem(requestId, body);
                } else {
                  await ApiService.updateOccasionTimelineItem(requestId, item['id'].toString(), body);
                }
                if (ctx.mounted) Navigator.pop(ctx, true);
              } on ApiException catch (e) {
                if (ctx.mounted) showAppSnack(ctx, e.message, tone: FeedbackTone.error);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (saved == true) await onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final items = ws['timeline'] is List
        ? (ws['timeline'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];
    final closed = ws['stage'] == 'closed';
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: closed
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _edit(context),
              icon: const Icon(Icons.add),
              label: const Text('فقرة'),
            ),
      body: items.isEmpty
          ? const Center(
              child: EmptyState(
                icon: Icons.schedule_rounded,
                title: 'برنامج اليوم فارغ',
                body: 'رتّب فقرات المناسبة بأوقاتها والمسؤول عن كل فقرة، وشاركها مع فريقك.',
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, 96),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
              itemBuilder: (context, i) {
                final it = items[i];
                final done = it['is_done'] == true;
                return AppCard(
                  accent: done ? AppPalette.success : AppPalette.navy,
                  padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.sm, Space.sm),
                  onTap: closed ? null : () => _edit(context, it),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        child: Column(
                          children: [
                            Text(workTime(it['start_time']?.toString()), style: AppText.number.copyWith(color: AppPalette.navy)),
                            if (it['end_time'] != null)
                              Text(workTime(it['end_time']?.toString()), style: AppText.caption),
                          ],
                        ),
                      ),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it['title']?.toString() ?? '',
                              style: AppText.title.copyWith(
                                decoration: done ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            if ((it['owner_label']?.toString() ?? '').isNotEmpty)
                              Text('المسؤول: ${it['owner_label']}', style: AppText.caption),
                          ],
                        ),
                      ),
                      Checkbox(
                        value: done,
                        onChanged: closed
                            ? null
                            : (v) async {
                                try {
                                  await ApiService.updateOccasionTimelineItem(requestId, it['id'].toString(), {'is_done': v == true});
                                  await onChanged();
                                } on ApiException catch (e) {
                                  if (context.mounted) showAppSnack(context, e.message, tone: FeedbackTone.error);
                                }
                              },
                      ),
                      if (!closed)
                        IconButton(
                          tooltip: 'حذف',
                          icon: const Icon(Icons.delete_outline, color: AppPalette.error),
                          onPressed: () async {
                            final ok = await confirmAction(context, title: 'حذف الفقرة', confirmLabel: 'حذف', destructive: true);
                            if (!ok) return;
                            try {
                              await ApiService.deleteOccasionTimelineItem(requestId, it['id'].toString());
                              await onChanged();
                            } on ApiException catch (e) {
                              if (context.mounted) showAppSnack(context, e.message, tone: FeedbackTone.error);
                            }
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ── ملاحظات ─────────────────────────────────────────────────

class _NotesTab extends StatefulWidget {
  const _NotesTab({required this.initial, required this.requestId});

  final String initial;
  final String requestId;

  @override
  State<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<_NotesTab> {
  late final TextEditingController _c = TextEditingController(text: widget.initial);
  bool _saving = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiService.saveOccasionNotes(widget.requestId, _c.text);
      if (mounted) showAppSnack(context, 'حُفظت الملاحظات', tone: FeedbackTone.success);
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, tone: FeedbackTone.error);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Space.lg),
      children: [
        Text('ملاحظاتك الخاصة — لا يراها العميل', style: AppText.bodySecondary),
        const SizedBox(height: Space.sm),
        TextField(
          controller: _c,
          minLines: 8,
          maxLines: 16,
          maxLength: 5000,
          decoration: const InputDecoration(
            hintText: 'تفضيلات العميل، ألوان الديكور، أرقام المكان، ما اتفقت عليه شفهياً...',
          ),
        ),
        const SizedBox(height: Space.md),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('حفظ الملاحظات'),
        ),
      ],
    );
  }
}
