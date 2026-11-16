import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.js';
import { list } from './categories.controller.js';

const router = Router();
router.use(requireAuth);
router.get('/', list);

export default router;