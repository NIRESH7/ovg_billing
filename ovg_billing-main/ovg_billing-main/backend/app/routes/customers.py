from fastapi import APIRouter, HTTPException
from app.database import customers_collection
from app.models import Customer
from bson import ObjectId
from typing import List

router = APIRouter(prefix="/customers", tags=["Customers"])


def serialize(c) -> dict:
    c["id"] = str(c["_id"])
    del c["_id"]
    return c


@router.get("/", response_model=List[dict])
async def get_all_customers():
    customers = await customers_collection.find().sort("name", 1).to_list(1000)
    return [serialize(c) for c in customers]


@router.post("/", response_model=dict)
async def create_customer(customer: Customer):
    existing = await customers_collection.find_one({"mobile": customer.mobile})
    if existing:
        return serialize(existing)
    result = await customers_collection.insert_one(customer.dict())
    new = await customers_collection.find_one({"_id": result.inserted_id})
    return serialize(new)


@router.get("/search", response_model=List[dict])
async def search_customers(q: str):
    customers = await customers_collection.find({
        "$or": [
            {"name": {"$regex": q, "$options": "i"}},
            {"mobile": {"$regex": q, "$options": "i"}}
        ]
    }).to_list(50)
    return [serialize(c) for c in customers]


@router.put("/{customer_id}", response_model=dict)
async def update_customer(customer_id: str, customer: Customer):
    await customers_collection.update_one(
        {"_id": ObjectId(customer_id)},
        {"$set": customer.dict()}
    )
    updated = await customers_collection.find_one({"_id": ObjectId(customer_id)})
    return serialize(updated)
