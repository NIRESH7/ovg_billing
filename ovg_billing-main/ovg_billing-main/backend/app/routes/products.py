from fastapi import APIRouter, HTTPException
from app.database import products_collection
from app.models import Product, ProductOut
from bson import ObjectId
from typing import List

router = APIRouter(prefix="/products", tags=["Products"])


def serialize_product(p) -> dict:
    p["id"] = str(p["_id"])
    del p["_id"]
    return p


@router.get("/", response_model=List[dict])
async def get_all_products():
    products = await products_collection.find().sort("sno", 1).to_list(1000)
    return [serialize_product(p) for p in products]


@router.get("/categories", response_model=List[str])
async def get_categories():
    categories = await products_collection.distinct("category")
    return sorted(categories)


@router.get("/category/{category}", response_model=List[dict])
async def get_by_category(category: str):
    products = await products_collection.find(
        {"category": {"$regex": category, "$options": "i"}}
    ).sort("sno", 1).to_list(1000)
    return [serialize_product(p) for p in products]


@router.get("/search", response_model=List[dict])
async def search_products(q: str):
    products = await products_collection.find(
        {"name": {"$regex": q, "$options": "i"}}
    ).sort("sno", 1).to_list(100)
    return [serialize_product(p) for p in products]


@router.get("/{product_id}", response_model=dict)
async def get_product(product_id: str):
    p = await products_collection.find_one({"_id": ObjectId(product_id)})
    if not p:
        raise HTTPException(status_code=404, detail="Product not found")
    return serialize_product(p)
