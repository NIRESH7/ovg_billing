const express = require('express');
const { MongoClient, ObjectId } = require('mongodb');
const cors = require('cors');
const dotenv = require('dotenv');
const bcrypt = require('bcryptjs');
const PDFDocument = require('pdfkit');
const QRCode = require('qrcode');
const fs = require('fs');
const path = require('path');
const multer = require('multer');
const { OpenAI } = require('openai');
const pdf = require('pdf-parse');

dotenv.config(); // Try default location first
dotenv.config({ path: path.join(__dirname, '.env') }); // Then try absolute path

const app = express();
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

let openai;
try {
    if (process.env.OPENAI_API_KEY) {
        openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
        console.log('OpenAI initialized successfully');
    } else {
        console.warn('OPENAI_API_KEY not found in environment');
    }
} catch (e) {
    console.error('Failed to initialize OpenAI:', e.message);
}

const upload = multer({ dest: 'uploads/' });

// Ensure uploads directory exists
if (!fs.existsSync('uploads')) { fs.mkdirSync('uploads'); }

const PORT = 8000;

// MongoDB Connection Setup
const uri = process.env.MONGODB_URL || "mongodb://localhost:27017";
const client = new MongoClient(uri);

let db;
let productsCollection;
let customersCollection;
let invoicesCollection;
let usersCollection;
let scannedBillsCollection;

async function connectDB() {
    try {
        await client.connect();
        db = client.db(process.env.DB_NAME || 'ovg_billing');
        productsCollection = db.collection('products');
        customersCollection = db.collection('customers');
        invoicesCollection = db.collection('invoices');
        usersCollection = db.collection('users');
        scannedBillsCollection = db.collection('scanned_bills');
        console.log("Connected to MongoDB!");
    } catch (err) {
        console.error("MongoDB connection error:", err);
    }
}
connectDB();

function serialize(doc) {
    if (!doc) return null;
    doc.id = doc._id.toString();
    return doc;
}

// --- Auth ---
app.post('/auth/login', async (req, res) => {
    const { username, password } = req.body;
    if (!username || !password)
        return res.status(400).json({ error: 'Username and password are required' });
    try {
        const user = await usersCollection.findOne({ username });
        if (!user) return res.status(401).json({ error: 'Invalid credentials' });
        const match = await bcrypt.compare(password, user.password);
        if (!match) return res.status(401).json({ error: 'Invalid credentials' });
        res.json({ success: true, username: user.username, role: user.role || 'user' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- Products ---
app.get('/products', async (req, res) => {
    try {
        const products = await productsCollection.find().sort({ sno: 1 }).toArray();
        res.json(products.map(serialize));
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/products/categories', async (req, res) => {
    try {
        const categories = await productsCollection.distinct('category');
        res.json(categories);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- Customers ---
app.get('/customers', async (req, res) => {
    try {
        const customers = await customersCollection.find().toArray();
        res.json(customers.map(serialize));
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/customers', async (req, res) => {
    const { name, mobile, address, gstin, whatsapp_no, pan_no, district, state, price_type, discount_percent } = req.body;
    try {
        const existing = await customersCollection.findOne({ mobile });
        if (existing) {
            // Update existing customer with new details if provided
            await customersCollection.updateOne(
                { _id: existing._id },
                { $set: { name, address, gstin, whatsapp_no, pan_no, district, state, price_type, discount_percent } }
            );
            const updated = await customersCollection.findOne({ _id: existing._id });
            return res.json(serialize(updated));
        }
        
        const result = await customersCollection.insertOne({ 
            name, mobile, address, gstin, whatsapp_no, pan_no, district, state, 
            price_type: price_type || 'Retail',
            discount_percent: discount_percent || 0
        });
        const newCust = await customersCollection.findOne({ _id: result.insertedId });
        res.json(serialize(newCust));
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- Products Creation ---
app.post('/products', async (req, res) => {
    const { name, category, sheet, quality, pkg, hsn_code, gst_percent, color, imageUrl, size_prices } = req.body;
    try {
        const result = await productsCollection.insertOne({
            name,
            category: category || 'General',
            sheet: sheet || '',
            quality: quality || '',
            pkg: pkg || 1,
            hsn_code: hsn_code || '6111',
            gst_percent: gst_percent || 5,
            color: color || '',
            imageUrl: imageUrl || '',
            size_prices: size_prices || [], // Expected to contain {size, company_price, distributor_price, wholesale_price, retail_price}
            created_at: new Date()
        });
        const newProduct = await productsCollection.findOne({ _id: result.insertedId });
        res.json(serialize(newProduct));
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- Invoices ---
app.get('/invoices', async (req, res) => {
    try {
        const invoices = await invoicesCollection.find().sort({ created_at: -1 }).toArray();
        res.json(invoices.map(serialize));
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/invoices/stats/today', async (req, res) => {
    try {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        
        const result = await invoicesCollection.aggregate([
            { $match: { created_at: { $gte: today } } },
            { $group: {
                _id: null,
                total_bills: { $sum: 1 },
                total_amount: { $sum: "$grand_total" }
            }}
        ]).toArray();
        
        if (result.length > 0) {
            res.json({
                total_bills: result[0].total_bills,
                total_amount: result[0].total_amount
            });
        } else {
            res.json({ total_bills: 0, total_amount: 0 });
        }
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.put('/invoices/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const updatedData = { ...req.body, updated_at: new Date().toISOString() };
        delete updatedData._id;
        const result = await invoicesCollection.updateOne(
            { _id: new ObjectId(id) },
            { $set: updatedData }
        );
        if (result.matchedCount === 0) return res.status(404).json({ error: 'Invoice not found' });
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/invoices', async (req, res) => {
    const inv = req.body;
    const year = new Date().getFullYear();
    const month = (new Date().getMonth() + 1).toString().padStart(2, '0');
    
    try {
        const count = await invoicesCollection.countDocuments({
            invoice_number: { $regex: `^OVG/${year}/${month}/` }
        });
        const inv_num = `OVG/${year}/${month}/${(count + 1).toString().padStart(4, '0')}`;
        
        const newInvoice = {
            ...inv,
            invoice_number: inv_num,
            created_at: new Date()
        };
        
        const result = await invoicesCollection.insertOne(newInvoice);
        const inserted = await invoicesCollection.findOne({ _id: result.insertedId });
        res.json(serialize(inserted));
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- Static Files ---
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// --- Image Upload ---
app.post('/upload', upload.single('image'), (req, res) => {
    if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
    const url = `/uploads/${req.file.filename}`;
    res.json({ url });
});

// --- Speech to Text ---
app.post('/stt', upload.single('audio'), async (req, res) => {
    console.log('Received STT request...');
    if (!openai) {
        return res.status(503).json({ error: 'Speech-to-Text service is not configured (Missing API Key)' });
    }
    try {
        if (!req.file) {
            console.log('No file received');
            return res.status(400).json({ error: 'No audio file provided' });
        }
        
        const stats = fs.statSync(req.file.path);
        console.log(`Audio file received. Size: ${stats.size} bytes`);
        
        if (stats.size < 1000) {
            console.log('Warning: Audio file is very small, possibly silent.');
        }

        console.log('Processing audio with OpenAI...');
        
        // OpenAI needs a file with a proper extension
        const filePath = req.file.path;
        const extension = req.file.originalname.split('.').pop() || 'm4a';
        const newPath = `${filePath}.${extension}`;
        fs.renameSync(filePath, newPath);

        const transcription = await openai.audio.transcriptions.create({
            file: fs.createReadStream(newPath),
            model: 'whisper-1',
            prompt: 'Garments billing, customer names, district names like Erode, Salem, Tirupur, party names, billing items, GST, HSN code.',
        });
        
        console.log('Transcription result:', transcription.text);
        // if (fs.existsSync(newPath)) fs.unlinkSync(newPath); 
        res.json({ text: transcription.text });
    } catch (err) {
        console.error('STT Error:', err);
        res.status(500).json({ error: err.message });
    }
});

// --- PDF Generation (Professional B2C Format) ---
app.get('/invoices/:id/pdf', async (req, res) => {
    try {
        const inv = await invoicesCollection.findOne({ _id: new ObjectId(req.params.id) });
        if (!inv) return res.status(404).send('Invoice not found');

        const doc = new PDFDocument({ margin: 20, size: 'A4', autoFirstPage: false });
        res.setHeader('Content-Type', 'application/pdf');
        res.setHeader('Content-Disposition', `attachment; filename=invoice_${inv.invoice_number.replace(/\//g, '_')}.pdf`);
        doc.pipe(res);

        // Constants
        const pageTop = 5;
        const logoY = 5;
        const titleY = 75;       
        const headerY = 95;     
        const middleY = 215;     
        const tableHeaderY = 305; 
        const tableTop = 330;
        const tableBottom = 550;
        const itemsPerPage = 7;

        // Helper functions
        const drawLine = (y) => doc.moveTo(20, y).lineTo(575, y).stroke();
        const drawHLine = (x1, x2, y) => doc.moveTo(x1, y).lineTo(x2, y).stroke();
        const drawVLine = (x, y1, y2) => doc.moveTo(x, y1).lineTo(x, y2).stroke();

        const drawHeader = (pageNum, totalPages) => {
            doc.addPage();
            // Main Border
            doc.rect(20, pageTop, 555, 790).stroke();

            // 1. Logo at Top Left
            const logoPath = path.join(__dirname, '..', 'ovg_billing', 'assets', 'images', 'ideal_logo.png');
            if (fs.existsSync(logoPath)) {
                doc.image(logoPath, 25, logoY, { width: 100 });
            }

            // 2. TAX INVOICE Title
            doc.fontSize(14).font('Helvetica-Bold').text('TAX INVOICE', 20, titleY, { align: 'center', width: 535 });
            drawLine(titleY + 18);

            // 3. Header Section (Company on Left, Grid on Right)
            doc.fontSize(12).font('Helvetica-Bold').text('OM VINAYAKA GARMENTS', 25, headerY);
            doc.fontSize(9).font('Helvetica');
            doc.text('SF No. 252/1, Merkalath Thottam North,', 25, headerY + 15);
            doc.text('Balaji Nagar, Boyampalayam,', 25, headerY + 27);
            doc.text('Tirupur - 641602.', 25, headerY + 39);
            doc.text('State : Tamilnadu | Code : 33', 25, headerY + 51);
            doc.text('Mobile : 8012552252', 25, headerY + 63);
            doc.text('E-Mail : idealovg@gmail.com', 25, headerY + 75);
            doc.text('GSTIN : 33BHNPS9629C1ZZ', 25, headerY + 87);

            // Right side grid
            drawVLine(280, titleY + 18, middleY); 
            drawVLine(425, titleY + 18, middleY); 
            
            let ry = titleY + 18;
            const rowH = 15;
            doc.fontSize(9).font('Helvetica');
            doc.text('Invoice Number', 285, ry + 4); doc.text(inv.invoice_number, 430, ry + 4); drawHLine(280, 575, ry += rowH);
            doc.text('Invoice Date', 285, ry + 4); doc.text(new Date(inv.created_at).toLocaleDateString('en-GB'), 430, ry + 4); drawHLine(280, 575, ry += rowH);
            doc.text('Buyer Order no. & Dt', 285, ry + 4); drawHLine(280, 575, ry += rowH);
            doc.text('Mode of Payment', 285, ry + 4); doc.text(inv.payment_type || '-', 430, ry + 4); drawHLine(280, 575, ry += rowH);
            doc.text('Payment Type', 285, ry + 4); doc.text(inv.payment_type || 'Online Payment', 430, ry + 4); drawHLine(280, 575, ry += rowH);
            doc.text('Destination', 285, ry + 4); doc.text(inv.destination || '-', 430, ry + 4); drawHLine(280, 575, ry += rowH);
            doc.text('Vehicle Number', 285, ry + 4); doc.text(inv.vehicle_number || '-', 430, ry + 4); drawHLine(280, 575, ry += rowH);
            doc.text('Other Reference', 285, ry + 4); doc.text(inv.other_reference || '-', 430, ry + 4);
            
            drawLine(middleY);

            // 4. Middle Section (Buyer & Consignee)
            doc.fontSize(11).font('Helvetica-Bold');
            doc.text('Buyer (Bill to)', 25, middleY + 5);
            doc.text('Consignee (Ship to)', 285, middleY + 5);
            
            doc.fontSize(9).font('Helvetica-Bold');
            doc.text(inv.customer_name, 25, middleY + 20);
            doc.text(inv.customer_name, 285, middleY + 20);
            
            doc.font('Helvetica');
            doc.text(inv.customer_address, 25, middleY + 32, { width: 250 });
            doc.text(inv.customer_address, 285, middleY + 32, { width: 250 });
            
            doc.font('Helvetica-Bold');
            const gstinText = inv.customer_gstin || inv.gstin || 'Unregistered/Consumer';
            doc.text(`GSTIN : ${gstinText}`, 25, middleY + 75);
            doc.text(`GSTIN : ${gstinText}`, 285, middleY + 75);
            
            drawLine(tableHeaderY);

            // 5. Table Header
            doc.fontSize(9).font('Helvetica-Bold');
            doc.text('Sl', 25, tableHeaderY + 5, { align: 'center', width: 20 });
            doc.text('No', 25, tableHeaderY + 15, { align: 'center', width: 20 });
            doc.text('Description of Goods', 60, tableHeaderY + 10);
            doc.text('HSN', 250, tableHeaderY + 10, { align: 'center', width: 40 });
            doc.text('QTY', 295, tableHeaderY + 10);
            doc.text('UQC', 335, tableHeaderY + 10);
            doc.text('Rate', 370, tableHeaderY + 5, { align: 'center', width: 50 });
            doc.text('per Nos', 370, tableHeaderY + 15, { align: 'center', width: 50 });
            doc.text('Disc. %', 430, tableHeaderY + 10);
            doc.text('Amount', 495, tableHeaderY + 10, { width: 70, align: 'right' });
            
            drawLine(tableTop);

            // Vertical lines for table
            drawVLine(45, tableHeaderY, tableBottom);  // Sl No
            drawVLine(250, tableHeaderY, tableBottom); // Description
            drawVLine(290, tableHeaderY, tableBottom); // HSN
            drawVLine(330, tableHeaderY, tableBottom); // QTY
            drawVLine(365, tableHeaderY, tableBottom); // UQC
            drawVLine(425, tableHeaderY, tableBottom); // Rate
            drawVLine(480, tableHeaderY, tableBottom); // Disc

            // Page Number
            doc.fontSize(8).font('Helvetica').text(`Page ${pageNum} of ${totalPages}`, 20, 800, { align: 'center', width: 555 });
        };

        // Chunking items
        const chunks = [];
        for (let i = 0; i < inv.items.length; i += itemsPerPage) {
            chunks.push(inv.items.slice(i, i + itemsPerPage));
        }

        let totalQty = 0;
        let subTotalBase = 0;
        const hsnMap = {};

        // Process each chunk
        for (let chunkIdx = 0; chunkIdx < chunks.length; chunkIdx++) {
            const chunk = chunks[chunkIdx];
            drawHeader(chunkIdx + 1, chunks.length);
            
            let currentY = tableTop + 5;
            chunk.forEach((item, itemIdx) => {
                const globalIdx = (chunkIdx * itemsPerPage) + itemIdx;
                const baseRate = item.rate / 1.05;
                const baseTotal = item.total_amount / 1.05;

                doc.fontSize(10).font('Helvetica'); 
                doc.text((globalIdx + 1).toString(), 25, currentY, { align: 'center', width: 20 });
                doc.font('Helvetica-Bold').text(item.product_name, 50, currentY, { width: 195 });
                doc.font('Helvetica').fontSize(9).text(`${item.size} • ${item.quality}`, 50, currentY + 12, { width: 195 });
                doc.fontSize(10).text(item.hsn_code || '', 250, currentY, { align: 'center', width: 40 });
                doc.text(item.quantity.toString(), 295, currentY);
                doc.text('NOS', 335, currentY);
                doc.text(baseRate.toFixed(2), 370, currentY, { align: 'center', width: 50 });
                doc.text(`${item.discount_percent}%`, 430, currentY);
                doc.text(baseTotal.toFixed(2), 495, currentY, { width: 70, align: 'right' });
                
                subTotalBase += baseTotal;
                totalQty += item.quantity;

                // Track HSN for summary
                const hsn = item.hsn_code || 'N/A';
                if (!hsnMap[hsn]) hsnMap[hsn] = { taxable: 0, cgst: 0, sgst: 0 };
                hsnMap[hsn].taxable += baseTotal;
                hsnMap[hsn].cgst += baseTotal * 0.025;
                hsnMap[hsn].sgst += baseTotal * 0.025;

                currentY += 30; 
                drawHLine(20, 575, currentY - 4);
            });

            // If it's the last page, draw the footer summary
            if (chunkIdx === chunks.length - 1) {
                // Totals Section of Table
                drawLine(currentY - 4);
                doc.fontSize(10).font('Helvetica-Bold').text('Total', 150, currentY);
                doc.text(totalQty.toString(), 295, currentY);
                doc.text('NOS', 335, currentY);
                doc.text(subTotalBase.toFixed(2), 495, currentY, { width: 70, align: 'right' });
                drawLine(tableBottom);

                // Tax Summary Table
                drawVLine(350, tableBottom, tableBottom + 105); 

                // Headers
                doc.fontSize(9).font('Helvetica-Bold');
                doc.text('HSN', 20, tableBottom + 10, { width: 60, align: 'center' });
                doc.text('Taxable Value', 80, tableBottom + 10, { width: 70, align: 'center' });
                doc.text('CGST', 150, tableBottom + 10, { width: 60, align: 'center' });
                doc.text('SGST', 210, tableBottom + 10, { width: 60, align: 'center' });
                doc.text('TOTAL TAX', 270, tableBottom + 10, { width: 80, align: 'center' });
                drawLine(tableBottom + 25);

                drawVLine(80, tableBottom, tableBottom + 105);
                drawVLine(150, tableBottom, tableBottom + 105);
                drawVLine(210, tableBottom, tableBottom + 105);
                drawVLine(270, tableBottom, tableBottom + 105);

                let hsnY = tableBottom + 30;
                let sumTaxable = 0, sumCgst = 0, sumSgst = 0, sumTotalTax = 0;
                Object.keys(hsnMap).forEach(hsn => {
                    const data = hsnMap[hsn];
                    const ttax = data.cgst + data.sgst;
                    doc.fontSize(8).font('Helvetica');
                    doc.text(hsn, 20, hsnY, { width: 60, align: 'center' });
                    doc.text(data.taxable.toFixed(2), 80, hsnY, { width: 65, align: 'right' });
                    doc.text(data.cgst.toFixed(2), 150, hsnY, { width: 55, align: 'right' });
                    doc.text(data.sgst.toFixed(2), 210, hsnY, { width: 55, align: 'right' });
                    doc.text(ttax.toFixed(2), 270, hsnY, { width: 75, align: 'right' });
                    sumTaxable += data.taxable; sumCgst += data.cgst; sumSgst += data.sgst; sumTotalTax += ttax;
                    hsnY += 12;
                });

                drawLine(tableBottom + 105);
                doc.fontSize(8).font('Helvetica-Bold').text('Total', 20, tableBottom + 108, { width: 60, align: 'center' });
                doc.text(sumTaxable.toFixed(2), 80, tableBottom + 108, { width: 65, align: 'right' });
                doc.text(sumCgst.toFixed(2), 150, tableBottom + 108, { width: 55, align: 'right' });
                doc.text(sumSgst.toFixed(2), 210, tableBottom + 108, { width: 55, align: 'right' });
                doc.text(sumTotalTax.toFixed(2), 270, tableBottom + 108, { width: 75, align: 'right' });

                // Right side final summary
                doc.fontSize(9).font('Helvetica-Bold');
                doc.text('Total Taxable Value', 355, tableBottom + 30); doc.text(sumTaxable.toFixed(2), 485, tableBottom + 30, { width: 75, align: 'right' });
                doc.font('Helvetica');
                doc.text('CGST @ 2.5%', 355, tableBottom + 43); doc.text(sumCgst.toFixed(2), 485, tableBottom + 43, { width: 75, align: 'right' });
                doc.text('SGST @ 2.5%', 355, tableBottom + 56); doc.text(sumSgst.toFixed(2), 485, tableBottom + 56, { width: 75, align: 'right' });
                const roundOff = inv.grand_total - (sumTaxable + sumCgst + sumSgst);
                doc.text('Round Off', 355, tableBottom + 69); doc.text(roundOff.toFixed(2), 485, tableBottom + 69, { width: 75, align: 'right' });
                
                doc.fontSize(10).font('Helvetica-Bold');
                doc.text('INVOICE VALUE', 355, tableBottom + 88); doc.text(inv.grand_total.toFixed(2), 485, tableBottom + 88, { width: 75, align: 'right' });

                // --- CONTINUOUS LINE ---
                drawLine(tableBottom + 115);

                // Amount in words
                doc.fontSize(9).font('Helvetica-Bold').text('Amount in words :', 25, tableBottom + 122);
                doc.font('Helvetica').text(`INR ${numberToWords(Math.round(inv.grand_total))} Only`, 120, tableBottom + 122);
                drawLine(tableBottom + 138);

                // Footer parts
                doc.fontSize(8).font('Helvetica-Bold').text('Narration : ', 25, tableBottom + 145);
                doc.font('Helvetica').text('10 Boxes, 1 Bundle', 80, tableBottom + 145);
                drawLine(tableBottom + 160);

                drawVLine(280, tableBottom + 160, 800);
                doc.fontSize(8).font('Helvetica-Bold').text('Declaration :', 25, tableBottom + 165);
                doc.font('Helvetica').fontSize(7).text('We declare that this invoice shows the actual price of the goods described and that all particulars are true and correct.', 25, tableBottom + 175, { width: 240 });
                
                doc.fontSize(9).font('Helvetica-Bold').text('Party Signature', 25, 785, { width: 240, align: 'center' });

                try {
                    const upiString = 'upi://pay?pa=SBIBHIM.INSTANT40743749241829455@sbipay&pn=Om Vinayaka Garments&cu=INR';
                    const qrBuffer = await QRCode.toBuffer(upiString, { margin: 0 });
                    doc.image(qrBuffer, 285, tableBottom + 165, { width: 60 });
                } catch(e) {}

                doc.fontSize(8).font('Helvetica-Bold').text('Bank Details', 360, tableBottom + 165);
                doc.font('Helvetica').fontSize(7).text('Bank: State Bank of India', 360, tableBottom + 175);
                doc.text('A/c: 3786 842 1441', 360, tableBottom + 185);
                doc.text('IFSC: SBIN0000267', 360, tableBottom + 195);

                doc.font('Helvetica-Bold').fontSize(9).text('For Om Vinayaka Garments', 290, 785, { width: 280, align: 'center' });
            } else {
                // If not last page, just close the table bottom
                drawLine(tableBottom);
            }
        }

        doc.end();
    } catch (err) {
        res.status(500).send(err.message);
    }
});


// Helper for numbers to words
function numberToWords(num) {
    const a = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
    const b = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];
    const g = ['', 'Thousand', 'Million', 'Billion', 'Trillion'];
    
    if (num === 0) return 'Zero';
    
    const makeGroup = (n) => {
        let s = '';
        if (n >= 100) {
            s += a[Math.floor(n / 100)] + ' Hundred ';
            n %= 100;
        }
        if (n >= 20) {
            s += b[Math.floor(n / 10)] + (n % 10 !== 0 ? ' ' + a[n % 10] : '');
        } else if (n > 0) {
            s += a[n];
        }
        return s;
    };

    let s = '';
    let i = 0;
    while (num > 0) {
        if (num % 1000 !== 0) {
            s = makeGroup(num % 1000) + ' ' + g[i] + ' ' + s;
        }
        num = Math.floor(num / 1000);
        i++;
    }
    return s.trim();
}

app.delete('/invoices/:id', async (req, res) => {
    try {
        await invoicesCollection.deleteOne({ _id: new ObjectId(req.params.id) });
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- Master Management Delete/Update ---
app.delete('/customers/:id', async (req, res) => {
    try {
        await customersCollection.deleteOne({ _id: new ObjectId(req.params.id) });
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.delete('/products/:id', async (req, res) => {
    try {
        await productsCollection.deleteOne({ _id: new ObjectId(req.params.id) });
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.put('/products/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const updatedData = { ...req.body, updated_at: new Date().toISOString() };
        delete updatedData._id;
        delete updatedData.id;
        await productsCollection.updateOne(
            { _id: new ObjectId(id) },
            { $set: updatedData }
        );
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.put('/customers/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const updatedData = { ...req.body, updated_at: new Date().toISOString() };
        delete updatedData._id;
        delete updatedData.id;
        await customersCollection.updateOne(
            { _id: new ObjectId(id) },
            { $set: updatedData }
        );
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- Scanned Bills (OCR) ---
app.get('/bills', async (req, res) => {
    try {
        const bills = await scannedBillsCollection.find().sort({ created_at: -1 }).toArray();
        res.json(bills.map(serialize));
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/bills/upload', upload.single('bill'), async (req, res) => {
    if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
    
    const imageUrl = `/uploads/${req.file.filename}`;
    const filePath = req.file.path;
    const isPDF = req.file.mimetype === 'application/pdf';

    if (!openai) {
        return res.json({ 
            success: true, 
            imageUrl, 
            parsedData: { note: "OCR not available (OpenAI Key missing)" } 
        });
    }

    try {
        let parsedData = {};

        if (isPDF) {
            console.log('Processing PDF bill...');
            const dataBuffer = fs.readFileSync(filePath);
            // pdf-parse can be imported differently depending on the environment
            const pdfParse = typeof pdf === 'function' ? pdf : pdf.default;
            const pdfData = await pdfParse(dataBuffer);
            const text = pdfData.text;

            console.log('Sending PDF text to OpenAI for structuring...');
            const response = await openai.chat.completions.create({
                model: "gpt-4o-mini",
                messages: [
                    {
                        role: "user",
                        content: `You are an expert invoice parser. Extract ALL available details from this bill text into a JSON format. This should include: party_name, date, total_amount, gst_number, invoice_number, address, and a list of items (name, qty, rate, amount). If you find other relevant fields, include them as well. Return ONLY the JSON.\n\nText: ${text}`
                    }
                ],
                response_format: { type: "json_object" }
            });
            parsedData = JSON.parse(response.choices[0].message.content);
        } else {
            console.log('Sending image bill to OpenAI Vision for OCR...');
            const imageBuffer = fs.readFileSync(filePath);
            const base64Image = imageBuffer.toString('base64');
            const mimeType = req.file.mimetype;

            const response = await openai.chat.completions.create({
                model: "gpt-4o-mini",
                messages: [
                    {
                        role: "user",
                        content: [
                            { type: "text", text: "You are an expert invoice parser. Extract ALL available details from this bill image into a JSON format. This should include: party_name, date, total_amount, gst_number, invoice_number, address, and a list of items (name, qty, rate, amount). If you find other relevant fields, include them as well. Return ONLY the JSON." },
                            {
                                type: "image_url",
                                image_url: {
                                    "url": `data:${mimeType};base64,${base64Image}`,
                                },
                            },
                        ],
                    },
                ],
                response_format: { type: "json_object" }
            });
            parsedData = JSON.parse(response.choices[0].message.content);
        }

        console.log('OCR/Parse Result:', parsedData);

        const billRecord = {
            imageUrl,
            isPDF,
            parsedData,
            status: 'parsed',
            created_at: new Date()
        };

        const result = await scannedBillsCollection.insertOne(billRecord);
        const savedBill = await scannedBillsCollection.findOne({ _id: result.insertedId });
        
        res.json(serialize(savedBill));
    } catch (err) {
        console.error('Processing Error:', err);
        const billRecord = {
            imageUrl,
            isPDF,
            error: err.message,
            status: 'failed',
            created_at: new Date()
        };
        const result = await scannedBillsCollection.insertOne(billRecord);
        const savedBill = await scannedBillsCollection.findOne({ _id: result.insertedId });
        res.json(serialize(savedBill));
    }
});

app.delete('/bills/:id', async (req, res) => {
    try {
        await scannedBillsCollection.deleteOne({ _id: new ObjectId(req.params.id) });
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.put('/bills/:id', async (req, res) => {
    try {
        const { parsedData } = req.body;
        await scannedBillsCollection.updateOne(
            { _id: new ObjectId(req.params.id) },
            { $set: { parsedData } }
        );
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.listen(PORT, '0.0.0.0', () => console.log(`Server running on port ${PORT}`));
