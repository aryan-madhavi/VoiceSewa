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
// Redirect rules (in priority order):
//   1. Auth loading          → /splash
//   2. Not logged in         → /login
//   3. On auth screen        → /home
//   4. ringingOutgoing       → /outgoing-call
//   5. connecting OR active  → /active-call
//      BUT: if currently on /incoming-call, stay there.
//      acceptCall() connects the WS first, THEN sets phase=connecting.
//      We must not redirect away from /incoming-call mid-setup or the
//      WS connect gets interrupted before Firestore is updated.
//   6. ended                 → /home (from call screens only)
//   7. Incoming call (Firestore) → /incoming-call
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

  String? redirect(BuildContext context, GoRouterState state) {
    final authAsync     = ref.read(currentUserProvider);
    final callAsync     = ref.read(callControllerProvider);
    final incomingAsync = ref.read(incomingCallProvider);
    final loc           = state.matchedLocation;

    if (authAsync.isLoading) {
      return loc == '/splash' ? null : '/splash';
    }

    final isLoggedIn   = authAsync.valueOrNull != null;
    final callPhase    = callAsync.valueOrNull?.phase;
    final incomingCall = incomingAsync.valueOrNull;

    if (!isLoggedIn) {
      const authRoutes = {'/login', '/signup', '/forgot-password'};
      return authRoutes.contains(loc) ? null : '/login';
    }

    if (loc == '/login' || loc == '/signup' ||
        loc == '/forgot-password' || loc == '/splash') {
      return '/home';
    }

    if (callPhase == CallPhase.ringingOutgoing) {
      return loc == '/outgoing-call' ? null : '/outgoing-call';
    }

    // CRITICAL: Do NOT redirect away from /incoming-call while the user is
    // accepting the call. acceptCall() sets phase=connecting only AFTER the
    // WS is connected and Firestore is updated. If we redirect to /active-call
    // the moment phase=connecting is seen, it happens before the WS connects.
    //
    // Rule: only go to /active-call if we are NOT on /incoming-call.
    if (callPhase == CallPhase.connecting || callPhase == CallPhase.active) {
      if (loc == '/incoming-call') return null; // stay — setup still in progress
      return loc == '/active-call' ? null : '/active-call';
    }

    if (callPhase == CallPhase.ended) {
      const callScreens = {'/outgoing-call', '/incoming-call', '/active-call'};
      return callScreens.contains(loc) ? '/home' : null;
    }

    if (incomingCall != null) {
      return loc == '/incoming-call' ? null : '/incoming-call';
    }

    if (loc == '/incoming-call') {
      return '/home';
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

    // Wire up the local notification tap callback.
    // This fires when the user taps the heads-up banner (foreground) or
    // the notification shade (background). It triggers a router refresh
    // which routes to /incoming-call where the user sees the accept/decline UI.
    NotificationService.instance.setOnNotificationTap((sessionId) {
      debugPrint('[App] Notification tap → session $sessionId');
      // The incomingCallProvider Firestore stream already has the session.
      // Just notify the router to re-evaluate — it will redirect to
      // /incoming-call because incomingCall != null.
      ref.read(_routerNotifierProvider.notifier).notifyListeners();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Re-init picks up any notification that launched the app while terminated
      NotificationService.instance.init();

      ref.read(fcmServiceProvider).init(
        onCallNotificationTap: (sessionId) {
          // FCM background/terminated tap — same as local notification tap.
          debugPrint('[FCM] Tap → session $sessionId');
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

  await NotificationService.instance.init();

  await FirebaseMessaging.instance.requestPermission(
    alert:         true,
    sound:         true,
    badge:         true,
    criticalAlert: true,
  );

  runApp(const ProviderScope(child: CallTranslateApp()));
}