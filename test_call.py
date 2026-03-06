#!/usr/bin/env python3
"""
test_call.py — VoiceSewa backend end-to-end test
=================================================
Simulates two participants (caller + receiver) without a Flutter app.

What it tests:
  ✓ POST /session  — backend session creation
  ✓ Firestore write — call doc creation (triggers Cloud Function → FCM)
  ✓ WebSocket connect (both sides)
  ✓ Audio streaming — reads raw PCM from mic or a WAV file
  ✓ Transcript events — prints live STT captions from backend
  ✓ Hang-up — DELETE /session + Firestore status update

Requirements:
  pip install firebase-admin requests websockets pyaudio

Setup:
  1. Download a Firebase service account key:
       Firebase Console → Project Settings → Service accounts
       → Generate new private key → save as serviceAccountKey.json
  2. Fill in the UID_* constants below with two real Firebase Auth UIDs
     (create two test users in Firebase Console → Authentication → Users)
  3. Run: python test_call.py
     Add --wav path/to/file.wav to stream a WAV file instead of the mic
     Add --no-audio to test signalling only (no audio streaming)

Usage:
  python test_call.py
  python test_call.py --wav test_audio.wav
  python test_call.py --no-audio
  python test_call.py --duration 20   # hang up after N seconds (default 15)
"""

import argparse
import asyncio
import json
import struct
import sys
import time
import wave
from pathlib import Path

import os

import requests
import websockets
from dotenv import load_dotenv

# ── firebase-admin for Firestore + auth token minting ─────────────────────────
import firebase_admin
from firebase_admin import auth, credentials, firestore

# Load .env file from same directory as this script
load_dotenv(Path(__file__).parent / ".env")

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURE THESE
# ─────────────────────────────────────────────────────────────────────────────

SERVICE_ACCOUNT_KEY = os.getenv("SERVICE_ACCOUNT_KEY", "serviceAccountKey.json")

# Loaded from .env — see .env.example
CALLER_UID      = os.getenv("CALLER_UID",   "")
RECEIVER_UID    = os.getenv("RECEIVER_UID", "")
FIREBASE_WEB_API_KEY = os.getenv("FIREBASE_WEB_API_KEY", "")

CALLER_NAME   = "Test Caller"
RECEIVER_NAME = "Test Receiver"
CALLER_LANG   = "hi-IN"   # BCP-47 — must match a CallLanguage.sourceLang
RECEIVER_LANG = "en-IN"

# Backend URLs — must match AppConstants in your Flutter app
BACKEND_HTTP = "https://voicesewa-call-translate-bzjis3bz3q-el.a.run.app"
BACKEND_WS   = "wss://voicesewa-call-translate-bzjis3bz3q-el.a.run.app/ws"

# Firestore collection names — must match AppConstants
CALLS_COLLECTION         = "calls"
USERS_COLLECTION         = "users"
CALL_HISTORY_SUBCOLLECTION = "call_history"

# Audio — PCM16 mono at 16 kHz (must match backend STT config)
SAMPLE_RATE  = 16000
CHUNK_FRAMES = 1600   # 100 ms per chunk
CHUNK_BYTES  = CHUNK_FRAMES * 2   # 2 bytes per PCM16 sample

# ─────────────────────────────────────────────────────────────────────────────
# Colours for terminal output
# ─────────────────────────────────────────────────────────────────────────────

RESET  = "\033[0m"
BOLD   = "\033[1m"
CYAN   = "\033[96m"
GREEN  = "\033[92m"
YELLOW = "\033[93m"
RED    = "\033[91m"
GREY   = "\033[90m"
BLUE   = "\033[94m"

def log(tag: str, msg: str, color: str = RESET) -> None:
    ts = time.strftime("%H:%M:%S")
    print(f"{GREY}[{ts}]{RESET} {color}{BOLD}[{tag}]{RESET} {msg}")

# ─────────────────────────────────────────────────────────────────────────────
# Firebase init
# ─────────────────────────────────────────────────────────────────────────────

def init_firebase() -> firestore.Client:
    key_path = Path(SERVICE_ACCOUNT_KEY)
    if not key_path.exists():
        print(f"{RED}ERROR: {SERVICE_ACCOUNT_KEY} not found.{RESET}")
        print("Download it from Firebase Console → Project Settings → Service accounts")
        sys.exit(1)

    sa = json.loads(key_path.read_text())
    project_id = sa["project_id"]

    cred = credentials.Certificate(str(key_path))
    # Pass databaseURL and projectId explicitly so the Admin SDK uses the
    # privileged server path that bypasses Firestore security rules.
    firebase_admin.initialize_app(cred, {
        "projectId":   project_id,
        "databaseURL": f"https://{project_id}-default-rtdb.firebaseio.com",
    })
    db = firestore.client()
    log("FIREBASE", f"Initialised (project={project_id}) ✓", GREEN)
    return db


def mint_token(uid: str) -> str:
    """Mint a Firebase custom token and exchange it for an ID token via REST."""
    custom_token = auth.create_custom_token(uid).decode("utf-8")

    # Exchange custom token for ID token using Firebase Auth REST API
    # We need the Web API key — extract it from the service account JSON
    sa = json.loads(Path(SERVICE_ACCOUNT_KEY).read_text())
    project_id = sa["project_id"]

    # Use the identitytoolkit endpoint
    url = (
        f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken"
        f"?key={_get_web_api_key(project_id)}"
    )
    resp = requests.post(url, json={"token": custom_token, "returnSecureToken": True})
    resp.raise_for_status()
    id_token = resp.json()["idToken"]
    log("AUTH", f"ID token minted for uid={uid[:8]}… ✓", GREEN)
    return id_token


def _get_web_api_key(project_id: str) -> str:
    """
    Returns the Firebase Web API key.
    Priority: FIREBASE_WEB_API_KEY env var → ADC auto-fetch → interactive prompt.
    """
    if FIREBASE_WEB_API_KEY:
        return FIREBASE_WEB_API_KEY
    try:
        import google.auth
        import google.auth.transport.requests
        creds, _ = google.auth.default(
            scopes=["https://www.googleapis.com/auth/cloud-platform"]
        )
        creds.refresh(google.auth.transport.requests.Request())
        url = f"https://firebase.googleapis.com/v1beta1/projects/{project_id}/webApps"
        resp = requests.get(
            url, headers={"Authorization": f"Bearer {creds.token}"}
        )
        resp.raise_for_status()
        apps = resp.json().get("apps", [])
        for app in apps:
            config_url = (
                f"https://firebase.googleapis.com/v1beta1/"
                f"{app['name']}/config"
            )
            config_resp = requests.get(
                config_url,
                headers={"Authorization": f"Bearer {creds.token}"},
            )
            if config_resp.ok:
                key = config_resp.json().get("apiKey", "")
                return key
    except Exception:
        pass

    # Fallback — ask user
    print(f"\n{YELLOW}Could not auto-fetch Web API key.{RESET}")
    print("Find it in Firebase Console → Project Settings → General → Web API Key")
    return input("Paste your Firebase Web API Key: ").strip()

# ─────────────────────────────────────────────────────────────────────────────
# REST: session lifecycle
# ─────────────────────────────────────────────────────────────────────────────

def create_backend_session(caller_token: str) -> str:
    resp = requests.post(
        f"{BACKEND_HTTP}/session",
        headers={
            "Authorization": f"Bearer {caller_token}",
            "Content-Type": "application/json",
        },
        timeout=15,
    )
    if resp.status_code != 201:
        raise RuntimeError(
            f"POST /session failed: {resp.status_code} {resp.text}"
        )
    session_id = resp.json()["sessionId"]
    log("REST", f"Session created: {session_id}", GREEN)
    return session_id


def end_backend_session(session_id: str, caller_token: str) -> None:
    try:
        requests.delete(
            f"{BACKEND_HTTP}/session/{session_id}",
            headers={"Authorization": f"Bearer {caller_token}"},
            timeout=10,
        )
        log("REST", f"Session {session_id} ended", GREY)
    except Exception as e:
        log("REST", f"End session error (non-fatal): {e}", YELLOW)

# ─────────────────────────────────────────────────────────────────────────────
# Firestore: signalling
# ─────────────────────────────────────────────────────────────────────────────

def write_call_doc(db: firestore.Client, session_id: str) -> None:
    from google.cloud.firestore_v1 import SERVER_TIMESTAMP

    call_data = {
        "sessionId":        session_id,
        "callerUid":        CALLER_UID,
        "receiverUid":      RECEIVER_UID,
        "callerName":       CALLER_NAME,
        "receiverName":     RECEIVER_NAME,
        "callerLang":       CALLER_LANG,
        "receiverLang":     RECEIVER_LANG,
        "status":           "ringing",
        "createdAt":        SERVER_TIMESTAMP,
        "endedAt":          None,
        "durationSeconds":  None,
        "receiverFcmToken": None,   # no real device in this test
    }

    batch = db.batch()

    # Main call doc
    call_ref = db.collection(CALLS_COLLECTION).document(session_id)
    batch.set(call_ref, call_data)

    # History entry for caller
    caller_hist = db.collection(USERS_COLLECTION)\
                    .document(CALLER_UID)\
                    .collection(CALL_HISTORY_SUBCOLLECTION)\
                    .document(session_id)
    batch.set(caller_hist, {
        "sessionId":       session_id,
        "otherUid":        RECEIVER_UID,
        "otherName":       RECEIVER_NAME,
        "myLang":          CALLER_LANG,
        "otherLang":       RECEIVER_LANG,
        "direction":       "outgoing",
        "status":          "ringing",
        "createdAt":       SERVER_TIMESTAMP,
        "endedAt":         None,
        "durationSeconds": None,
    })

    # History entry for receiver
    receiver_hist = db.collection(USERS_COLLECTION)\
                      .document(RECEIVER_UID)\
                      .collection(CALL_HISTORY_SUBCOLLECTION)\
                      .document(session_id)
    batch.set(receiver_hist, {
        "sessionId":       session_id,
        "otherUid":        CALLER_UID,
        "otherName":       CALLER_NAME,
        "myLang":          RECEIVER_LANG,
        "otherLang":       CALLER_LANG,
        "direction":       "incoming",
        "status":          "ringing",
        "createdAt":       SERVER_TIMESTAMP,
        "endedAt":         None,
        "durationSeconds": None,
    })

    batch.commit()
    log("FIRESTORE", "Call doc + history entries written ✓", GREEN)


def accept_call(db: firestore.Client, session_id: str) -> None:
    db.collection(CALLS_COLLECTION).document(session_id).update(
        {"status": "active"}
    )
    log("FIRESTORE", "status → active (receiver accepted) ✓", GREEN)


def end_call(db: firestore.Client, session_id: str, duration_seconds: int) -> None:
    from google.cloud.firestore_v1 import SERVER_TIMESTAMP
    data = {
        "status":          "ended",
        "endedAt":         SERVER_TIMESTAMP,
        "durationSeconds": duration_seconds,
    }
    db.collection(CALLS_COLLECTION).document(session_id).update(data)

    for uid in [CALLER_UID, RECEIVER_UID]:
        db.collection(USERS_COLLECTION)\
          .document(uid)\
          .collection(CALL_HISTORY_SUBCOLLECTION)\
          .document(session_id)\
          .update(data)

    log("FIRESTORE", f"status → ended (duration={duration_seconds}s) ✓", GREEN)

# ─────────────────────────────────────────────────────────────────────────────
# WebSocket participant
# ─────────────────────────────────────────────────────────────────────────────

class Participant:
    """
    Represents one side of the call on the WebSocket.
    Connects, streams audio, prints transcripts.
    """

    def __init__(
        self,
        name: str,
        token: str,
        session_id: str,
        source_lang: str,
        target_lang: str,
        voice_lang: str,
        audio_source,   # async generator of Uint8List chunks
        color: str,
    ):
        self.name        = name
        self.token       = token
        self.session_id  = session_id
        self.source_lang = source_lang
        self.target_lang = target_lang
        self.voice_lang  = voice_lang
        self.audio_src   = audio_source
        self.color       = color
        self.ws          = None
        self.connected   = asyncio.Event()
        self.call_started = asyncio.Event()
        self._stop       = asyncio.Event()
        self.user_index  = None
        self.audio_bytes_received = 0

    def _ws_url(self) -> str:
        from urllib.parse import urlencode
        params = urlencode({
            "token":      self.token,
            "sessionId":  self.session_id,
            "sourceLang": self.source_lang,
            "targetLang": self.target_lang,
            "voiceLang":  self.voice_lang,
        })
        return f"{BACKEND_WS}?{params}"

    async def run(self) -> None:
        url = self._ws_url()
        log(self.name, f"Connecting to WS…", self.color)
        try:
            async with websockets.connect(
                url,
                ping_interval=20,
                ping_timeout=10,
                max_size=10 * 1024 * 1024,
            ) as ws:
                self.ws = ws
                log(self.name, "WS connected ✓", self.color)

                await asyncio.gather(
                    self._recv_loop(),
                    self._send_loop(),
                )
        except Exception as e:
            log(self.name, f"WS error: {e}", RED)
        finally:
            self._stop.set()

    async def _recv_loop(self) -> None:
        async for msg in self.ws:
            if self._stop.is_set():
                break
            if isinstance(msg, bytes):
                self.audio_bytes_received += len(msg)
                # Audio received — in a real app this goes to the speaker
                # Here we just count it to confirm the pipeline works
            elif isinstance(msg, str):
                try:
                    data = json.loads(msg)
                    await self._handle_json(data)
                except json.JSONDecodeError:
                    pass

    async def _handle_json(self, msg: dict) -> None:
        t = msg.get("type")

        if t == "connected":
            self.user_index = msg.get("userIndex")
            self.connected.set()
            log(self.name,
                f"✓ connected (userIndex={self.user_index})", self.color)

        elif t == "call_started":
            self.call_started.set()
            log(self.name, f"🟢 call_started — translation pipeline active", self.color)

        elif t == "transcript":
            text    = msg.get("text", "")
            is_final = msg.get("isFinal", False)
            lang    = msg.get("lang", "?")
            marker  = "▶" if is_final else "…"
            log(self.name,
                f"{marker} [{lang}] {text}",
                GREEN if is_final else GREY)

        elif t == "partner_left":
            log(self.name, "Partner left the call", YELLOW)
            self._stop.set()

        elif t == "error":
            log(self.name,
                f"Backend error: {msg.get('code')} — {msg.get('message')}",
                RED)

        elif t == "pong":
            pass  # keep-alive, ignore

        else:
            log(self.name, f"Unknown message type: {t} — {msg}", GREY)

    async def _send_loop(self) -> None:
        # Wait until the backend confirms both sides are connected
        await self.call_started.wait()
        log(self.name, "Starting audio stream…", self.color)

        async for chunk in self.audio_src:
            if self._stop.is_set():
                break
            try:
                await self.ws.send(chunk)
            except websockets.ConnectionClosed:
                break

        log(self.name,
            f"Audio stream ended "
            f"({self.audio_bytes_received:,} bytes received from backend)",
            self.color)

    def stop(self) -> None:
        self._stop.set()

# ─────────────────────────────────────────────────────────────────────────────
# Audio sources
# ─────────────────────────────────────────────────────────────────────────────

async def mic_audio_source():
    """Stream PCM16 mono 16 kHz from the default microphone."""
    try:
        import pyaudio
    except ImportError:
        print(f"{RED}pyaudio not installed. Run: pip install pyaudio{RESET}")
        print("Or use --wav to stream a WAV file, or --no-audio to skip audio.")
        sys.exit(1)

    pa     = pyaudio.PyAudio()
    stream = pa.open(
        format=pyaudio.paInt16,
        channels=1,
        rate=SAMPLE_RATE,
        input=True,
        frames_per_buffer=CHUNK_FRAMES,
    )
    log("MIC", "Recording… speak now", CYAN)
    try:
        while True:
            data = stream.read(CHUNK_FRAMES, exception_on_overflow=False)
            yield data
            await asyncio.sleep(0)   # yield control
    finally:
        stream.stop_stream()
        stream.close()
        pa.terminate()


async def wav_audio_source(path: str):
    """Stream PCM16 mono from a WAV file, looping if it ends before hang-up."""
    wav_path = Path(path)
    if not wav_path.exists():
        print(f"{RED}WAV file not found: {path}{RESET}")
        sys.exit(1)

    log("WAV", f"Streaming from {path}", CYAN)
    while True:
        with wave.open(str(wav_path), "rb") as wf:
            if wf.getsampwidth() != 2 or wf.getnchannels() != 1:
                print(f"{YELLOW}Warning: WAV should be PCM16 mono 16kHz. "
                      f"Got: {wf.getsampwidth()*8}-bit, "
                      f"{wf.getnchannels()}ch, "
                      f"{wf.getframerate()}Hz{RESET}")
            while True:
                frames = wf.readframes(CHUNK_FRAMES)
                if not frames:
                    break
                yield frames
                await asyncio.sleep(CHUNK_FRAMES / SAMPLE_RATE)


async def silence_audio_source():
    """Stream silence — useful for testing signalling without audio."""
    silence = bytes(CHUNK_BYTES)
    while True:
        yield silence
        await asyncio.sleep(CHUNK_FRAMES / SAMPLE_RATE)

# ─────────────────────────────────────────────────────────────────────────────
# Orchestration
# ─────────────────────────────────────────────────────────────────────────────

async def run_test(
    db: firestore.Client,
    caller_token: str,
    receiver_token: str,
    audio_source_factory,
    duration_seconds: int,
) -> None:
    print()
    print(f"{BOLD}{'─' * 60}{RESET}")
    print(f"{BOLD}  VoiceSewa Backend Test{RESET}")
    print(f"  Caller:   {CALLER_NAME} ({CALLER_UID[:8]}…) [{CALLER_LANG}]")
    print(f"  Receiver: {RECEIVER_NAME} ({RECEIVER_UID[:8]}…) [{RECEIVER_LANG}]")
    print(f"  Duration: {duration_seconds}s")
    print(f"{BOLD}{'─' * 60}{RESET}")
    print()

    # 1. Create backend session (caller-side REST call)
    session_id = create_backend_session(caller_token)

    # 2. Write Firestore signalling docs
    write_call_doc(db, session_id)

    # Short delay to let Firestore propagate before WS connects
    await asyncio.sleep(0.5)

    # 3. Receiver "accepts" — sets status to active
    accept_call(db, session_id)

    # 4. Build audio sources — each participant gets its own instance
    #    (in a real test you might want different audio per side)
    caller_audio   = audio_source_factory()
    receiver_audio = audio_source_factory()

    # 5. Build participants
    caller = Participant(
        name        = "CALLER",
        token       = caller_token,
        session_id  = session_id,
        source_lang = CALLER_LANG,
        target_lang = RECEIVER_LANG.split("-")[0],  # "en"
        voice_lang  = RECEIVER_LANG,
        audio_source = caller_audio,
        color       = CYAN,
    )

    receiver = Participant(
        name        = "RECEIVER",
        token       = receiver_token,
        session_id  = session_id,
        source_lang = RECEIVER_LANG,
        target_lang = CALLER_LANG.split("-")[0],    # "hi"
        voice_lang  = CALLER_LANG,
        audio_source = receiver_audio,
        color       = BLUE,
    )

    # 6. Connect both sides concurrently + run for duration_seconds
    start = time.time()

    async def run_with_timeout():
        await asyncio.gather(
            caller.run(),
            receiver.run(),
        )

    try:
        await asyncio.wait_for(run_with_timeout(), timeout=duration_seconds)
    except asyncio.TimeoutError:
        log("TEST", f"Duration ({duration_seconds}s) reached — hanging up", YELLOW)
    finally:
        caller.stop()
        receiver.stop()

    elapsed = int(time.time() - start)

    # 7. Clean up
    end_call(db, session_id, elapsed)
    end_backend_session(session_id, caller_token)

    # 8. Summary
    print()
    print(f"{BOLD}{'─' * 60}{RESET}")
    print(f"{BOLD}  Test complete{RESET}")
    print(f"  Session ID:              {session_id}")
    print(f"  Duration:                {elapsed}s")
    print(f"  Caller   audio received: {caller.audio_bytes_received:,} bytes")
    print(f"  Receiver audio received: {receiver.audio_bytes_received:,} bytes")

    all_ok = (
        caller.connected.is_set()
        and receiver.connected.is_set()
        and caller.call_started.is_set()
        and receiver.call_started.is_set()
    )
    status = f"{GREEN}PASS ✓{RESET}" if all_ok else f"{RED}FAIL ✗{RESET}"
    print(f"  Result:                  {status}")

    if not caller.connected.is_set():
        print(f"  {RED}✗ Caller never connected to WebSocket{RESET}")
    if not receiver.connected.is_set():
        print(f"  {RED}✗ Receiver never connected to WebSocket{RESET}")
    if not caller.call_started.is_set():
        print(f"  {RED}✗ call_started event never received (caller){RESET}")
    if not receiver.call_started.is_set():
        print(f"  {RED}✗ call_started event never received (receiver){RESET}")
    if caller.audio_bytes_received == 0:
        print(f"  {YELLOW}⚠ Caller received 0 audio bytes — TTS may not be working{RESET}")
    if receiver.audio_bytes_received == 0:
        print(f"  {YELLOW}⚠ Receiver received 0 audio bytes — TTS may not be working{RESET}")

    print(f"{BOLD}{'─' * 60}{RESET}")

# ─────────────────────────────────────────────────────────────────────────────
# Entry point
# ─────────────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(description="VoiceSewa backend test")
    parser.add_argument(
        "--wav",
        metavar="PATH",
        help="Stream a WAV file instead of the microphone (PCM16 mono 16kHz recommended)",
    )
    parser.add_argument(
        "--no-audio",
        action="store_true",
        help="Send silence — test signalling only, no mic or WAV needed",
    )
    parser.add_argument(
        "--duration",
        type=int,
        default=15,
        help="How many seconds to run the call before hanging up (default: 15)",
    )
    args = parser.parse_args()

    # Validate config
    missing = [k for k, v in {
        "CALLER_UID":           CALLER_UID,
        "RECEIVER_UID":         RECEIVER_UID,
        "FIREBASE_WEB_API_KEY": FIREBASE_WEB_API_KEY,
    }.items() if not v]

    if missing:
        print(f"{RED}ERROR: Missing required .env values: {', '.join(missing)}{RESET}")
        print(f"Copy .env.example to .env and fill in the values.")
        sys.exit(1)

    # Pick audio source
    if args.no_audio:
        log("AUDIO", "Mode: silence (signalling test only)", YELLOW)
        audio_factory = silence_audio_source
    elif args.wav:
        log("AUDIO", f"Mode: WAV file ({args.wav})", CYAN)
        audio_factory = lambda: wav_audio_source(args.wav)
    else:
        log("AUDIO", "Mode: microphone", CYAN)
        audio_factory = mic_audio_source

    # Init Firebase
    db = init_firebase()

    # Mint ID tokens for both test users
    log("AUTH", "Minting ID tokens (requires internet)…", YELLOW)
    caller_token   = mint_token(CALLER_UID)
    receiver_token = mint_token(RECEIVER_UID)

    # Run
    asyncio.run(
        run_test(
            db            = db,
            caller_token  = caller_token,
            receiver_token = receiver_token,
            audio_source_factory = audio_factory,
            duration_seconds = args.duration,
        )
    )


if __name__ == "__main__":
    main()