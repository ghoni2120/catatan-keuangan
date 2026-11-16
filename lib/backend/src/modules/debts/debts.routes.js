import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.js';
import * as c from './debts.controller.js';

const router = Router();
router.use(requireAuth);

router.get('/', c.list);
router.post('/', c.create);
router.get('/:id', c.get);
router.patch('/:id', c.update);
router.delete('/:id', c.remove);
router.post('/:id/payments', c.pay);
router.delete('/:id/payments/:paymentId', c.cancelPayment);

export default router;