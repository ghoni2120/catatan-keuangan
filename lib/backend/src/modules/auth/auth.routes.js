import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { requireAuth } from '../../middleware/auth.js';
import * as c from './auth.controller.js';

const router = Router();

// Batasi percobaan register/login per IP untuk mencegah brute force
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 30,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { success: false, message: 'Terlalu banyak percobaan, coba lagi nanti', errors: [] },
});

router.post('/register', authLimiter, c.register);
router.post('/login', authLimiter, c.login);
router.post('/refresh', c.refresh);
router.post('/logout', c.logout);
router.get('/me', requireAuth, c.me);

export default router;