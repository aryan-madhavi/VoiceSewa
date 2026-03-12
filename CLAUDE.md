# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VoiceSewa is a multilingual voice-assisted job platform for blue-collar services. This repo contains the **auto-translating call** subsystem: a Node.js backend and a Flutter app that together let two users on a call hear each other in their own language in real time.

## Repository Layout

```
backend/          Node.js translation server (run here for the backend)
app/
  call_translate/ Flutter standalone app (later integrate into voicesewa_client / voicesewa_worker)
```

---

## Backend (`backend/`)

### Commands

```bash
cd backend
npm install
npm run dev       # hot-reload via nodemon
npm start         # production
```

### Source files (`backend/src/`)

| File | Responsibility |
|------|---------------|
| `index.js` | Bootstrap: Firebase Admin init, Express, WebSocketServer, SIGTERM |
| `routes.js` | REST: `GET /health`, `POST /session`, `GET /session/:id`, `DELETE /session/:id` |
| `firebaseAuth.js` | `verifyToken(token, { checkRevoked })` wrapper around Firebase Admin |
| `sessionManager.js` | In-memory session store with TTL timers; `createSession`, `addUserToSession`, `removeUserFromSession`, `cleanupExpiredSessions` |
| `translationPipeline.js` | `TranslationPipeline` class — one-directional STT → Translate → TTS pipeline per user |
| `wsHandler.js` | WebSocket upgrade handler; wires up two `TranslationPipeline` instances once both users join |

### Translation pipeline (one direction)

```
Caller audio (PCM16 mono 16 kHz, binary WebSocket frames)
  → Google Cloud Speech-to-Text (latest_long model, auto-restarts at 270 s)
  → Google Cloud Translation (final transcripts only)
  → Google Cloud Text-to-Speech (Chirp3-HD → Neural2-A → Standard-A fallback, cached failures)
  → MP3 binary frame sent to the other user's WebSocket
```

### REST API

| Method | Path | Auth | Body / Returns |
|--------|------|------|----------------|
| GET | `/health` | — | `{ status, timestamp }` |
| POST | `/session` | Bearer token | `{ receiverUid }` → `{ sessionId }` |
| GET | `/session/:id` | Bearer token | `{ sessionId, status, callerUid, receiverUid }` |
| DELETE | `/session/:id` | Bearer token | 204 |

### WebSocket

Connect: `ws://host/ws?token=<firebase_id_token>&sessionId=<id>&lang=<BCP-47>`

- **Binary frames in** → PCM16 audio (16 kHz mono) from the user's mic
- **Binary frames out** → MP3 audio (translated speech from the partner)
- **JSON frames out** → `{ type: 'connected' | 'call_started' | 'partner_left' | 'transcript' | 'error', ...fields }`

Transcript event shape:
```json
{ "type": "transcript", "text": "...", "lang": "mr-IN", "isFinal": true, "isTranslation": false }
```
- `isTranslation: false` → sent to the **speaker** (their own words)
- `isTranslation: true` → sent to the **listener** (translated text they will hear)

### Environment variables

```
GOOGLE_APPLICATION_CREDENTIALS=./secrets/serviceAccountKey.json
GOOGLE_CLOUD_PROJECT=voicesewa
PORT=8080
WAITING_TTL_MS=90000    # session TTL before anyone connects
RINGING_TTL_MS=60000    # TTL after first user connects
ACTIVE_TTL_MS=7200000   # TTL once both connected (2 h)
```

---

## Flutter App (`app/call_translate/`)

### First-time setup

```bash
cd app/call_translate

# 1. Scaffold platform files (creates android/, ios/, etc.)
flutter create . --project-name call_translate --org com.voicesewa

# 2. Add permissions to android/app/src/main/AndroidManifest.xml (inside <manifest>):
#    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
#    <uses-permission android:name="android.permission.INTERNET"/>

# 3. Generate Firebase config
dart pub global activate flutterfire_cli
flutterfire configure --project=voicesewa
# (replaces lib/firebase_options.dart)

# 4. Install packages + run code generation
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Daily commands

```bash
flutter run --dart-define=BACKEND_URL=http://10.0.2.2:8080   # Android emulator
flutter run --dart-define=BACKEND_URL=http://localhost:8080   # iOS simulator
dart run build_runner build --delete-conflicting-outputs      # after editing freezed models
flutter test
```

### Architecture

Feature-first under `lib/features/`:

```
features/
  auth/
    domain/app_user.dart          AppUser freezed model (also stored in Firestore users/{uid})
    data/auth_repository.dart     Firebase Auth + Firestore user profile; authStateProvider, currentUserProvider
    presentation/login_screen.dart
  settings/
    domain/language_settings.dart  LanguageSettings freezed model
    data/language_repository.dart  SharedPreferences + Firestore sync; languageSettingsProvider (AsyncNotifier)
    presentation/language_settings_screen.dart
  call/
    domain/call_state.dart         CallPhase (freezed union), TranscriptEntry, CallSignal
    data/call_repository.dart      WebSocket + audio + Firestore signalling; incomingCallProvider
    providers/call_providers.dart  CallController (AsyncNotifier<CallPhase>), TranscriptsNotifier
    presentation/
      home_screen.dart             Dial by UID, shows own UID
      outgoing_call_screen.dart    Ringing state
      incoming_call_screen.dart    Accept / decline
      active_call_screen.dart      Transcript bubbles + end button
core/
  constants.dart   AppConstants (BACKEND_URL), kSupportedLanguages, FirestoreCollections
  router.dart      GoRouter with redirect logic driven by authStateProvider + callControllerProvider
  theme.dart       AppTheme.light / dark
```

### Call flow

1. **Caller**: `CallController.startCall(receiverUid)` → `POST /session` → writes Firestore `calls/{sessionId}` with `status: ringing` → connects WebSocket
2. **Receiver**: Firestore `incomingCallProvider` stream detects doc → `CallPhase.incoming(...)` set → router shows `IncomingCallScreen`
3. **Receiver accepts**: `CallController.acceptCall(signal)` → connects WebSocket → backend fires `call_started` to both
4. **Active call**: both users stream PCM16 audio; backend sends translated MP3 back; transcript events update UI
5. **Hang up**: `CallController.endCall()` → `DELETE /session` → Firestore `status: ended` → `CallPhase.ended` → idle after 2 s

### Riverpod providers summary

| Provider | Type | Purpose |
|----------|------|---------|
| `authStateProvider` | `StreamProvider<User?>` | Firebase auth stream |
| `currentUserProvider` | `FutureProvider<AppUser?>` | Resolved AppUser from Firestore |
| `languageSettingsProvider` | `AsyncNotifierProvider` | User's language (local + Firestore) |
| `callControllerProvider` | `AsyncNotifierProvider<CallPhase>` | Call lifecycle state machine |
| `incomingCallProvider(uid)` | `StreamProvider.family<CallSignal?>` | Firestore stream for incoming calls |
| `transcriptsProvider` | `NotifierProvider<List<TranscriptEntry>>` | Live transcript entries during call |

### Code generation (freezed models)

Files with `part '*.freezed.dart'` / `part '*.g.dart'` need build_runner:
- `lib/features/auth/domain/app_user.dart`
- `lib/features/settings/domain/language_settings.dart`
- `lib/features/call/domain/call_state.dart`

Run `dart run build_runner build --delete-conflicting-outputs` after modifying any of these.

### Supported languages

Defined in `lib/core/constants.dart` → `kSupportedLanguages`. Add entries there to expose more languages in the picker. The BCP-47 code is sent directly to Google Cloud STT/TTS.

---

## Firestore structure

```
users/{uid}
  email: string
  displayName: string
  lang: string          // BCP-47, e.g. 'mr-IN'

calls/{sessionId}
  callerUid: string
  receiverUid: string
  callerLang: string    // set by caller when creating session
  status: 'ringing' | 'active' | 'ended'
  createdAt: Timestamp
```
