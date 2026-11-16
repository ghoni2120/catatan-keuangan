import { randomUUID } from 'node:crypto';
import { query, withTransaction } from '../../config/db.js';
import { AppError } from '../../utils/AppError.js';
import {
  WALLET_COLS,
  TRANSACTION_COLS,
  toWallet,
  toTransaction,
} from '../../utils/mappers.js';

export async function listWallets(userId) {
  const { rows } = await query(
    `SELECT ${WALLET_COLS} FROM wallets WHERE user_id = $1 ORDER BY created_at, id`,
    [userId]
  );
  return rows.map(toWallet);
}

export async function getWallet(userId, id) {
  const { rows } = await query(
    `SELECT ${WALLET_COLS} FROM wallets WHERE id = $1 AND user_id = $2`,
    [id, userId]
  );
  if (!rows[0]) throw new AppError('Dompet tidak ditemukan', 404);
  return toWallet(rows[0]);
}

export async function createWallet(userId, d) {
  const { rows } = await query(
    `INSERT INTO wallets (user_id, name, type, balance, icon_code_point, icon_font_family, color)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING ${WALLET_COLS}`,
    [userId, d.name, d.type, d.balance, d.iconCodePoint, d.iconFontFamily, d.color]
  );
  return toWallet(rows[0]);
}

// Nama kolom diambil dari peta tetap ini (bukan dari input user)
const UPDATABLE = {
  name: 'name',
  type: 'type',
  iconCodePoint: 'icon_code_point',
  iconFontFamily: 'icon_font_family',
  color: 'color',
};

export async function updateWallet(userId, id, patch) {
  const sets = [];
  const values = [];
  for (const [key, column] of Object.entries(UPDATABLE)) {
    if (patch[key] !== undefined) {
      values.push(patch[key]);
      sets.push(`${column} = $${values.length}`);
    }
  }
  if (!sets.length) throw new AppError('Tidak ada data yang diubah', 400);

  values.push(id, userId);
  const { rows } = await query(
    `UPDATE wallets SET ${sets.join(', ')}
     WHERE id = $${values.length - 1} AND user_id = $${values.length}
     RETURNING ${WALLET_COLS}`,
    values
  );
  if (!rows[0]) throw new AppError('Dompet tidak ditemukan', 404);
  return toWallet(rows[0]);
}

export async function deleteWallet(userId, id) {
  try {
    const r = await query('DELETE FROM wallets WHERE id = $1 AND user_id = $2', [id, userId]);
    if (!r.rowCount) throw new AppError('Dompet tidak ditemukan', 404);
  } catch (err) {
    // 23503 = masih direferensikan transaksi / pembayaran utang / log tabungan
    if (err.code === '23503') {
      throw new AppError(
        'Dompet masih memiliki transaksi, utang, atau tabungan terkait sehingga tidak dapat dihapus',
        409
      );
    }
    throw err;
  }
}

export async function transfer(userId, { fromWalletId, toWalletId, amount, note }) {
  if (fromWalletId === toWalletId) {
    throw new AppError('Dompet asal dan tujuan tidak boleh sama', 400);
  }

  return withTransaction(async (db) => {
    // Kunci kedua baris dompet (urut by id agar tidak deadlock)
    const { rows } = await db.query(
      `SELECT ${WALLET_COLS} FROM wallets
       WHERE user_id = $1 AND id = ANY($2::uuid[])
       ORDER BY id FOR UPDATE`,
      [userId, [fromWalletId, toWalletId]]
    );
    const from = rows.find((r) => r.id === fromWalletId);
    const to = rows.find((r) => r.id === toWalletId);
    if (!from || !to) throw new AppError('Dompet tidak ditemukan', 404);
    if (from.balance < amount) throw new AppError('Saldo dompet asal tidak mencukupi', 422);

    const move = async (walletId, delta) =>
      (
        await db.query(
          `UPDATE wallets SET balance = balance + $1 WHERE id = $2 RETURNING ${WALLET_COLS}`,
          [delta, walletId]
        )
      ).rows[0];
    const newFrom = await move(fromWalletId, -amount);
    const newTo = await move(toWalletId, amount);

    // Catat sebagai dua transaksi (sama seperti perilaku Flutter), diberi source_id yang sama
    const transferId = randomUUID();
    const now = new Date();
    const noteText = note || 'Transfer saldo antar dompet';
    const insertTx = async (title, type, categoryId, walletId) =>
      (
        await db.query(
          `INSERT INTO transactions
             (user_id, title, amount, type, category_id, wallet_id, date, note, source, source_id)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'transfer', $9)
           RETURNING ${TRANSACTION_COLS}`,
          [userId, title, amount, type, categoryId, walletId, now, noteText, transferId]
        )
      ).rows[0];

    const outTx = await insertTx(`Transfer: ${from.name} ➔ ${to.name}`, 'expense', 'exp_other', fromWalletId);
    const inTx = await insertTx(`Terima Transfer dari ${from.name}`, 'income', 'inc_other', toWalletId);

    return {
      fromWallet: toWallet(newFrom),
      toWallet: toWallet(newTo),
      transactions: [toTransaction(outTx), toTransaction(inTx)],
    };
  });
}