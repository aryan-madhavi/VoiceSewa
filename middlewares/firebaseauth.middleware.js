import { StatusCodes } from 'http-status-codes';
import { auth } from '../config/firebase.js';
import { errorResponse } from '../utils/response.util.js';
import logger from '../utils/logger.util.js';

export const verifyFirebaseToken = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return errorResponse(
        res,
        StatusCodes.UNAUTHORIZED,
        'No authorization token provided'
      );
    }

    const token = authHeader.split('Bearer ')[1];

    const decoded = await auth.verifyIdToken(token);
    
    req.user = {
      uid: decoded.uid,
      email: decoded.email,
      phone: decoded.phone_number,
    };

    next();
  } catch (err) {
    logger.error('Firebase token verification failed:', err);
    return errorResponse(
      res,
      StatusCodes.UNAUTHORIZED,
      'Invalid or expired token'
    );
  }
};

export default verifyFirebaseToken;