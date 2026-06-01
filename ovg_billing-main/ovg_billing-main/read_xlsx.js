const XLSX = require('xlsx');
const workbook = XLSX.readFile('2026 PRICE LIST_FINAL 25.04.2026.xlsx');
const sheetName = workbook.SheetNames[0];
const worksheet = workbook.Sheets[sheetName];
const data = XLSX.utils.sheet_to_json(worksheet, {header: 1}); // Read as array of arrays
data.slice(0, 30).forEach(row => console.log(row.join(' | ')));
