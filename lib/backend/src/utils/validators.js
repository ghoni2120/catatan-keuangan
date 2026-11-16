import { z } from 'zod';

// UUID dari client dinormalkan ke huruf kecil (Postgres mengembalikan huruf kecil)
export const idSchema = z.uuid('ID tidak valid').transform((s) => s.toLowerCase());

export const moneySchema = z
  .number('Nominal harus berupa angka')
  .int('Nominal harus bilangan bulat (rupiah)');

// Tanggal wajib ISO 8601 LENGKAP dengan zona waktu (Z atau +08:00).
// Di Flutter: date.toUtc().toIso8601String()
export const dateTimeSchema = z.iso
  .datetime({
    offset: true,
    error: 'Tanggal harus format ISO 8601 beserta zona waktu, mis. 2026-11-16T06:46:23Z',
  })
  .transform((s) => new Date(s));