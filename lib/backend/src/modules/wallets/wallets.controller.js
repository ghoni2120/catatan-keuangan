import * as service from './wallets.service.js';
import { ok } from '../../utils/response.js';
import {
  idParamSchema,
  createWalletSchema,
  updateWalletSchema,
  transferSchema,
} from './wallets.schema.js';

export async function list(req, res) {
  ok(res, await service.listWallets(req.user.id));
}

export async function get(req, res) {
  const { id } = idParamSchema.parse(req.params);
  ok(res, await service.getWallet(req.user.id, id));
}

export async function create(req, res) {
  const input = createWalletSchema.parse(req.body);
  ok(res, await service.createWallet(req.user.id, input), 'Dompet berhasil dibuat', 201);
}

export async function update(req, res) {
  const { id } = idParamSchema.parse(req.params);
  const patch = updateWalletSchema.parse(req.body);
  ok(res, await service.updateWallet(req.user.id, id, patch), 'Dompet berhasil diperbarui');
}

export async function remove(req, res) {
  const { id } = idParamSchema.parse(req.params);
  await service.deleteWallet(req.user.id, id);
  ok(res, null, 'Dompet berhasil dihapus');
}

export async function transfer(req, res) {
  const input = transferSchema.parse(req.body);
  ok(res, await service.transfer(req.user.id, input), 'Transfer berhasil', 201);
}