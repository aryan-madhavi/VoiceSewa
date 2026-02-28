import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/core/constants/color_constants.dart';
import 'package:voicesewa_client/core/extensions/context_extensions.dart';
import 'package:voicesewa_client/features/quotations/prsentation/quotations_screen.dart';
import 'package:voicesewa_client/features/jobs/presentation/widgets/job_detail_widgets.dart';
import 'package:voicesewa_client/features/jobs/providers/job_provider.dart';
import 'package:voicesewa_client/features/quotations/providers/quotation_provider.dart';
import 'package:voicesewa_client/shared/models/job_model.dart';

class JobDetailsScreen extends ConsumerWidget {
  final String jobId;

  const JobDetailsScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobProvider(jobId));

    return Scaffold(
      backgroundColor: ColorConstants.scaffold,
      appBar: AppBar(
        title: Text(context.loc.jobDetails),
        backgroundColor: ColorConstants.appBar,
      ),
      body: jobAsync.when(
        data: (job) {
          if (job == null) {
            return Center(child: Text(context.loc.jobNotFound));
          }
          return _JobDetailsContent(job: job);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _JobDetailsContent extends ConsumerWidget {
  final Job job;

  const _JobDetailsContent({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unviewedCountAsync = ref.watch(
      unviewedQuotationsCountProvider(job.id),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Service Info Card (includes worker name/rating when assigned)
          ServiceInfoCard(job: job),
          const SizedBox(height: 16),

          // ✅ In-Progress banner — shown only when job is inProgress
          if (job.isInProgress) ...[
            JobInProgressBanner(job: job),
            const SizedBox(height: 16),
          ],

          // ✅ OTP Card — shown only when job is scheduled (not inProgress)
          if (job.isScheduled && job.otp != null) ...[
            JobOtpCard(otp: job.otp!),
            const SizedBox(height: 16),
          ],

          // Job Description Card
          JobDescriptionCard(description: job.description),
          const SizedBox(height: 16),

          // Address Card
          JobAddressCard(fullAddress: job.address.fullAddress),
          const SizedBox(height: 16),

          // Dates Card
          JobDatesCard(
            createdDate: job.formattedCreatedDate,
            scheduledDate: job.formattedScheduledDate,
          ),
          const SizedBox(height: 16),

          // ✅ Bill Card — always shown after job is completed
          if (job.isCompleted) ...[
            JobBillCard(bill: job.bill),
            const SizedBox(height: 16),
          ],

          // ✅ Feedback Card — shown when job is completed
          if (job.isCompleted) ...[
            JobFeedbackCard(
              existingFeedback: job.clientFeedback,
              onSubmit: (rating, comment) =>
                  _submitFeedback(context, ref, job.id, rating, comment),
            ),
            const SizedBox(height: 16),
          ],

          // Action Buttons
          unviewedCountAsync.when(
            data: (unviewedCount) => JobActionButtons(
              job: job,
              unviewedQuotationsCount: unviewedCount,
              onViewQuotations: () => _navigateToQuotations(context),
              onCancel: () => _showCancelDialog(context, ref, job.id),
              onReschedule: () => _showRescheduleDialog(context, ref, job.id),
            ),
            loading: () => JobActionButtons(
              job: job,
              onViewQuotations: () => _navigateToQuotations(context),
              onCancel: () => _showCancelDialog(context, ref, job.id),
              onReschedule: () => _showRescheduleDialog(context, ref, job.id),
            ),
            error: (_, __) => JobActionButtons(
              job: job,
              onViewQuotations: () => _navigateToQuotations(context),
              onCancel: () => _showCancelDialog(context, ref, job.id),
              onReschedule: () => _showRescheduleDialog(context, ref, job.id),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitFeedback(
    BuildContext context,
    WidgetRef ref,
    String jobId,
    double rating,
    String comment,
  ) async {
    try {
      final actions = ref.read(jobActionsProvider);
      await actions.submitClientFeedback(jobId, rating, comment);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.loc.thankYouForYourFeedback),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  void _navigateToQuotations(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuotationsScreen(jobId: job.id)),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, String jobId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.loc.cancelJob),
        content: Text(context.loc.areYouSureYouWantToCancelThisJob),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.loc.no),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final actions = ref.read(jobActionsProvider);
                await actions.cancelJob(jobId, 'Cancelled by client');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.loc.jobCancelled)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text(context.loc.yesCancel),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(
    BuildContext context,
    WidgetRef ref,
    String jobId,
  ) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.loc.rescheduleJob),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.loc.selectNewDate),
            SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  selectedDate = date;
                }
              },
              child: Text(
                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.loc.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final actions = ref.read(jobActionsProvider);
                await actions.rescheduleJob(jobId, selectedDate);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.loc.jobRescheduled)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text(context.loc.confirm),
          ),
        ],
      ),
    );
  }
}
