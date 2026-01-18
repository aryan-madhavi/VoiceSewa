import { Router } from 'express';
import userController from '../controllers/user.controller.js';
import verifyFirebaseToken from '../middlewares/firebaseAuth.middleware.js';

const router = Router();

// Get current user profile
router.get('/me', verifyFirebaseToken, userController.getMe);

// Update current user profile
router.put('/update/me', verifyFirebaseToken, userController.updateMe);

// Create client profile (for new users)
router.post('/create/client', verifyFirebaseToken, userController.createClient);

export default router;