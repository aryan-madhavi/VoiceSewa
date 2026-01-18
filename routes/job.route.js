import { Router } from 'express';
import jobController from '../controllers/job.controller.js';
import verifyFirebaseToken from '../middlewares/firebaseAuth.middleware.js';

const router = Router();

// Create job
router.post('/create', verifyFirebaseToken, jobController.createJob);

// Get job details
router.get('/:jobId', verifyFirebaseToken, jobController.getJobById);

// Get client's jobs
router.get('/client/my-jobs', verifyFirebaseToken, jobController.getMyJobs);

// Get available jobs for worker
router.get('/worker/available', verifyFirebaseToken, jobController.getAvailableJobs);

// Update job
router.patch('/update/:jobId', verifyFirebaseToken, jobController.updateJob);

// Cancel job
router.post('/cancel/:jobId/', verifyFirebaseToken, jobController.cancelJob);

// Delete job
router.delete('/delete/:jobId', verifyFirebaseToken, jobController.deleteJob);

export default router;