import express from 'express';
import UserRoutes from './routes/users.js';

const app = express();
const PORT = 3000;

app.use(express.json());

app.use('/api', UserRoutes);

app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
})
