from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import products, customers, invoices

app = FastAPI(
    title="OVG Billing API",
    description="Om Vinayaka Garments - Billing Backend",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(products.router)
app.include_router(customers.router)
app.include_router(invoices.router)


@app.get("/")
async def root():
    return {"message": "OVG Billing API is running 🚀", "version": "1.0.0"}


@app.get("/health")
async def health():
    return {"status": "ok"}
