import { StatusCodes } from 'http-status-codes';
import admin from '../firebase.js';


const verifyFirebaseToken = async (req, res, next) => {
  const token = req.headers.authorization?.split("Bearer ")[1];

  if (!token) return res.status(StatusCodes.UNAUTHORIZED).json({ error: "No token" });

  try {
    const decoded = await admin.auth().verifyIdToken(token);
    req.user = decoded;
    next();
  } catch (err) {
    res.status(StatusCodes.UNAUTHORIZED).json({ error: "Invalid Firebase token" });
  }
};

export default verifyFirebaseToken;