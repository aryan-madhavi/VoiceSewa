import { StatusCodes } from 'http-status-codes';
import jobService from '../services/job.service.js';
import { successResponse, errorResponse } from '../utils/response.util.js';
import logger from '../utils/logger.util.js';

class JobController {
  async createJob(req, res, next) {
    try {
      const clientUid = req.user.uid;
      const jobData = req.body;

      // Debug log
      logger.debug('Create job request body:', jobData);
      logger.debug('User UID:', clientUid);

      // Check if body exists
      if (!jobData || Object.keys(jobData).length === 0) {
        return errorResponse(
          res,
          StatusCodes.BAD_REQUEST,
          'Request body is required'
        );
      }

      // Validate required fields
      if (!jobData.service_type) {
        return errorResponse(
          res,
          StatusCodes.BAD_REQUEST,
          'service_type is required'
        );
      }

      if (!jobData.description) {
        return errorResponse(
          res,
          StatusCodes.BAD_REQUEST,
          'description is required'
        );
      }

      if (!jobData.address) {
        return errorResponse(
          res,
          StatusCodes.BAD_REQUEST,
          'address is required'
        );
      }

      const job = await jobService.createJob(clientUid, jobData);

      return successResponse(
        res,
        StatusCodes.CREATED,
        job,
        'Job created successfully'
      );
    } catch (error) {
      logger.error('Error in createJob controller:', error);
      next(error);
    }
  }

  async getJobById(req, res, next) {
    try {
      const { jobId } = req.params;

      const job = await jobService.getJobById(jobId);

      if (!job) {
        return errorResponse(
          res,
          StatusCodes.NOT_FOUND,
          'Job not found'
        );
      }

      return successResponse(
        res,
        StatusCodes.OK,
        job,
        'Job retrieved successfully'
      );
    } catch (error) {
      logger.error('Error in getJobById controller:', error);
      next(error);
    }
  }

  async getMyJobs(req, res, next) {
    try {
      const clientUid = req.user.uid;
      const { status } = req.query;

      const filters = {};
      if (status) {
        filters.status = status;
      }

      const jobs = await jobService.getClientJobs(clientUid, filters);

      return successResponse(
        res,
        StatusCodes.OK,
        { items: jobs },
        'Jobs retrieved successfully'
      );
    } catch (error) {
      logger.error('Error in getMyJobs controller:', error);
      next(error);
    }
  }

  async getAvailableJobs(req, res, next) {
    try {
      const workerUid = req.user.uid;

      const jobs = await jobService.getAvailableJobs(workerUid);

      return successResponse(
        res,
        StatusCodes.OK,
        { items: jobs },
        'Available jobs retrieved successfully'
      );
    } catch (error) {
      logger.error('Error in getAvailableJobs controller:', error);
      next(error);
    }
  }

  async updateJob(req, res, next) {
    try {
      const clientUid = req.user.uid;
      const { jobId } = req.params;
      const updateData = req.body;

      const updatedJob = await jobService.updateJob(jobId, clientUid, updateData);

      if (!updatedJob) {
        return errorResponse(
          res,
          StatusCodes.NOT_FOUND,
          'Job not found'
        );
      }

      return successResponse(
        res,
        StatusCodes.OK,
        updatedJob,
        'Job updated successfully'
      );
    } catch (error) {
      if (error.message === 'Unauthorized to update this job') {
        return errorResponse(
          res,
          StatusCodes.FORBIDDEN,
          error.message
        );
      }
      if (error.message === 'Cannot update job in current status') {
        return errorResponse(
          res,
          StatusCodes.BAD_REQUEST,
          error.message
        );
      }
      logger.error('Error in updateJob controller:', error);
      next(error);
    }
  }

  async cancelJob(req, res, next) {
    try {
      const clientUid = req.user.uid;
      const { jobId } = req.params;

      const result = await jobService.cancelJob(jobId, clientUid);

      if (!result) {
        return errorResponse(
          res,
          StatusCodes.NOT_FOUND,
          'Job not found'
        );
      }

      return successResponse(
        res,
        StatusCodes.OK,
        result,
        'Job cancelled successfully'
      );
    } catch (error) {
      if (error.message === 'Unauthorized to cancel this job') {
        return errorResponse(
          res,
          StatusCodes.FORBIDDEN,
          error.message
        );
      }
      if (error.message === 'Cannot cancel completed job') {
        return errorResponse(
          res,
          StatusCodes.BAD_REQUEST,
          error.message
        );
      }
      logger.error('Error in cancelJob controller:', error);
      next(error);
    }
  }

  async deleteJob(req, res, next) {
    try {
      const clientUid = req.user.uid;
      const { jobId } = req.params;

      const result = await jobService.deleteJob(jobId, clientUid);

      if (!result) {
        return errorResponse(
          res,
          StatusCodes.NOT_FOUND,
          'Job not found'
        );
      }

      return successResponse(
        res,
        StatusCodes.OK,
        null,
        'Job deleted successfully'
      );
    } catch (error) {
      if (error.message === 'Unauthorized to delete this job') {
        return errorResponse(
          res,
          StatusCodes.FORBIDDEN,
          error.message
        );
      }
      if (error.message === 'Cannot delete job in current status') {
        return errorResponse(
          res,
          StatusCodes.BAD_REQUEST,
          error.message
        );
      }
      logger.error('Error in deleteJob controller:', error);
      next(error);
    }
  }
}

export default new JobController();