// lib/features/translate_call/application/providers.dart
//
// Providers scoped to the translate_call feature.
// Firebase singletons (firebaseAuthProvider, firestoreProvider,
// currentUserProvider) live in auth/application/auth_providers.dart
// and are imported from there — this file never re-declares them.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/providers.dart';
import '../data/call_history_repository.dart';
import '../../auth/data/fcm_service.dart';
import '../data/notification_service.dart';
import '../data/translate_call_repository.dart';
import '../domain/call_history_entry.dart';
import '../domain/call_language.dart';
import '../domain/call_session.dart';
import 'call_controller.dart';
import 'call_history_controller.dart';

// Re-export auth providers so the rest of translate_call only needs
// to import this one file (no change to call_controller.dart imports).
export '../../auth/application/providers.dart'
    show firebaseAuthProvider, firestoreProvider, currentUserProvider;

// ── Services ──────────────────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>(
  (_) => NotificationService.instance,
);

final fcmServiceProvider = Provider<FcmService>(
  (ref) => FcmService(
    auth:      ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  ),
);

// ── Repositories ──────────────────────────────────────────────────────────────

final translateCallRepositoryProvider = Provider<TranslateCallRepository>(
  (ref) {
    final repo = TranslateCallRepository(
      auth:      ref.watch(firebaseAuthProvider),
      firestore: ref.watch(firestoreProvider),
    );
    ref.onDispose(repo.dispose);
    return repo;
  },
);

final callHistoryRepositoryProvider = Provider<CallHistoryRepository>(
  (ref) => CallHistoryRepository(
    firestore: ref.watch(firestoreProvider),
  ),
);

// ── Language selection ────────────────────────────────────────────────────────

final selectedLanguageProvider = StateProvider<CallLanguage>(
  (_) => CallLanguage.hindi,
);

// ── Call controller ───────────────────────────────────────────────────────────

final callControllerProvider =
    AsyncNotifierProvider<CallController, CallState>(
  CallController.new,
);

// ── Call history ──────────────────────────────────────────────────────────────

final callHistoryControllerProvider =
    AsyncNotifierProvider<CallHistoryController, List<CallHistoryEntry>>(
  CallHistoryController.new,
);

// ── Incoming call watcher ─────────────────────────────────────────────────────

final incomingCallProvider = StreamProvider<CallSession?>(
  (ref) {
    final userAsync = ref.watch(currentUserProvider);
    final repo      = ref.watch(translateCallRepositoryProvider);

    return userAsync.when(
      data:    (user) => user == null
                           ? const Stream.empty()
                           : repo.watchIncomingCall(user.uid),
      loading: () => const Stream.empty(),
      error:   (_, __) => const Stream.empty(),
    );
  },
);