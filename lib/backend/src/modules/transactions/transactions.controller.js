import * as service from './transactions.service.js';
import { ok } from '../../utils/response.js';
import { idParamSchema, transactionBodySchema, listQuerySchema } from './transactions.schema.js';

export async function list(req, res) {
  const filters = listQuerySchema.parse(req.query);
  const { items, total } = await service.listTransactions(req.user.id, filters);
  ok(res, items, 'Berhasil', 200, { total, limit: filters.limit, offset: filters.offset });
}

export async function get(req, res) {
  const { id } = idParamSchema.parse(req.params);
  ok(res, await service.getTransaction(req.user.id, id));
}

export async function create(req, res) {
  const input = transactionBodySchema.parse(req.body);
  ok(res, await service.createTransaction(req.user.id, input), 'Transaksi berhasil dicatat', 201);
}

export async function update(req, res) {
  const { id } = idParamSchema.parse(req.params);
  const input = transactionBodySchema.parse(req.body);
  ok(res, await service.updateTransaction(req.user.id, id, input), 'Transaksi berhasil diperbarui');
}

export async function remove(req, res) {
  const { id } = idParamSchema.parse(req.params);
  ok(res, await service.deleteTransaction(req.user.id, id), 'Transaksi berhasil dihapus');
}