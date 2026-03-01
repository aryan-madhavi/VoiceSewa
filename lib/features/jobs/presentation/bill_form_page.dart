import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/features/jobs/providers/job_provider.dart';
import 'package:voicesewa_worker/shared/models/job_model.dart';
import 'package:voicesewa_worker/core/extensions/context_extensions.dart';

class BillFormPage extends ConsumerStatefulWidget {
  final JobModel job;

  const BillFormPage({super.key, required this.job});

  @override
  ConsumerState<BillFormPage> createState() => _BillFormPageState();
}

class _BillFormPageState extends ConsumerState<BillFormPage> {
  final _notesCtrl = TextEditingController();
  final List<_Row> _rows = [_Row()];
  bool _submitting = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final r in _rows) r.dispose();
    super.dispose();
  }

  double get _total => _rows.fold(0.0, (sum, r) {
    final qty = double.tryParse(r.qtyCtrl.text) ?? 0;
    final price = double.tryParse(r.priceCtrl.text) ?? 0;
    return sum + qty * price;
  });

  Future<void> _endJob() async {
    final valid = _rows.where((r) => r.isValid).toList();
    if (valid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.loc.addAtLeastOneItemToTheBill),
          backgroundColor: ColorConstants.errorRed,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final bill = JobBill(
      items: valid
          .map(
            (r) => BillItem(
              name: r.nameCtrl.text.trim(),
              quantity: int.tryParse(r.qtyCtrl.text) ?? 1,
              unitPrice: double.tryParse(r.priceCtrl.text) ?? 0,
            ),
          )
          .toList(),
      totalAmount: _total,
      notes: _notesCtrl.text.trim(),
    );

    final ok = await ref.read(saveBillAndCompleteProvider)(
      jobId: widget.job.jobId,
      bill: bill,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      // Pop back exactly 2 screens (BillFormPage + OtpVerificationPage)
      // so we land on JobDetailPage. Its live stream will detect the
      // completed status and auto-trigger the feedback bottom sheet.
      int _popCount = 0;
      Navigator.of(context).popUntil((_) => _popCount++ >= 2);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to complete job. Please try again.'),
          backgroundColor: ColorConstants.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Final Bill',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: ColorConstants.pureWhite,
        foregroundColor: ColorConstants.textDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ColorConstants.successTeal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ColorConstants.successTeal.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    color: ColorConstants.successTeal,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Work Completed!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.successTeal,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          widget.job.serviceName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: ColorConstants.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bill card
            Container(
              decoration: BoxDecoration(
                color: ColorConstants.pureWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: ColorConstants.shadowBlack.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.list_alt_outlined,
                          size: 18,
                          color: ColorConstants.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Bill Items',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.textDark,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _rows.add(_Row())),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                size: 16,
                                color: ColorConstants.primaryBlue,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Add item',
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
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Divider(height: 1),
                  ),

                  // Column headers
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    child: Row(
                      children: const [
                        Expanded(
                          flex: 4,
                          child: Text(
                            'Item',
                            style: TextStyle(
                              fontSize: 11,
                              color: ColorConstants.textGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        SizedBox(
                          width: 52,
                          child: Text(
                            'Qty',
                            style: TextStyle(
                              fontSize: 11,
                              color: ColorConstants.textGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Price (₹)',
                            style: TextStyle(
                              fontSize: 11,
                              color: ColorConstants.textGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 28),
                      ],
                    ),
                  ),

                  // Item rows
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Column(
                      children: List.generate(_rows.length, (i) {
                        final row = _rows[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: TextFormField(
                                  controller: row.nameCtrl,
                                  onChanged: (_) => setState(() {}),
                                  decoration: _dec('e.g. Labour'),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 52,
                                child: TextFormField(
                                  controller: row.qtyCtrl,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                  decoration: _dec('1'),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: row.priceCtrl,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                  decoration: _dec('500'),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              SizedBox(
                                width: 28,
                                child: _rows.length > 1
                                    ? GestureDetector(
                                        onTap: () => setState(() {
                                          row.dispose();
                                          _rows.removeAt(i);
                                        }),
                                        child: const Icon(
                                          Icons.remove_circle_outline,
                                          color: ColorConstants.errorRed,
                                          size: 20,
                                        ),
                                      )
                                    : const SizedBox(),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),

                  // Total row
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: ColorConstants.primaryBlue.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.textDark,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '₹${_total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.primaryBlue,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            Container(
              decoration: BoxDecoration(
                color: ColorConstants.pureWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: ColorConstants.shadowBlack.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: context.loc.additionalNotesOptional,
                  hintText: context.loc.anyRemarksAboutTheWorkDone,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sticky_note_2_outlined, size: 18),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Slide to end
            _SlideToEnd(isLoading: _submitting, onCompleted: _endJob),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    filled: true,
    fillColor: ColorConstants.backgroundColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    isDense: true,
  );
}

// ── Bill Row helper ────────────────────────────────────────────────────────

class _Row {
  final nameCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '1');
  final priceCtrl = TextEditingController();

  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }

  bool get isValid =>
      nameCtrl.text.trim().isNotEmpty && priceCtrl.text.trim().isNotEmpty;
}

// ── Slide to End ───────────────────────────────────────────────────────────

class _SlideToEnd extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onCompleted;

  const _SlideToEnd({required this.isLoading, required this.onCompleted});

  @override
  State<_SlideToEnd> createState() => _SlideToEndState();
}

class _SlideToEndState extends State<_SlideToEnd> {
  double _pos = 0;
  double _maxDrag = 0;
  bool _done = false;

  static const _thumbSize = 56.0;
  static const _trackHeight = 62.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Slide to End Job',
          style: TextStyle(
            fontSize: 13,
            color: ColorConstants.textGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (ctx, cons) {
            _maxDrag = cons.maxWidth - _thumbSize - 8;

            return Container(
              height: _trackHeight,
              decoration: BoxDecoration(
                color: ColorConstants.successTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: ColorConstants.successTeal.withOpacity(0.35),
                ),
              ),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Progress fill
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 50),
                    width: _thumbSize + _pos + 4,
                    decoration: BoxDecoration(
                      color: ColorConstants.successTeal.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(36),
                    ),
                  ),

                  // Label (fades as thumb moves)
                  Center(
                    child: AnimatedOpacity(
                      opacity: _pos > _maxDrag * 0.25 ? 0 : 1,
                      duration: const Duration(milliseconds: 120),
                      child: const Text(
                        '→  Slide to end job',
                        style: TextStyle(
                          fontSize: 14,
                          color: ColorConstants.successTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Draggable thumb
                  Positioned(
                    left: 4 + _pos,
                    child: GestureDetector(
                      onHorizontalDragUpdate: widget.isLoading
                          ? null
                          : (d) => setState(() {
                              _pos = (_pos + d.delta.dx).clamp(0, _maxDrag);
                            }),
                      onHorizontalDragEnd: widget.isLoading
                          ? null
                          : (_) {
                              if (_pos >= _maxDrag * 0.85) {
                                setState(() {
                                  _pos = _maxDrag;
                                  _done = true;
                                });
                                widget.onCompleted();
                              } else {
                                setState(() => _pos = 0);
                              }
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: _thumbSize,
                        height: _thumbSize,
                        decoration: BoxDecoration(
                          color: _done
                              ? ColorConstants.successGreen
                              : ColorConstants.successTeal,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: ColorConstants.successTeal.withOpacity(
                                0.4,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: widget.isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ColorConstants.pureWhite,
                                ),
                              )
                            : Icon(
                                _done ? Icons.check : Icons.chevron_right,
                                color: ColorConstants.pureWhite,
                                size: 28,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
