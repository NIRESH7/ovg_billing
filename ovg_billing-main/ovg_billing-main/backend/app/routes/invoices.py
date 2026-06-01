from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from app.database import invoices_collection, customers_collection
from app.models import InvoiceCreate
from bson import ObjectId
from datetime import datetime
from typing import List, Optional
import io

router = APIRouter(prefix="/invoices", tags=["Invoices"])


def serialize(inv) -> dict:
    inv["id"] = str(inv["_id"])
    del inv["_id"]
    if isinstance(inv.get("created_at"), datetime):
        inv["created_at"] = inv["created_at"].isoformat()
    return inv


async def get_next_invoice_number() -> str:
    year = datetime.now().year
    month = datetime.now().month
    prefix = f"OVG/{year}/{month:02d}/"
    count = await invoices_collection.count_documents({
        "invoice_number": {"$regex": f"^{prefix}"}
    })
    return f"{prefix}{count + 1:04d}"


@router.post("/", response_model=dict)
async def create_invoice(invoice: InvoiceCreate):
    inv_dict = invoice.dict()
    inv_dict["invoice_number"] = await get_next_invoice_number()
    inv_dict["created_at"] = datetime.utcnow()

    # Save customer if not exists
    if not invoice.customer_id:
        existing = await customers_collection.find_one({"mobile": invoice.customer_mobile})
        if not existing:
            cust = await customers_collection.insert_one({
                "name": invoice.customer_name,
                "mobile": invoice.customer_mobile,
                "address": invoice.customer_address,
                "gstin": invoice.customer_gstin
            })
            inv_dict["customer_id"] = str(cust.inserted_id)
        else:
            inv_dict["customer_id"] = str(existing["_id"])

    result = await invoices_collection.insert_one(inv_dict)
    new = await invoices_collection.find_one({"_id": result.inserted_id})
    return serialize(new)


@router.get("/", response_model=List[dict])
async def get_all_invoices(skip: int = 0, limit: int = 50):
    invoices = await invoices_collection.find().sort("created_at", -1).skip(skip).limit(limit).to_list(limit)
    return [serialize(i) for i in invoices]


@router.get("/stats/today")
async def get_today_stats():
    today = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    pipeline = [
        {"$match": {"created_at": {"$gte": today}}},
        {"$group": {
            "_id": None,
            "total_bills": {"$sum": 1},
            "total_amount": {"$sum": "$grand_total"},
            "total_items": {"$sum": {"$size": "$items"}}
        }}
    ]
    result = await invoices_collection.aggregate(pipeline).to_list(1)
    if result:
        return {
            "total_bills": result[0]["total_bills"],
            "total_amount": result[0]["total_amount"],
            "total_items": result[0]["total_items"]
        }
    return {"total_bills": 0, "total_amount": 0.0, "total_items": 0}


@router.get("/stats/monthly")
async def get_monthly_stats():
    from datetime import timedelta
    # Last 6 months
    pipeline = [
        {"$group": {
            "_id": {
                "year": {"$year": "$created_at"},
                "month": {"$month": "$created_at"}
            },
            "total": {"$sum": "$grand_total"},
            "count": {"$sum": 1}
        }},
        {"$sort": {"_id.year": -1, "_id.month": -1}},
        {"$limit": 6}
    ]
    result = await invoices_collection.aggregate(pipeline).to_list(6)
    return result


@router.get("/{invoice_id}", response_model=dict)
async def get_invoice(invoice_id: str):
    inv = await invoices_collection.find_one({"_id": ObjectId(invoice_id)})
    if not inv:
        raise HTTPException(status_code=404, detail="Invoice not found")
    return serialize(inv)


@router.get("/{invoice_id}/pdf")
async def download_invoice_pdf(invoice_id: str):
    """Generate and return PDF for an invoice"""
    from app.utils.pdf_generator import generate_invoice_pdf

    inv = await invoices_collection.find_one({"_id": ObjectId(invoice_id)})
    if not inv:
        raise HTTPException(status_code=404, detail="Invoice not found")

    inv["id"] = str(inv["_id"])
    pdf_bytes = generate_invoice_pdf(inv)

    return StreamingResponse(
        io.BytesIO(pdf_bytes),
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="invoice_{inv["invoice_number"].replace("/", "-")}.pdf"'}
    )
