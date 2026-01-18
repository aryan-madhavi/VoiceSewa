import { StatusCodes } from 'http-status-codes';
import { errorResponse } from '../utils/response.util.js';
import logger from '../utils/logger.util.js';

export const errorHandler = (err, req, res, next) => {
  logger.error('Error occurred:', err);

  const statusCode = err.statusCode || StatusCodes.INTERNAL_SERVER_ERROR;
  const message = err.message || 'Internal server error';

  return errorResponse(res, statusCode, message, err.errors);
};

export const notFoundHandler = (req, res) => {
  return errorResponse(
    res,
    StatusCodes.NOT_FOUND,
    `Route ${req.originalUrl} not found`
  );
};

export default errorHandler;