import { Router } from 'express';
import admin from 'firebase-admin';
import { verifyToken } from './firebaseAuth.js';
import { createSession, getSession, deleteSession } from './sessionManager.js';

const router = Router();

async function requireAuth(req, res, next) {
  const auth = req.headers.authorization;
  if (!auth?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing Bearer token' });
  }
  try {
    // checkRevoked: false matches the WebSocket handler — the 1-hour JWT
    // expiry is sufficient; the extra revocation network call causes
    // spurious "invalid token" failures on fresh logins.
    req.user = await verifyToken(auth.slice(7), { checkRevoked: false });
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}

router.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// POST /session — caller creates a new session
// Body: { receiverUid: string }
// Returns: { sessionId: string }
router.post('/session', requireAuth, async (req, res) => {
  const { receiverUid } = req.body;
  if (!receiverUid || typeof receiverUid !== 'string') {
    return res.status(400).json({ error: 'receiverUid is required' });
  }
  const callerUid = req.user.uid;
  if (callerUid === receiverUid) {
    return res.status(400).json({ error: 'Cannot call yourself' });
  }

  const sessionId = createSession({ callerUid, receiverUid });

  // Send FCM push to the receiver so they are notified even when the app is
  // backgrounded or closed. The Firestore stream handles the actual call
  // signalling once the app comes to the foreground.
  try {
    const receiverDoc = await admin
      .firestore()
      .collection('users')
      .doc(receiverUid)
      .get();
    const fcmToken = receiverDoc.data()?.fcmToken;
    if (fcmToken) {
      await admin.messaging().send({
        token: fcmToken,
        data: {
          type: 'incoming_call',
          sessionId,
          callerUid,
        },
        android: {
          priority: 'high',
        },
        apns: {
          payload: { aps: { contentAvailable: true } },
          headers: { 'apns-priority': '10' },
        },
      });
      console.log(`[fcm] Notified ${receiverUid} of incoming call`);
    } else {
      console.warn(`[fcm] No FCM token for receiver ${receiverUid}`);
    }
  } catch (fcmErr) {
    // Never fail the session creation because FCM is best-effort.
    console.warn('[fcm] Failed to send push:', fcmErr.message);
  }

  res.status(201).json({ sessionId });
});

// GET /session/:id — poll session status
router.get('/session/:id', requireAuth, (req, res) => {
  const session = getSession(req.params.id);
  if (!session) return res.status(404).json({ error: 'Session not found' });

  const { uid } = req.user;
  if (uid !== session.callerUid && uid !== session.receiverUid) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  res.json({
    sessionId: session.id,
    status: session.status,
    callerUid: session.callerUid,
    receiverUid: session.receiverUid,
  });
});

// DELETE /session/:id — either party can end the call
router.delete('/session/:id', requireAuth, (req, res) => {
  const session = getSession(req.params.id);
  if (!session) return res.status(404).json({ error: 'Session not found' });

  const { uid } = req.user;
  if (uid !== session.callerUid && uid !== session.receiverUid) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  // Notify any connected partner BEFORE deleting the session. Without this,
  // deleteSession() removes the session from memory first, and the subsequent
  // ws 'close' event can no longer find it to send partner_left.
  const partnerLeft = JSON.stringify({ type: 'partner_left' });
  for (const [slotUid, slot] of Object.entries(session.slots)) {
    if (slotUid !== uid && slot.ws.readyState === 1 /* OPEN */) {
      slot.ws.send(partnerLeft);
    }
  }

  deleteSession(req.params.id);
  res.status(204).send();
});

export default router;
