import express from 'express';
import UserRoutes from './routes/users.js';

const app = express();
const PORT = 3000;

app.use(express.json());

app.use('/api', UserRoutes);

app.get('/api/deploy/status', (req,res) => {
  res.status(200).json({
    msg: `Server is running on http://oneplus-gm1901.orthrus-mahi.ts.net:${PORT}`,
  })
})

app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
})
