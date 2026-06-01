const { MongoClient } = require('mongodb');
const https = require('https');

function fetchJson(url) {
    return new Promise((resolve, reject) => {
        const options = {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
            }
        };
        https.get(url, options, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                try {
                    resolve(JSON.parse(data));
                } catch (e) {
                    reject(new Error('Failed to parse JSON: ' + data.substring(0, 100)));
                }
            });
        }).on('error', reject);
    });
}

async function run() {
    const client = new MongoClient('mongodb://localhost:27017');
    try {
        await client.connect();
        const db = client.db('ovg_billing');
        const productsCollection = db.collection('products');

        console.log('Fetching all products from website with User-Agent...');
        const response = await fetchJson('https://www.idealinnerwear.in/collections/all/products.json?limit=250');
        const webProducts = response.products;
        
        if (!webProducts) {
            console.error('Could not find products in response');
            return;
        }

        console.log(`Found ${webProducts.length} products on website.`);

        const localProducts = await productsCollection.find({}).toArray();
        console.log(`Found ${localProducts.length} products in local database.`);

        let updatedCount = 0;

        for (const localP of localProducts) {
            const match = webProducts.find(webP => {
                const webName = webP.title.toLowerCase();
                const localName = localP.name.toLowerCase();
                const cleanWeb = webName.replace(/[^a-z0-9]/g, '');
                const cleanLocal = localName.replace(/[^a-z0-9]/g, '');
                return cleanWeb.includes(cleanLocal) || cleanLocal.includes(cleanWeb);
            });

            if (match && match.images && match.images.length > 0) {
                const imageUrl = match.images[0].src;
                await productsCollection.updateOne(
                    { _id: localP._id },
                    { $set: { imageUrl: imageUrl } }
                );
                console.log(`Matched: ${localP.name} -> ${match.title}`);
                updatedCount++;
            }
        }

        console.log(`Successfully updated ${updatedCount} products with images!`);
    } catch (err) {
        console.error('Error during full sync:', err);
    } finally {
        await client.close();
    }
}

run();
