import { Router } from 'express';
import quotationController from '../controllers/quotation.controller.js';
import verifyFirebaseToken from '../middlewares/firebaseAuth.middleware.js';

const router = Router();

// Submit quotation for a job
router.post('/:jobId/submit', verifyFirebaseToken, quotationController.submitQuotation);

// Get all quotations for a job (Client only)
router.get('/:jobId/getAll', verifyFirebaseToken, quotationController.getJobQuotations);

// Get worker's own quotations
router.get('/my-quotations', verifyFirebaseToken, quotationController.getMyQuotations);

// Get specific quotation details
router.get('/:quotationId/get', verifyFirebaseToken, quotationController.getQuotationDetails);

// Update quotation (Worker only - within 5 min, before client views)
router.patch('/:quotationId/update', verifyFirebaseToken, quotationController.updateQuotation);
    
// Withdraw quotation (Worker only)
router.post('/:quotationId/withdraw', verifyFirebaseToken, quotationController.withdrawQuotation);

// Accept quotation (Client only)
router.post('/:quotationId/accept', verifyFirebaseToken, quotationController.acceptQuotation);

// Reject quotation (Client only)
router.post('/:quotationId/reject', verifyFirebaseToken, quotationController.rejectQuotation);

export default router;
