import { query, withTransaction } from '../../config/db.js';
import { AppError } from '../../utils/AppError.js';
import { WALLET_COLS, TRANSACTION_COLS, toWallet, toTransaction } from '../../utils/mappers.js';

// Efek transaksi terhadap saldo dompet: pemasukan menambah, pengeluaran mengurangi
export const effect = (type, amount) => (type === 'income' ? amount : -amount);

const addDelta = (map, walletId, delta) => map.set(walletId, (map.get(walletId) || 0) + delta);

// Mengunci dompet terkait (urut by id agar tidak deadlock), lalu menerapkan perubahan saldo.
// Mengembalikan dompet yang sudah diperbarui agar Flutter bisa langsung memperbarui tampilan.
export async function applyWalletDeltas(db, userId, deltas) {
  const ids = [...deltas.keys()].sort();
  const locked = await db.query(
    `SELECT id FROM wallets WHERE user_id = $1 AND id = ANY($2::uuid[]) ORDER BY id FOR UPDATE`,
    [userId, ids]
  );
  if (locked.rows.length !== ids.length) throw new AppError('Dompet tidak ditemukan', 404);

  const updated = [];
  for (const id of ids) {
    const { rows } = await db.query(
      `UPDATE wallets SET balance = balance + $1 WHERE id = $2 RETURNING ${WALLET_COLS}`,
      [deltas.get(id), id]
    );
    updated.push(toWallet(rows[0]));
  }
  return updated;
}

async function assertCategory(db, userId, categoryId, type) {
  const { rows } = await db.query(
    'SELECT type FROM categories WHERE id = $1 AND (user_id IS NULL OR user_id = $2)',
    [categoryId, userId]
  );
  if (!rows[0]) throw new AppError('Kategori tidak ditemukan', 400);
  if (rows[0].type !== type) {
    throw new AppError('Jenis kategori tidak sesuai dengan jenis transaksi', 400);
  }
}

// ---------------------------------------------------------------- READ

export async function listTransactions(userId, f) {
  const params = [userId];
  const where = ['user_id = $1'];
  const add = (sql, value) => {
    params.push(value);
    where.push(sql.replace('?', `$${params.length}`));
  };

  if (f.walletId) add('wallet_id = ?', f.walletId);
  if (f.categoryId) add('category_id = ?', f.categoryId);
  if (f.type) add('type = ?', f.type);
  if (f.from) add('date >= ?', f.from);
  if (f.to) add('date <= ?', f.to);
  if (f.q) {
    // Escape karakter khusus LIKE agar "50%" dicari apa adanya
    params.push(`%${f.q.replace(/[\\%_]/g, '\\$&')}%`);
    where.push(`(title ILIKE $${params.length} OR note ILIKE $${params.length})`);
  }
  const whereSql = where.join(' AND ');

  const total = (await query(`SELECT count(*) AS n FROM transactions WHERE ${whereSql}`, params))
    .rows[0].n;

  const { rows } = await query(
    `SELECT ${TRANSACTION_COLS} FROM transactions
     WHERE ${whereSql}
     ORDER BY date DESC, created_at DESC, id
     LIMIT ${f.limit} OFFSET ${f.offset}`,
    params
  );
  return { items: rows.map(toTransaction), total };
}

export async function getTransaction(userId, id) {
  const { rows } = await query(
    `SELECT ${TRANSACTION_COLS} FROM transactions WHERE id = $1 AND user_id = $2`,
    [id, userId]
  );
  if (!rows[0]) throw new AppError('Transaksi tidak ditemukan', 404);
  return toTransaction(rows[0]);
}

// ---------------------------------------------------------------- WRITE

export async function createTransaction(userId, d) {
  return withTransaction(async (db) => {
    await assertCategory(db, userId, d.categoryId, d.type);
    const wallets = await applyWalletDeltas(
      db,
      userId,
      new Map([[d.walletId, effect(d.type, d.amount)]])
    );
    const { rows } = await db.query(
      `INSERT INTO transactions (user_id, title, amount, type, category_id, wallet_id, date, note)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING ${TRANSACTION_COLS}`,
      [userId, d.title, d.amount, d.type, d.categoryId, d.walletId, d.date, d.note || null]
    );
    return { transaction: toTransaction(rows[0]), wallets };
  });
}

export async function updateTransaction(userId, id, d) {
  return withTransaction(async (db) => {
    const found = await db.query(
      `SELECT ${TRANSACTION_COLS} FROM transactions WHERE id = $1 AND user_id = $2 FOR UPDATE`,
      [id, userId]
    );
    const old = found.rows[0];
    if (!old) throw new AppError('Transaksi tidak ditemukan', 404);
    if (old.source !== 'manual') {
      throw new AppError(
        'Transaksi ini dibuat otomatis oleh fitur transfer/utang/tabungan dan tidak dapat diubah langsung. Ubah atau hapus melalui fitur terkait',
        409
      );
    }
    await assertCategory(db, userId, d.categoryId, d.type);

    // Batalkan efek lama, terapkan efek baru (bisa pindah dompet / ganti jenis / ganti nominal)
    const deltas = new Map();
    addDelta(deltas, old.wallet_id, -effect(old.type, old.amount));
    addDelta(deltas, d.walletId, effect(d.type, d.amount));
    const wallets = await applyWalletDeltas(db, userId, deltas);

    const { rows } = await db.query(
      `UPDATE transactions
       SET title = $1, amount = $2, type = $3, category_id = $4, wallet_id = $5, date = $6, note = $7
       WHERE id = $8
       RETURNING ${TRANSACTION_COLS}`,
      [d.title, d.amount, d.type, d.categoryId, d.walletId, d.date, d.note || null, id]
    );
    return { transaction: toTransaction(rows[0]), wallets };
  });
}

export async function deleteTransaction(userId, id) {
  return withTransaction(async (db) => {
    const found = await db.query(
      `SELECT ${TRANSACTION_COLS}, source_id FROM transactions
       WHERE id = $1 AND user_id = $2 FOR UPDATE`,
      [id, userId]
    );
    const tx = found.rows[0];
    if (!tx) throw new AppError('Transaksi tidak ditemukan', 404);

    if (tx.source === 'debt_payment' || tx.source === 'savings') {
      throw new AppError(
        'Transaksi ini berasal dari pembayaran utang/tabungan. Batalkan melalui fitur utang/tabungan',
        409
      );
    }

    // Transfer = sepasang transaksi: hapus keduanya agar saldo kedua dompet tetap konsisten
    let victims = [tx];
    if (tx.source === 'transfer' && tx.source_id) {
      const pair = await db.query(
        `SELECT ${TRANSACTION_COLS} FROM transactions
         WHERE user_id = $1 AND source = 'transfer' AND source_id = $2
         ORDER BY id FOR UPDATE`,
        [userId, tx.source_id]
      );
      victims = pair.rows;
    }

    const deltas = new Map();
    for (const v of victims) addDelta(deltas, v.wallet_id, -effect(v.type, v.amount));
    const wallets = await applyWalletDeltas(db, userId, deltas);

    const deletedIds = victims.map((v) => v.id);
    await db.query('DELETE FROM transactions WHERE id = ANY($1::uuid[])', [deletedIds]);
    return { deletedIds, wallets };
  });
}