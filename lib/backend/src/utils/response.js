export function ok(res, data = null, message = 'Berhasil', status = 200) {
  return res.status(status).json({ success: true, message, data });
}