import express from 'express';
import config from './config/env.js';
import routes from './routes/index.js';
import { errorHandler, notFoundHandler } from './middlewares/error.middleware.js';
import logger from './utils/logger.util.js';

const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`);
  next();
});

app.use('/api', routes);

// app.get('/api/deploy/status', (req,res) => {
//   res.status(200).json({
//     msg: `Server is running on http://oneplus-gm1901.orthrus-mahi.ts.net:${config.port}`,
//   })
// })
app.get('/api/deploy/status', (req, res) => {
  res.status(200).json({
    success: true,
    message: `Server is running on port ${config.port}`,
    timestamp: new Date().toISOString(),
    environment: config.nodeEnv
  });
});

app.use(notFoundHandler);
app.use(errorHandler);

app.listen(config.port, () => {
  logger.info(`Server is running on port ${config.port}`);
  logger.info(`Environment: ${config.nodeEnv}`);
});