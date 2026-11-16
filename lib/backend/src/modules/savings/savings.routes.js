import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.js';
import * as c from './savings.controller.js';

const router = Router();
router.use(requireAuth);

router.get('/', c.list);
router.post('/', c.create);
router.get('/:id', c.get);
router.patch('/:id', c.update);
router.delete('/:id', c.remove);
router.post('/:id/deposit', c.deposit);
router.post('/:id/withdraw', c.withdraw);
router.delete('/:id/logs/:logId', c.cancelLog);

export default router;