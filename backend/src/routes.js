import { Router } from 'express';
import { verifyToken } from './firebaseAuth.js';
import { createSession, getSession, deleteSession } from './sessionManager.js';

const router = Router();

async function requireAuth(req, res, next) {
  const auth = req.headers.authorization;
  if (!auth?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing Bearer token' });
  }
  try {
    req.user = await verifyToken(auth.slice(7));
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
router.post('/session', requireAuth, (req, res) => {
  const { receiverUid } = req.body;
  if (!receiverUid || typeof receiverUid !== 'string') {
    return res.status(400).json({ error: 'receiverUid is required' });
  }
  const callerUid = req.user.uid;
  if (callerUid === receiverUid) {
    return res.status(400).json({ error: 'Cannot call yourself' });
  }

  const sessionId = createSession({ callerUid, receiverUid });
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

  deleteSession(req.params.id);
  res.status(204).send();
});

export default router;
