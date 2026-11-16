import * as service from './debts.service.js';
import { ok } from '../../utils/response.js';
import {
  idParamSchema,
  paymentParamSchema,
  createDebtSchema,
  updateDebtSchema,
  payDebtSchema,
} from './debts.schema.js';

export async function list(req, res) {
  ok(res, await service.listDebts(req.user.id));
}

export async function get(req, res) {
  const { id } = idParamSchema.parse(req.params);
  ok(res, await service.getDebt(req.user.id, id));
}

export async function create(req, res) {
  const input = createDebtSchema.parse(req.body);
  ok(res, await service.createDebt(req.user.id, input), 'Data berhasil dicatat', 201);
}

export async function update(req, res) {
  const { id } = idParamSchema.parse(req.params);
  const patch = updateDebtSchema.parse(req.body);
  ok(res, await service.updateDebt(req.user.id, id, patch), 'Data berhasil diperbarui');
}

export async function remove(req, res) {
  const { id } = idParamSchema.parse(req.params);
  await service.deleteDebt(req.user.id, id);
  ok(res, null, 'Data berhasil dihapus');
}

export async function pay(req, res) {
  const { id } = idParamSchema.parse(req.params);
  const input = payDebtSchema.parse(req.body);
  ok(res, await service.payDebt(req.user.id, id, input), 'Pembayaran berhasil dicatat', 201);
}

export async function cancelPayment(req, res) {
  const { id, paymentId } = paymentParamSchema.parse(req.params);
  ok(res, await service.cancelPayment(req.user.id, id, paymentId), 'Pembayaran dibatalkan');
}