// lib/features/translate_call/application/call_history_controller.dart
//
// Streams the current user's call history from Firestore and exposes
// a delete action. The stream is set up in build() so Riverpod
// automatically re-subscribes when the user signs in/out.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/call_history_entry.dart';
import 'providers.dart';

class CallHistoryController
    extends AsyncNotifier<List<CallHistoryEntry>> {
  StreamSubscription<List<CallHistoryEntry>>? _sub;

  @override
  Future<List<CallHistoryEntry>> build() async {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return [];

    final repo = ref.watch(callHistoryRepositoryProvider);

    // Cancel any previous subscription when build() re-runs
    ref.onDispose(() => _sub?.cancel());

    // Resolve the first emission as the initial state, then keep
    // updating state for subsequent Firestore snapshots.
    final completer = Completer<List<CallHistoryEntry>>();

    _sub = repo.watchHistory(user.uid).listen(
      (entries) {
        if (!completer.isCompleted) {
          completer.complete(entries);
        } else {
          state = AsyncData(entries);
        }
      },
      onError: (Object e, StackTrace st) {
        if (!completer.isCompleted) {
          completer.completeError(e, st);
        } else {
          state = AsyncError(e, st);
        }
      },
    );

    return completer.future;
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> deleteEntry(String sessionId) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    final repo = ref.read(callHistoryRepositoryProvider);
    await repo.deleteEntry(user.uid, sessionId);
    // Firestore listener emits automatically — no manual state update needed
  }
}