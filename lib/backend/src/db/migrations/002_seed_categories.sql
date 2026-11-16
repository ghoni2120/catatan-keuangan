-- ID sama persis dengan lib/models/category.dart.
-- Ikon & warna dibiarkan NULL: Flutter memakai definisinya sendiri berdasarkan ID.
INSERT INTO categories (id, name, type) VALUES
  ('exp_food',          'Makanan & Minuman',    'expense'),
  ('exp_transport',     'Transportasi',         'expense'),
  ('exp_shopping',      'Belanja',              'expense'),
  ('exp_bills',         'Tagihan & Listrik',    'expense'),
  ('exp_entertainment', 'Hiburan',              'expense'),
  ('exp_health',        'Kesehatan',            'expense'),
  ('exp_education',     'Pendidikan',           'expense'),
  ('exp_donation',      'Donasi & Amal',        'expense'),
  ('exp_other',         'Lain-lain',            'expense'),
  ('inc_salary',        'Gaji Pokok',           'income'),
  ('inc_bonus',         'Bonus / THR',          'income'),
  ('inc_business',      'Usaha & Bisnis',       'income'),
  ('inc_investment',    'Investasi / Dividen',  'income'),
  ('inc_freelance',     'Freelance / Side Job', 'income'),
  ('inc_other',         'Pemasukan Lain',       'income')
ON CONFLICT (id) DO NOTHING;