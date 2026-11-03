import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../services/api_exceptions.dart';
import '../../services/api_service.dart';
import 'work_formatters.dart';

/// إضافة/تعديل حجز خارجي. الإلزامي: التاريخ واسم العميل والمبلغ الكلي.
class WorkBookingFormScreen extends StatefulWidget {
  const WorkBookingFormScreen({
    super.key,
    this.existing,
    required this.canBlockCalendar,
  });

  /// عند التعديل: صف الحجز الخارجي كما رجع من القائمة.
  final Map<String, dynamic>? existing;

  /// إغلاق التاريخ أمام عملاء التطبيق متاح للمزوّد.
  final bool canBlockCalendar;

  @override
  State<WorkBookingFormScreen> createState() => _WorkBookingFormScreenState();
}

class _WorkBookingFormScreenState extends State<WorkBookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _total = TextEditingController();
  final _paid = TextEditingController();
  final _phone = TextEditingController();
  final _venue = TextEditingController();
  final _summary = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  bool _block = false;
  bool _saving = false;
  bool _dateMissing = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e == null) return;
    _name.text = e['customer_name']?.toString() ?? '';
    _total.text = _numText(e['total_amount']);
    _paid.text = _numText(e['paid_amount']);
    _phone.text = e['customer_phone']?.toString() ?? '';
    _venue.text = e['venue']?.toString() ?? '';
    _summary.text = e['title'] == 'حجز خارجي' ? '' : e['title']?.toString() ?? '';
    _date = DateTime.tryParse(e['event_date']?.toString() ?? '');
    final t = workTime(e['event_time']?.toString());
    if (t.isNotEmpty) {
      final parts = t.split(':');
      _time = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
    }
    _block = e['block_calendar'] == true;
  }

  @override
  void dispose() {
    for (final c in [_name, _total, _paid, _phone, _venue, _summary, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String _numText(dynamic v) {
    final n = v is num ? v : num.tryParse('$v');
    if (n == null || n == 0) return '';
    return n == n.roundToDouble() ? n.toInt().toString() : n.toString();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _dateMissing = false;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  String? _requiredNumber(String? v, {bool required = true}) {
    final text = (v ?? '').trim();
    if (text.isEmpty) return required ? 'مطلوب' : null;
    final n = num.tryParse(text);
    if (n == null || n < 0) return 'رقم غير صالح';
    return null;
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    if (_date == null) setState(() => _dateMissing = true);
    if (!valid || _date == null) return;

    final total = num.parse(_total.text.trim());
    final paid = _paid.text.trim().isEmpty ? 0 : num.parse(_paid.text.trim());
    if (paid > total) {
      _toast('المدفوع أكبر من المبلغ الكلي');
      return;
    }

    final body = <String, dynamic>{
      'event_date': workIsoDate(_date!),
      'customer_name': _name.text.trim(),
      'total_amount': total,
      'paid_amount': paid,
      'customer_phone': _phone.text.trim(),
      'venue': _venue.text.trim(),
      'items_summary': _summary.text.trim(),
      if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
      'event_time': _time == null
          ? null
          : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
      if (widget.canBlockCalendar) 'block_calendar': _block,
    };

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await ApiService.updateWorkBooking(
            widget.existing!['id'].toString(), body);
      } else {
        await ApiService.createWorkBooking(body);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('تعذر الحفظ');
    }
    if (mounted) setState(() => _saving = false);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(title: Text(_isEdit ? 'تعديل الحجز' : 'حجز جديد')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            Text('الحقول الإلزامية', style: AppText.subtitle),
            const SizedBox(height: Space.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(_date == null
                  ? 'تاريخ الفعالية *'
                  : workDate(workIsoDate(_date!))),
              subtitle: _dateMissing
                  ? const Text('مطلوب', style: TextStyle(color: Colors.red))
                  : null,
              onTap: _pickDate,
            ),
            TextFormField(
              controller: _name,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'اسم العميل *'),
              validator: (v) =>
                  (v ?? '').trim().length < 2 ? 'اسم العميل مطلوب' : null,
            ),
            TextFormField(
              controller: _total,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'المبلغ الكلي (\$) *'),
              validator: _requiredNumber,
            ),
            const SizedBox(height: Space.lg),
            Text('اختياري — أكمله لاحقاً', style: AppText.subtitle),
            const SizedBox(height: Space.sm),
            TextFormField(
              controller: _paid,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'المدفوع (\$)'),
              validator: (v) => _requiredNumber(v, required: false),
            ),
            TextFormField(
              controller: _phone,
              maxLength: 30,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'رقم العميل'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: Text(_time == null ? 'وقت الفعالية' : _time!.format(context)),
              trailing: _time == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _time = null),
                    ),
              onTap: _pickTime,
            ),
            TextFormField(
              controller: _venue,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'المكان'),
            ),
            TextFormField(
              controller: _summary,
              maxLength: 1000,
              maxLines: 2,
              decoration:
                  const InputDecoration(labelText: 'الخدمات المتفق عليها'),
            ),
            TextFormField(
              controller: _notes,
              maxLength: 2000,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'ملاحظات خاصة'),
            ),
            if (widget.canBlockCalendar)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('إغلاق هذا التاريخ أمام عملاء التطبيق'),
                subtitle: const Text('أطفئه إن كنت تقبل حجزاً إضافياً في اليوم نفسه.'),
                value: _block,
                onChanged: (v) => setState(() => _block = v),
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
                  : Text(_isEdit ? 'حفظ التعديلات' : 'إضافة الحجز'),
            ),
          ],
        ),
      ),
    );
  }
}
