import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/features/jobs/repositories/job_repository.dart';
import 'package:voicesewa_worker/shared/models/job_model.dart';
import 'package:voicesewa_worker/shared/models/quotation_model.dart';

// ── Repository ─────────────────────────────────────────────────────────────

final jobRepositoryProvider = Provider<JobRepository>((_) => JobRepository());

// ── Current worker UID ────────────────────────────────────────────────────

final currentWorkerUidProvider = Provider<String>((ref) {
  return FirebaseAuth.instance.currentUser?.uid ?? '';
});

// ── Single job stream (live) ──────────────────────────────────────────────

final jobStreamProvider = StreamProvider.autoDispose.family<JobModel?, String>((
  ref,
  jobId,
) {
  return ref.watch(jobRepositoryProvider).watchJob(jobId);
});

// ── Incoming jobs ─────────────────────────────────────────────────────────
// Uses watchIncomingJobs() which holds live Firestore snapshots() listeners
// on the jobs/ collection per service type. New client jobs appear instantly
// without a refresh or app restart.
//
// NOT autoDispose — stream must survive tab switches.

final incomingJobsProvider = StreamProvider<List<JobModel>>((ref) {
  final uid = ref.watch(currentWorkerUidProvider);
  if (uid.isEmpty) return const Stream.empty();

  return ref.watch(jobRepositoryProvider).watchIncomingJobs(workerUid: uid);
});

// ── Declined jobs ─────────────────────────────────────────────────────────

final declinedJobsProvider = FutureProvider<List<JobModel>>((ref) async {
  final uid = ref.watch(currentWorkerUidProvider);
  if (uid.isEmpty) return [];
  return ref.watch(jobRepositoryProvider).fetchDeclinedJobs(uid);
});

// ── Applied jobs ──────────────────────────────────────────────────────────

final appliedJobsProvider = FutureProvider.autoDispose<List<JobModel>>((
  ref,
) async {
  final uid = ref.watch(currentWorkerUidProvider);
  if (uid.isEmpty) return [];
  return ref.watch(jobRepositoryProvider).fetchAppliedJobs(uid);
});

// ── Ongoing jobs (stream) ─────────────────────────────────────────────────

final ongoingJobsProvider = StreamProvider<List<JobModel>>((ref) {
  final uid = ref.watch(currentWorkerUidProvider);
  if (uid.isEmpty) return const Stream.empty();
  return ref.watch(jobRepositoryProvider).watchOngoingJobs(uid);
});

// ── Completed jobs (stream — first page only) ─────────────────────────────

final completedJobsProvider = StreamProvider<List<JobModel>>((ref) {
  final uid = ref.watch(currentWorkerUidProvider);
  if (uid.isEmpty) return const Stream.empty();
  return ref.watch(jobRepositoryProvider).watchCompletedJobs(uid);
});

// ── Load more completed jobs (lazy pagination) ────────────────────────────

final loadMoreCompletedProvider =
    Provider<
      Future<List<JobModel>> Function({required int alreadyLoadedCount})
    >((ref) {
      return ({required int alreadyLoadedCount}) async {
        final uid = ref.read(currentWorkerUidProvider);
        if (uid.isEmpty) return [];
        return ref
            .read(jobRepositoryProvider)
            .loadMoreCompleted(
              workerUid: uid,
              alreadyLoadedCount: alreadyLoadedCount,
            );
      };
    });

// ── Withdrawn jobs (stream — raw declined[] refs) ─────────────────────────

final withdrawnJobsProvider = StreamProvider.autoDispose<List<JobModel>>((ref) {
  final uid = ref.watch(currentWorkerUidProvider);
  if (uid.isEmpty) return const Stream.empty();
  return ref.watch(jobRepositoryProvider).watchWithdrawnJobs(uid);
});

// ── Truly withdrawn jobs (quotation.status == withdrawn only) ────────────
// declined[] contains BOTH rejected-by-client AND worker-withdrawn jobs.
// This provider fetches each declined job's quotation and keeps only those
// where the worker explicitly withdrew. Used by CompletedJobsTab for the
// accurate chip count and the withdrawn list.

final trueWithdrawnJobsProvider = FutureProvider.autoDispose<List<JobModel>>((
  ref,
) async {
  final uid = ref.watch(currentWorkerUidProvider);
  if (uid.isEmpty) return [];

  final repo = ref.read(jobRepositoryProvider);
  final allDeclined = await repo.fetchDeclinedJobs(uid);
  if (allDeclined.isEmpty) return [];

  final results = await Future.wait(
    allDeclined.map((job) async {
      final quo = await repo.fetchMyQuotation(jobId: job.jobId, workerUid: uid);
      return (quo != null && quo.isWithdrawn) ? job : null;
    }),
  );

  return results.whereType<JobModel>().toList();
});

// ── Incoming-tab declined jobs (excludes withdrawn) ───────────────────────
// declined[] in Firestore holds BOTH rejected-by-client AND worker-withdrawn
// jobs. This provider strips out withdrawn ones so the Declined chip in the
// Incoming tab never shows jobs the worker voluntarily withdrew from.

final incomingDeclinedJobsProvider = FutureProvider<List<JobModel>>((
  ref,
) async {
  final uid = ref.watch(currentWorkerUidProvider);
  if (uid.isEmpty) return [];

  final repo = ref.read(jobRepositoryProvider);
  final allDeclined = await repo.fetchDeclinedJobs(uid);
  if (allDeclined.isEmpty) return [];

  // Check each job's quotation — exclude any that are withdrawn
  final results = await Future.wait(
    allDeclined.map((job) async {
      final quo = await repo.fetchMyQuotation(jobId: job.jobId, workerUid: uid);
      // Keep if: no quotation (manual decline) OR quotation is rejected/auto-rejected
      // Exclude if: quotation is withdrawn
      if (quo != null && quo.isWithdrawn) return null;
      return job;
    }),
  );

  return results.whereType<JobModel>().toList();
});

// ── Submit quotation ──────────────────────────────────────────────────────

final submitQuotationProvider =
    Provider<
      Future<bool> Function({
        required String jobId,
        required QuotationModel quotation,
      })
    >((ref) {
      return ({required jobId, required quotation}) async {
        final uid = ref.read(currentWorkerUidProvider);
        if (uid.isEmpty) return false;
        final success = await ref
            .read(jobRepositoryProvider)
            .submitQuotation(
              jobId: jobId,
              quotation: quotation,
              workerUid: uid,
            );
        if (success) {
          ref.invalidate(incomingJobsProvider);
          ref.invalidate(appliedJobsProvider);
        }
        return success;
      };
    });

// ── Update quotation ──────────────────────────────────────────────────────

final updateQuotationProvider =
    Provider<
      Future<bool> Function({
        required String jobId,
        required String quotationId,
        required QuotationModel quotation,
      })
    >((ref) {
      return ({
        required jobId,
        required quotationId,
        required quotation,
      }) async {
        return ref
            .read(jobRepositoryProvider)
            .updateQuotation(
              jobId: jobId,
              quotationId: quotationId,
              quotation: quotation,
            );
      };
    });

// ── Withdraw quotation ────────────────────────────────────────────────────

final withdrawQuotationProvider =
    Provider<
      Future<bool> Function({
        required String jobId,
        required String quotationId,
        required String reason,
      })
    >((ref) {
      return ({required jobId, required quotationId, required reason}) async {
        final uid = ref.read(currentWorkerUidProvider);
        if (uid.isEmpty) return false;
        final success = await ref
            .read(jobRepositoryProvider)
            .withdrawQuotation(
              jobId: jobId,
              quotationId: quotationId,
              workerUid: uid,
              reason: reason,
            );
        if (success) {
          ref.invalidate(incomingJobsProvider);
          ref.invalidate(appliedJobsProvider);
          ref.invalidate(withdrawnJobsProvider);
          ref.invalidate(trueWithdrawnJobsProvider);
        }
        return success;
      };
    });

// ── Worker's quotation for a job ──────────────────────────────────────────

final myQuotationProvider = FutureProvider.autoDispose
    .family<QuotationModel?, (String, String)>((ref, args) async {
      final (jobId, workerUid) = args;
      if (jobId.isEmpty || workerUid.isEmpty) return null;
      return ref
          .watch(jobRepositoryProvider)
          .fetchMyQuotation(jobId: jobId, workerUid: workerUid);
    });

// ── Decline incoming job ──────────────────────────────────────────────────

final declineJobProvider = Provider<Future<bool> Function(String)>((ref) {
  return (jobId) async {
    final uid = ref.read(currentWorkerUidProvider);
    if (uid.isEmpty) return false;
    final success = await ref
        .read(jobRepositoryProvider)
        .declineJob(jobId: jobId, workerUid: uid);
    if (success) {
      ref.invalidate(incomingJobsProvider);
      ref.invalidate(declinedJobsProvider);
    }
    return success;
  };
});

// ── Client phone ──────────────────────────────────────────────────────────

final clientPhoneProvider = FutureProvider.autoDispose.family<String?, String>((
  ref,
  clientUid,
) async {
  if (clientUid.isEmpty) return null;
  return ref.watch(jobRepositoryProvider).fetchClientPhone(clientUid);
});

// ── Verify OTP ────────────────────────────────────────────────────────────

final verifyOtpProvider =
    Provider<
      Future<bool> Function({required String jobId, required String enteredOtp})
    >((ref) {
      return ({required jobId, required enteredOtp}) async {
        return ref
            .read(jobRepositoryProvider)
            .verifyOtp(jobId: jobId, enteredOtp: enteredOtp);
      };
    });

// ── Start job ─────────────────────────────────────────────────────────────

final startJobProvider = Provider<Future<bool> Function(String)>((ref) {
  return (jobId) => ref.read(jobRepositoryProvider).startJob(jobId: jobId);
});

// ── Save bill and complete ────────────────────────────────────────────────

final saveBillAndCompleteProvider =
    Provider<
      Future<bool> Function({required String jobId, required JobBill bill})
    >((ref) {
      return ({required jobId, required bill}) async {
        final uid = ref.read(currentWorkerUidProvider);
        if (uid.isEmpty) return false;
        return ref
            .read(jobRepositoryProvider)
            .saveBillAndComplete(jobId: jobId, workerUid: uid, bill: bill);
      };
    });

// ── Mark job complete (legacy) ────────────────────────────────────────────

final markJobCompletedProvider = Provider<Future<bool> Function(String)>((ref) {
  return (jobId) async {
    final uid = ref.read(currentWorkerUidProvider);
    if (uid.isEmpty) return false;
    return ref
        .read(jobRepositoryProvider)
        .markJobCompleted(jobId: jobId, workerUid: uid);
  };
});

// ── Save worker feedback ──────────────────────────────────────────────────

final saveWorkerFeedbackProvider =
    Provider<
      Future<bool> Function({
        required String jobId,
        required WorkerFeedback feedback,
      })
    >((ref) {
      return ({required jobId, required feedback}) async {
        return ref
            .read(jobRepositoryProvider)
            .saveWorkerFeedback(jobId: jobId, feedback: feedback);
      };
    });

// ── Chat messages stream ──────────────────────────────────────────────────
// Family key is (jobId, quotationId) — messages live at
// jobs/{jobId}/quotations/{quotationId}/messages per the DB schema.

final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, (String, String)>((ref, args) {
      final (jobId, quotationId) = args;
      return ref
          .watch(jobRepositoryProvider)
          .watchMessages(jobId: jobId, quotationId: quotationId)
          .map((snap) => snap.docs.map((d) => ChatMessage.fromDoc(d)).toList());
    });

// ── Send message ──────────────────────────────────────────────────────────

final sendMessageProvider =
    Provider<
      Future<bool> Function({
        required String jobId,
        required String quotationId,
        required String text,
        required String senderName,
      })
    >((ref) {
      return ({
        required jobId,
        required quotationId,
        required text,
        required senderName,
      }) async {
        final uid = ref.read(currentWorkerUidProvider);
        if (uid.isEmpty) return false;
        return ref
            .read(jobRepositoryProvider)
            .sendMessage(
              jobId: jobId,
              quotationId: quotationId,
              senderUid: uid,
              senderName: senderName,
              text: text,
              isWorker: true,
            );
      };
    });

// ── Chat message model ────────────────────────────────────────────────────

class ChatMessage {
  final String senderUid;
  final String senderName;
  final String text;
  final bool isWorker;
  final DateTime? sentAt;

  const ChatMessage({
    required this.senderUid,
    required this.senderName,
    required this.text,
    required this.isWorker,
    this.sentAt,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      senderUid: map['sender_uid'] as String? ?? '',
      senderName: map['sender_name'] as String? ?? '',
      text: map['text'] as String? ?? '',
      isWorker: map['is_worker'] as bool? ?? false,
      sentAt: (map['sent_at'] as Timestamp?)?.toDate(),
    );
  }
}
