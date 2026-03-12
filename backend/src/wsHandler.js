import { verifyToken } from './firebaseAuth.js';
import {
  getSession,
  addUserToSession,
  removeUserFromSession,
} from './sessionManager.js';
import { TranslationPipeline } from './translationPipeline.js';

function parseQuery(rawUrl) {
  const { searchParams } = new URL(rawUrl, 'http://localhost');
  return {
    token: searchParams.get('token'),
    sessionId: searchParams.get('sessionId'),
    lang: searchParams.get('lang'),
  };
}

/**
 * Handle an HTTP → WebSocket upgrade request.
 * Expected URL: /ws?token=<firebase_id_token>&sessionId=<id>&lang=<BCP-47>
 */
export function handleUpgrade(wss, req, socket, head) {
  const { token, sessionId, lang } = parseQuery(req.url);

  if (!token || !sessionId || !lang) {
    socket.write('HTTP/1.1 400 Bad Request\r\n\r\n');
    socket.destroy();
    return;
  }

  // WS auth: checkRevoked=false avoids a Firebase network call on every connect.
  // The 1-hour JWT expiry is sufficient protection here.
  verifyToken(token, { checkRevoked: false })
    .then((decoded) => {
      const session = getSession(sessionId);
      if (!session) {
        socket.write('HTTP/1.1 404 Not Found\r\n\r\n');
        socket.destroy();
        return;
      }
      if (decoded.uid !== session.callerUid && decoded.uid !== session.receiverUid) {
        socket.write('HTTP/1.1 403 Forbidden\r\n\r\n');
        socket.destroy();
        return;
      }

      wss.handleUpgrade(req, socket, head, (ws) => {
        onConnect(ws, { uid: decoded.uid, sessionId, lang });
      });
    })
    .catch(() => {
      socket.write('HTTP/1.1 401 Unauthorized\r\n\r\n');
      socket.destroy();
    });
}

function send(ws, obj) {
  if (ws.readyState === 1 /* OPEN */) ws.send(JSON.stringify(obj));
}

function onConnect(ws, { uid, sessionId, lang }) {
  console.log(`[ws] ${uid} joined session ${sessionId} (lang: ${lang})`);

  const session = addUserToSession(sessionId, uid, ws, lang);
  send(ws, { type: 'connected', sessionId, lang });

  const slots = session.slots;
  const uids = Object.keys(slots);

  if (uids.length === 2) {
    // Both users connected — wire up bidirectional pipelines.
    const [uidA, uidB] = uids;
    const slotA = slots[uidA];
    const slotB = slots[uidB];

    // A → B: recognise slotA's speech, translate, synthesise in slotB's lang, send to B
    slotA.pipeline = new TranslationPipeline({
      sourceLang: slotA.lang,
      targetLang: slotB.lang,
      onAudio: (audio) => {
        if (slotB.ws.readyState === 1) slotB.ws.send(audio, { binary: true });
      },
      onTranscript: (evt) => {
        // Original speech → show on speaker A's screen
        // Translation      → show on listener B's screen
        const target = evt.isTranslation ? slotB.ws : slotA.ws;
        send(target, { type: 'transcript', ...evt });
      },
    });

    // B → A: recognise slotB's speech, translate, synthesise in slotA's lang, send to A
    slotB.pipeline = new TranslationPipeline({
      sourceLang: slotB.lang,
      targetLang: slotA.lang,
      onAudio: (audio) => {
        if (slotA.ws.readyState === 1) slotA.ws.send(audio, { binary: true });
      },
      onTranscript: (evt) => {
        const target = evt.isTranslation ? slotA.ws : slotB.ws;
        send(target, { type: 'transcript', ...evt });
      },
    });

    const callStarted = JSON.stringify({ type: 'call_started' });
    if (slotA.ws.readyState === 1) slotA.ws.send(callStarted);
    if (slotB.ws.readyState === 1) slotB.ws.send(callStarted);

    console.log(`[ws] Call active: ${uidA}(${slotA.lang}) ↔ ${uidB}(${slotB.lang})`);
  }

  ws.on('message', (data, isBinary) => {
    if (!isBinary) return; // only accept binary PCM16 audio frames
    // Re-fetch slot in case reference was replaced during pipeline init
    session.slots[uid]?.pipeline?.sendAudio(data);
  });

  ws.on('close', () => {
    console.log(`[ws] ${uid} left session ${sessionId}`);
    const live = getSession(sessionId);
    if (!live) return;

    // Notify partner before removing
    const partnerUid = Object.keys(live.slots).find((u) => u !== uid);
    if (partnerUid) {
      send(live.slots[partnerUid].ws, { type: 'partner_left' });
    }

    removeUserFromSession(sessionId, uid);
  });

  ws.on('error', (err) => {
    console.error(`[ws] Error for ${uid}: ${err.message}`);
  });
}
