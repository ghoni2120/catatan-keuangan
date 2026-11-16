import { z } from 'zod';

const email = z
  .string()
  .trim()
  .toLowerCase()
  .email('Format email tidak valid')
  .max(254, 'Email terlalu panjang');

// bcrypt hanya membaca 72 byte pertama password
const password = z
  .string()
  .min(8, 'Password minimal 8 karakter')
  .refine((v) => Buffer.byteLength(v, 'utf8') <= 72, 'Password terlalu panjang (maks 72 byte)');

export const registerSchema = z.object({
  name: z.string().trim().min(1, 'Nama wajib diisi').max(100, 'Nama terlalu panjang'),
  email,
  password,
});

export const loginSchema = z.object({
  email,
  password: z.string().min(1, 'Password wajib diisi'),
});

export const refreshSchema = z.object({
  refreshToken: z.string().min(1, 'refreshToken wajib diisi'),
});