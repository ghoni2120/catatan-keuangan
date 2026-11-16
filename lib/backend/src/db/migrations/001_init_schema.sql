-- Semua nominal rupiah = BIGINT. Warna Flutter (Color.value) bisa sampai
-- 4.294.967.295, jadi kolom warna juga BIGINT.

CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  email         TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX users_email_unique ON users (lower(email));

-- ID teks seperti 'exp_food' (sama dengan yang dipakai Flutter).
-- user_id NULL = kategori bawaan sistem.
CREATE TABLE categories (
  id                TEXT PRIMARY KEY,
  user_id           UUID REFERENCES users(id) ON DELETE CASCADE,
  name              TEXT NOT NULL,
  type              TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  icon_code_point   INTEGER,
  icon_font_family  TEXT,
  color             BIGINT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE wallets (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name              TEXT NOT NULL,
  type              TEXT NOT NULL CHECK (type IN ('cash', 'bank', 'ewallet', 'other')),
  balance           BIGINT NOT NULL DEFAULT 0,
  icon_code_point   INTEGER NOT NULL,
  icon_font_family  TEXT NOT NULL DEFAULT 'MaterialIcons',
  color             BIGINT NOT NULL,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX wallets_user_idx ON wallets (user_id);

-- source/source_id: menandai transaksi yang lahir dari fitur lain
-- (manual | transfer | debt_payment | savings). Kedua transaksi sebuah
-- transfer berbagi source_id yang sama.
CREATE TABLE transactions (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title        TEXT NOT NULL,
  amount       BIGINT NOT NULL CHECK (amount > 0),
  type         TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  category_id  TEXT NOT NULL REFERENCES categories(id),
  wallet_id    UUID NOT NULL REFERENCES wallets(id) ON DELETE RESTRICT,
  date         TIMESTAMPTZ NOT NULL,
  note         TEXT,
  source       TEXT NOT NULL DEFAULT 'manual'
               CHECK (source IN ('manual', 'transfer', 'debt_payment', 'savings')),
  source_id    UUID,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX transactions_user_date_idx     ON transactions (user_id, date DESC);
CREATE INDEX transactions_wallet_idx        ON transactions (wallet_id);
CREATE INDEX transactions_user_category_idx ON transactions (user_id, category_id);
CREATE INDEX transactions_source_idx        ON transactions (source, source_id) WHERE source_id IS NOT NULL;

-- type: debt = utang saya, receivable = piutang
CREATE TABLE debts (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  person_name  TEXT NOT NULL,
  type         TEXT NOT NULL CHECK (type IN ('debt', 'receivable')),
  amount       BIGINT NOT NULL CHECK (amount > 0),
  paid_amount  BIGINT NOT NULL DEFAULT 0,
  due_date     TIMESTAMPTZ,
  notes        TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT debts_paid_range CHECK (paid_amount >= 0 AND paid_amount <= amount)
);
CREATE INDEX debts_user_idx ON debts (user_id);

CREATE TABLE debt_payments (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  debt_id     UUID NOT NULL REFERENCES debts(id) ON DELETE CASCADE,
  wallet_id   UUID NOT NULL REFERENCES wallets(id) ON DELETE RESTRICT,
  amount      BIGINT NOT NULL CHECK (amount > 0),
  date        TIMESTAMPTZ NOT NULL,
  notes       TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX debt_payments_debt_idx ON debt_payments (debt_id);

CREATE TABLE savings_goals (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title             TEXT NOT NULL,
  target_amount     BIGINT NOT NULL CHECK (target_amount > 0),
  current_amount    BIGINT NOT NULL DEFAULT 0 CHECK (current_amount >= 0),
  target_date       TIMESTAMPTZ,
  icon_code_point   INTEGER NOT NULL,
  icon_font_family  TEXT NOT NULL DEFAULT 'MaterialIcons',
  color             BIGINT NOT NULL,
  notes             TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX savings_goals_user_idx ON savings_goals (user_id);

CREATE TABLE savings_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id     UUID NOT NULL REFERENCES savings_goals(id) ON DELETE CASCADE,
  wallet_id   UUID NOT NULL REFERENCES wallets(id) ON DELETE RESTRICT,
  type        TEXT NOT NULL CHECK (type IN ('deposit', 'withdraw')),
  amount      BIGINT NOT NULL CHECK (amount > 0),
  date        TIMESTAMPTZ NOT NULL,
  notes       TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX savings_logs_goal_idx ON savings_logs (goal_id);

CREATE TRIGGER trg_users_updated         BEFORE UPDATE ON users         FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_wallets_updated       BEFORE UPDATE ON wallets       FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_transactions_updated  BEFORE UPDATE ON transactions  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_debts_updated         BEFORE UPDATE ON debts         FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_savings_goals_updated BEFORE UPDATE ON savings_goals FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Keamanan Supabase: tabel di schema public otomatis terbuka lewat API
-- PostgREST (anon key). RLS aktif TANPA policy = anon/authenticated tidak
-- bisa membaca apa pun. Backend Express tetap bisa akses karena terhubung
-- sebagai role postgres (bypass RLS).
ALTER TABLE users         ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories    ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets       ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE debts         ENABLE ROW LEVEL SECURITY;
ALTER TABLE debt_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE savings_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE savings_logs  ENABLE ROW LEVEL SECURITY;