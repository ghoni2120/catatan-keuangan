// Menyusun bagian SET untuk UPDATE parsial. Nama kolom HANYA dari columnMap (bukan input user).
// Field yang bernilai undefined dilewati; null berarti "kosongkan kolom".
export function buildSet(patch, columnMap, startIndex = 1) {
  const sets = [];
  const values = [];
  for (const [key, column] of Object.entries(columnMap)) {
    if (patch[key] !== undefined) {
      values.push(patch[key]);
      sets.push(`${column} = $${startIndex + values.length - 1}`);
    }
  }
  return { sets, values };
}