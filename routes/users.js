import { Router } from 'express';
import { StatusCodes } from 'http-status-codes';
import verifyFirebaseToken from '../middleware/authfirebasetoken.js';

const router = Router();

router.get('/users/me', verifyFirebaseToken, (req, res) => {
  res.status(StatusCodes.NOT_FOUND)
  res.send({
    error: "Resource not Found",
  });
})

export default router;