import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/features/jobs/presentation/widgets/my_job_card.dart';
import 'package:voicesewa_worker/features/jobs/providers/job_provider.dart';
import 'package:voicesewa_worker/features/profile/providers/worker_profile_provider.dart';
import 'package:voicesewa_worker/shared/models/job_model.dart';
import 'package:voicesewa_worker/shared/models/quotation_model.dart';

class JobDetailPage extends ConsumerStatefulWidget {
  final JobModel job;
  final JobTabType tabType;

  const JobDetailPage({super.key, required this.job, required this.tabType});

  @override
  ConsumerState<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends ConsumerState<JobDetailPage> {
  bool _showQuotationForm = false;

  @override
  Widget build(BuildContext context) {
    final location   = widget.job.address.location;
    final hasLocation = location != null;

    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.job.serviceName,       // ← serviceName (display) not serviceType (enum)
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: ColorConstants.textDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),

            _buildSection(
              title: 'Job Details',
              icon: Icons.description_outlined,
              child: _buildJobDetails(),
            ),
            const SizedBox(height: 16),

            _buildSection(
              title: 'Client Location',
              icon: Icons.location_on_outlined,
              child: _buildLocationSection(hasLocation, location),
            ),
            const SizedBox(height: 16),

            if (widget.tabType == JobTabType.incoming) ...[
              _buildQuotationSection(),
              const SizedBox(height: 16),
            ],

            if (widget.tabType == JobTabType.ongoing) ...[
              _buildMarkCompleteButton(),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Status card ───────────────────────────────────────────────────────────

  Widget _buildStatusCard() {
    // Use model's own getters — no hardcoded maps needed
    final color = widget.job.statusColor;
    final label = widget.job.statusLabel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 4, height: 40,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 14),
          // Service icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.job.serviceColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.job.serviceIcon, size: 18, color: widget.job.serviceColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Job #${widget.job.jobId.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(fontSize: 12, color: ColorConstants.textGrey, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.job.serviceName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ColorConstants.textDark),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section wrapper ───────────────────────────────────────────────────────

  Widget _buildSection({required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 18, color: ColorConstants.primaryBlue),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ColorConstants.textDark)),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Divider(height: 1)),
          child,
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Job details ───────────────────────────────────────────────────────────

  Widget _buildJobDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow(Icons.build_outlined, 'Service', widget.job.serviceName),
          if (widget.job.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            _detailRow(Icons.notes_outlined, 'Description', widget.job.description),
          ],
          if (widget.job.createdAt != null) ...[
            const SizedBox(height: 10),
            _detailRow(Icons.access_time, 'Posted', _formatDateTime(widget.job.createdAt!)),
          ],
          if (widget.job.scheduledAt != null) ...[
            const SizedBox(height: 10),
            _detailRow(Icons.event_outlined, 'Scheduled', _formatDateTime(widget.job.scheduledAt!)),
          ],
          if (widget.job.finalizedQuotationAmount != null) ...[
            const SizedBox(height: 10),
            _detailRow(
              Icons.payments_outlined,
              'Agreed Amount',
              '₹${widget.job.finalizedQuotationAmount!.toStringAsFixed(0)}',
              valueColor: ColorConstants.primaryBlue,
              valueBold: true,
            ),
          ],
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? valueColor, bool valueBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: ColorConstants.textGrey),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(label, style: const TextStyle(fontSize: 13, color: ColorConstants.textGrey)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: valueColor ?? ColorConstants.textDark,
              fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  // ── Location + map ────────────────────────────────────────────────────────

  Widget _buildLocationSection(bool hasLocation, GeoPoint? location) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // City + pincode from address model
          if (widget.job.address.displayAddress.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_outlined, size: 15, color: ColorConstants.textGrey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.job.address.displayAddress,
                    style: const TextStyle(fontSize: 13, color: ColorConstants.textDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (hasLocation) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 200,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(location!.latitude, location.longitude),
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.voicesewa.worker',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(location.latitude, location.longitude),
                          width: 40, height: 40,
                          child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new, size: 16),
                onPressed: () => _openInMaps(location),
                label: const Text('Open in Maps'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorConstants.primaryBlue,
                  side: BorderSide(color: ColorConstants.primaryBlue.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ] else
            const Text('Location not provided', style: TextStyle(fontSize: 13, color: ColorConstants.textGrey)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _openInMaps(GeoPoint location) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}',
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ── Quotation section ─────────────────────────────────────────────────────

  Widget _buildQuotationSection() {
    final existingQuotation = ref.watch(myQuotationProvider(widget.job.jobId));
    return existingQuotation.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
      error: (_, __) => _buildSubmitQuotationTile(),
      data: (quotation) =>
          quotation != null ? _buildExistingQuotationCard(quotation) : _buildSubmitQuotationTile(),
    );
  }

  Widget _buildExistingQuotationCard(QuotationModel quotation) {
    final statusColor = {
      QuotationStatus.submitted: Colors.orange,
      QuotationStatus.accepted:  Colors.green,
      QuotationStatus.rejected:  Colors.red,
      QuotationStatus.withdrawn: Colors.grey,
    }[quotation.status] ?? Colors.orange;

    return _buildSection(
      title: 'Your Quotation',
      icon: Icons.request_quote_outlined,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${quotation.estimatedCost}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ColorConstants.primaryBlue),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    quotation.status.value.toUpperCase(),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _detailRow(Icons.timer_outlined, 'Est. Time', quotation.estimatedTime),
            if (quotation.availability.isNotEmpty) ...[
              const SizedBox(height: 8),
              _detailRow(Icons.event_available_outlined, 'Available', quotation.availability),
            ],
            if (quotation.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              _detailRow(Icons.notes_outlined, 'Details', quotation.description),
            ],
            if (quotation.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              _detailRow(Icons.sticky_note_2_outlined, 'Notes', quotation.notes),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitQuotationTile() {
    return _buildSection(
      title: 'Submit Quotation',
      icon: Icons.request_quote_outlined,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            if (!_showQuotationForm) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'Submit your quotation to apply for this job. The client will review it and may accept your offer.',
                  style: TextStyle(fontSize: 13, color: ColorConstants.textGrey),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  onPressed: () => setState(() => _showQuotationForm = true),
                  label: const Text('Submit Quotation', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ] else
              _QuotationForm(
                jobId: widget.job.jobId,
                onCancel: () => setState(() => _showQuotationForm = false),
                onSubmitted: () {
                  setState(() => _showQuotationForm = false);
                  ref.invalidate(myQuotationProvider(widget.job.jobId));
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── Mark completed ────────────────────────────────────────────────────────

  Widget _buildMarkCompleteButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.task_alt, size: 18, color: Color(0xFF00BFA5)),
              SizedBox(width: 8),
              Text('Job Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ColorConstants.textDark)),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline, size: 18),
              onPressed: _confirmMarkComplete,
              label: const Text('Mark as Completed', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmMarkComplete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark as Completed?'),
        content: const Text('Confirm that you have finished this job. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BFA5), foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(markJobCompletedProvider)(widget.job.jobId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? '✅ Job marked as completed!' : '❌ Failed. Please try again.'),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
        if (success) Navigator.of(context).pop();
      }
    }
  }

  // ── Date helpers ──────────────────────────────────────────────────────────

  String _formatDateTime(DateTime dt) {
    const m = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${m[dt.month]} ${dt.year}, $h:$min $period';
  }
}

// ── Quotation Form ─────────────────────────────────────────────────────────

class _QuotationForm extends ConsumerStatefulWidget {
  final String jobId;
  final VoidCallback onCancel;
  final VoidCallback onSubmitted;

  const _QuotationForm({required this.jobId, required this.onCancel, required this.onSubmitted});

  @override
  ConsumerState<_QuotationForm> createState() => _QuotationFormState();
}

class _QuotationFormState extends ConsumerState<_QuotationForm> {
  final _formKey             = GlobalKey<FormState>();
  final _costController       = TextEditingController();
  final _timeController       = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController      = TextEditingController();
  final _availabilityController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _costController.dispose();
    _timeController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _availabilityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field(controller: _costController,         label: 'Estimated Cost (₹)',  hint: 'e.g. 1500',              icon: Icons.currency_rupee,           keyboardType: TextInputType.number, required: true),
          const SizedBox(height: 12),
          _field(controller: _timeController,         label: 'Estimated Time',       hint: 'e.g. 2-3 hours',         icon: Icons.timer_outlined,           required: true),
          const SizedBox(height: 12),
          _field(controller: _availabilityController, label: 'Your Availability',    hint: 'e.g. Tomorrow 10 AM',    icon: Icons.event_available_outlined, required: true),
          const SizedBox(height: 12),
          _field(controller: _descriptionController,  label: 'Work Description',     hint: 'Describe what you\'ll do...', icon: Icons.description_outlined, maxLines: 3, required: true),
          const SizedBox(height: 12),
          _field(controller: _notesController,        label: 'Additional Notes (optional)', hint: 'Any extra info...', icon: Icons.sticky_note_2_outlined,  maxLines: 2),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Submit Quotation', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _field({
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
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: ColorConstants.backgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final uid     = ref.read(currentWorkerUidProvider);
      final profile = ref.read(workerProfileStreamProvider(uid)).value;

      final quotation = QuotationModel(
        quotationId:   '',
        jobId:         widget.jobId,
        workerUid:     uid,
        workerName:    profile?.name ?? '',
        workerRating:  profile?.avgRating ?? 0.0,
        estimatedCost: _costController.text.trim(),
        estimatedTime: _timeController.text.trim(),
        description:   _descriptionController.text.trim(),
        notes:         _notesController.text.trim(),
        availability:  _availabilityController.text.trim(),
      );

      final success = await ref.read(submitQuotationProvider)(
        jobId: widget.jobId,
        quotation: quotation,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? '✅ Quotation submitted!' : '❌ Failed. Please try again.'),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
        if (success) widget.onSubmitted();
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}