from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime


# ─── Product Models ──────────────────────────────────────────────────────────
class SizePrice(BaseModel):
    size: str
    price: float


class Product(BaseModel):
    sno: int
    name: str
    category: str
    quality: str  # IE, OE, RN, etc.
    pkg: int = 10
    hsn_code: str = "61112000"
    gst_percent: float = 5.0
    size_prices: List[SizePrice]  # [{size: "75x80cm", price: 68.0}, ...]


class ProductOut(Product):
    id: str


# ─── Customer Models ─────────────────────────────────────────────────────────
class Customer(BaseModel):
    name: str
    mobile: str
    address: Optional[str] = ""
    gstin: Optional[str] = ""


class CustomerOut(Customer):
    id: str


# ─── Invoice Models ──────────────────────────────────────────────────────────
class InvoiceItem(BaseModel):
    product_id: str
    product_name: str
    hsn_code: str
    size: str
    quality: str
    category: str
    rate: float
    quantity: int
    discount_percent: float = 0.0
    taxable_amount: float
    cgst_percent: float = 2.5
    sgst_percent: float = 2.5
    cgst_amount: float
    sgst_amount: float
    total_amount: float


class InvoiceCreate(BaseModel):
    customer_id: Optional[str] = None
    customer_name: str
    customer_mobile: str
    customer_address: Optional[str] = ""
    customer_gstin: Optional[str] = ""
    items: List[InvoiceItem]
    subtotal: float
    total_cgst: float
    total_sgst: float
    grand_total: float
    payment_mode: str = "Cash"  # Cash, UPI, Credit
    notes: Optional[str] = ""


class InvoiceOut(InvoiceCreate):
    id: str
    invoice_number: str
    created_at: datetime
