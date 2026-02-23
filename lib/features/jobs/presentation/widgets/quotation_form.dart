import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/features/jobs/providers/job_provider.dart';
import 'package:voicesewa_worker/features/profile/providers/worker_profile_provider.dart';
import 'package:voicesewa_worker/shared/models/quotation_model.dart';

// ── Price Breakdown Row ────────────────────────────────────────────────────

class _BreakdownRow {
  final TextEditingController labelCtrl;
  final TextEditingController amountCtrl;

  _BreakdownRow()
    : labelCtrl = TextEditingController(),
      amountCtrl = TextEditingController();

  _BreakdownRow.prefilled(String label, String amount)
    : labelCtrl = TextEditingController(text: label),
      amountCtrl = TextEditingController(text: amount);

  void dispose() {
    labelCtrl.dispose();
    amountCtrl.dispose();
  }

  bool get isValid =>
      labelCtrl.text.trim().isNotEmpty && amountCtrl.text.trim().isNotEmpty;
}

// ── Quotation Form ─────────────────────────────────────────────────────────

class QuotationForm extends ConsumerStatefulWidget {
  final String jobId;
  final VoidCallback onCancel;
  final VoidCallback onSubmitted;
  final QuotationModel? existingQuotation;

  const QuotationForm({
    super.key,
    required this.jobId,
    required this.onCancel,
    required this.onSubmitted,
    this.existingQuotation,
  });

  @override
  ConsumerState<QuotationForm> createState() => _QuotationFormState();
}

class _QuotationFormState extends ConsumerState<QuotationForm> {
  final _formKey = GlobalKey<FormState>();
  final _costController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  // Estimated duration
  int _estHours = 1, _estMinutes = 0;

  // Availability window
  TimeOfDay? _availFrom;
  TimeOfDay? _availTo;

  bool _isSubmitting = false;
  List<_BreakdownRow> _breakdownRows = [];

  bool get _isEditMode => widget.existingQuotation != null;

  // ── Formatted strings ─────────────────────────────────────────────────────

  String get _durationString {
    final parts = <String>[];
    if (_estHours > 0) parts.add('$_estHours hr${_estHours > 1 ? 's' : ''}');
    if (_estMinutes > 0) parts.add('$_estMinutes min');
    return parts.isEmpty ? '0 min' : parts.join(' ');
  }

  String _formatTod(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String get _availabilityString {
    if (_availFrom != null && _availTo != null) {
      return '${_formatTod(_availFrom!)} – ${_formatTod(_availTo!)}';
    }
    return '';
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final q = widget.existingQuotation;
    if (q != null) {
      _costController.text = q.estimatedCost;
      _descriptionController.text = q.description;
      _notesController.text = q.notes;

      // Parse stored duration string
      final hMatch = RegExp(r'(\d+)\s*hr').firstMatch(q.estimatedTime);
      final mMatch = RegExp(r'(\d+)\s*min').firstMatch(q.estimatedTime);
      _estHours = int.tryParse(hMatch?.group(1) ?? '') ?? 1;
      _estMinutes = int.tryParse(mMatch?.group(1) ?? '') ?? 0;

      // Parse stored availability "10:00 AM – 3:00 PM"
      if (q.availability.contains('–')) {
        final parts = q.availability.split('–');
        _availFrom = _parseTod(parts[0].trim());
        _availTo = _parseTod(parts[1].trim());
      }

      if (q.priceBreakdown != null && q.priceBreakdown!.isNotEmpty) {
        _breakdownRows = q.priceBreakdown!.entries
            .map((e) => _BreakdownRow.prefilled(e.key, e.value.toString()))
            .toList();
      }
    }
    if (_breakdownRows.isEmpty) _breakdownRows.add(_BreakdownRow());
  }

  TimeOfDay? _parseTod(String s) {
    final match = RegExp(
      r'(\d+):(\d+)\s*(AM|PM)',
      caseSensitive: false,
    ).firstMatch(s);
    if (match == null) return null;
    int h = int.parse(match.group(1)!);
    final m = int.parse(match.group(2)!);
    final p = match.group(3)!.toUpperCase();
    if (p == 'PM' && h != 12) h += 12;
    if (p == 'AM' && h == 12) h = 0;
    return TimeOfDay(hour: h, minute: m);
  }

  @override
  void dispose() {
    _costController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    for (final r in _breakdownRows) r.dispose();
    super.dispose();
  }

  // ── Duration picker ───────────────────────────────────────────────────────

  Future<void> _pickDuration() async {
    int tempH = _estHours, tempM = _estMinutes;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Estimated Duration',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Spinner(
                    label: 'Hours',
                    value: tempH,
                    min: 0,
                    max: 23,
                    onChanged: (v) => set(() => tempH = v),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      ':',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _Spinner(
                    label: 'Minutes',
                    value: tempM,
                    min: 0,
                    max: 59,
                    step: 15,
                    onChanged: (v) => set(() => tempM = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: ColorConstants.primaryBlue.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _buildDurStr(tempH, tempM),
                  style: const TextStyle(
                    fontSize: 14,
                    color: ColorConstants.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _estHours = tempH;
                  _estMinutes = tempM;
                });
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryBlue,
                foregroundColor: ColorConstants.pureWhite,
              ),
              child: const Text('Set'),
            ),
          ],
        ),
      ),
    );
  }

  String _buildDurStr(int h, int m) {
    final parts = <String>[];
    if (h > 0) parts.add('$h hr${h > 1 ? 's' : ''}');
    if (m > 0) parts.add('$m min');
    return parts.isEmpty ? '0 min' : parts.join(' ');
  }

  // ── Availability pickers ──────────────────────────────────────────────────

  Future<void> _pickAvailFrom() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _availFrom ?? const TimeOfDay(hour: 9, minute: 0),
      helpText: 'AVAILABLE FROM',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _availFrom = picked);
  }

  Future<void> _pickAvailTo() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _availTo ?? const TimeOfDay(hour: 17, minute: 0),
      helpText: 'AVAILABLE UNTIL',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _availTo = picked);
  }

  // ── Price breakdown ───────────────────────────────────────────────────────

  Map<String, dynamic>? _buildBreakdownMap() {
    final valid = _breakdownRows.where((r) => r.isValid).toList();
    if (valid.isEmpty) return null;
    return {
      for (final r in valid) r.labelCtrl.text.trim(): r.amountCtrl.text.trim(),
    };
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_estHours == 0 && _estMinutes == 0) {
      _snack('Please set an estimated duration', ColorConstants.errorRed);
      return;
    }
    if (_availFrom == null || _availTo == null) {
      _snack('Please set your availability window', ColorConstants.errorRed);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final uid = ref.read(currentWorkerUidProvider);
      final profile = ref.read(workerProfileStreamProvider(uid)).value;

      final quotation = QuotationModel(
        quotationId: widget.existingQuotation?.quotationId ?? '',
        jobId: widget.jobId,
        workerUid: uid,
        workerName: profile?.name ?? '',
        workerRating: profile?.avgRating ?? 0.0,
        estimatedCost: _costController.text.trim(),
        estimatedTime: _durationString,
        description: _descriptionController.text.trim(),
        notes: _notesController.text.trim(),
        availability: _availabilityString,
        priceBreakdown: _buildBreakdownMap(),
      );

      bool success;
      if (_isEditMode) {
        success = await ref.read(updateQuotationProvider)(
          jobId: widget.jobId,
          quotationId: widget.existingQuotation!.quotationId,
          quotation: quotation,
        );
      } else {
        success = await ref.read(submitQuotationProvider)(
          jobId: widget.jobId,
          quotation: quotation,
        );
      }

      if (mounted) {
        _snack(
          success
              ? (_isEditMode
                    ? '✅ Quotation updated!'
                    : '✅ Quotation submitted!')
              : '❌ Failed. Please try again.',
          success ? ColorConstants.successGreen : ColorConstants.errorRed,
        );
        if (success) widget.onSubmitted();
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _textField(
            controller: _costController,
            label: 'Estimated Cost (₹)',
            hint: 'e.g. 1500',
            icon: Icons.currency_rupee,
            keyboardType: TextInputType.number,
            required: true,
          ),
          const SizedBox(height: 12),

          _buildDurationTile(),
          const SizedBox(height: 12),

          _buildAvailabilityRow(),
          const SizedBox(height: 12),

          _textField(
            controller: _descriptionController,
            label: 'Work Description',
            hint: 'Describe what you\'ll do...',
            icon: Icons.description_outlined,
            maxLines: 3,
            required: true,
          ),
          const SizedBox(height: 12),

          _buildBreakdownSection(),
          const SizedBox(height: 12),

          _textField(
            controller: _notesController,
            label: 'Additional Notes (optional)',
            hint: 'Any extra info...',
            icon: Icons.sticky_note_2_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primaryBlue,
                    foregroundColor: ColorConstants.pureWhite,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ColorConstants.pureWhite,
                          ),
                        )
                      : Text(
                          _isEditMode ? 'Update Quotation' : 'Submit Quotation',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Duration tile ─────────────────────────────────────────────────────────

  Widget _buildDurationTile() {
    final hasTime = _estHours > 0 || _estMinutes > 0;
    return GestureDetector(
      onTap: _pickDuration,
      child: _pickerTile(
        icon: Icons.timer_outlined,
        label: 'Estimated Time',
        value: hasTime ? _durationString : null,
        placeholder: 'Tap to set duration',
        active: hasTime,
      ),
    );
  }

  // ── Availability from–to ──────────────────────────────────────────────────

  Widget _buildAvailabilityRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 15,
              color: ColorConstants.textGrey,
            ),
            SizedBox(width: 8),
            Text(
              'Your Availability *',
              style: TextStyle(
                fontSize: 12,
                color: ColorConstants.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _pickAvailFrom,
                child: _pickerTile(
                  icon: Icons.access_time,
                  label: 'From',
                  value: _availFrom != null ? _formatTod(_availFrom!) : null,
                  placeholder: 'Select',
                  active: _availFrom != null,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '–',
                style: TextStyle(
                  fontSize: 20,
                  color: ColorConstants.chipGreyMid,
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _pickAvailTo,
                child: _pickerTile(
                  icon: Icons.access_time,
                  label: 'To',
                  value: _availTo != null ? _formatTod(_availTo!) : null,
                  placeholder: 'Select',
                  active: _availTo != null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required String label,
    required String? value,
    required String placeholder,
    required bool active,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: active
              ? ColorConstants.primaryBlue.withOpacity(0.5)
              : ColorConstants.chipGreyBadge,
        ),
        borderRadius: BorderRadius.circular(10),
        color: ColorConstants.backgroundColor,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: active
                ? ColorConstants.primaryBlue
                : ColorConstants.unselectedGrey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: active
                        ? ColorConstants.primaryBlue
                        : ColorConstants.textGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value ?? placeholder,
                  style: TextStyle(
                    fontSize: 13,
                    color: active
                        ? ColorConstants.textDark
                        : ColorConstants.textGrey,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.edit_outlined,
            size: 14,
            color: ColorConstants.textGrey,
          ),
        ],
      ),
    );
  }

  // ── Price breakdown section ───────────────────────────────────────────────

  Widget _buildBreakdownSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 16,
              color: ColorConstants.textGrey,
            ),
            const SizedBox(width: 8),
            const Text(
              'Price Breakdown (optional)',
              style: TextStyle(
                fontSize: 13,
                color: ColorConstants.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _breakdownRows.add(_BreakdownRow())),
              child: const Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 16,
                    color: ColorConstants.primaryBlue,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Add row',
                    style: TextStyle(
                      fontSize: 12,
                      color: ColorConstants.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(_breakdownRows.length, (i) {
          final row = _breakdownRows[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: row.labelCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Labour',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: ColorConstants.backgroundColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: row.amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '₹ 500',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: ColorConstants.backgroundColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                if (_breakdownRows.length > 1) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => setState(() {
                      row.dispose();
                      _breakdownRows.removeAt(i);
                    }),
                    child: const Icon(
                      Icons.remove_circle_outline,
                      color: ColorConstants.errorRed,
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: ColorConstants.backgroundColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}

// ── Time Spinner (used in duration dialog) ────────────────────────────────

class _Spinner extends StatelessWidget {
  final String label;
  final int value, min, max, step;
  final ValueChanged<int> onChanged;

  const _Spinner({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: ColorConstants.textGrey),
        ),
        const SizedBox(height: 6),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_up),
          onPressed: value + step <= max ? () => onChanged(value + step) : null,
        ),
        Container(
          width: 60,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: ColorConstants.chipGreyBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: value - step >= min ? () => onChanged(value - step) : null,
        ),
      ],
    );
  }
}
