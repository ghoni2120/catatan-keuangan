import { z } from 'zod';
import { idSchema, moneySchema, dateTimeSchema } from '../../utils/validators.js';

export const idParamSchema = z.object({ id: idSchema });
export const paymentParamSchema = z.object({ id: idSchema, paymentId: idSchema });

const personName = z.string().trim().min(1, 'Nama wajib diisi').max(100, 'Nama terlalu panjang');
const notes = z.string().trim().max(1000);

export const createDebtSchema = z
  .object({
    personName,
    type: z.enum(['debt', 'receivable'], 'Jenis harus debt (utang) atau receivable (piutang)'),
    amount: moneySchema.positive('Nominal harus lebih dari 0'),
    // Nominal yang SUDAH dibayar sebelum dicatat (tanpa dompet, tidak membuat transaksi)
    paidAmount: moneySchema.min(0, 'Nominal yang sudah dibayar tidak boleh negatif').default(0),
    dueDate: dateTimeSchema.nullish(),
    notes: notes.nullish(),
  })
  .refine((d) => d.paidAmount <= d.amount, {
    message: 'Nominal yang sudah dibayar tidak boleh melebihi total',
    path: ['paidAmount'],
  });

// Jenis (type) tidak bisa diubah. paidAmount & payments hanya berubah lewat pembayaran.
export const updateDebtSchema = z
  .object({
    personName,
    amount: moneySchema.positive('Nominal harus lebih dari 0'),
    dueDate: dateTimeSchema.nullable(),
    notes: notes.nullable(),
  })
  .partial();

export const payDebtSchema = z.object({
  amount: moneySchema.positive('Nominal pembayaran harus lebih dari 0'),
  walletId: idSchema,
  notes: notes.nullish(),
});