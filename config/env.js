import dotenv from 'dotenv';

dotenv.config();

export const config = {
  baseEndpoint: process.env.BASE_ENDPOINT || '/api',
  port: process.env.PORT || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID,
  },
};

export default config;