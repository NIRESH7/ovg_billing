"""
Seed MongoDB with all products from the Excel price list.
Run: python seed_db.py
"""
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
from dotenv import load_dotenv
import os

load_dotenv()

MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
DB_NAME = os.getenv("DB_NAME", "ovg_billing")

# ── All 39 products parsed from 2026 PRICE LIST ─────────────────────────────
PRODUCTS = [
    # BANIANS
    {"sno": 1, "name": "PREMIUM VEST", "category": "BANIANS", "quality": "RN", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 90}, {"size": "85x90cm", "price": 102}, {"size": "95x100cm", "price": 116}]},
    {"sno": 2, "name": "PREMIUM VEST (S)", "category": "BANIANS", "quality": "RNS", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 105}, {"size": "85x90cm", "price": 124}, {"size": "95x100cm", "price": 143}]},
    {"sno": 3, "name": "PLUS VEST", "category": "BANIANS", "quality": "RN", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 86}, {"size": "85x90cm", "price": 97}, {"size": "95x100cm", "price": 109}]},
    {"sno": 4, "name": "PLUS VEST (S)", "category": "BANIANS", "quality": "RNBS", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 93}, {"size": "85x90cm", "price": 107}, {"size": "95x100cm", "price": 120}]},
    {"sno": 5, "name": "PREMIUM COLOUR VEST", "category": "BANIANS", "quality": "RN", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 100}, {"size": "85x90cm", "price": 115}, {"size": "95x100cm", "price": 128}]},
    {"sno": 6, "name": "GYM VEST", "category": "BANIANS", "quality": "RN", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 123}, {"size": "85x90cm", "price": 137}, {"size": "95x100cm", "price": 154}]},
    {"sno": 7, "name": "111 VEST", "category": "BANIANS", "quality": "RN", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 133}, {"size": "85x90cm", "price": 152}, {"size": "95x100cm", "price": 172}]},
    # BRIEFS
    {"sno": 8, "name": "PREMIUM BRIEF", "category": "BRIEFS", "quality": "IE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 75}, {"size": "85x90cm", "price": 82}, {"size": "95x100cm", "price": 91}]},
    {"sno": 9, "name": "PREMIUM BRIEF", "category": "BRIEFS", "quality": "OE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 79}, {"size": "85x90cm", "price": 86}, {"size": "95x100cm", "price": 95}]},
    {"sno": 10, "name": "ROYAL BRIEF", "category": "BRIEFS", "quality": "OE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 83}, {"size": "85x90cm", "price": 90}, {"size": "95x100cm", "price": 98}]},
    # TRUNKS
    {"sno": 11, "name": "RIO TRUNKS (POCKET)", "category": "TRUNKS", "quality": "IE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 121}, {"size": "85x90cm", "price": 138}, {"size": "95x100cm", "price": 164}]},
    {"sno": 12, "name": "RIO TRUNKS (POCKET)", "category": "TRUNKS", "quality": "OE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 120}, {"size": "85x90cm", "price": 137}, {"size": "95x100cm", "price": 162}]},
    {"sno": 13, "name": "RIO TRUNKS (W.O.P)", "category": "TRUNKS", "quality": "OE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 112}, {"size": "85x90cm", "price": 126}, {"size": "95x100cm", "price": 155}]},
    {"sno": 14, "name": "RIB TRUNKS", "category": "TRUNKS", "quality": "OE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 142}, {"size": "85x90cm", "price": 163}, {"size": "95x100cm", "price": 191}]},
    # PANTIES
    {"sno": 15, "name": "JAR PLAIN", "category": "PANTIES", "quality": "IE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 68}, {"size": "85x90cm", "price": 75}, {"size": "95x100cm", "price": 83}]},
    {"sno": 16, "name": "JAR PLAIN", "category": "PANTIES", "quality": "OE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 67}, {"size": "85x90cm", "price": 74}, {"size": "95x100cm", "price": 81}]},
    {"sno": 17, "name": "JAR PRINT", "category": "PANTIES", "quality": "IE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 71}, {"size": "85x90cm", "price": 78}, {"size": "95x100cm", "price": 87}]},
    {"sno": 18, "name": "JAR PRINT", "category": "PANTIES", "quality": "OE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 70}, {"size": "85x90cm", "price": 77}, {"size": "95x100cm", "price": 84}]},
    {"sno": 19, "name": "2PCS ANGEL PLAIN", "category": "PANTIES", "quality": "IE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 55}, {"size": "85x90cm", "price": 62}, {"size": "95x100cm", "price": 70}]},
    {"sno": 20, "name": "2PCS ANGEL PLAIN", "category": "PANTIES", "quality": "OE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 55}, {"size": "85x90cm", "price": 62}, {"size": "95x100cm", "price": 70}]},
    {"sno": 21, "name": "2PCS JASS PRINT", "category": "PANTIES", "quality": "IE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 61}, {"size": "85x90cm", "price": 68}, {"size": "95x100cm", "price": 78}]},
    {"sno": 22, "name": "2PCS JASS PRINT", "category": "PANTIES", "quality": "OE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 61}, {"size": "85x90cm", "price": 68}, {"size": "95x100cm", "price": 78}]},
    {"sno": 23, "name": "TIGHTS", "category": "PANTIES", "quality": "IE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 92}, {"size": "85x90cm", "price": 103}, {"size": "95x100cm", "price": 118}]},
    # SLIPS
    {"sno": 24, "name": "MINI SLIP", "category": "SLIPS", "quality": "BWS/CLR", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 87}, {"size": "85x90cm", "price": 97}, {"size": "95x100cm", "price": 109}]},
    {"sno": 25, "name": "CUTE SLIP", "category": "SLIPS", "quality": "BWS/CLR", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 91}, {"size": "85x90cm", "price": 99}, {"size": "95x100cm", "price": 112}]},
    {"sno": 26, "name": "ADJUSTABLE SLIP", "category": "SLIPS", "quality": "BWS/CLR", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "75x80cm", "price": 105}, {"size": "85x90cm", "price": 114}, {"size": "95x100cm", "price": 126}]},
    # BABY ITEMS
    {"sno": 27, "name": "TEDDY VEST", "category": "BABY ITEM", "quality": "RN", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "50x55cm", "price": 46}, {"size": "60x65cm", "price": 53}, {"size": "70x75cm", "price": 59}]},
    {"sno": 28, "name": "JUNIOR GYM VEST", "category": "BABY ITEM", "quality": "RN", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "50x55cm", "price": 90}, {"size": "60x65cm", "price": 104}]},
    {"sno": 29, "name": "JUNIOR TIGHTS", "category": "BABY ITEM", "quality": "IE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "50x55cm", "price": 63}, {"size": "60x65cm", "price": 74}]},
    {"sno": 30, "name": "JUNIOR ROYAL TOP", "category": "BABY ITEM", "quality": "OE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "50x55cm", "price": 54}, {"size": "60x65cm", "price": 61}]},
    {"sno": 31, "name": "MINI FRENCHIE", "category": "BABY ITEM", "quality": "IE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "50x55cm", "price": 47}, {"size": "60x65cm", "price": 53}]},
    {"sno": 32, "name": "PUPPY SLIP", "category": "BABY ITEM", "quality": "SLIP", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "50x55cm", "price": 62}, {"size": "60x65cm", "price": 67}]},
    {"sno": 33, "name": "NICE JETTY", "category": "BABY ITEM", "quality": "IE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "50x55cm", "price": 37}, {"size": "60x65cm", "price": 41}, {"size": "70x75cm", "price": 46}]},
    {"sno": 34, "name": "NICE DRAWER", "category": "BABY ITEM", "quality": "IE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "50x55cm", "price": 40}, {"size": "60x65cm", "price": 44}, {"size": "70x75cm", "price": 49}]},
    {"sno": 35, "name": "NICE JETTY", "category": "BABY ITEM", "quality": "OE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "50x55cm", "price": 39}, {"size": "60x65cm", "price": 42}, {"size": "70x75cm", "price": 48}]},
    {"sno": 36, "name": "NICE DRAWER", "category": "BABY ITEM", "quality": "OE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "50x55cm", "price": 42}, {"size": "60x65cm", "price": 46}, {"size": "70x75cm", "price": 51}]},
    {"sno": 37, "name": "BLOOMER JETTY", "category": "BABY ITEM", "quality": "IE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "50x55cm", "price": 42}, {"size": "60x65cm", "price": 48}, {"size": "70x75cm", "price": 53}]},
    {"sno": 38, "name": "BLOOMER DRAWER", "category": "BABY ITEM", "quality": "IE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "50x55cm", "price": 50}, {"size": "60x65cm", "price": 55}, {"size": "70x75cm", "price": 62}]},
    {"sno": 39, "name": "CUTE FRILL", "category": "BABY ITEM", "quality": "OE", "pkg": 10, "hsn_code": "61112000", "gst_percent": 5.0,
     "size_prices": [{"size": "50x55cm", "price": 36}, {"size": "60x65cm", "price": 38}, {"size": "70x75cm", "price": 41}]},
]


async def seed():
    client = AsyncIOMotorClient(MONGODB_URL)
    db = client[DB_NAME]
    products_col = db["products"]

    # Clear existing products
    await products_col.delete_many({})
    print(f"🗑  Cleared existing products")

    # Insert all products
    result = await products_col.insert_many(PRODUCTS)
    print(f"✅ Inserted {len(result.inserted_ids)} products into MongoDB")

    # Create indexes
    await products_col.create_index("name")
    await products_col.create_index("category")
    await products_col.create_index("sno")
    print("✅ Indexes created")

    client.close()


if __name__ == "__main__":
    asyncio.run(seed())
