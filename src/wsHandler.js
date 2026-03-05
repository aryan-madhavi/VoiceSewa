/**
 * wsHandler.js
 *
 * Handles WebSocket connections from Flutter clients.
 *
 * Connection URL format:
 *   ws://host:port/ws?sessionId=XXX&sourceLang=en-US&targetLang=es&voiceLang=es-ES
 *
 * Message protocol:
 *   Client → Server:  Binary frames (raw PCM16 audio, 16kHz mono)
 *   Server → Client:  Binary frames (raw PCM16 audio, translated speech)
 *                     OR JSON string frames (transcript updates, errors, events)
 */

import { WebSocketServer, WebSocket } from 'ws';
import {
  getSession,
  removeUserFromSession,
} from './sessionManager.js';
import { createTranslationSession } from './translationSession.js';
import { verifyWsToken } from './firebaseAuth.js';

// JSON helper — always safe to call on the wire
function sendJson(ws, payload) {
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(payload));
  }
}

// Binary helper for translated audio
function sendAudio(ws, audioBuffer) {
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(audioBuffer);
  }
}

/**
 * Attach a WebSocket upgrade handler to an existing HTTP server.
 * @param {import('http').Server} httpServer
 */
export function attachWebSocketServer(httpServer) {
  const wss = new WebSocketServer({ server: httpServer, path: '/ws' });

  wss.on('connection', async (ws, req) => {
    // ── Parse query params ────────────────────────────────────────────────────
    const url = new URL(req.url, 'http://localhost');
    const token      = url.searchParams.get('token');
    const sessionId  = url.searchParams.get('sessionId');
    const sourceLang = url.searchParams.get('sourceLang') || 'en-US';
    const targetLang = url.searchParams.get('targetLang') || 'hi';
    const voiceLang  = url.searchParams.get('voiceLang')  || 'hi-IN';

    // ── Verify Firebase ID token ──────────────────────────────────────────────
    // Flutter sends: ws://host/ws?token=<firebase-id-token>&sessionId=...
    // Works for both email/password and phone number Firebase Auth users.
    let firebaseUser;
    try {
      firebaseUser = await verifyWsToken(token);
    } catch (err) {
      console.warn('[Auth] WS token rejected:', err.message);
      sendJson(ws, { type: 'error', code: 'UNAUTHORIZED', message: 'Invalid or expired token' });
      ws.close(4003, 'Unauthorized');
      return;
    }

    console.log(`[Auth] Verified user uid=${firebaseUser.uid} (${firebaseUser.phone_number ?? firebaseUser.email ?? 'unknown'})`);

    // ── Validate session ──────────────────────────────────────────────────────
    const session = getSession(sessionId);
    if (!session) {
      sendJson(ws, { type: 'error', code: 'SESSION_NOT_FOUND', sessionId });
      ws.close(4001, 'Session not found');
      return;
    }

    if (session.users.length >= 2) {
      sendJson(ws, { type: 'error', code: 'SESSION_FULL', sessionId });
      ws.close(4002, 'Session is full (max 2 users)');
      return;
    }

    // ── Build translation pipeline for this user ──────────────────────────────
    const pipeline = createTranslationSession({
      sourceLang,
      targetLang,
      voiceLang,

      // Translated audio → send to the OTHER user in this session
      onTranslatedAudio: (audioBuffer) => {
        const partner = session.users.find((u) => u !== userEntry);
        if (partner) {
          sendAudio(partner.ws, audioBuffer);
        }
      },

      // Interim/final transcript → send back to THIS user for caption display
      onTranscript: (text, isFinal) => {
        sendJson(ws, { type: 'transcript', text, isFinal, lang: sourceLang });
      },

      onError: (err) => {
        sendJson(ws, { type: 'error', code: 'PIPELINE_ERROR', message: err.message });
      },
    });

    const userEntry = { ws, sourceLang, targetLang, voiceLang, pipeline, uid: firebaseUser.uid };
    session.users.push(userEntry);

    const userIndex = session.users.length; // 1 = caller, 2 = receiver
    console.log(
      `[WS] User ${userIndex} joined session=${sessionId} ` +
      `(${sourceLang} → ${targetLang}, voice=${voiceLang})`
    );

    // Notify client that they're connected and ready
    sendJson(ws, {
      type: 'connected',
      userIndex,
      sessionId,
      sourceLang,
      targetLang,
      voiceLang,
    });

    // Notify both users once the second person joins
    if (session.users.length === 2) {
      for (const user of session.users) {
        sendJson(user.ws, { type: 'call_started', sessionId });
      }
      console.log(`[WS] Call started for session=${sessionId}`);
    }

    // ── Incoming messages ─────────────────────────────────────────────────────
    ws.on('message', (data, isBinary) => {
      if (isBinary) {
        // Raw PCM audio chunk from Flutter microphone → feed into STT pipeline
        pipeline.sendAudio(data);
      } else {
        // Control messages (future: mute, language switch, etc.)
        try {
          const msg = JSON.parse(data.toString());
          console.log(`[WS] Control msg from session=${sessionId}:`, msg);
        } catch {
          // Ignore malformed text frames
        }
      }
    });

    // ── Disconnect ────────────────────────────────────────────────────────────
    ws.on('close', (code, reason) => {
      console.log(
        `[WS] User ${userIndex} left session=${sessionId} ` +
        `(code=${code}, reason=${reason})`
      );

      removeUserFromSession(session, userEntry);

      // Notify remaining user that partner left
      const remaining = session.users[0];
      if (remaining) {
        sendJson(remaining.ws, { type: 'partner_left', sessionId });
      }
    });

    ws.on('error', (err) => {
      console.error(`[WS] Socket error in session=${sessionId}:`, err.message);
    });
  });

  console.log('[WS] WebSocket server attached at /ws');
  return wss;
}