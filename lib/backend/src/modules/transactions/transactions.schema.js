import { z } from 'zod';
import { idSchema, moneySchema, dateTimeSchema } from '../../utils/validators.js';

export const idParamSchema = z.object({ id: idSchema });

// Dipakai untuk POST (buat) dan PUT (ganti seluruh data, seperti updateTransaction di Flutter).
// Field "id" dari client diabaikan; ID dibuat server.
export const transactionBodySchema = z.object({
  title: z.string().trim().min(1, 'Judul wajib diisi').max(200, 'Judul terlalu panjang'),
  amount: moneySchema.positive('Nominal harus lebih dari 0'),
  type: z.enum(['income', 'expense'], 'Jenis transaksi harus income atau expense'),
  categoryId: z.string().trim().min(1, 'Kategori wajib diisi').max(100),
  walletId: idSchema,
  date: dateTimeSchema,
  note: z.string().trim().max(1000).nullish(),
});

export const listQuerySchema = z
  .object({
    walletId: idSchema.optional(),
    categoryId: z.string().trim().min(1).max(100).optional(),
    type: z.enum(['income', 'expense']).optional(),
    // Batas tanggal dihitung di client sesuai zona waktu user (mis. awal & akhir bulan)
    from: dateTimeSchema.optional(),
    to: dateTimeSchema.optional(),
    q: z.string().trim().max(100).optional(),
    limit: z.coerce.number().int().min(1).max(500).default(100),
    offset: z.coerce.number().int().min(0).default(0),
  })
  .refine((v) => !v.from || !v.to || v.from <= v.to, {
    message: 'from tidak boleh setelah to',
    path: ['from'],
  });
  