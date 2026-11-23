import { z } from 'zod';
import { idSchema, moneySchema, dateTimeSchema } from '../../utils/validators.js';

export const idParamSchema = z.object({ id: idSchema });
export const logParamSchema = z.object({ id: idSchema, logId: idSchema });

const title = z.string().trim().min(1, 'Nama tujuan wajib diisi').max(100, 'Nama tujuan terlalu panjang');
const notes = z.string().trim().max(1000);

const base = z.object({
  title,
  targetAmount: moneySchema.positive('Target harus lebih dari 0'),
  targetDate: dateTimeSchema.nullable(),
  iconCodePoint: z.number().int().min(0).max(0x10ffff),
  iconFontFamily: z.string().trim().min(1).max(100),
  color: z.number().int().min(0).max(4294967295),
  notes: notes.nullable(),
});

export const createGoalSchema = base.extend({
  iconFontFamily: base.shape.iconFontFamily.default('MaterialIcons'),
  targetDate: base.shape.targetDate.optional(),
  notes: base.shape.notes.optional(),
});

// currentAmount tidak bisa diubah langsung; hanya lewat setor/tarik.
export const updateGoalSchema = base.partial();

export const moveMoneySchema = z.object({
  amount: moneySchema.positive('Nominal harus lebih dari 0'),
  walletId: idSchema,
  notes: notes.nullish(),
});

// DELETE /savings/:id?refundWalletId=...  (opsional: kembalikan dana tabungan ke dompet itu)
export const deleteGoalQuerySchema = z.object({
  refundWalletId: idSchema.optional(),
});