import { ZodError } from 'zod';
import { AppError } from '../utils/AppError.js';
import { isProd } from '../config/env.js';

export function notFound(req, res) {
  res.status(404).json({
    success: false,
    message: `Endpoint ${req.method} ${req.originalUrl} tidak ditemukan`,
    errors: [],
  });
}

// eslint-disable-next-line no-unused-vars
export function errorHandler(err, req, res, next) {
  if (err instanceof ZodError) {
    return res.status(400).json({
      success: false,
      message: 'Data yang dikirim tidak valid',
      errors: err.issues.map((i) => ({ field: i.path.join('.'), message: i.message })),
    });
  }

  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      success: false,
      message: err.message,
      errors: err.errors,
    });
  }

  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ success: false, message: 'Format JSON tidak valid', errors: [] });
  }

  console.error('[error]', err);
  res.status(500).json({
    success: false,
    message: isProd ? 'Terjadi kesalahan pada server' : err.message,
    errors: [],
  });
}