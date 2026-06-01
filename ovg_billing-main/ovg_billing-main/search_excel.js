const XLSX = require('xlsx');
const workbook = XLSX.readFile('2026 PRICE LIST_FINAL 25.04.2026.xlsx');
workbook.SheetNames.forEach(name => {
    const sheet = workbook.Sheets[name];
    const data = XLSX.utils.sheet_to_json(sheet, {header: 1});
    data.forEach((row, i) => {
        const line = row.join(' | ').toUpperCase();
        if (line.includes('LUNA') || line.includes('BRESIYAR') || line.includes('TIGHTS') || line.includes('JASS')) {
            console.log(`Sheet: ${name}, Row ${i}: ${line}`);
        }
    });
});
