import { Router } from 'express';
import { StatusCodes } from 'http-status-codes';

const router = Router();

router.get('/users/me', (req, res) => {
  res.status(StatusCodes.NOT_FOUND)
  res.send({
    error: "Resource not Found",
  });
})

export default router;