import { query, withTransaction } from '../../config/db.js';
import { AppError } from '../../utils/AppError.js';
import { buildSet } from '../../utils/sql.js';
import {
  GOAL_COLS,
  LOG_COLS,
  TRANSACTION_COLS,
  toSavingsGoal,
  toSavingsLog,
  toTransaction,
} from '../../utils/mappers.js';
import { effect, applyWalletDeltas } from '../transactions/transactions.service.js';

async function loadLogs(db, goalIds) {
  const map = new Map();
  if (!goalIds.length) return map;
  const { rows } = await db.query(
    `SELECT ${LOG_COLS} FROM savings_logs
     WHERE goal_id = ANY($1::uuid[]) ORDER BY date DESC, created_at DESC`,
    [goalIds]
  );
  for (const r of rows) {
    if (!map.has(r.goal_id)) map.set(r.goal_id, []);
    map.get(r.goal_id).push(toSavingsLog(r));
  }
  return map;
}

async function fetchGoal(db, userId, id, { lock = false } = {}) {
  const { rows } = await db.query(
    `SELECT ${GOAL_COLS} FROM savings_goals WHERE id = $1 AND user_id = $2 ${lock ? 'FOR UPDATE' : ''}`,
    [id, userId]
  );
  if (!rows[0]) throw new AppError('Tujuan tabungan tidak ditemukan', 404);
  return rows[0];
}

async function present(db, row) {
  const logs = (await loadLogs(db, [row.id])).get(row.id) || [];
  return toSavingsGoal(row, logs);
}

export async function listGoals(userId) {
  const { rows } = await query(
    `SELECT ${GOAL_COLS} FROM savings_goals WHERE user_id = $1 ORDER BY created_at DESC, id`,
    [userId]
  );
  const logs = await loadLogs({ query }, rows.map((r) => r.id));
  return rows.map((r) => toSavingsGoal(r, logs.get(r.id) || []));
}

export async function getGoal(userId, id) {
  return present({ query }, await fetchGoal({ query }, userId, id));
}

export async function createGoal(userId, d) {
  const { rows } = await query(
    `INSERT INTO savings_goals
       (user_id, title, target_amount, target_date, icon_code_point, icon_font_family, color, notes)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING ${GOAL_COLS}`,
    [userId, d.title, d.targetAmount, d.targetDate ?? null, d.iconCodePoint, d.iconFontFamily, d.color, d.notes || null]
  );
  return toSavingsGoal(rows[0], []);
}

const UPDATABLE = {
  title: 'title',
  targetAmount: 'target_amount',
  targetDate: 'target_date',
  iconCodePoint: 'icon_code_point',
  iconFontFamily: 'icon_font_family',
  color: 'color',
  notes: 'notes',
};

export async function updateGoal(userId, id, patch) {
  const { sets, values } = buildSet(patch, UPDATABLE);
  if (!sets.length) throw new AppError('Tidak ada data yang diubah', 400);
  values.push(id, userId);
  const { rows } = await query(
    `UPDATE savings_goals SET ${sets.join(', ')}
     WHERE id = $${values.length - 1} AND user_id = $${values.length}
     RETURNING ${GOAL_COLS}`,
    values
  );
  if (!rows[0]) throw new AppError('Tujuan tabungan tidak ditemukan', 404);
  return present({ query }, rows[0]);
}

// Sama seperti Flutter: dana yang masih tersimpan TIDAK otomatis dikembalikan ke dompet
// (setoran sudah tercatat sebagai pengeluaran). Tarik dulu jika ingin mengembalikannya.
export async function deleteGoal(userId, id) {
  return withTransaction(async (db) => {
    await fetchGoal(db, userId, id, { lock: true });
    await db.query(
      `UPDATE transactions SET source = 'manual', source_id = NULL
       WHERE user_id = $1 AND source = 'savings'
         AND source_id IN (SELECT id FROM savings_logs WHERE goal_id = $2)`,
      [userId, id]
    );
    await db.query('DELETE FROM savings_goals WHERE id = $1', [id]); // logs ikut terhapus
  });
}

async function move(userId, goalId, kind, { amount, walletId, notes }) {
  return withTransaction(async (db) => {
    const goal = await fetchGoal(db, userId, goalId, { lock: true });
    const isDeposit = kind === 'deposit';

    let actual = amount;
    if (!isDeposit) {
      if (goal.current_amount <= 0) throw new AppError('Saldo tabungan masih kosong', 422);
      actual = Math.min(amount, goal.current_amount); // sama seperti Flutter: dibatasi saldo tabungan
    }

    const txType = isDeposit ? 'expense' : 'income';
    const wallets = await applyWalletDeltas(
      db,
      userId,
      new Map([[walletId, effect(txType, actual)]])
    );

    const now = new Date();
    const log = (
      await db.query(
        `INSERT INTO savings_logs (goal_id, wallet_id, type, amount, date, notes)
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING ${LOG_COLS}`,
        [goalId, walletId, kind, actual, now, notes || null]
      )
    ).rows[0];

    const title = isDeposit ? `Setor Tabungan: ${goal.title}` : `Tarik Tabungan: ${goal.title}`;
    const defaultNote = isDeposit
      ? `Menabung ke impian "${goal.title}"`
      : `Penarikan dari tabungan "${goal.title}"`;
    const tx = (
      await db.query(
        `INSERT INTO transactions
           (user_id, title, amount, type, category_id, wallet_id, date, note, source, source_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'savings', $9)
         RETURNING ${TRANSACTION_COLS}`,
        [userId, title, actual, txType, isDeposit ? 'exp_other' : 'inc_other', walletId, now, notes || defaultNote, log.id]
      )
    ).rows[0];

    const updated = (
      await db.query(
        `UPDATE savings_goals SET current_amount = current_amount + $1 WHERE id = $2 RETURNING ${GOAL_COLS}`,
        [isDeposit ? actual : -actual, goalId]
      )
    ).rows[0];

    return {
      goal: await present(db, updated),
      log: toSavingsLog(log),
      transaction: toTransaction(tx),
      wallets,
    };
  });
}

export const deposit = (userId, goalId, input) => move(userId, goalId, 'deposit', input);
export const withdraw = (userId, goalId, input) => move(userId, goalId, 'withdraw', input);

// Membatalkan satu setoran/penarikan: saldo dompet & tabungan dikembalikan, transaksi dihapus.
export async function cancelLog(userId, goalId, logId) {
  return withTransaction(async (db) => {
    const goal = await fetchGoal(db, userId, goalId, { lock: true });
    const found = await db.query(
      `SELECT ${LOG_COLS} FROM savings_logs WHERE id = $1 AND goal_id = $2`,
      [logId, goalId]
    );
    const log = found.rows[0];
    if (!log) throw new AppError('Riwayat tabungan tidak ditemukan', 404);

    const isDeposit = log.type === 'deposit';
    const newCurrent = goal.current_amount + (isDeposit ? -log.amount : log.amount);
    if (newCurrent < 0) {
      throw new AppError(
        'Setoran ini tidak dapat dibatalkan karena sebagian dananya sudah ditarik',
        422
      );
    }

    const txType = isDeposit ? 'expense' : 'income';
    const wallets = await applyWalletDeltas(
      db,
      userId,
      new Map([[log.wallet_id, -effect(txType, log.amount)]])
    );

    await db.query(
      `DELETE FROM transactions WHERE user_id = $1 AND source = 'savings' AND source_id = $2`,
      [userId, logId]
    );
    await db.query('DELETE FROM savings_logs WHERE id = $1', [logId]);
    const updated = (
      await db.query(
        `UPDATE savings_goals SET current_amount = $1 WHERE id = $2 RETURNING ${GOAL_COLS}`,
        [newCurrent, goalId]
      )
    ).rows[0];

    return { goal: await present(db, updated), wallets };
  });
}