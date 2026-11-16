import { query, withTransaction } from '../../config/db.js';
import { AppError } from '../../utils/AppError.js';
import { buildSet } from '../../utils/sql.js';
import {
  DEBT_COLS,
  PAYMENT_COLS,
  TRANSACTION_COLS,
  toDebt,
  toDebtPayment,
  toTransaction,
} from '../../utils/mappers.js';
import { effect, applyWalletDeltas } from '../transactions/transactions.service.js';

const rupiah = (n) => `Rp ${n.toLocaleString('id-ID')}`;

async function loadPayments(db, debtIds) {
  const map = new Map();
  if (!debtIds.length) return map;
  const { rows } = await db.query(
    `SELECT ${PAYMENT_COLS} FROM debt_payments
     WHERE debt_id = ANY($1::uuid[]) ORDER BY date DESC, created_at DESC`,
    [debtIds]
  );
  for (const r of rows) {
    if (!map.has(r.debt_id)) map.set(r.debt_id, []);
    map.get(r.debt_id).push(toDebtPayment(r));
  }
  return map;
}

async function fetchDebt(db, userId, id, { lock = false } = {}) {
  const { rows } = await db.query(
    `SELECT ${DEBT_COLS} FROM debts WHERE id = $1 AND user_id = $2 ${lock ? 'FOR UPDATE' : ''}`,
    [id, userId]
  );
  if (!rows[0]) throw new AppError('Data utang/piutang tidak ditemukan', 404);
  return rows[0];
}

async function present(db, row) {
  const payments = (await loadPayments(db, [row.id])).get(row.id) || [];
  return toDebt(row, payments);
}

export async function listDebts(userId) {
  const { rows } = await query(
    `SELECT ${DEBT_COLS} FROM debts WHERE user_id = $1 ORDER BY created_at DESC, id`,
    [userId]
  );
  const payments = await loadPayments({ query }, rows.map((r) => r.id));
  return rows.map((r) => toDebt(r, payments.get(r.id) || []));
}

export async function getDebt(userId, id) {
  const row = await fetchDebt({ query }, userId, id);
  return present({ query }, row);
}

export async function createDebt(userId, d) {
  const { rows } = await query(
    `INSERT INTO debts (user_id, person_name, type, amount, due_date, notes)
     VALUES ($1, $2, $3, $4, $5, $6) RETURNING ${DEBT_COLS}`,
    [userId, d.personName, d.type, d.amount, d.dueDate ?? null, d.notes || null]
  );
  return toDebt(rows[0], []);
}

const UPDATABLE = {
  personName: 'person_name',
  amount: 'amount',
  dueDate: 'due_date',
  notes: 'notes',
};

export async function updateDebt(userId, id, patch) {
  return withTransaction(async (db) => {
    const debt = await fetchDebt(db, userId, id, { lock: true });
    if (patch.amount !== undefined && patch.amount < debt.paid_amount) {
      throw new AppError(
        `Nominal tidak boleh lebih kecil dari yang sudah dibayar (${rupiah(debt.paid_amount)})`,
        422
      );
    }
    const { sets, values } = buildSet(patch, UPDATABLE);
    if (!sets.length) throw new AppError('Tidak ada data yang diubah', 400);

    values.push(id);
    const { rows } = await db.query(
      `UPDATE debts SET ${sets.join(', ')} WHERE id = $${values.length} RETURNING ${DEBT_COLS}`,
      values
    );
    return present(db, rows[0]);
  });
}

// Sama seperti Flutter: uang yang sudah keluar/masuk TIDAK dikembalikan.
// Transaksi pembayarannya dilepas dari utang (jadi transaksi biasa) agar tetap bisa dikelola.
export async function deleteDebt(userId, id) {
  return withTransaction(async (db) => {
    await fetchDebt(db, userId, id, { lock: true });
    await db.query(
      `UPDATE transactions SET source = 'manual', source_id = NULL
       WHERE user_id = $1 AND source = 'debt_payment'
         AND source_id IN (SELECT id FROM debt_payments WHERE debt_id = $2)`,
      [userId, id]
    );
    await db.query('DELETE FROM debts WHERE id = $1', [id]); // payments ikut terhapus (CASCADE)
  });
}

export async function payDebt(userId, debtId, { amount, walletId, notes }) {
  return withTransaction(async (db) => {
    const debt = await fetchDebt(db, userId, debtId, { lock: true });
    const remaining = debt.amount - debt.paid_amount;
    const label = debt.type === 'debt' ? 'utang' : 'piutang';
    if (remaining <= 0) throw new AppError(`Ini sudah lunas`, 422);
    if (amount > remaining) {
      throw new AppError(`Nominal melebihi sisa ${label} (sisa ${rupiah(remaining)})`, 422);
    }

    // Utang: uang keluar dari dompet. Piutang: uang masuk ke dompet.
    const txType = debt.type === 'debt' ? 'expense' : 'income';
    const wallets = await applyWalletDeltas(
      db,
      userId,
      new Map([[walletId, effect(txType, amount)]])
    );

    const now = new Date();
    const pay = (
      await db.query(
        `INSERT INTO debt_payments (debt_id, wallet_id, amount, date, notes)
         VALUES ($1, $2, $3, $4, $5) RETURNING ${PAYMENT_COLS}`,
        [debtId, walletId, amount, now, notes || null]
      )
    ).rows[0];

    const title =
      debt.type === 'debt' ? `Bayar Utang: ${debt.person_name}` : `Terima Piutang: ${debt.person_name}`;
    const defaultNote =
      debt.type === 'debt' ? 'Pembayaran cicilan / pelunasan utang' : 'Penerimaan pembayaran piutang';
    const tx = (
      await db.query(
        `INSERT INTO transactions
           (user_id, title, amount, type, category_id, wallet_id, date, note, source, source_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'debt_payment', $9)
         RETURNING ${TRANSACTION_COLS}`,
        [
          userId, title, amount, txType,
          debt.type === 'debt' ? 'exp_other' : 'inc_other',
          walletId, now, notes || defaultNote, pay.id,
        ]
      )
    ).rows[0];

    const updated = (
      await db.query(
        `UPDATE debts SET paid_amount = paid_amount + $1 WHERE id = $2 RETURNING ${DEBT_COLS}`,
        [amount, debtId]
      )
    ).rows[0];

    return {
      debt: await present(db, updated),
      payment: toDebtPayment(pay),
      transaction: toTransaction(tx),
      wallets,
    };
  });
}

// Membatalkan satu pembayaran: saldo dompet dikembalikan, transaksi terkait dihapus.
export async function cancelPayment(userId, debtId, paymentId) {
  return withTransaction(async (db) => {
    const debt = await fetchDebt(db, userId, debtId, { lock: true });
    const found = await db.query(
      `SELECT ${PAYMENT_COLS} FROM debt_payments WHERE id = $1 AND debt_id = $2`,
      [paymentId, debtId]
    );
    const pay = found.rows[0];
    if (!pay) throw new AppError('Pembayaran tidak ditemukan', 404);

    const txType = debt.type === 'debt' ? 'expense' : 'income';
    const wallets = await applyWalletDeltas(
      db,
      userId,
      new Map([[pay.wallet_id, -effect(txType, pay.amount)]])
    );

    await db.query(
      `DELETE FROM transactions WHERE user_id = $1 AND source = 'debt_payment' AND source_id = $2`,
      [userId, paymentId]
    );
    await db.query('DELETE FROM debt_payments WHERE id = $1', [paymentId]);
    const updated = (
      await db.query(
        `UPDATE debts SET paid_amount = paid_amount - $1 WHERE id = $2 RETURNING ${DEBT_COLS}`,
        [pay.amount, debtId]
      )
    ).rows[0];

    return { debt: await present(db, updated), wallets };
  });
}