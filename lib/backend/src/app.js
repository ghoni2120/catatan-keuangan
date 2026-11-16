import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';

import { env, isProd } from './config/env.js';
import { query } from './config/db.js';
import { notFound, errorHandler } from './middleware/errorHandler.js';
import authRoutes from './modules/auth/auth.routes.js';

import categoriesRoutes from './modules/categories/categories.routes.js';
import walletsRoutes from './modules/wallets/wallets.routes.js';

const app = express();

// Aktifkan jika backend berada di belakang proxy/load balancer (agar rate limit membaca IP asli)
if (isProd) app.set('trust proxy', 1);

app.use(helmet());
app.use(
  cors({
    origin(origin, cb) {
      // Tanpa Origin = aplikasi mobile / curl / Postman -> boleh
      if (!origin) return cb(null, true);
      // Flutter Web saat development berjalan di localhost:<port acak>
      if (!isProd && /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)) {
        return cb(null, true);
      }
      if (env.corsOrigins.includes(origin)) return cb(null, true);
      return cb(new Error(`Origin ${origin} tidak diizinkan oleh CORS`));
    },
  })
);
app.use(express.json({ limit: '1mb' }));
app.use(morgan(isProd ? 'combined' : 'dev'));

const api = express.Router();

api.get('/health', async (req, res) => {
  try {
    await query('SELECT 1');
    res.json({ success: true, message: 'API berjalan', data: { db: 'up' } });
  } catch (err) {
    console.error('[health] DB error:', err.message);
    res.status(503).json({ success: false, message: 'Database tidak dapat dihubungi', errors: [] });
  }
});

api.use('/auth', authRoutes);
api.use('/categories', categoriesRoutes);
api.use('/wallets', walletsRoutes);
// Router modul lain (wallets, transactions, dst.) ditambahkan di sini pada step berikutnya.

app.use('/api/v1', api);

app.use(notFound);
app.use(errorHandler);

export default app;