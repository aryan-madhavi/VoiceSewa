// lib/main.dart

import 'dart:async';

import 'package:call_translate/features/translate_call/domain/call_session.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/auth/presentation/forgot_password_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/signup_screen.dart';
import 'features/translate_call/application/call_controller.dart';
import 'features/translate_call/application/providers.dart';
import 'features/translate_call/data/notification_service.dart';
import 'features/translate_call/presentation/active_call_screen.dart';
import 'features/translate_call/presentation/call_history_screen.dart';
import 'features/translate_call/presentation/home_screen.dart';
import 'features/translate_call/presentation/incoming_call_screen.dart';
import 'features/translate_call/presentation/language_picker_screen.dart';
import 'features/translate_call/presentation/outgoing_call_screen.dart';
import 'firebase_options.dart';

// ── Background FCM handler ────────────────────────────────────────────────────
// Runs in a separate isolate when app is terminated or backgrounded.
// Must be top-level and annotated.

@pragma('vm:entry-point')
Future<void> _backgroundFcmHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.init();

  if (message.data['type'] == AppConstants.fcmTypeIncomingCall) {
    await NotificationService.instance.showIncomingCall(
      sessionId:    message.data['sessionId']    ?? '',
      callerUid:    message.data['callerUid']    ?? '',
      callerName:   message.data['callerName']   ?? 'Unknown',
      callerLang:   message.data['callerLang']   ?? 'hi-IN',
      receiverLang: message.data['receiverLang'] ?? 'en-IN',
    );
  }
}

// ── Router notifier ───────────────────────────────────────────────────────────
//
// REDIRECT PRIORITY:
//   1. Auth loading             → /splash
//   2. Not logged in            → /login
//   3. On auth/splash screen    → /home
//   4. ringingOutgoing          → /outgoing-call
//   5. connecting OR active:
//        • if currently on /incoming-call → STAY (acceptCall is mid-flight,
//          WS not connected yet — must not interrupt)
//        • otherwise                      → /active-call
//   6. ended                    → /home  (from call screens)
//   7. incomingCall != null     → /incoming-call
//   8. On /incoming-call with no session → /home

class _RouterNotifier extends AsyncNotifier<void> implements ChangeNotifier {
  final _listeners = <VoidCallback>[];

  @override
  Future<void> build() async {
    ref.watch(currentUserProvider);
    ref.watch(callControllerProvider);
    ref.watch(incomingCallProvider);
    notifyListeners();
  }

  @override void addListener(VoidCallback l)    => _listeners.add(l);
  @override void removeListener(VoidCallback l) => _listeners.remove(l);
  @override bool get hasListeners               => _listeners.isNotEmpty;
  @override void dispose()                      => _listeners.clear();

  @override
  void notifyListeners() {
    for (final l in List<VoidCallback>.from(_listeners)) l();
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authAsync     = ref.read(currentUserProvider);
    final callAsync     = ref.read(callControllerProvider);
    final incomingAsync = ref.read(incomingCallProvider);
    final loc           = state.matchedLocation;

    // 1. Auth loading
    if (authAsync.isLoading) return loc == '/splash' ? null : '/splash';

    final isLoggedIn   = authAsync.valueOrNull != null;
    final callPhase    = callAsync.valueOrNull?.phase;
    final incomingCall = incomingAsync.valueOrNull;

    // 2. Not logged in
    if (!isLoggedIn) {
      const authRoutes = {'/login', '/signup', '/forgot-password'};
      return authRoutes.contains(loc) ? null : '/login';
    }

    // 3. On auth/splash screen while logged in
    if (loc == '/login' || loc == '/signup' ||
        loc == '/forgot-password' || loc == '/splash') {
      return '/home';
    }

    // 4. Caller is ringing
    if (callPhase == CallPhase.ringingOutgoing) {
      return loc == '/outgoing-call' ? null : '/outgoing-call';
    }

    // 5. Connecting or active
    //    IMPORTANT: stay on /incoming-call while acceptCall() is executing.
    //    acceptCall() connects WS first, updates Firestore second, then sets
    //    phase=connecting. Redirecting away mid-flight breaks the WS handshake.
    if (callPhase == CallPhase.connecting || callPhase == CallPhase.active) {
      if (loc == '/incoming-call') return null; // acceptCall still running
      return loc == '/active-call' ? null : '/active-call';
    }

    // 6. Call ended — go home from any call screen
    if (callPhase == CallPhase.ended) {
      const callScreens = {'/outgoing-call', '/incoming-call', '/active-call'};
      return callScreens.contains(loc) ? '/home' : null;
    }

    // 7. Incoming call from Firestore
    if (incomingCall != null) {
      return loc == '/incoming-call' ? null : '/incoming-call';
    }

    // 8. Stale /incoming-call with no session
    if (loc == '/incoming-call') return '/home';

    return null;
  }
}

final _routerNotifierProvider =
    AsyncNotifierProvider<_RouterNotifier, void>(_RouterNotifier.new);

// ── Router ────────────────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  // FIX: watch the provider VALUE (not just .notifier) so that
  // _RouterNotifier.build() actually runs and subscribes to
  // incomingCallProvider. Without this, the Firestore stream never
  // starts and ref.read(incomingCallProvider) always returns AsyncLoading.
  ref.watch(_routerNotifierProvider);
  final notifier = ref.watch(_routerNotifierProvider.notifier);
  return GoRouter(
    initialLocation:   '/splash',
    refreshListenable: notifier,
    redirect:          notifier.redirect,
    routes: [
      GoRoute(path: '/splash',          builder: (_, __) => const _SplashScreen()),
      GoRoute(path: '/login',           builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup',          builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/home',            builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/history',         builder: (_, __) => const CallHistoryScreen()),
      GoRoute(
        path: '/language-picker',
        builder: (_, __) => Consumer(
          builder: (ctx, ref, __) => LanguagePickerScreen(
            onConfirmed: (lang) {
              ref.read(selectedLanguageProvider.notifier).state = lang;
              ctx.pop();
            },
          ),
        ),
      ),
      GoRoute(path: '/outgoing-call', builder: (_, __) => const OutgoingCallScreen()),
      GoRoute(
        path: '/incoming-call',
        builder: (_, __) => Consumer(
          builder: (_, ref, __) {
            final session = ref.watch(incomingCallProvider).valueOrNull;
            if (session == null) return const SizedBox.shrink();
            return IncomingCallScreen(session: session);
          },
        ),
      ),
      GoRoute(path: '/active-call', builder: (_, __) => const ActiveCallScreen()),
    ],
  );
});

// ── Splash ────────────────────────────────────────────────────────────────────

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.callBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('VoiceSewa',
                style: TextStyle(
                  color:        AppTheme.primary,
                  fontSize:     36,
                  fontWeight:   FontWeight.bold,
                  letterSpacing: 0.5,
                )),
            SizedBox(height: 8),
            Text('Translate',
                style: TextStyle(
                    color: AppTheme.callTextSecondary, fontSize: 18)),
            SizedBox(height: 48),
            CircularProgressIndicator(
                color: AppTheme.primary, strokeWidth: 2.5),
          ],
        ),
      ),
    );
  }
}

// ── App root ──────────────────────────────────────────────────────────────────

class CallTranslateApp extends ConsumerStatefulWidget {
  const CallTranslateApp({super.key});
  @override
  ConsumerState<CallTranslateApp> createState() => _CallTranslateAppState();
}

class _CallTranslateAppState extends ConsumerState<CallTranslateApp> {
  @override
  void initState() {
    super.initState();

    // ── Step 1: Register the notification tap handler FIRST ──────────────
    NotificationService.instance.setOnNotificationTap((sessionId) {
      debugPrint('[App] notification tap → sessionId=$sessionId');
      _navigateToIncomingCall();
    });

    // ── Step 2: Re-init NotificationService now that tap handler is set ──
    // The first init() was called in main() before ProviderScope existed,
    // so _onNotificationTap was null then. Re-calling init() here picks up
    // any launch notification (TERMINATED tap scenario).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.init();

      // ── Step 3: Init FCM service ─────────────────────────────────────
      // Handles FCM background/terminated taps (onMessageOpenedApp /
      // getInitialMessage). Same router-refresh approach as above.
      ref.read(fcmServiceProvider).init(
        onCallNotificationTap: (sessionId) {
          debugPrint('[FCM] tap → sessionId=$sessionId');
          _navigateToIncomingCall();
        },
      );
    });
  }

  // ── Notification tap → /incoming-call ────────────────────────────────────
  //
  // FIX: Simply calling notifyListeners() on tap was a race condition.
  // redirect() reads incomingCallProvider with ref.read() — if the Firestore
  // stream hasn't emitted yet (cold start, or stream just subscribed),
  // valueOrNull is null and the redirect does nothing.
  //
  // Fix: poll incomingCallProvider until it has a non-null session (up to
  // 5 seconds), then trigger the redirect. This covers all three tap scenarios:
  //   A) Foreground — stream is live, emits immediately, 1st poll succeeds
  //   B) Background — stream resumes quickly, usually 1-2 polls
  //   C) Terminated — cold start, stream needs to connect, may take ~1-3s
  void _navigateToIncomingCall() {
    // FIX: ref.read(incomingCallProvider) only returns the cached snapshot.
    // If the StreamProvider was never subscribed (build() never ran because
    // routerProvider only watched .notifier not the value), the stream never
    // started and valueOrNull is always null no matter how long we poll.
    //
    // Correct approach: use ref.listen which both subscribes the provider
    // (starting the Firestore stream if not already running) AND gives us
    // a callback the moment a non-null session arrives.
    // We keep a reference to cancel the subscription after routing.

    // Check immediately in case the stream already has data
    final existing = ref.read(incomingCallProvider).valueOrNull;
    if (existing != null) {
      debugPrint('[App] incomingCall already in cache → navigating');
      ref.read(_routerNotifierProvider.notifier).notifyListeners();
      return;
    }

    debugPrint('[App] waiting for incomingCallProvider via listen...');

    // Timeout guard
    Timer? timeoutTimer;
    ProviderSubscription<AsyncValue<CallSession?>>? sub;

    timeoutTimer = Timer(const Duration(seconds: 8), () {
      sub?.close();
      debugPrint('[App] incomingCallProvider timed out — call may have ended');
    });

    sub = ref.listenManual(incomingCallProvider, (_, next) {
      final session = next.valueOrNull;
      if (session != null) {
        timeoutTimer?.cancel();
        sub?.close();
        debugPrint('[App] incomingCallProvider emitted → navigating');
        ref.read(_routerNotifierProvider.notifier).notifyListeners();
      }
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title:                      'VoiceSewa Translate',
      debugShowCheckedModeBanner: false,
      theme:      AppTheme.light(),
      darkTheme:  AppTheme.dark(),
      themeMode:  ThemeMode.system,
      routerConfig: router,
    );
  }
}

// ── Entry point ───────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background FCM handler before runApp
  FirebaseMessaging.onBackgroundMessage(_backgroundFcmHandler);

  // Early init — creates the Android notification channel.
  // _onNotificationTap is NOT set yet (ProviderScope doesn't exist yet),
  // so launch-notification detection is deferred to the second init() call
  // in CallTranslateApp.initState (after tap handler is registered).
  await NotificationService.instance.init();

  await FirebaseMessaging.instance.requestPermission(
    alert:         true,
    sound:         true,
    badge:         true,
    criticalAlert: true,
  );

  runApp(const ProviderScope(child: CallTranslateApp()));
}