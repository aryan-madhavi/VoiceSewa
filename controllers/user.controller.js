import { StatusCodes } from 'http-status-codes';
import userService from '../services/user.service.js';
import { successResponse, errorResponse } from '../utils/response.util.js';
import logger from '../utils/logger.util.js';

class UserController {
  async getMe(req, res, next) {
    try {
      const uid = req.user.uid;

      const user = await userService.getUserProfile(uid);

      if (!user) {
        return errorResponse(
          res,
          StatusCodes.NOT_FOUND,
          'User profile not found'
        );
      }

      return successResponse(
        res,
        StatusCodes.OK,
        user,
        'User profile retrieved successfully'
      );
    } catch (error) {
      logger.error('Error in getMe controller:', error);
      next(error);
    }
  }

  async updateMe(req, res, next) {
    try {
      const uid = req.user.uid;
      const updateData = req.body;

      // Remove fields that shouldn't be updated directly
      delete updateData.id;
      delete updateData.role;
      delete updateData.services;
      delete updateData.jobs;

      const updatedUser = await userService.updateUserProfile(uid, updateData);

      if (!updatedUser) {
        return errorResponse(
          res,
          StatusCodes.NOT_FOUND,
          'User profile not found'
        );
      }

      return successResponse(
        res,
        StatusCodes.OK,
        updatedUser,
        'User profile updated successfully'
      );
    } catch (error) {
      logger.error('Error in updateMe controller:', error);
      next(error);
    }
  }

  async createClient(req, res, next) {
    try {
      const uid = req.user.uid;
      const clientData = req.body;

      const client = await userService.createClient(uid, clientData);

      return successResponse(
        res,
        StatusCodes.CREATED,
        client,
        'Client profile created successfully'
      );
    } catch (error) {
      logger.error('Error in createClient controller:', error);
      next(error);
    }
  }
}

export default new UserController();