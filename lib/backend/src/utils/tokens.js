import crypto from 'node:crypto';
import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';

export function signAccessToken(userId) {
  return jwt.sign({ sub: userId }, env.jwtAccessSecret, {
    algorithm: 'HS256',
    expiresIn: env.accessTtl,
  });
}

export function verifyAccessToken(token) {
  return jwt.verify(token, env.jwtAccessSecret, { algorithms: ['HS256'] });
}

export function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

// Refresh token = string acak (opaque), yang disimpan di DB hanya hash-nya
export function generateRefreshToken() {
  const token = crypto.randomBytes(48).toString('base64url');
  return { token, hash: hashToken(token) };
}

export function refreshExpiryDate() {
  return new Date(Date.now() + env.refreshDays * 24 * 60 * 60 * 1000);
}