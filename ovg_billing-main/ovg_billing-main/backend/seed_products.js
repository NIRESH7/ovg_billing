const { MongoClient } = require('mongodb');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.join(__dirname, '.env') });

async function seedProducts() {
    const client = new MongoClient(process.env.MONGODB_URL || 'mongodb://localhost:27017');
    try {
        await client.connect();
        const db = client.db(process.env.DB_NAME || 'ovg_billing');
        const products = db.collection('products');

        await products.deleteMany({}); // Clear existing products

        const productData = [
            // BANIANS (HSN 6109 1000)
            { sno: 1, name: 'PREMIUM RN', category: 'BANIANS', quality: 'PREMIUM', sheet: 'RN', pkg: 10, hsn_code: '61091000', gst_percent: 5, size_prices: [{size:'75x80', price:100}, {size:'85x90', price:114}, {size:'95x100', price:128}] },
            { sno: 2, name: 'PREMIUM RNS', category: 'BANIANS', quality: 'PREMIUM', sheet: 'RNS', pkg: 10, hsn_code: '61091000', gst_percent: 5, size_prices: [{size:'75x80', price:125}, {size:'85x90', price:144}, {size:'95x100', price:163}] },
            { sno: 3, name: 'PREMIUM RNBS', category: 'BANIANS', quality: 'PREMIUM', sheet: 'RNBS', pkg: 10, hsn_code: '61091000', gst_percent: 5, size_prices: [{size:'75x80', price:109}, {size:'85x90', price:124}, {size:'95x100', price:140}] },
            { sno: 4, name: 'GYM VEST RN', category: 'BANIANS', quality: 'GYM VEST', sheet: 'RN', pkg: 10, hsn_code: '61091000', gst_percent: 5, size_prices: [{size:'75x80', price:142}, {size:'85x90', price:158}, {size:'95x100', price:182}] },

            // BRIEFS (HSN 6107 1100)
            { sno: 5, name: 'PREMIUM BRIEF IE', category: 'BRIEFS', quality: 'PREMIUM BRIEF', sheet: 'IE', pkg: 10, hsn_code: '61071100', gst_percent: 5, size_prices: [{size:'75x80', price:80}, {size:'85x90', price:88}, {size:'95x100', price:98}] },
            { sno: 6, name: 'PREMIUM BRIEF OE', category: 'BRIEFS', quality: 'PREMIUM BRIEF', sheet: 'OE', pkg: 10, hsn_code: '61071100', gst_percent: 5, size_prices: [{size:'75x80', price:86}, {size:'85x90', price:98}, {size:'95x100', price:108}, {size:'105x110', price:121}] },
            { sno: 7, name: 'ROYAL BRIEF OE', category: 'BRIEFS', quality: 'ROYAL BRIEF', sheet: 'OE', pkg: 10, hsn_code: '61071100', gst_percent: 5, size_prices: [{size:'75x80', price:83}, {size:'85x90', price:92}, {size:'95x100', price:102}] },

            // TRUNKS (HSN 6107 1100)
            { sno: 8, name: 'RIO TRUNKS(POCKET) IE', category: 'TRUNKS', quality: 'RIO TRUNKS', sheet: 'IE', pkg: 10, hsn_code: '61071100', gst_percent: 5, size_prices: [{size:'75x80', price:134}, {size:'85x90', price:154}, {size:'95x100', price:184}] },
            { sno: 9, name: 'RIO TRUNKS(POCKET) OE', category: 'TRUNKS', quality: 'RIO TRUNKS', sheet: 'OE', pkg: 10, hsn_code: '61071100', gst_percent: 5, size_prices: [{size:'75x80', price:139}, {size:'85x90', price:160}, {size:'95x100', price:187}] },
            { sno: 10, name: 'RIO TRUNKS(W.O.P) OE', category: 'TRUNKS', quality: 'RIO TRUNKS', sheet: 'OE', pkg: 10, hsn_code: '61071100', gst_percent: 5, size_prices: [{size:'75x80', price:124}, {size:'85x90', price:144}, {size:'95x100', price:172}] },
            { sno: 11, name: 'RIB B.PATTI TRUNKS OE', category: 'TRUNKS', quality: 'RIB B.PATTI', sheet: 'OE', pkg: 10, hsn_code: '61071100', gst_percent: 5, size_prices: [{size:'75x80', price:151}, {size:'85x90', price:172}, {size:'95x100', price:202}] },
            { sno: 12, name: 'RIO B.PATTI TRUNKS OE', category: 'TRUNKS', quality: 'RIO B.PATTI', sheet: 'OE', pkg: 10, hsn_code: '61071100', gst_percent: 5, size_prices: [{size:'75x80', price:144}, {size:'85x90', price:160}, {size:'95x100', price:177}] },

            // PANTIES (HSN 6108 2100)
            { sno: 13, name: 'JAR PLAIN IE', category: 'PANTIES', quality: 'JAR PLAIN', sheet: 'IE', pkg: 10, hsn_code: '61082100', gst_percent: 5, size_prices: [{size:'75x80', price:74}, {size:'85x90', price:82}, {size:'95x100', price:90}] },
            { sno: 14, name: 'JAR PLAIN OE', category: 'PANTIES', quality: 'JAR PLAIN', sheet: 'OE', pkg: 10, hsn_code: '61082100', gst_percent: 5, size_prices: [{size:'75x80', price:74}, {size:'85x90', price:82}, {size:'95x100', price:90}] },
            { sno: 15, name: 'JAR PRINT OE', category: 'PANTIES', quality: 'JAR PRINT', sheet: 'OE', pkg: 10, hsn_code: '61082100', gst_percent: 5, size_prices: [{size:'75x80', price:80}, {size:'85x90', price:88}, {size:'95x100', price:101}] },
            { sno: 16, name: '2PCS ANGEL PLAIN IE', category: 'PANTIES', quality: 'ANGEL PLAIN', sheet: 'IE', pkg: 10, hsn_code: '61082100', gst_percent: 5, size_prices: [{size:'75x80', price:61}, {size:'85x90', price:69}, {size:'95x100', price:80}, {size:'105x110', price:92}] },
            { sno: 17, name: '2PCS ANGEL PLAIN OE', category: 'PANTIES', quality: 'ANGEL PLAIN', sheet: 'OE', pkg: 10, hsn_code: '61082100', gst_percent: 5, size_prices: [{size:'75x80', price:61}, {size:'85x90', price:69}, {size:'95x100', price:80}, {size:'105x110', price:92}] },
            { sno: 18, name: '2PCS JASS PRINT IE', category: 'PANTIES', quality: 'JASS PRINT', sheet: 'IE', pkg: 10, hsn_code: '61082100', gst_percent: 5, size_prices: [{size:'75x80', price:70}, {size:'85x90', price:79}, {size:'95x100', price:88}] },
            { sno: 19, name: '2PCS JASS PRINT OE', category: 'PANTIES', quality: 'JASS PRINT', sheet: 'OE', pkg: 10, hsn_code: '61082100', gst_percent: 5, size_prices: [{size:'75x80', price:70}, {size:'85x90', price:79}, {size:'95x100', price:88}] },
            { sno: 20, name: 'TESLA PANTIES IE', category: 'PANTIES', quality: 'TESLA', sheet: 'IE', pkg: 12, hsn_code: '61082100', gst_percent: 5, size_prices: [{size:'75x80', price:70}, {size:'85x90', price:79}, {size:'95x100', price:88}] },
            { sno: 21, name: 'PENGUIN DRAWER IE', category: 'PANTIES', quality: 'PENGUIN', sheet: 'IE', pkg: 10, hsn_code: '61082100', gst_percent: 5, size_prices: [{size:'75x80', price:78}, {size:'85x90', price:84}, {size:'95x100', price:95}] },
            { sno: 22, name: 'TIGHTS IE', category: 'PANTIES', quality: 'TIGHTS', sheet: 'IE', pkg: 10, hsn_code: '61082100', gst_percent: 5, size_prices: [{size:'75x80', price:99}, {size:'85x90', price:109}, {size:'95x100', price:127}] },

            // SLIPS (HSN 6108 2100)
            { sno: 23, name: 'RAGA SLIP (MINI)', category: 'SLIPS', quality: 'RAGA', sheet: 'BWS/CLR', pkg: 10, hsn_code: '61082100', gst_percent: 5, size_prices: [{size:'75x80', price:94}, {size:'85x90', price:104}, {size:'95x100', price:118}] },
            { sno: 24, name: 'LAYA SLIP (CUTE)', category: 'SLIPS', quality: 'LAYA', sheet: 'BWS/CLR', pkg: 10, hsn_code: '61082100', gst_percent: 5, size_prices: [{size:'75x80', price:102}, {size:'85x90', price:113}, {size:'129', price:129}] },
            { sno: 25, name: 'PALLAVI (ADJUSTABLE)', category: 'SLIPS', quality: 'PALLAVI', sheet: 'BWS/CLR', pkg: 10, hsn_code: '61082100', gst_percent: 5, size_prices: [{size:'75x80', price:104}, {size:'85x90', price:116}, {size:'95x100', price:131}] },
            { sno: 41, name: 'BRASIYER SLIP', category: 'SLIPS', quality: 'BRASIYER', sheet: 'CLR', pkg: 10, hsn_code: '61082100', gst_percent: 5, size_prices: [{size:'75x80', price:118}, {size:'85x90', price:132}, {size:'95x100', price:152}] },

            // BABY ITEMS (HSN 6111 2000)
            { sno: 26, name: 'TEDDY VEST RN', category: 'BABY ITEMS', quality: 'TEDDY', sheet: 'RN', pkg: 10, hsn_code: '61112000', gst_percent: 5, size_prices: [{size:'50x55', price:51}, {size:'60x65', price:58}, {size:'70x75', price:63}] },
            { sno: 27, name: 'JUNIOR GYM VEST RN', category: 'BABY ITEMS', quality: 'JUNIOR GYM', sheet: 'RN', pkg: 10, hsn_code: '61112000', gst_percent: 5, size_prices: [{size:'60x65', price:98}, {size:'70x75', price:113}] },
            { sno: 28, name: 'JUNIOR TIGHTS IE', category: 'BABY ITEMS', quality: 'JUNIOR TIGHTS', sheet: 'IE', pkg: 10, hsn_code: '61112000', gst_percent: 5, size_prices: [{size:'60x65', price:76}, {size:'70x75', price:86}] },
            { sno: 29, name: 'JUNIOR ROYAL TOP OE', category: 'BABY ITEMS', quality: 'JUNIOR ROYAL', sheet: 'OE', pkg: 10, hsn_code: '61112000', gst_percent: 5, size_prices: [{size:'60x65', price:55}, {size:'70x75', price:62}] },
            { sno: 30, name: 'PUPPY SLIP', category: 'BABY ITEMS', quality: 'PUPPY', sheet: 'SLIP', pkg: 10, hsn_code: '61112000', gst_percent: 5, size_prices: [{size:'60x65', price:69}, {size:'70x75', price:76}] },
            { sno: 31, name: 'NICE JETTY IE', category: 'BABY ITEMS', quality: 'NICE JETTY', sheet: 'IE', pkg: 10, hsn_code: '61112000', gst_percent: 5, size_prices: [{size:'50x55', price:41}, {size:'60x65', price:44}, {size:'70x75', price:49}] },
            { sno: 32, name: 'NICE DRAWER IE', category: 'BABY ITEMS', quality: 'NICE DRAWER', sheet: 'IE', pkg: 10, hsn_code: '61112000', gst_percent: 5, size_prices: [{size:'50x55', price:46}, {size:'60x65', price:51}, {size:'70x75', price:58}] },
            { sno: 33, name: 'NICE JETTY OE', category: 'BABY ITEMS', quality: 'NICE JETTY', sheet: 'OE', pkg: 10, hsn_code: '61112000', gst_percent: 5, size_prices: [{size:'50x55', price:44}, {size:'60x65', price:48}, {size:'70x75', price:52}] },
            { sno: 34, name: 'NICE DRAWER OE', category: 'BABY ITEMS', quality: 'NICE DRAWER', sheet: 'OE', pkg: 10, hsn_code: '61112000', gst_percent: 5, size_prices: [{size:'50x55', price:49}, {size:'60x65', price:54}, {size:'70x75', price:62}] },
            { sno: 35, name: 'NICE DRAWER (PRINT) IE', category: 'BABY ITEMS', quality: 'NICE DRAWER', sheet: 'IE', pkg: 10, hsn_code: '61112000', gst_percent: 5, size_prices: [{size:'50x55', price:48}, {size:'60x65', price:52}, {size:'70x75', price:59}] },
            { sno: 36, name: 'FANCY DRAWER IE', category: 'BABY ITEMS', quality: 'FANCY', sheet: 'IE', pkg: 10, hsn_code: '61112000', gst_percent: 5, size_prices: [{size:'50x55', price:50}, {size:'60x65', price:55}, {size:'70x75', price:63}] },
            { sno: 37, name: 'BLOOMER JETTY IE', category: 'BABY ITEMS', quality: 'BLOOMER', sheet: 'IE', pkg: 10, hsn_code: '61112000', gst_percent: 5, size_prices: [{size:'50x55', price:49}, {size:'60x65', price:54}, {size:'70x75', price:62}] },
            { sno: 38, name: 'BLOOMER DRAWER IE', category: 'BABY ITEMS', quality: 'BLOOMER', sheet: 'IE', pkg: 10, hsn_code: '61112000', gst_percent: 5, size_prices: [{size:'50x55', price:54}, {size:'60x65', price:64}, {size:'70x75', price:73}] },
            { sno: 39, name: 'CUTE FRILL OE', category: 'BABY ITEMS', quality: 'CUTE FRILL', sheet: 'OE', pkg: 10, hsn_code: '61112000', gst_percent: 5, size_prices: [{size:'50x55', price:40}, {size:'60x65', price:42}, {size:'70x75', price:48}] },
            { sno: 40, name: 'MINI TRUNKS OE', category: 'BABY ITEMS', quality: 'MINI TRUNKS', sheet: 'OE', pkg: 10, hsn_code: '61112000', gst_percent: 5, size_prices: [{size:'60x65', price:76}, {size:'70x75', price:90}] },

            // MODAL PANTIES (HSN 6108 2100)
            { sno: 101, name: 'FEMI - BIKINI IE', category: 'MODAL PANTIES', quality: 'FEMI', sheet: 'IE', pkg: 10, hsn_code: '61082100', gst_percent: 5, size_prices: [{size:'75x80', price:116}, {size:'85x90', price:132}, {size:'95x100', price:151}] },
            { sno: 103, name: 'LYCA - HIPSTER OE', category: 'MODAL PANTIES', quality: 'LYCA', sheet: 'OE', pkg: 10, hsn_code: '61082100', gst_percent: 5, size_prices: [{size:'75x80', price:106}, {size:'85x90', price:123}, {size:'95x100', price:142}] },
            { sno: 102, name: 'PETALS - BIKINI OE', category: 'MODAL PANTIES', quality: 'PETALS', sheet: 'OE', pkg: 10, hsn_code: '61082100', gst_percent: 5, size_prices: [{size:'75x80', price:100}, {size:'85x90', price:109}, {size:'95x100', price:126}] },

            // BRA (HSN 6212 1000)
            { sno: 105, name: 'SPARK (T-SHIRT BRA)', category: 'BRA', quality: 'SPARK', sheet: 'BRA', pkg: 10, hsn_code: '62121000', gst_percent: 5, size_prices: [{size:'75 TO 95 CM', price:206}] },
            { sno: 106, name: 'LUNA (ENCERCULAR BRA)', category: 'BRA', quality: 'LUNA', sheet: 'BRA', pkg: 10, hsn_code: '62121000', gst_percent: 5, size_prices: [{size:'75 TO 95 CM', price:228}] },
            { sno: 107, name: 'BRAVI (SPORTS BRA)', category: 'BRA', quality: 'BRAVI', sheet: 'BRA', pkg: 10, hsn_code: '62121000', gst_percent: 5, size_prices: [{size:'75 TO 95 CM', price:224}] },
            { sno: 108, name: 'AURORA (TEENAGE BRA)', category: 'BRA', quality: 'AURORA', sheet: 'BRA', pkg: 10, hsn_code: '62121000', gst_percent: 5, size_prices: [{size:'75 TO 95 CM', price:163}] },
        ];

        await products.insertMany(productData);
        console.log('✅ Products updated successfully with new HSN codes!');
    } catch (err) {
        console.error('❌ Error:', err.message);
    } finally {
        await client.close();
    }
}

seedProducts();
