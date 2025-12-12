"""
Mobile Banking Service Layer - Main Application Entry Point
FastAPI REST API for direct database operations

Author: Mobile Banking Team
Date: 2025-12-12
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from db.database import init_db
from controllers import customer_controller, account_controller, transaction_controller

# Initialize FastAPI app
app = FastAPI(
    title="Mobile Banking Service Layer",
    description="REST API untuk operasi database Mobile Banking System. "
                "Service layer ini berinteraksi langsung dengan database "
                "dan dipanggil oleh Middleware layer.",
    version="1.0.0",
    docs_url="/docs",  # Swagger UI
    redoc_url="/redoc"  # ReDoc
)

# CORS Configuration
# Allow middleware to access this service
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify middleware URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(customer_controller.router)
app.include_router(account_controller.router)
app.include_router(transaction_controller.router)


@app.on_event("startup")
def on_startup():
    """
    Event yang dijalankan saat aplikasi start
    Initialize database tables
    """
    print("🚀 Starting Mobile Banking Service Layer...")
    print("📦 Initializing database...")
    init_db()
    print("✅ Database initialized successfully!")
    print("🌐 Service Layer ready to accept requests")


@app.get("/")
def root():
    """
    Root endpoint - Health check
    """
    return {
        "service": "Mobile Banking Service Layer",
        "status": "running",
        "version": "1.0.0",
        "description": "REST API untuk operasi database Mobile Banking",
        "endpoints": {
            "customer": "/service/customer",
            "account": "/service/account",
            "transaction": "/service/transaction"
        },
        "documentation": {
            "swagger": "/docs",
            "redoc": "/redoc"
        }
    }


@app.get("/health")
def health_check():
    """
    Health check endpoint
    Digunakan oleh middleware untuk cek service availability
    """
    return {
        "status": "healthy",
        "service": "Mobile Banking Service Layer",
        "database": "connected"
    }


@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """
    Global exception handler untuk error yang tidak tertangani
    """
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal Server Error",
            "detail": str(exc)
        }
    )


if __name__ == "__main__":
    import uvicorn
    
    # Run the application
    # In production, use: uvicorn main:app --host 0.0.0.0 --port 8001
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8001,  # Service Layer port (berbeda dengan Middleware yang di 8000)
        reload=True,  # Auto-reload saat development
        log_level="info"
    )
