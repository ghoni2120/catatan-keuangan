import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.js';
import * as c from './wallets.controller.js';

const router = Router();
router.use(requireAuth);

router.get('/', c.list);
router.post('/', c.create);
router.post('/transfer', c.transfer); // harus di atas '/:id'
router.get('/:id', c.get);
router.patch('/:id', c.update);
router.delete('/:id', c.remove);

export default router;