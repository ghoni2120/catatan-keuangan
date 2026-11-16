import { AppError } from '../utils/AppError.js';
import { verifyAccessToken } from '../utils/tokens.js';

// Pasang di route yang butuh login. Mengisi req.user.id
export function requireAuth(req, res, next) {
  const [scheme, token] = (req.headers.authorization || '').split(' ');
  if (scheme !== 'Bearer' || !token) {
    throw new AppError('Token autentikasi tidak ditemukan', 401);
  }
  try {
    const payload = verifyAccessToken(token);
    req.user = { id: payload.sub };
    next();
  } catch {
    throw new AppError('Token tidak valid atau sudah kedaluwarsa', 401);
  }
}