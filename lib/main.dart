// lib/main.dart

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
// Top-level function required by firebase_messaging.
// Runs in a separate isolate when the app is terminated or backgrounded.

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

// ── Pending session ID ────────────────────────────────────────────────────────
// When the app is opened via a notification tap (background or terminated),
// we store the sessionId here. The router redirect reads it and navigates
// to /incoming-call even before the Firestore stream has had time to emit.
// Cleared once the user reaches /incoming-call.

String? _pendingNotificationSessionId;

// ── Router notifier ───────────────────────────────────────────────────────────

class _RouterNotifier extends AsyncNotifier<void> implements ChangeNotifier {
  final _listeners = <VoidCallback>[];

  @override
  Future<void> build() async {
    ref.watch(currentUserProvider);
    ref.watch(callControllerProvider);
    ref.watch(incomingCallProvider);
    notifyListeners();
  }

  // ── ChangeNotifier ────────────────────────────────────────────────────────

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  @override
  void notifyListeners() {
    for (final l in List<VoidCallback>.from(_listeners)) {
      l();
    }
  }

  @override
  bool get hasListeners => _listeners.isNotEmpty;

  @override
  void dispose() => _listeners.clear();

  // ── Redirect ──────────────────────────────────────────────────────────────

  String? redirect(BuildContext context, GoRouterState state) {
    final authAsync     = ref.read(currentUserProvider);
    final callAsync     = ref.read(callControllerProvider);
    final incomingAsync = ref.read(incomingCallProvider);
    final loc           = state.matchedLocation;

    // While Firebase resolves the persisted session, stay on /splash.
    if (authAsync.isLoading) {
      return loc == '/splash' ? null : '/splash';
    }

    final isLoggedIn   = authAsync.valueOrNull != null;
    final callPhase    = callAsync.valueOrNull?.phase;
    final incomingCall = incomingAsync.valueOrNull;

    // ── Not logged in ──────────────────────────────────────────────────────
    if (!isLoggedIn) {
      const authRoutes = {'/login', '/signup', '/forgot-password'};
      return authRoutes.contains(loc) ? null : '/login';
    }

    // ── Logged in, on an auth/splash screen ────────────────────────────────
    if (loc == '/login' || loc == '/signup' ||
        loc == '/forgot-password' || loc == '/splash') {
      return '/home';
    }

    // ── Call phase overrides ───────────────────────────────────────────────
    if (callPhase == CallPhase.ringingOutgoing) {
      return loc == '/outgoing-call' ? null : '/outgoing-call';
    }
    if (callPhase == CallPhase.active || callPhase == CallPhase.connecting) {
      return loc == '/active-call' ? null : '/active-call';
    }
    if (callPhase == CallPhase.ended) {
      const callScreens = {'/outgoing-call', '/incoming-call', '/active-call'};
      return callScreens.contains(loc) ? '/home' : null;
    }

    // ── Notification tap pending (app opened from background/terminated) ──
    // The Firestore incomingCallProvider stream may not have emitted yet.
    // We navigate optimistically and let the screen handle the null case.
    if (_pendingNotificationSessionId != null) {
      // Clear it once we're routing to the screen
      if (loc != '/incoming-call') {
        return '/incoming-call';
      }
      // We've arrived — clear the pending flag
      _pendingNotificationSessionId = null;
      return null;
    }

    // ── Live incoming call (Firestore stream has emitted) ──────────────────
    if (incomingCall != null) {
      return loc == '/incoming-call' ? null : '/incoming-call';
    }
    if (loc == '/incoming-call') {
      return '/home'; // call was answered/declined, no active incoming
    }

    return null;
  }
}

final _routerNotifierProvider =
    AsyncNotifierProvider<_RouterNotifier, void>(_RouterNotifier.new);

// ── Router ────────────────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
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
            // Try live Firestore session first, fall back to pending sessionId
            final session = ref.watch(incomingCallProvider).valueOrNull;

            if (session != null) {
              return IncomingCallScreen(session: session);
            }

            // Firestore stream hasn't emitted yet (app opened from notification).
            // Show a loading screen while we wait for the stream.
            return _WaitingForSessionScreen(
              pendingSessionId: _pendingNotificationSessionId,
            );
          },
        ),
      ),
      GoRoute(path: '/active-call', builder: (_, __) => const ActiveCallScreen()),
    ],
  );
});

// ── Waiting screen shown while Firestore stream loads ─────────────────────────
// Displayed only in the narrow window between notification tap and the
// incomingCallProvider emitting the CallSession. Polls incomingCallProvider
// and navigates automatically once it arrives.

class _WaitingForSessionScreen extends ConsumerStatefulWidget {
  const _WaitingForSessionScreen({this.pendingSessionId});
  final String? pendingSessionId;

  @override
  ConsumerState<_WaitingForSessionScreen> createState() =>
      _WaitingForSessionScreenState();
}

class _WaitingForSessionScreenState
    extends ConsumerState<_WaitingForSessionScreen> {

  @override
  Widget build(BuildContext context) {
    // Watch the incoming call stream — when it emits, the router's
    // incomingCall != null branch will redirect to /incoming-call which
    // now has data and will render IncomingCallScreen.
    ref.watch(incomingCallProvider);

    return Scaffold(
      backgroundColor: AppTheme.callBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color:       AppTheme.primary,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 20),
            const Text(
              'Connecting…',
              style: TextStyle(
                color:    AppTheme.callTextSecondary,
                fontSize: 16,
              ),
            ),
            if (widget.pendingSessionId != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.pendingSessionId!,
                style: const TextStyle(
                  color:    AppTheme.callTextSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Splash screen ─────────────────────────────────────────────────────────────

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
            Text(
              'VoiceSewa',
              style: TextStyle(
                color:        AppTheme.primary,
                fontSize:     36,
                fontWeight:   FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Translate',
              style: TextStyle(
                color:    AppTheme.callTextSecondary,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(
              color:       AppTheme.primary,
              strokeWidth: 2.5,
            ),
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

    // Register the notification tap handler BEFORE calling FcmService.init()
    // so that launch-from-notification is handled correctly.
    NotificationService.instance.setOnNotificationTap((sessionId) {
      debugPrint('[App] Notification tap → session $sessionId');
      _pendingNotificationSessionId = sessionId;
      // Trigger a router refresh so the redirect logic picks up the pending id
      ref.read(_routerNotifierProvider.notifier).notifyListeners();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.init(); // picks up any launch notification

      ref.read(fcmServiceProvider).init(
        onCallNotificationTap: (sessionId) {
          debugPrint('[FCM] Background/terminated tap → session $sessionId');
          _pendingNotificationSessionId = sessionId;
          ref.read(_routerNotifierProvider.notifier).notifyListeners();
        },
      );
    });
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

  FirebaseMessaging.onBackgroundMessage(_backgroundFcmHandler);

  // Init notification plugin early (before ProviderScope) so the channel
  // exists. The tap callback will be registered later by CallTranslateApp.
  await NotificationService.instance.init();

  await FirebaseMessaging.instance.requestPermission(
    alert:         true,
    sound:         true,
    badge:         true,
    criticalAlert: true,
  );

  runApp(const ProviderScope(child: CallTranslateApp()));
}