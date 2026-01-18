import { Router } from 'express';
import userController from '../controllers/user.controller.js';
import verifyFirebaseToken from '../middlewares/firebaseauth.middleware.js';

const router = Router();

// Get current user profile
router.get('/me', verifyFirebaseToken, userController.getMe);

// Update current user profile
router.put('/me', verifyFirebaseToken, userController.updateMe);

// Create client profile (for new users)
router.post('/client', verifyFirebaseToken, userController.createClient);

export default router;