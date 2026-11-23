import { z } from 'zod';

// UUID dari client dinormalkan ke huruf kecil (Postgres mengembalikan huruf kecil)
const id = z.uuid('ID tidak valid').transform((s) => s.toLowerCase());

const money = z
  .number('Nominal harus berupa angka')
  .int('Nominal harus bilangan bulat (rupiah)');

const base = z.object({
  name: z.string().trim().min(1, 'Nama dompet wajib diisi').max(100, 'Nama dompet terlalu panjang'),
  type: z.enum(['cash', 'bank', 'ewallet', 'other'], 'Tipe dompet tidak valid'),
  iconCodePoint: z.number().int().min(0).max(0x10ffff),
  iconFontFamily: z.string().trim().min(1).max(100),
  color: z.number().int().min(0).max(4294967295),
});

export const idParamSchema = z.object({ id });

export const createWalletSchema = base.extend({
  iconFontFamily: base.shape.iconFontFamily.default('MaterialIcons'),
  balance: money.default(0), // saldo awal
});

// Saldo TIDAK bisa diubah lewat sini; saldo hanya berubah oleh transaksi/transfer.
export const updateWalletSchema = base.partial();

export const transferSchema = z.object({
  fromWalletId: id,
  toWalletId: id,
  amount: money.positive('Nominal transfer harus lebih dari 0'),
  note: z.string().trim().max(500).optional(),
});

// DELETE /wallets/:id?moveToWalletId=...  (opsional: pindahkan seluruh riwayat & saldo ke dompet lain)
export const deleteWalletQuerySchema = z.object({
  moveToWalletId: id.optional(),
});