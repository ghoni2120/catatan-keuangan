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

export const TRANSACTION_COLS = 
  'id, title, amount, type, category_id, wallet_id, date, note, source';


export const toTransaction = (r) => ({
  id: r.id,
  title: r.title,
  amount: r.amount,
  type: r.type,
  categoryId: r.category_id,
  walletId: r.wallet_id,
  date: r.date,
  note: r.note,
  source: r.source,
});


// ---------------------------------------------------------------- utang & piutang

export const DEBT_COLS = 'id, person_name, type, amount, paid_amount, due_date, notes, created_at';
export const PAYMENT_COLS = 'id, debt_id, wallet_id, amount, date, notes';

export const toDebtPayment = (r) => ({
  id: r.id,
  amount: r.amount,
  date: r.date,
  walletId: r.wallet_id,
  notes: r.notes,
});

export const toDebt = (r, payments = []) => ({
  id: r.id,
  personName: r.person_name,
  type: r.type, // debt = utang saya, receivable = piutang
  amount: r.amount,
  paidAmount: r.paid_amount,
  dueDate: r.due_date,
  createdAt: r.created_at,
  notes: r.notes,
  payments,
});

// ---------------------------------------------------------------- tabungan

export const GOAL_COLS =
  'id, title, target_amount, current_amount, target_date, icon_code_point, icon_font_family, color, notes, created_at';
export const LOG_COLS = 'id, goal_id, wallet_id, type, amount, date, notes';

export const toSavingsLog = (r) => ({
  id: r.id,
  amount: r.amount,
  date: r.date,
  type: r.type, // deposit | withdraw
  walletId: r.wallet_id,
  notes: r.notes,
});

export const toSavingsGoal = (r, logs = []) => ({
  id: r.id,
  title: r.title,
  targetAmount: r.target_amount,
  currentAmount: r.current_amount,
  targetDate: r.target_date,
  createdAt: r.created_at,
  iconCodePoint: r.icon_code_point,
  iconFontFamily: r.icon_font_family,
  color: r.color,
  notes: r.notes,
  logs,
});