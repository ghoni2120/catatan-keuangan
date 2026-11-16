import bcrypt from 'bcryptjs';
import { pool, query, withTransaction } from '../../config/db.js';
import { AppError } from '../../utils/AppError.js';
import {
  signAccessToken,
  generateRefreshToken,
  hashToken,
  refreshExpiryDate,
} from '../../utils/tokens.js';

const BCRYPT_ROUNDS = 12;
// Dipakai agar waktu respons login sama baik email ada maupun tidak
const DUMMY_HASH = bcrypt.hashSync('password-palsu', BCRYPT_ROUNDS);

const toUser = (r) => ({ id: r.id, name: r.name, email: r.email, createdAt: r.created_at });

async function issueTokens(db, userId) {
  const { token, hash } = generateRefreshToken();
  await db.query(
    'INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)',
    [userId, hash, refreshExpiryDate()]
  );
  return { accessToken: signAccessToken(userId), refreshToken: token };
}

export async function register({ name, email, password }) {
  const passwordHash = await bcrypt.hash(password, BCRYPT_ROUNDS);
  try {
    return await withTransaction(async (db) => {
      const { rows } = await db.query(
        `INSERT INTO users (name, email, password_hash) VALUES ($1, $2, $3)
         RETURNING id, name, email, created_at`,
        [name, email, passwordHash]
      );
      const tokens = await issueTokens(db, rows[0].id);
      return { user: toUser(rows[0]), ...tokens };
    });
  } catch (err) {
    if (err.code === '23505') throw new AppError('Email sudah terdaftar', 409);
    throw err;
  }
}

export async function login({ email, password }) {
  const { rows } = await query(
    `SELECT id, name, email, created_at, password_hash
     FROM users WHERE lower(email) = lower($1)`,
    [email]
  );
  const row = rows[0];
  const valid = await bcrypt.compare(password, row ? row.password_hash : DUMMY_HASH);
  if (!row || !valid) throw new AppError('Email atau password salah', 401);

  const tokens = await issueTokens(pool, row.id);
  return { user: toUser(row), ...tokens };
}

// Rotasi: refresh token lama dicabut, token baru diterbitkan.
// Jika token yang SUDAH dicabut dipakai lagi (indikasi dicuri), semua sesi user dicabut.
export async function refresh(refreshToken) {
  const hash = hashToken(refreshToken);

  const result = await withTransaction(async (db) => {
    const { rows } = await db.query(
      'SELECT id, user_id, expires_at, revoked_at FROM refresh_tokens WHERE token_hash = $1 FOR UPDATE',
      [hash]
    );
    const rt = rows[0];
    if (!rt) return { invalid: true };

    if (rt.revoked_at) {
      await db.query(
        'UPDATE refresh_tokens SET revoked_at = now() WHERE user_id = $1 AND revoked_at IS NULL',
        [rt.user_id]
      );
      return { invalid: true };
    }
    if (new Date(rt.expires_at) < new Date()) return { invalid: true };

    await db.query('UPDATE refresh_tokens SET revoked_at = now() WHERE id = $1', [rt.id]);
    const u = await db.query(
      'SELECT id, name, email, created_at FROM users WHERE id = $1',
      [rt.user_id]
    );
    const tokens = await issueTokens(db, rt.user_id);
    return { user: toUser(u.rows[0]), ...tokens };
  });

  if (result.invalid) {
    throw new AppError('Refresh token tidak valid atau sudah kedaluwarsa', 401);
  }
  return result;
}

export async function logout(refreshToken) {
  await query(
    'UPDATE refresh_tokens SET revoked_at = now() WHERE token_hash = $1 AND revoked_at IS NULL',
    [hashToken(refreshToken)]
  );
}

export async function getMe(userId) {
  const { rows } = await query(
    'SELECT id, name, email, created_at FROM users WHERE id = $1',
    [userId]
  );
  if (!rows[0]) throw new AppError('User tidak ditemukan', 404);
  return toUser(rows[0]);
}