import { Router } from 'express';
import { StatusCodes } from 'http-status-codes';
import userRoutes from './users.route.js';

const router = Router();

// Mount routes
router.use('/users', userRoutes);

// Health check
router.get('/health', (req, res) => {
  res.status(StatusCodes.OK).json({
    success: true,
    message: 'API is running',
    timestamp: new Date().toISOString()
  });
});

export default router;