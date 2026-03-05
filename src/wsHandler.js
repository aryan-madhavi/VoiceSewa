/**
 * wsHandler.js
 *
 * Handles WebSocket connections from Flutter clients.
 *
 * Connection URL format:
 *   wss://host/ws?token=<firebase-id-token>&sessionId=XXX
 *               &sourceLang=hi-IN&targetLang=hi&voiceLang=hi-IN
 *
 * Session affinity:
 *   Cloud Run session affinity works via a GCILB cookie. Flutter's http package
 *   does NOT persist cookies, so POST /session and WS /ws can land on different
 *   instances → SESSION_NOT_FOUND. Fix: the /session route embeds the sessionId
 *   in the response AND the WS handler echoes the GCILB cookie if present so
 *   the client can resend it. But the real fix is --min-instances=1 in Cloud Run
 *   (set in cloudbuild.yaml) so there's only ever one instance during testing.
 */

import { WebSocketServer, WebSocket } from 'ws';
import {
  getSession,
  removeUserFromSession,
  onFirstUserConnected,
  onCallStarted,
} from './sessionManager.js';
import { createTranslationSession } from './translationSession.js';
import { verifyWsToken } from './firebaseAuth.js';

function sendJson(ws, payload) {
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(payload));
  }
}

function sendAudio(ws, audioBuffer) {
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(audioBuffer);
  }
}

export function attachWebSocketServer(httpServer) {
  const wss = new WebSocketServer({ server: httpServer, path: '/ws' });

  wss.on('connection', async (ws, req) => {
    const url        = new URL(req.url, 'http://localhost');
    const token      = url.searchParams.get('token');
    const sessionId  = url.searchParams.get('sessionId');
    const sourceLang = url.searchParams.get('sourceLang') ?? 'en-US';
    const targetLang = url.searchParams.get('targetLang') ?? 'hi';
    const voiceLang  = url.searchParams.get('voiceLang')  ?? 'hi-IN';

    // ── Auth ─────────────────────────────────────────────────────────────────
    // checkRevoked=false — avoids an extra Firebase network call on every WS
    // connection. The 1-hour JWT expiry is sufficient for WS sessions.
    let firebaseUser;
    try {
      firebaseUser = await verifyWsToken(token);
    } catch (err) {
      console.warn('[WS] Token rejected:', err.message);
      sendJson(ws, { type: 'error', code: 'AUTH_FAILED', message: 'Invalid or expired token' });
      ws.close(4003, 'Unauthorized');
      return;
    }

    console.log(`[WS] Auth ok uid=${firebaseUser.uid}`);

    // ── Session lookup ────────────────────────────────────────────────────────
    const session = getSession(sessionId);
    if (!session) {
      // Most common cause: session was created on a different Cloud Run instance.
      // Solution: set --min-instances=1 in cloudbuild.yaml so there's only
      // one instance and sessions are always found.
      console.warn(`[WS] SESSION_NOT_FOUND: ${sessionId} (check Cloud Run min-instances)`);
      sendJson(ws, { type: 'error', code: 'SESSION_NOT_FOUND', sessionId });
      ws.close(4001, 'Session not found');
      return;
    }

    if (session.users.length >= 2) {
      sendJson(ws, { type: 'error', code: 'SESSION_FULL', sessionId });
      ws.close(4002, 'Session is full');
      return;
    }

    // ── Build translation pipeline ────────────────────────────────────────────
    // Declare userEntry with let so the onTranslatedAudio closure can reference
    // it after assignment (the closure only fires after sendAudio() is called,
    // which only happens after userEntry is fully assigned and pushed).
    let userEntry;

    const pipeline = createTranslationSession({
      sourceLang,
      targetLang,
      voiceLang,

      onTranslatedAudio: (audioBuffer) => {
        const partner = session.users.find((u) => u !== userEntry);
        if (partner) sendAudio(partner.ws, audioBuffer);
      },

      onTranscript: (text, isFinal) => {
        sendJson(ws, { type: 'transcript', text, isFinal, lang: sourceLang });
      },

      onError: (err) => {
        console.error(`[Pipeline] uid=${firebaseUser.uid}:`, err.message);
        sendJson(ws, { type: 'error', code: 'PIPELINE_ERROR', message: err.message });
      },
    });

    userEntry = { ws, uid: firebaseUser.uid, sourceLang, targetLang, voiceLang, pipeline };

    const isFirstUser = session.users.length === 0;
    session.users.push(userEntry);
    const userIndex = session.users.length; // 1 = first to connect, 2 = second

    console.log(`[WS] User ${userIndex} joined session=${sessionId} uid=${firebaseUser.uid} (${sourceLang}→${targetLang})`);

    if (isFirstUser) {
      onFirstUserConnected(session); // cancel waiting timer, start ringing timer
    }

    sendJson(ws, { type: 'connected', userIndex, sessionId, sourceLang, targetLang, voiceLang });

    if (session.users.length === 2) {
      onCallStarted(session); // cancel ringing timer
      for (const user of session.users) {
        sendJson(user.ws, { type: 'call_started', sessionId });
      }
      console.log(`[WS] Call started session=${sessionId}`);
    }

    // ── Incoming messages ─────────────────────────────────────────────────────
    ws.on('message', (data, isBinary) => {
      if (isBinary) {
        pipeline.sendAudio(data);
      } else {
        try {
          const msg = JSON.parse(data.toString());
          if (msg.type === 'ping') {
            // Must respond with pong — Flutter uses this to keep the Cloud Run
            // connection alive. Without pong the client has no way to detect
            // a dead connection until the next send fails.
            sendJson(ws, { type: 'pong' });
          } else {
            console.log(`[WS] Control msg session=${sessionId} type=${msg.type}`);
          }
        } catch {
          // Ignore malformed text frames
        }
      }
    });

    // ── Disconnect ────────────────────────────────────────────────────────────
    ws.on('close', (code, reason) => {
      console.log(`[WS] User ${userIndex} left session=${sessionId} uid=${firebaseUser.uid} code=${code}`);

      removeUserFromSession(session, userEntry);

      // Tell the remaining user their partner left
      const remaining = session.users[0];
      if (remaining) {
        sendJson(remaining.ws, { type: 'partner_left', sessionId });
      }
    });

    ws.on('error', (err) => {
      console.error(`[WS] Socket error session=${sessionId} uid=${firebaseUser.uid}:`, err.message);
      // 'close' fires after 'error', so cleanup happens there
    });
  });

  console.log('[WS] WebSocket server attached at /ws');
  return wss;
}