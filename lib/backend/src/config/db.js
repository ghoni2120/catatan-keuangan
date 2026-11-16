import pg from 'pg';
import { env } from './env.js';

// pg mengembalikan BIGINT (int8) sebagai string. Nominal rupiah & warna aman
// sebagai Number (batas aman JS ~9 kuadriliun), jadi ubah ke Number.
pg.types.setTypeParser(20, (val) => Number(val));

export const pool = new pg.Pool({
  connectionString: env.databaseUrl,
  ssl: env.dbSsl ? { rejectUnauthorized: false } : false,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});

pool.on('error', (err) => {
  console.error('[db] Error pada koneksi idle:', err.message);
});

export const query = (text, params) => pool.query(text, params);

// Menjalankan beberapa query dalam SATU database transaction.
// Dipakai nanti untuk transfer, bayar utang, setor tabungan, dll.
export async function withTransaction(fn) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}