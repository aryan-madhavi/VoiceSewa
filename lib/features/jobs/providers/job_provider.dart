import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/features/jobs/repositories/job_repository.dart';
import 'package:voicesewa_worker/features/profile/providers/worker_profile_provider.dart';
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
// NOT autoDispose — keeps the result alive across tab switches so we don't
// re-fetch every time the user navigates away and back.
// Uses workerProfileStreamProvider (already in memory) instead of a fresh
// getProfile() call, eliminating the sequential profile-fetch bottleneck.

final incomingJobsProvider = FutureProvider<List<JobModel>>((ref) async {
  final uid = ref.watch(currentWorkerUidProvider);
  if (uid.isEmpty) return [];

  // Read from the already-live profile stream — no extra network call.
  final worker = ref.watch(workerProfileStreamProvider(uid)).value;
  if (worker == null) return [];

  final location = worker.address?.location;
  if (location == null || worker.skills.isEmpty) return [];

  return ref
      .watch(jobRepositoryProvider)
      .fetchIncomingJobs(
        workerSkills: worker.skills,
        workerLocation: location,
        workerUid: uid,
      );
});

// ── Declined jobs ─────────────────────────────────────────────────────────

// NOT autoDispose — kept alive alongside incomingJobsProvider.
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

final ongoingJobsProvider = StreamProvider.autoDispose<List<JobModel>>((ref) {
  final uid = ref.watch(currentWorkerUidProvider);
  if (uid.isEmpty) return const Stream.empty();
  return ref.watch(jobRepositoryProvider).watchOngoingJobs(uid);
});

// ── Completed jobs (stream — first page only) ─────────────────────────────
// Streams the most recent 20 completed jobs.
// Older pages are loaded on demand via loadMoreCompletedProvider.

final completedJobsProvider = StreamProvider.autoDispose<List<JobModel>>((ref) {
  final uid = ref.watch(currentWorkerUidProvider);
  if (uid.isEmpty) return const Stream.empty();
  return ref.watch(jobRepositoryProvider).watchCompletedJobs(uid);
});

// ── Load more completed jobs (lazy pagination) ────────────────────────────
// Call this provider's function when the user scrolls to the bottom of the
// Completed tab. Pass [alreadyLoadedCount] = total jobs currently displayed
// (stream page + any previously loaded extra pages).
//
// Returns the next page of older jobs, or [] when there are no more.

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

// ── Withdrawn jobs (stream) ───────────────────────────────────────────────

final withdrawnJobsProvider = StreamProvider.autoDispose<List<JobModel>>((ref) {
  final uid = ref.watch(currentWorkerUidProvider);
  if (uid.isEmpty) return const Stream.empty();
  return ref.watch(jobRepositoryProvider).watchWithdrawnJobs(uid);
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
        }
        return success;
      };
    });

// ── Worker's quotation for a job ──────────────────────────────────────────

final myQuotationProvider = FutureProvider.autoDispose
    .family<QuotationModel?, String>((ref, jobId) async {
      final uid = ref.watch(currentWorkerUidProvider);
      if (uid.isEmpty) return null;
      return ref
          .watch(jobRepositoryProvider)
          .fetchMyQuotation(jobId: jobId, workerUid: uid);
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

final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, jobId) {
      return ref
          .watch(jobRepositoryProvider)
          .watchMessages(jobId)
          .map((snap) => snap.docs.map((d) => ChatMessage.fromDoc(d)).toList());
    });

// ── Send message ──────────────────────────────────────────────────────────

final sendMessageProvider =
    Provider<
      Future<bool> Function({
        required String jobId,
        required String text,
        required String senderName,
      })
    >((ref) {
      return ({required jobId, required text, required senderName}) async {
        final uid = ref.read(currentWorkerUidProvider);
        if (uid.isEmpty) return false;
        return ref
            .read(jobRepositoryProvider)
            .sendMessage(
              jobId: jobId,
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
