-- Masalah: menghapus user (cascade ke wallets) gagal jika debt_payments / savings_logs /
-- transactions yang menunjuk dompet itu belum sempat ikut terhapus, karena FK diperiksa
-- seketika. Solusi: tunda pemeriksaan sampai akhir transaksi, saat semua hapus-berantai
-- sudah selesai. Menghapus SATU dompet yang masih dipakai tetap ditolak (error 23503 -> 409).
ALTER TABLE transactions  DROP CONSTRAINT transactions_wallet_id_fkey,
  ADD CONSTRAINT transactions_wallet_id_fkey  FOREIGN KEY (wallet_id) REFERENCES wallets(id)
  DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE debt_payments DROP CONSTRAINT debt_payments_wallet_id_fkey,
  ADD CONSTRAINT debt_payments_wallet_id_fkey FOREIGN KEY (wallet_id) REFERENCES wallets(id)
  DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE savings_logs  DROP CONSTRAINT savings_logs_wallet_id_fkey,
  ADD CONSTRAINT savings_logs_wallet_id_fkey  FOREIGN KEY (wallet_id) REFERENCES wallets(id)
  DEFERRABLE INITIALLY DEFERRED;