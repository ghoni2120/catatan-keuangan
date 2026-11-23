import * as service from './savings.service.js';
import { ok } from '../../utils/response.js';
import {
  idParamSchema,
  logParamSchema,
  createGoalSchema,
  updateGoalSchema,
  moveMoneySchema,
  deleteGoalQuerySchema,
} from './savings.schema.js';

export async function list(req, res) {
  ok(res, await service.listGoals(req.user.id));
}

export async function get(req, res) {
  const { id } = idParamSchema.parse(req.params);
  ok(res, await service.getGoal(req.user.id, id));
}

export async function create(req, res) {
  const input = createGoalSchema.parse(req.body);
  ok(res, await service.createGoal(req.user.id, input), 'Tujuan tabungan dibuat', 201);
}

export async function update(req, res) {
  const { id } = idParamSchema.parse(req.params);
  const patch = updateGoalSchema.parse(req.body);
  ok(res, await service.updateGoal(req.user.id, id, patch), 'Tujuan tabungan diperbarui');
}

export async function remove(req, res) {
  const { id } = idParamSchema.parse(req.params);
  const { refundWalletId } = deleteGoalQuerySchema.parse(req.query);
  ok(res, await service.deleteGoal(req.user.id, id, { refundWalletId }), 'Tujuan tabungan dihapus');
}

export async function deposit(req, res) {
  const { id } = idParamSchema.parse(req.params);
  const input = moveMoneySchema.parse(req.body);
  ok(res, await service.deposit(req.user.id, id, input), 'Setoran berhasil dicatat', 201);
}

export async function withdraw(req, res) {
  const { id } = idParamSchema.parse(req.params);
  const input = moveMoneySchema.parse(req.body);
  ok(res, await service.withdraw(req.user.id, id, input), 'Penarikan berhasil dicatat', 201);
}

export async function cancelLog(req, res) {
  const { id, logId } = logParamSchema.parse(req.params);
  ok(res, await service.cancelLog(req.user.id, id, logId), 'Riwayat dibatalkan');
}