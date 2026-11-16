import { query } from '../../config/db.js';
import { ok } from '../../utils/response.js';

// Kategori bawaan (user_id NULL) + kategori milik user (jika kelak ada)
export async function list(req, res) {
  const { rows } = await query(
    `SELECT id, name, type, icon_code_point, icon_font_family, color
     FROM categories
     WHERE user_id IS NULL OR user_id = $1
     ORDER BY type DESC, created_at, id`,
    [req.user.id]
  );
  ok(
    res,
    rows.map((r) => ({
      id: r.id,
      name: r.name,
      type: r.type,
      iconCodePoint: r.icon_code_point,
      iconFontFamily: r.icon_font_family,
      color: r.color,
    }))
  );
}