import '../../ui/kit/kit.dart';
import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../services/api_exceptions.dart';
import '../../services/api_service.dart';
import '../../services/search_date.dart';
import '../work/work_formatters.dart';

const Map<String, String> kEventTypeLabels = {
  'wedding': 'زفاف',
  'engagement': 'خطوبة',
  'graduation': 'تخرج',
  'birthday': 'عيد ميلاد',
  'conference': 'مؤتمر',
  'corporate': 'فعالية شركة',
  'other': 'أخرى',
};

/// إنشاء فعالية جديدة أو تعديل الحالية.
/// الإلزامي: النوع والتاريخ. يرجع `true` عند الحفظ.
class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key, this.existing, this.hasActiveBookings = false});

  final Map<String, dynamic>? existing;

  /// عند وجود حجوزات نشطة لا يُسمح بتغيير التاريخ.
  final bool hasActiveBookings;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _guests = TextEditingController();
  final _governorate = TextEditingController(text: 'دمشق');
  final _venue = TextEditingController();
  final _budget = TextEditingController();
  String _type = 'wedding';
  DateTime? _date;
  bool _dateMissing = false;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _type = e['event_type']?.toString() ?? 'wedding';
      _title.text = e['title']?.toString() ?? '';
      _guests.text = e['guests_count']?.toString() ?? '';
      _governorate.text = e['governorate']?.toString() ?? '';
      _venue.text = e['venue_note']?.toString() ?? '';
      final b = e['budget_usd'];
      _budget.text = b == null ? '' : '$b';
      _date = DateTime.tryParse(e['event_date']?.toString() ?? '');
    } else {
      // اقتراح التاريخ الذي اختاره العميل في البحث
      _date = SearchDate.date.value;
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _guests, _governorate, _venue, _budget]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 2)),
      firstDate: now,
      lastDate: DateTime(now.year + 1, now.month, now.day),
      helpText: 'تاريخ الفعالية',
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _dateMissing = false;
      });
    }
  }

  String? _optionalInt(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    return n == null || n < 0 ? 'رقم غير صالح' : null;
  }

  String? _optionalNum(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    final n = num.tryParse(t);
    return n == null || n < 0 ? 'رقم غير صالح' : null;
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    if (_date == null) setState(() => _dateMissing = true);
    if (!valid || _date == null) return;

    final body = <String, dynamic>{
      'event_type': _type,
      'event_date': workIsoDate(_date!),
      'title': _title.text.trim(),
      'governorate': _governorate.text.trim(),
      'venue_note': _venue.text.trim(),
      'guests_count':
          _guests.text.trim().isEmpty ? null : int.parse(_guests.text.trim()),
      'budget_usd':
          _budget.text.trim().isEmpty ? null : num.parse(_budget.text.trim()),
    };

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await ApiService.updateEvent(widget.existing!['id'].toString(), body);
      } else {
        await ApiService.createEvent(body);
      }
      SearchDate.date.value = _date;
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        showAppSnack(context, e.message, tone: FeedbackTone.error);
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final dateLocked = _isEdit && widget.hasActiveBookings;
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(title: Text(_isEdit ? 'تعديل الفعالية' : 'فعالية جديدة')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            Text('نوع الفعالية *', style: AppText.subtitle),
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                for (final entry in kEventTypeLabels.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _type == entry.key,
                    onSelected: (_) => setState(() => _type = entry.key),
                  ),
              ],
            ),
            const SizedBox(height: Space.lg),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(_date == null
                  ? 'تاريخ الفعالية *'
                  : workDate(workIsoDate(_date!))),
              subtitle: _dateMissing
                  ? const Text('مطلوب', style: TextStyle(color: Colors.red))
                  : dateLocked
                      ? const Text('لا يمكن تغيير التاريخ بعد وجود حجوزات نشطة')
                      : null,
              onTap: dateLocked ? null : _pickDate,
            ),
            const SizedBox(height: Space.sm),
            TextFormField(
              controller: _title,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'اسم الفعالية (اختياري)'),
            ),
            TextFormField(
              controller: _guests,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'عدد المدعوين'),
              validator: _optionalInt,
            ),
            TextFormField(
              controller: _governorate,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'المحافظة'),
            ),
            TextFormField(
              controller: _venue,
              maxLength: 300,
              decoration: const InputDecoration(labelText: 'المكان'),
            ),
            TextFormField(
              controller: _budget,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'الميزانية (\$)'),
              validator: _optionalNum,
            ),
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEdit ? 'حفظ التعديلات' : 'إنشاء الفعالية'),
            ),
          ],
        ),
      ),
    );
  }
}
