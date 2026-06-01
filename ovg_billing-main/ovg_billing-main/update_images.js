const { MongoClient } = require('mongodb');

async function run() {
    const client = new MongoClient('mongodb://localhost:27017');
    try {
        await client.connect();
        const db = client.db('ovg_billing');
        const products = db.collection('products');

        const updates = [
            { name: 'PREMIUM', url: 'https://cdn.shopify.com/s/files/1/0713/3298/7138/files/Front_6cb553e6-1d57-443b-a0ff-aa3bd69bbf24.jpg?v=1761983266' },
            { name: 'JUNIOR GYM VEST', url: 'https://cdn.shopify.com/s/files/1/0713/3298/7138/files/WhatsApp_Image_2025-07-22_at_12.15.49_PM_1.jpg?v=1753179531' },
            { name: '2PCS ANGEL PLAIN', url: 'https://cdn.shopify.com/s/files/1/0713/3298/7138/files/front_f20e975a-1309-4485-830f-b884c9416f22.jpg?v=1762148984' },
            { name: 'TEDDY VEST', url: 'https://cdn.shopify.com/s/files/1/0713/3298/7138/files/WhatsApp_Image_2025-07-15_at_7.00.06_PM_1.jpg?v=1752733578' }
        ];

        for (const update of updates) {
            const result = await products.updateMany(
                { name: update.name },
                { $set: { imageUrl: update.url } }
            );
            console.log(`Updated ${update.name}: matched ${result.matchedCount}, modified ${result.modifiedCount}`);
        }

        console.log('Successfully updated with verified fresh URLs');
    } catch (err) {
        console.error('Error updating products:', err);
    } finally {
        await client.close();
    }
}

run();
