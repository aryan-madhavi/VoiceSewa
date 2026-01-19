import { StatusCodes } from 'http-status-codes';
import quotationService from '../services/quotation.service.js';
import { successResponse, errorResponse } from '../utils/response.util.js';
import logger from '../utils/logger.util.js';

class QuotationController {
  async submitQuotation(req, res, next) {
    try {
      const workerUid = req.user.uid;
      const { jobId } = req.params;
      const quotationData = req.body;

      logger.debug('Submit quotation request:', { jobId, workerUid, quotationData });

      // Validate required fields
      if (!quotationData.estimated_cost) {
        return errorResponse(
          res,
          StatusCodes.BAD_REQUEST,
          'estimated_cost is required'
        );
      }

      if (parseFloat(quotationData.estimated_cost) <= 0) {
        return errorResponse(
          res,
          StatusCodes.BAD_REQUEST,
          'estimated_cost must be greater than 0'
        );
      }

      if (!quotationData.estimated_time) {
        return errorResponse(
          res,
          StatusCodes.BAD_REQUEST,
          'estimated_time is required'
        );
      }

      const quotation = await quotationService.submitQuotation(
        jobId,
        workerUid,
        quotationData
      );

      return successResponse(
        res,
        StatusCodes.CREATED,
        quotation,
        'Quotation submitted successfully. Client has been notified.'
      );
    } catch (error) {
      if (error.message === 'Job not found') {
        return errorResponse(res, StatusCodes.NOT_FOUND, error.message);
      }
      if (error.message === 'Job is not available for quotations') {
        return errorResponse(res, StatusCodes.BAD_REQUEST, error.message);
      }
      if (error.message === 'You have already submitted a quotation for this job') {
        return errorResponse(res, StatusCodes.CONFLICT, error.message);
      }
      if (error.message === 'Worker profile not found. Please complete your profile first.') {
        return errorResponse(res, StatusCodes.NOT_FOUND, error.message);
      }
      logger.error('Error in submitQuotation controller:', error);
      next(error);
    }
  }

  async getJobQuotations(req, res, next) {
    try {
      const { jobId } = req.params;
      const { sortBy = 'created_at', sortOrder = 'desc' } = req.query;
      const userUid = req.user.uid;

      logger.debug('Get job quotations:', { jobId, userUid, sortBy, sortOrder });

      const result = await quotationService.getJobQuotations(
        jobId,
        userUid,
        { sortBy, sortOrder }
      );

      return successResponse(
        res,
        StatusCodes.OK,
        result,
        'Quotations retrieved successfully'
      );
    } catch (error) {
      if (error.message === 'Job not found') {
        return errorResponse(res, StatusCodes.NOT_FOUND, error.message);
      }
      if (error.message === 'Unauthorized to view quotations for this job') {
        return errorResponse(res, StatusCodes.FORBIDDEN, error.message);
      }
      logger.error('Error in getJobQuotations controller:', error);
      next(error);
    }
  }

  async getQuotationDetails(req, res, next) {
    try {
      const { quotationId } = req.params;
      const { jobId } = req.query;
      const userUid = req.user.uid;

      if (!jobId) {
        return errorResponse(
          res,
          StatusCodes.BAD_REQUEST,
          'jobId query parameter is required'
        );
      }

      logger.debug('Get quotation details:', { quotationId, jobId, userUid });

      const quotation = await quotationService.getQuotationDetails(
        jobId,
        quotationId,
        userUid
      );

      if (!quotation) {
        return errorResponse(
          res,
          StatusCodes.NOT_FOUND,
          'Quotation not found'
        );
      }

      return successResponse(
        res,
        StatusCodes.OK,
        quotation,
        'Quotation details retrieved successfully'
      );
    } catch (error) {
      if (error.message === 'Unauthorized to view this quotation') {
        return errorResponse(res, StatusCodes.FORBIDDEN, error.message);
      }
      logger.error('Error in getQuotationDetails controller:', error);
      next(error);
    }
  }

  async updateQuotation(req, res, next) {
    try {
      const workerUid = req.user.uid;
      const { quotationId } = req.params;
      const { jobId } = req.query;
      const updateData = req.body;

      if (!jobId) {
        return errorResponse(
          res,
          StatusCodes.BAD_REQUEST,
          'jobId query parameter is required'
        );
      }

      if (!updateData || Object.keys(updateData).length === 0) {
        return errorResponse(
          res,
          StatusCodes.BAD_REQUEST,
          'Request body is required'
        );
      }

      logger.debug('Update quotation:', { quotationId, jobId, workerUid, updateData });

      const updatedQuotation = await quotationService.updateQuotation(
        jobId,
        quotationId,
        workerUid,
        updateData
      );

      return successResponse(
        res,
        StatusCodes.OK,
        updatedQuotation,
        'Quotation updated successfully'
      );
    } catch (error) {
      if (error.message === 'Quotation not found') {
        return errorResponse(res, StatusCodes.NOT_FOUND, error.message);
      }
      if (error.message === 'Unauthorized to update this quotation') {
        return errorResponse(res, StatusCodes.FORBIDDEN, error.message);
      }
      if (error.message === 'Cannot update quotation after 5 minutes') {
        return errorResponse(res, StatusCodes.BAD_REQUEST, error.message);
      }
      if (error.message === 'Cannot update quotation that has been viewed by client') {
        return errorResponse(res, StatusCodes.BAD_REQUEST, error.message);
      }
      if (error.message === 'Cannot update accepted or rejected quotation') {
        return errorResponse(res, StatusCodes.BAD_REQUEST, error.message);
      }
      if (error.message === 'No valid fields to update') {
        return errorResponse(res, StatusCodes.BAD_REQUEST, error.message);
      }
      logger.error('Error in updateQuotation controller:', error);
      next(error);
    }
  }

  async withdrawQuotation(req, res, next) {
    try {
      const workerUid = req.user.uid;
      const { quotationId } = req.params;
      const { jobId } = req.query;
      const { reason } = req.body;

      if (!jobId) {
        return errorResponse(
          res,
          StatusCodes.BAD_REQUEST,
          'jobId query parameter is required'
        );
      }

      logger.debug('Withdraw quotation:', { quotationId, jobId, workerUid, reason });

      const result = await quotationService.withdrawQuotation(
        jobId,
        quotationId,
        workerUid,
        reason
      );

      return successResponse(
        res,
        StatusCodes.OK,
        result,
        'Quotation withdrawn successfully'
      );
    } catch (error) {
      if (error.message === 'Quotation not found') {
        return errorResponse(res, StatusCodes.NOT_FOUND, error.message);
      }
      if (error.message === 'Unauthorized to withdraw this quotation') {
        return errorResponse(res, StatusCodes.FORBIDDEN, error.message);
      }
      if (error.message === 'Cannot withdraw accepted quotation') {
        return errorResponse(res, StatusCodes.BAD_REQUEST, error.message);
      }
      logger.error('Error in withdrawQuotation controller:', error);
      next(error);
    }
  }

  async acceptQuotation(req, res, next) {
    try {
      const clientUid = req.user.uid;
      const { quotationId } = req.params;
      const { jobId } = req.query;
      const { scheduled_at, notes } = req.body;

      if (!jobId) {
        return errorResponse(
          res,
          StatusCodes.BAD_REQUEST,
          'jobId query parameter is required'
        );
      }

      // CHECK req.body BEFORE destructuring
      if (!req.body || Object.keys(req.body).length === 0) {
        return errorResponse(
          res,
          StatusCodes.BAD_REQUEST,
          'Request body is required'
        );
      }

      logger.debug('Accept quotation:', { quotationId, jobId, clientUid, scheduled_at, notes });

      const result = await quotationService.acceptQuotation(
        jobId,
        quotationId,
        clientUid,
        { scheduled_at, notes }
      );

      return successResponse(
        res,
        StatusCodes.OK,
        result,
        'Quotation accepted successfully. Job has been scheduled.'
      );
    } catch (error) {
      if (error.message === 'Job not found') {
        return errorResponse(res, StatusCodes.NOT_FOUND, error.message);
      }
      if (error.message === 'Quotation not found') {
        return errorResponse(res, StatusCodes.NOT_FOUND, error.message);
      }
      if (error.message === 'Unauthorized to accept this quotation') {
        return errorResponse(res, StatusCodes.FORBIDDEN, error.message);
      }
      if (error.message === 'Quotation has been withdrawn by worker') {
        return errorResponse(res, StatusCodes.BAD_REQUEST, error.message);
      }
      if (error.message === 'Quotation already accepted or rejected') {
        return errorResponse(res, StatusCodes.BAD_REQUEST, error.message);
      }
      logger.error('Error in acceptQuotation controller:', error);
      next(error);
    }
  }

  async rejectQuotation(req, res, next) {
    try {
      const clientUid = req.user.uid;
      const { quotationId } = req.params;
      const { jobId } = req.query;
      const { reason } = req.body;

      if (!jobId) {
        return errorResponse(
          res,
          StatusCodes.BAD_REQUEST,
          'jobId query parameter is required'
        );
      }

      logger.debug('Reject quotation:', { quotationId, jobId, clientUid, reason });

      const result = await quotationService.rejectQuotation(
        jobId,
        quotationId,
        clientUid,
        reason
      );

      return successResponse(
        res,
        StatusCodes.OK,
        result,
        'Quotation rejected'
      );
    } catch (error) {
      if (error.message === 'Job not found') {
        return errorResponse(res, StatusCodes.NOT_FOUND, error.message);
      }
      if (error.message === 'Quotation not found') {
        return errorResponse(res, StatusCodes.NOT_FOUND, error.message);
      }
      if (error.message === 'Unauthorized to reject this quotation') {
        return errorResponse(res, StatusCodes.FORBIDDEN, error.message);
      }
      if (error.message === 'Quotation already accepted or rejected') {
        return errorResponse(res, StatusCodes.BAD_REQUEST, error.message);
      }
      logger.error('Error in rejectQuotation controller:', error);
      next(error);
    }
  }

  async getMyQuotations(req, res, next) {
    try {
      const workerUid = req.user.uid;
      const { 
        status, 
        page = 1, 
        limit = 20, 
        sortBy = 'created_at', 
        sortOrder = 'desc' 
      } = req.query;

      logger.debug('Get my quotations:', { workerUid, status, page, limit });

      const result = await quotationService.getWorkerQuotations(
        workerUid,
        { status, page: parseInt(page), limit: parseInt(limit), sortBy, sortOrder }
      );

      return successResponse(
        res,
        StatusCodes.OK,
        result,
        'Quotations retrieved successfully'
      );
    } catch (error) {
      logger.error('Error in getMyQuotations controller:', error);
      next(error);
    }
  }
}

export default new QuotationController();