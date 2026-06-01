const { MongoClient } = require('mongodb');
const XLSX = require('xlsx');

const url = 'mongodb://localhost:27017';
const dbName = 'ovg_billing';

// Helper to clean dates and unwanted text
function cleanText(text) {
    if (!text) return '';
    // Remove dates like 01.12.2025 or 25.04.2026
    return text.toString().replace(/\d{2}\.\d{2}\.\d{4}/g, '').replace(/PRICE LIST/g, '').trim() || 'General';
}

async function importAll() {
    const client = new MongoClient(url);
    try {
        await client.connect();
        const db = client.db(dbName);
        const collection = db.collection('products');

        await collection.deleteMany({});
        console.log('🗑  Existing products cleared');

        const workbook = XLSX.readFile('2026 PRICE LIST_FINAL 25.04.2026.xlsx');
        let totalInserted = 0;

        workbook.SheetNames.forEach(sheetName => {
            const sheet = workbook.Sheets[sheetName];
            const data = XLSX.utils.sheet_to_json(sheet, { header: 1 });
            
            let currentCategory = cleanText(sheetName);
            
            data.forEach(row => {
                if (!row || row.length < 2) return;

                const col0 = row[0] ? row[0].toString().trim() : '';
                const col1 = row[1] ? row[1].toString().trim() : '';

                // Filter out junk
                if (col1.includes('DATE') || col1.includes('STYLE NO') || col1.includes('TOTAL') || col1.length < 2) return;
                if (col0.includes('S.NO') || col0.includes('PRICE')) return;

                // Category Update
                if (col0 && isNaN(col0) && !row[4]) {
                    currentCategory = cleanText(col0);
                    return;
                }

                const sno = parseInt(col0);
                if (!isNaN(sno) && col1 && col1 !== 'Unknown') {
                    const quality = row[2] ? row[2].toString().trim() : '';
                    
                    const sizePrices = [];
                    const sizeLabels = ['S/M', 'L/XL', 'XXL', '75x80', '85x90', '95x100']; 
                    
                    for (let i = 4; i < 10; i++) {
                        if (row[i] && !isNaN(row[i]) && parseFloat(row[i]) > 5) {
                            sizePrices.push({
                                size: sizeLabels[i-4] || `Size ${i-3}`,
                                price: parseFloat(row[i])
                            });
                        }
                    }

                    if (sizePrices.length > 0) {
                        collection.insertOne({
                            sno,
                            name: col1,
                            category: currentCategory,
                            sheet: cleanText(sheetName),
                            quality,
                            pkg: parseInt(row[3]) || 10,
                            hsn_code: "61112000",
                            gst_percent: 5,
                            size_prices: sizePrices
                        });
                        totalInserted++;
                    }
                }
            });
        });

        console.log(`✅ Successfully imported ${totalInserted} ESSENTIAL products!`);
        await collection.createIndex({ name: 1 });

    } catch (err) {
        console.error('❌ Error:', err);
    } finally {
        setTimeout(() => client.close(), 2000);
    }
}

importAll();
