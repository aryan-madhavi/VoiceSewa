import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/features/jobs/presentation/bill_form_page.dart';
import 'package:voicesewa_worker/features/jobs/presentation/chat_page.dart';
import 'package:voicesewa_worker/features/jobs/presentation/otp_verification_page.dart';
import 'package:voicesewa_worker/features/jobs/presentation/widgets/my_job_card.dart';
import 'package:voicesewa_worker/features/jobs/providers/job_provider.dart';
import 'package:voicesewa_worker/shared/models/job_model.dart';
import 'package:voicesewa_worker/shared/models/quotation_model.dart';
import 'widgets/job_status_card.dart';
import 'widgets/job_info_section.dart';
import 'widgets/job_location_section.dart';
import 'widgets/job_quotation_section.dart';

class JobDetailPage extends ConsumerStatefulWidget {
  final JobModel job;
  final JobTabType tabType;
  // Passed directly from the declined list so we never depend on async
  // quotation fetch for basic display decisions (badge, amount, etc.)
  final bool isDeclinedEntry;

  const JobDetailPage({
    super.key,
    required this.job,
    required this.tabType,
    this.isDeclinedEntry = false,
  });

  @override
  ConsumerState<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends ConsumerState<JobDetailPage> {
  // Always holds the freshest job — updated via ref.listen so we never
  // revert to the stale widget.job snapshot even when autoDispose fires
  // (e.g. while OtpVerificationPage is on top of the nav stack).
  late JobModel _liveJob;

  // Prevents the feedback popup firing more than once per page session.
  bool _feedbackShownOnce = false;

  @override
  void initState() {
    super.initState();
    _liveJob = widget.job;
  }

  @override
  Widget build(BuildContext context) {
    // ref.listen keeps _liveJob in sync without causing a double rebuild.
    ref.listen<AsyncValue<JobModel?>>(jobStreamProvider(widget.job.jobId), (
      _,
      next,
    ) {
      final updated = next.value;
      if (updated != null && mounted) {
        setState(() => _liveJob = updated);
      }
    });

    // ref.watch drives rebuilds when stream emits; _liveJob is the fallback
    // until the first stream value arrives (or after autoDispose).
    final jobAsync = ref.watch(jobStreamProvider(widget.job.jobId));
    JobModel job = jobAsync.value ?? _liveJob;

    // ── Display override ──────────────────────────────────────────────────
    final workerUid = ref.watch(currentWorkerUidProvider);
    final myQuo = ref.watch(myQuotationProvider((job.jobId, workerUid)));

    if (widget.tabType == JobTabType.incoming) {
      // Worker B who hasn't quoted yet should see "requested" not "quoted"
      if (job.isQuoted && myQuo.value == null && !myQuo.isLoading) {
        job = job.copyWith(status: JobStatusType.requested);
      }
    }

    // A declined job may have any real status (scheduled/completed/etc.)
    // depending on what happened — gate all action cards behind isDeclined.
    // widget.isDeclinedEntry is set by the card so we don't flicker while
    // myQuo is still loading on page open.
    final isDeclined =
        widget.isDeclinedEntry ||
        (widget.tabType == JobTabType.incoming &&
            _isDeclinedJob(job, myQuo.value));

    final isScheduled = !isDeclined && job.status == JobStatusType.scheduled;
    final isInProgress = !isDeclined && job.status == JobStatusType.inProgress;
    final isCompleted = !isDeclined && job.status == JobStatusType.completed;

    // Auto-popup: fires once when the live stream delivers completed status
    // and the worker hasn't left feedback yet.
    if (isCompleted && !isDeclined && !job.hasFeedback && !_feedbackShownOnce) {
      _feedbackShownOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showFeedbackSheet(context, job);
      });
    }

    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          job.serviceName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: ColorConstants.pureWhite,
        foregroundColor: ColorConstants.textDark,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (isScheduled || isInProgress)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                tooltip: 'Call client',
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: ColorConstants.successGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.call,
                    color: ColorConstants.successGreen,
                    size: 20,
                  ),
                ),
                onPressed: () => _callClient(context, ref, job),
              ),
            ),
          if (isCompleted)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                tooltip: job.hasFeedback ? 'Edit feedback' : 'Leave feedback',
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: ColorConstants.ratingAmber.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    job.hasFeedback ? Icons.star : Icons.star_outline,
                    color: ColorConstants.ratingAmberDark,
                    size: 20,
                  ),
                ),
                onPressed: () => _showFeedbackSheet(context, job),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            JobStatusCard(job: job, isDeclined: isDeclined),
            const SizedBox(height: 16),

            JobInfoSection(job: job, isDeclined: isDeclined),
            const SizedBox(height: 16),

            JobLocationSection(job: job),
            const SizedBox(height: 16),

            // ── Incoming tab ──────────────────────────────────────────────

            // Declined info card — auto-rejected or manually declined
            // Shows reason only, hides all actions
            if (widget.tabType == JobTabType.incoming &&
                _isDeclinedJob(job, myQuo.value)) ...[
              _DeclinedInfoCard(quotation: myQuo.value),
              const SizedBox(height: 16),
            ],

            // Cancelled banner — client cancelled after worker quoted
            if (widget.tabType == JobTabType.incoming &&
                job.isCancelled &&
                !_isDeclinedJob(job, myQuo.value)) ...[
              _CancelledJobBanner(),
              const SizedBox(height: 16),
            ],

            // Decline/quotation actions — only for still-open jobs
            if (widget.tabType == JobTabType.incoming &&
                (job.isRequested || job.isQuoted))
              _AcceptRejectGate(job: job),

            // Quotation section — requested/quoted jobs only
            if (widget.tabType == JobTabType.incoming &&
                (job.isRequested || job.isQuoted)) ...[
              const SizedBox(height: 16),
              JobQuotationSection(jobId: job.jobId, jobStatus: job.status),
              const SizedBox(height: 16),
            ],

            // Chat with client — only when job is quoted and worker has a quotation
            if (widget.tabType == JobTabType.incoming && job.isQuoted) ...[
              _QuotedChatCard(job: job),
              const SizedBox(height: 16),
            ],

            // ── Scheduled → Start Job (today only) ───────────────────────
            if (isScheduled) ...[
              _ScheduledActionsCard(
                key: ValueKey('sched_${job.jobId}'),
                job: job,
              ),
              const SizedBox(height: 16),
            ],

            // ── In Progress → End Job; NO start-job button ────────────────
            if (isInProgress) ...[
              _InProgressActionsCard(
                key: ValueKey('prog_${job.jobId}'),
                job: job,
              ),
              const SizedBox(height: 16),
            ],

            // ── Completed ─────────────────────────────────────────────────
            if (isCompleted) ...[
              _CompletedSummaryCard(
                job: job,
                onFeedback: () => _showFeedbackSheet(context, job),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // A job is in the "declined" bucket if:
  // - worker manually declined (no quotation, job in declined[])
  // - auto-rejected (quotation exists, auto_rejected == true)
  // - quotation was rejected by client (status == rejected)
  bool _isDeclinedJob(JobModel job, QuotationModel? quotation) {
    if (quotation == null) {
      return job.isScheduled ||
          job.status == JobStatusType.completed ||
          job.isCancelled;
    }
    return quotation.isRejected || quotation.isWithdrawn;
  }

  Future<void> _callClient(
    BuildContext context,
    WidgetRef ref,
    JobModel job,
  ) async {
    String? phone = job.clientPhone;
    if (phone == null || phone.isEmpty) {
      phone = await ref
          .read(jobRepositoryProvider)
          .fetchClientPhone(job.clientUid);
    }
    if (phone == null || phone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client phone number not available'),
            backgroundColor: ColorConstants.errorRed,
          ),
        );
      }
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _showFeedbackSheet(BuildContext context, JobModel job) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      builder: (_) => _FeedbackSheet(job: job),
    );
  }
}

// ── Accept / Decline gate ─────────────────────────────────────────────────

class _AcceptRejectGate extends ConsumerWidget {
  final JobModel job;
  const _AcceptRejectGate({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workerUid = ref.watch(currentWorkerUidProvider);
    final quotationAsync = ref.watch(
      myQuotationProvider((job.jobId, workerUid)),
    );
    if (quotationAsync.isLoading) return const SizedBox.shrink();
    final hasQuotation = quotationAsync.value != null;
    if (hasQuotation) return const SizedBox.shrink();

    return Column(
      children: [
        _AcceptRejectCard(job: job),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Accept / Decline card ──────────────────────────────────────────────────

class _AcceptRejectCard extends ConsumerStatefulWidget {
  final JobModel job;
  const _AcceptRejectCard({super.key, required this.job});

  @override
  ConsumerState<_AcceptRejectCard> createState() => _AcceptRejectCardState();
}

class _AcceptRejectCardState extends ConsumerState<_AcceptRejectCard> {
  bool _declining = false;

  Future<void> _decline() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Decline Job?'),
        content: const Text(
          'This job will be removed from your incoming list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.errorRed,
              foregroundColor: ColorConstants.pureWhite,
            ),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _declining = true);
    final ok = await ref.read(declineJobProvider)(widget.job.jobId);
    if (!mounted) return;
    setState(() => _declining = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '✅ Job declined' : '❌ Failed. Try again.'),
        backgroundColor: ok
            ? ColorConstants.warningOrange
            : ColorConstants.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.handshake_outlined,
                size: 18,
                color: ColorConstants.primaryBlue,
              ),
              SizedBox(width: 8),
              Text(
                'Job Actions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.textDark,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          const Text(
            'Submit your quotation to apply for this job, or decline if you\'re not interested.',
            style: TextStyle(fontSize: 13, color: ColorConstants.textGrey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: _declining
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.close, size: 16),
              label: Text(_declining ? 'Declining...' : 'Not Interested'),
              onPressed: _declining ? null : _decline,
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstants.errorRed,
                side: BorderSide(
                  color: ColorConstants.errorRed.withOpacity(0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quoted chat card ───────────────────────────────────────────────────────

class _QuotedChatCard extends ConsumerWidget {
  final JobModel job;
  const _QuotedChatCard({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workerUid = ref.watch(currentWorkerUidProvider);
    final quotationAsync = ref.watch(
      myQuotationProvider((job.jobId, workerUid)),
    );

    // Don't show if quotation is loading or absent
    if (quotationAsync.isLoading) return const SizedBox.shrink();
    final quo = quotationAsync.value;
    if (quo == null) return const SizedBox.shrink();

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: ColorConstants.primaryBlue,
              ),
              SizedBox(width: 8),
              Text(
                'Client Communication',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.textDark,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: const Text('Chat with Client'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ChatPage(job: job, quotationId: quo.quotationId),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstants.primaryBlue,
                side: BorderSide(
                  color: ColorConstants.primaryBlue.withOpacity(0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scheduled actions card ─────────────────────────────────────────────────

class _ScheduledActionsCard extends StatelessWidget {
  final JobModel job;
  const _ScheduledActionsCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final canStart = job.isScheduledToday;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.task_alt, size: 18, color: ColorConstants.primaryBlue),
              SizedBox(width: 8),
              Text(
                'Job Actions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.textDark,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: const Text('Chat with Client'),
              // ── FIX: messages path = jobs/{jobId}/quotations/{quotationId}/messages
              // job.finalizedQuotationId is always set for scheduled jobs
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    job: job,
                    quotationId: job.finalizedQuotationId ?? '',
                  ),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstants.primaryBlue,
                side: BorderSide(
                  color: ColorConstants.primaryBlue.withOpacity(0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_circle_outline, size: 18),
              label: Text(
                canStart ? 'Start Job' : 'Available on Scheduled Day',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: canStart
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OtpVerificationPage(job: job),
                      ),
                    )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.successTeal,
                foregroundColor: ColorConstants.pureWhite,
                disabledBackgroundColor: ColorConstants.disabledGrey,
                disabledForegroundColor: ColorConstants.textGrey,
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          if (!canStart && job.scheduledAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 13,
                  color: ColorConstants.textGrey,
                ),
                const SizedBox(width: 6),
                Text(
                  'Scheduled for ${job.formattedScheduledDate}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ColorConstants.textGrey,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── In-Progress actions card ───────────────────────────────────────────────

class _InProgressActionsCard extends StatelessWidget {
  final JobModel job;
  const _InProgressActionsCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.task_alt, size: 18, color: ColorConstants.successTeal),
              SizedBox(width: 8),
              Text(
                'Job In Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.textDark,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: ColorConstants.successTeal.withOpacity(0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: ColorConstants.successTeal,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Job is currently in progress',
                  style: TextStyle(
                    fontSize: 13,
                    color: ColorConstants.successTeal,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: const Text('Chat with Client'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    job: job,
                    quotationId: job.finalizedQuotationId ?? '',
                  ),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstants.primaryBlue,
                side: BorderSide(
                  color: ColorConstants.primaryBlue.withOpacity(0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: const Text(
                'Generate Bill & End Job',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => BillFormPage(job: job))),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.successTeal,
                foregroundColor: ColorConstants.pureWhite,
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Completed summary card ─────────────────────────────────────────────────

class _CompletedSummaryCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onFeedback;
  const _CompletedSummaryCard({required this.job, required this.onFeedback});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 18,
                color: ColorConstants.successGreen,
              ),
              SizedBox(width: 8),
              Text(
                'Job Completed',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.textDark,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          if (job.bill != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Final Bill Amount',
                  style: TextStyle(
                    fontSize: 13,
                    color: ColorConstants.textGrey,
                  ),
                ),
                Text(
                  '₹${job.bill!.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          if (job.hasFeedback) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorConstants.ratingAmber.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ColorConstants.ratingAmber.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: ColorConstants.ratingAmber,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Your Feedback',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.ratingAmberDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < job.workerFeedback!.rating
                            ? Icons.star
                            : Icons.star_border,
                        size: 20,
                        color: ColorConstants.ratingAmber,
                      );
                    }),
                  ),
                  if (job.workerFeedback!.comment.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      job.workerFeedback!.comment,
                      style: const TextStyle(
                        fontSize: 13,
                        color: ColorConstants.textGrey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit Feedback'),
                onPressed: onFeedback,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorConstants.ratingAmberDark,
                  side: BorderSide(
                    color: ColorConstants.ratingAmber.withOpacity(0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorConstants.ratingAmber.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ColorConstants.ratingAmber.withOpacity(0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star_outline,
                    color: ColorConstants.ratingAmberDark,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'How was your experience? Leave feedback to help the community.',
                      style: TextStyle(
                        fontSize: 13,
                        color: ColorConstants.textGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.star_outline, size: 18),
                label: const Text(
                  'Leave Feedback',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: onFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.ratingAmberDark,
                  foregroundColor: ColorConstants.pureWhite,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Declined info card ─────────────────────────────────────────────────────

class _DeclinedInfoCard extends StatelessWidget {
  final QuotationModel? quotation;
  const _DeclinedInfoCard({this.quotation});

  @override
  Widget build(BuildContext context) {
    final quo = quotation;

    String reasonTitle;
    String reasonBody;

    if (quo == null) {
      reasonTitle = 'Job Declined';
      reasonBody = 'You declined this job without submitting a quotation.';
    } else if (quo.autoRejected == true) {
      reasonTitle = 'Quotation Auto-Rejected by System';
      reasonBody =
          'Another worker\'s quotation was accepted by the client. '
          'Your quotation was automatically rejected.';
    } else if (quo.isRejected) {
      reasonTitle = 'Quotation Rejected';
      reasonBody = quo.rejectionReason?.isNotEmpty == true
          ? quo.rejectionReason!
          : 'The client did not select your quotation.';
    } else if (quo.isWithdrawn) {
      reasonTitle = 'Quotation Withdrawn';
      reasonBody = quo.withdrawalReason?.isNotEmpty == true
          ? quo.withdrawalReason!
          : 'You withdrew your quotation.';
    } else {
      reasonTitle = 'Declined';
      reasonBody = 'This job is no longer available.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.errorRed.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorConstants.errorRed.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.block_outlined,
                color: ColorConstants.errorRed,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                reasonTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: ColorConstants.errorRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reasonBody,
            style: const TextStyle(
              fontSize: 13,
              color: ColorConstants.textGrey,
              height: 1.4,
            ),
          ),
          if (quo != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            if (quo.createdAt != null)
              _DateRow(
                icon: Icons.send_outlined,
                label: 'Submitted',
                date: quo.createdAt!,
              ),
            if (quo.rejectedAt != null) ...[
              const SizedBox(height: 6),
              _DateRow(
                icon: Icons.cancel_outlined,
                label: 'Rejected',
                date: quo.rejectedAt!,
              ),
            ],
            if (quo.withdrawnAt != null) ...[
              const SizedBox(height: 6),
              _DateRow(
                icon: Icons.undo_outlined,
                label: 'Withdrawn',
                date: quo.withdrawnAt!,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime date;
  const _DateRow({required this.icon, required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    final d = date;
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final formatted =
        '${d.day} ${months[d.month]}, ${d.year}  '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return Row(
      children: [
        Icon(icon, size: 14, color: ColorConstants.textGrey),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ColorConstants.textGrey,
          ),
        ),
        Text(
          formatted,
          style: const TextStyle(fontSize: 12, color: ColorConstants.textGrey),
        ),
      ],
    );
  }
}

// ── Cancelled job banner ───────────────────────────────────────────────────

class _CancelledJobBanner extends StatelessWidget {
  const _CancelledJobBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.errorRed.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorConstants.errorRed.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.cancel_outlined,
            color: ColorConstants.errorRed,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Job Cancelled by Client',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: ColorConstants.errorRed,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'The client has cancelled this job. Your quotation is no longer active.',
                  style: TextStyle(
                    fontSize: 13,
                    color: ColorConstants.textGrey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feedback Bottom Sheet ──────────────────────────────────────────────────

class _FeedbackSheet extends ConsumerStatefulWidget {
  final JobModel job;
  const _FeedbackSheet({required this.job});

  @override
  ConsumerState<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends ConsumerState<_FeedbackSheet> {
  late double _rating;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.job.workerFeedback?.rating ?? 0;
    _commentCtrl.text = widget.job.workerFeedback?.comment ?? '';
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: ColorConstants.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _submitting = true);

    final ok = await ref.read(saveWorkerFeedbackProvider)(
      jobId: widget.job.jobId,
      feedback: WorkerFeedback(
        rating: _rating,
        comment: _commentCtrl.text.trim(),
      ),
    );

    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '✅ Feedback submitted, thank you!'
              : '❌ Failed to submit. Please try again.',
        ),
        backgroundColor: ok
            ? ColorConstants.successGreen
            : ColorConstants.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.job.hasFeedback;

    return Container(
      decoration: const BoxDecoration(
        color: ColorConstants.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorConstants.dividerGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.star, color: ColorConstants.ratingAmberDark, size: 22),
              const SizedBox(width: 10),
              Text(
                isEdit ? 'Edit Your Feedback' : 'Rate This Job',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.job.serviceName,
            style: const TextStyle(
              fontSize: 13,
              color: ColorConstants.textGrey,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'How was your experience with this client?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: ColorConstants.textDark,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starVal = (i + 1).toDouble();
              return GestureDetector(
                onTap: () => setState(() => _rating = starVal),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      _rating >= starVal ? Icons.star : Icons.star_border,
                      key: ValueKey('$i-${_rating >= starVal}'),
                      size: 42,
                      color: _rating >= starVal
                          ? ColorConstants.ratingAmber
                          : ColorConstants.dividerGrey,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              _ratingLabel(_rating),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _rating > 0
                    ? ColorConstants.ratingAmberDark
                    : ColorConstants.textGrey,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Additional Comments (optional)',
              hintText: 'e.g. Great client, clear instructions...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: ColorConstants.backgroundColor,
              prefixIcon: const Icon(Icons.comment_outlined, size: 18),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.ratingAmberDark,
                foregroundColor: ColorConstants.pureWhite,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ColorConstants.pureWhite,
                      ),
                    )
                  : Text(
                      isEdit ? 'Update Feedback' : 'Submit Feedback',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _ratingLabel(double r) {
    if (r == 0) return 'Tap to rate';
    if (r == 1) return 'Poor';
    if (r == 2) return 'Fair';
    if (r == 3) return 'Good';
    if (r == 4) return 'Very Good';
    return 'Excellent!';
  }
}
