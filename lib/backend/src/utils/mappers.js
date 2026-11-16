// Mengubah baris database (snake_case) menjadi JSON untuk Flutter (camelCase).
// Nama field disamakan dengan toJson() di model Flutter.

export const WALLET_COLS =
  'id, name, type, balance, icon_code_point, icon_font_family, color, created_at';

export const toWallet = (r) => ({
  id: r.id,
  name: r.name,
  type: r.type,
  balance: r.balance,
  iconCodePoint: r.icon_code_point,
  iconFontFamily: r.icon_font_family,
  color: r.color,
  createdAt: r.created_at,
});

export const TRANSACTION_COLS = 'id, title, amount, type, category_id, wallet_id, date, note';

export const toTransaction = (r) => ({
  id: r.id,
  title: r.title,
  amount: r.amount,
  type: r.type,
  categoryId: r.category_id,
  walletId: r.wallet_id,
  date: r.date,
  note: r.note,
});