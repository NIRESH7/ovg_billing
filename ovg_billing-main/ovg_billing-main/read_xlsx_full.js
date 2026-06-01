const XLSX = require('xlsx');
const workbook = XLSX.readFile('2026 PRICE LIST_FINAL 25.04.2026.xlsx');

console.log('Sheet Names:', workbook.SheetNames);

workbook.SheetNames.forEach(sheetName => {
  console.log(`\n========== Sheet: ${sheetName} ==========`);
  const ws = workbook.Sheets[sheetName];
  const data = XLSX.utils.sheet_to_json(ws, { header: 1, defval: '' });
  data.forEach((row, i) => {
    const cleaned = row.map(c => String(c).trim()).filter(c => c !== '');
    if (cleaned.length > 0) console.log(`Row ${i}: ${JSON.stringify(cleaned)}`);
  });
});
