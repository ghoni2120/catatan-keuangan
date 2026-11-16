import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.js';
import * as c from './transactions.controller.js';

const router = Router();
router.use(requireAuth);

router.get('/', c.list);
router.post('/', c.create);
router.get('/:id', c.get);
router.put('/:id', c.update);
router.delete('/:id', c.remove);

export default router;