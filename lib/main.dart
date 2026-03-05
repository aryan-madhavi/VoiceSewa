// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'package:call_translate/features/auth/application/providers.dart';
import 'package:call_translate/features/auth/presentation/forgot_password_screen.dart';
import 'package:call_translate/features/auth/presentation/login_screen.dart';
import 'package:call_translate/features/auth/presentation/signup_screen.dart';
import 'package:call_translate/features/translate-call/application/call_controller.dart';
import 'package:call_translate/features/translate-call/application/providers.dart';
import 'package:call_translate/features/translate-call/data/notification_service.dart';
import 'package:call_translate/features/translate-call/presentation/active_call_screen.dart';
import 'package:call_translate/features/translate-call/presentation/call_history_screen.dart';
import 'package:call_translate/features/translate-call/presentation/home_screen.dart';
import 'package:call_translate/features/translate-call/presentation/incoming_call_screen.dart';
import 'package:call_translate/features/translate-call/presentation/language_picker_screen.dart';
import 'package:call_translate/features/translate-call/presentation/outgoing_call_screen.dart';
import 'firebase_options.dart';

// ── Background FCM handler ────────────────────────────────────────────────────
// Must be a top-level function. Runs in its own isolate.

@pragma('vm:entry-point')
Future<void> _backgroundFcmHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
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

// ── Router ────────────────────────────────────────────────────────────────────
// Defined as a Notifier so it can watch other providers and call
// ref.read() safely inside the redirect callback.

class _RouterNotifier extends AsyncNotifier<void>
    implements Listenable {
  VoidCallback? _routerListener;

  @override
  Future<void> build() async {
    // Watch every provider that should trigger a redirect re-evaluation
    ref.watch(currentUserProvider);
    ref.watch(callControllerProvider);
    ref.watch(incomingCallProvider);

    // Tell go_router to re-evaluate redirect whenever state changes
    _routerListener?.call();
  }

  @override
  void addListener(VoidCallback listener) {
    _routerListener = listener;
  }

  @override
  void removeListener(VoidCallback listener) {
    if (_routerListener == listener) _routerListener = null;
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final isLoggedIn   = ref.read(currentUserProvider).valueOrNull != null;
    final callPhase    = ref.read(callControllerProvider).valueOrNull?.phase;
    final incomingCall = ref.read(incomingCallProvider).valueOrNull;
    final loc          = state.matchedLocation;

    // ── Auth ──────────────────────────────────────────────────────────────
    if (!isLoggedIn) {
      final authRoutes = {'/login', '/signup', '/forgot-password'};
      return authRoutes.contains(loc) ? null : '/login';
    }

    // ── Active call phases ─────────────────────────────────────────────────
    if (callPhase == CallPhase.ringingOutgoing && loc != '/outgoing-call') {
      return '/outgoing-call';
    }
    if ((callPhase == CallPhase.active || callPhase == CallPhase.connecting) &&
        loc != '/active-call') {
      return '/active-call';
    }
    if (callPhase == CallPhase.ended && loc != '/home') {
      return '/home';
    }

    // ── Incoming call ──────────────────────────────────────────────────────
    if (incomingCall != null && loc != '/incoming-call') {
      return '/incoming-call';
    }
    if (incomingCall == null && loc == '/incoming-call') {
      return '/home';
    }

    return null;
  }
}

final _routerNotifierProvider =
    AsyncNotifierProvider<_RouterNotifier, void>(_RouterNotifier.new);

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider.notifier);

  return GoRouter(
    initialLocation:    '/home',
    refreshListenable:  notifier,
    redirect:           notifier.redirect,
    routes: [
      // ── Auth ─────────────────────────────────────────────────────────────
      GoRoute(
        path:    '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path:    '/signup',
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path:    '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),

      // ── Main ─────────────────────────────────────────────────────────────
      GoRoute(
        path:    '/home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/language-picker',
        builder: (context, __) => Consumer(
          builder: (ctx, ref, _) => LanguagePickerScreen(
            onConfirmed: (lang) {
              ref.read(selectedLanguageProvider.notifier).state = lang;
              ctx.pop();
            },
          ),
        ),
      ),

      // ── Call ─────────────────────────────────────────────────────────────
      GoRoute(
        path:    '/outgoing-call',
        builder: (_, __) => const OutgoingCallScreen(),
      ),
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
      GoRoute(
        path:    '/active-call',
        builder: (_, __) => const ActiveCallScreen(),
      ),
      GoRoute(
        path:    '/history',
        builder: (_, __) => const CallHistoryScreen(),
      ),
    ],
  );
});

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fcmServiceProvider).init(
        onCallNotificationTap: (sessionId) {
          // incomingCallProvider + router redirect handle navigation
          debugPrint('[FCM] Notification tap → session $sessionId');
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title:                     'VoiceSewa Translate',
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

  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);

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