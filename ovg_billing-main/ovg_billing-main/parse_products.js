const XLSX = require('xlsx');
const workbook = XLSX.readFile('2026 PRICE LIST_FINAL 25.04.2026.xlsx');

// We'll parse the main sheet (first sheet) which has B2C/B2B pricing
// and the OS RETAIL sheet
const products = [];

// Parse OS RETAIL sheet - it has cleaner format
const osRetailSheet = workbook.Sheets['OS RETAIL'];
const rows = XLSX.utils.sheet_to_json(osRetailSheet, { header: 1, defval: '' });

let currentCategory = '';
for (let i = 0; i < rows.length; i++) {
  const row = rows[i].map(c => String(c).trim());
  const cleaned = row.filter(c => c !== '');
  if (cleaned.length === 0) continue;

  // Check if this is a category header row (single word rows like BANIANS, BRIEFS, etc.)
  if (cleaned.length === 1 && isNaN(cleaned[0]) && cleaned[0].length > 2) {
    currentCategory = cleaned[0];
    continue;
  }

  // Check if it's a product row: starts with a number
  if (!isNaN(cleaned[0]) && cleaned.length >= 6) {
    const sno = cleaned[0];
    let productName = '';
    let quality = '';
    let style = '';
    let pkg = '';
    let sizes = {};

    // Detect if it has style column or not
    // Pattern: sno, name, style, pkg, size1, size2, size3
    // Or: sno, name, pkg, size1, size2, size3 (no style)
    const numeric_idxs = [];
    for (let j = 1; j < cleaned.length; j++) {
      if (!isNaN(cleaned[j]) && cleaned[j] !== '') numeric_idxs.push(j);
    }

    // First non-numeric after sno is product name
    if (!isNaN(cleaned[1])) {
      // Skip - this might be a continuation row
      continue;
    }

    productName = cleaned[1];
    let idx = 2;

    // Check if next is a known style (IE, OE, RN, etc.) or pkg (number)
    if (['IE', 'OE', 'RN', 'BWS/CLR', 'SLIP'].includes(cleaned[idx])) {
      style = cleaned[idx];
      idx++;
    }

    if (!isNaN(cleaned[idx])) {
      pkg = parseInt(cleaned[idx]);
      idx++;
    }

    // Remaining are sizes
    const sizeLabels = ['75x80', '85x90', '95x100', '50x55', '60x65', '70x75'];
    const priceValues = [];
    while (idx < cleaned.length && !isNaN(cleaned[idx]) && cleaned[idx] !== '') {
      priceValues.push(parseFloat(cleaned[idx]));
      idx++;
    }

    // Build product object
    const product = {
      sno: parseInt(sno),
      name: productName,
      category: currentCategory,
      quality: style || 'N/A',
      pkg: pkg || 10,
      prices: priceValues,
      hsnCode: '61112000', // Default innerwear HSN
      gstPercent: 5
    };

    // Assign size-wise prices
    const sizeLabelMap = ['75x80cm', '85x90cm', '95x100cm', '50x55cm', '60x65cm', '70x75cm'];
    priceValues.forEach((p, pi) => {
      product[sizeLabelMap[pi] || `size_${pi + 1}`] = p;
    });

    products.push(product);
  }
}

// Also parse main sheet for additional products (Modal Panties, etc.)
const mainSheet = workbook.Sheets[workbook.SheetNames[0]];
const mainRows = XLSX.utils.sheet_to_json(mainSheet, { header: 1, defval: '' });

// Find unique product names from main sheet
const mainProducts = new Set();
for (const row of mainRows) {
  const cleaned = row.map(c => String(c).trim()).filter(c => c !== '');
  if (cleaned.length > 3 && !isNaN(cleaned[0])) {
    mainProducts.add(cleaned[1]);
  }
}

console.log('Products parsed:', products.length);
console.log('\nFull product list for MongoDB seeding:');
console.log(JSON.stringify(products, null, 2));
