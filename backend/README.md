# VoiceSewa — Call Translation Backend

Real-time bidirectional call translation server. Two users on a WebSocket call hear each other in their own language with near-zero perceptible latency.

**Stack:** Node.js · Express · WebSocketServer (`ws`) · Google Cloud STT / Translation / TTS · Firebase Admin SDK

---

## How It Works

Each active call runs **two independent one-directional pipelines** — one per speaker:

```
User A mic (PCM16) ──► Pipeline A→B ──► User B speaker (MP3)
User B mic (PCM16) ──► Pipeline B→A ──► User A speaker (MP3)
```

### Inside one pipeline

```
Binary WS frame (PCM16, 16 kHz mono)
  │
  ▼
Google Cloud Speech-to-Text  [gRPC streaming, latest_long model]
  • Interim results → { type:'transcript', isFinal:false } sent to speaker's UI
  • Final result   → passed to Translation
  │
  ▼
Google Cloud Translation  [final transcripts only]
  • { type:'transcript', isFinal:true, isTranslation:true } sent to listener's UI
  │
  ▼
Google Cloud Text-to-Speech  [Chirp3-HD → Neural2-A → Standard-A fallback]
  │
  ▼
Binary WS frame (MP3) sent to the other user's socket
```

### STT stream management

Google Cloud STT streaming sessions expire after 290 s. The pipeline handles this automatically:

- **Lazy init** — the STT gRPC stream is opened only when the first audio chunk arrives, not at pipeline construction, to avoid the "no audio received" early timeout.
- **Auto-restart** — the stream is replaced every 270 s (before Google's hard limit).
- **Silence keepalive** — if the user hasn't spoken for 4 s, 100 ms of zeroed PCM is written to the stream to keep it alive during natural pauses.
- **Error restart** — on any STT error, the stream restarts after a 1 s delay to avoid tight loops.

### TTS voice fallback

For each target language the pipeline tries voices in order:

```
{lang}-Chirp3-HD-Aoede  (highest quality)
{lang}-Neural2-A
{lang}-Standard-A
{lang}-Standard-B       (lowest quality, widest availability)
```

A per-process failure cache prevents retrying a broken voice on every utterance.

---

## Session Lifecycle

```
POST /session
  └─► status: waiting   TTL 90 s   (session created, no WS yet)

Caller WebSocket connects
  └─► status: ringing   TTL 60 s   (waiting for receiver)

Receiver WebSocket connects
  └─► status: active    TTL 2 h    (pipelines created, call_started sent)

DELETE /session  OR  last user disconnects
  └─► pipelines destroyed, session removed
```

Sessions are stored in-memory. They do not survive process restarts. For multi-instance deployments, replace `sessionManager.js` with a Redis-backed store.

---

## REST API

All endpoints except `/health` require `Authorization: Bearer <Firebase ID token>`.

| Method | Path | Body | Response |
|--------|------|------|----------|
| `GET` | `/health` | — | `{ status, timestamp }` |
| `POST` | `/session` | `{ receiverUid }` | `201 { sessionId }` |
| `GET` | `/session/:id` | — | `{ sessionId, status, callerUid, receiverUid }` |
| `DELETE` | `/session/:id` | — | `204` |

---

## WebSocket

**Connect:** `ws://host/ws?token=<firebase_id_token>&sessionId=<id>&lang=<BCP-47>`

| Frame | Direction | Content |
|-------|-----------|---------|
| Binary | Client → Server | PCM16 audio (16 kHz, mono) |
| Binary | Server → Client | MP3 audio (translated speech from partner) |
| JSON | Server → Client | Control / transcript events (see below) |

### JSON events (server → client)

```jsonc
{ "type": "connected",    "sessionId": "...", "lang": "mr-IN" }
{ "type": "call_started" }
{ "type": "partner_left" }
{ "type": "transcript",   "text": "...", "lang": "mr-IN", "isFinal": true, "isTranslation": false }
// isTranslation: false → speaker's own words (sent to speaker)
// isTranslation: true  → translated text     (sent to listener)
{ "type": "error",        "message": "..." }
```

---

## Source Files

| File | Responsibility |
|------|---------------|
| `src/index.js` | Bootstrap — Firebase Admin, Express, WebSocketServer, cleanup interval, SIGTERM |
| `src/routes.js` | REST endpoints (`/health`, `/session` CRUD) |
| `src/firebaseAuth.js` | `verifyToken()` wrapper around Firebase Admin |
| `src/sessionManager.js` | In-memory session store with TTL timers |
| `src/translationPipeline.js` | `TranslationPipeline` class — STT → Translate → TTS |
| `src/wsHandler.js` | WebSocket upgrade handler; wires bidirectional pipelines |

---

## Local Development

```bash
cd backend
npm install

# Put your GCP service account key at:
#   secrets/serviceAccountKey.json

export GOOGLE_APPLICATION_CREDENTIALS=./secrets/serviceAccountKey.json
export GOOGLE_CLOUD_PROJECT=voicesewa

npm run dev   # hot-reload via nodemon
# npm start   # production
```

Point the Flutter app at:
- `http://10.0.2.2:8080` — Android emulator
- `http://localhost:8080` — iOS simulator
- `http://<LAN IP>:8080` — physical device on the same network

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `GOOGLE_APPLICATION_CREDENTIALS` | *(required)* | Path to GCP service account JSON |
| `GOOGLE_CLOUD_PROJECT` | *(required)* | GCP project ID |
| `PORT` | `8080` | HTTP/WS listen port |
| `WAITING_TTL_MS` | `90000` | Session TTL before anyone connects (90 s) |
| `RINGING_TTL_MS` | `60000` | Session TTL after caller connects (60 s) |
| `ACTIVE_TTL_MS` | `7200000` | Session TTL once both connected (2 h) |

---

## Deployment

See [`Deploy.md`](./Deploy.md) for a full Google Cloud Run deployment guide using `cloudbuild.yaml`.
