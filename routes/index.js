import { Router } from 'express';
import { StatusCodes } from 'http-status-codes';
import userRoutes from './users.route.js';
import jobRoutes from './job.route.js';
import quotationRoutes from './quotation.route.js';

const router = Router();

router.use('/users', userRoutes);
router.use('/jobs', jobRoutes);
router.use('/quotations', quotationRoutes);

router.get('/health', (req, res) => {
  res.status(StatusCodes.OK).json({
    success: true,
    message: 'API is running',
    timestamp: new Date().toISOString()
  });
});

export default router;