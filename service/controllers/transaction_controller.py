"""
Transaction Controller - REST API Endpoints untuk Transaction operations
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional, List
from db.database import get_db
from services.transaction_service import TransactionService

router = APIRouter(prefix="/service/transaction", tags=["Transaction Service"])
transaction_service = TransactionService()


# ===== Pydantic Models (Request/Response) =====

class TransactionCreate(BaseModel):
    """Request model untuk create transaction"""
    m_customer_id: int
    transaction_type: str  # TR (Transfer), WD (Withdrawal), DP (Deposit)
    transaction_amount: float
    from_account_number: Optional[str] = None
    to_account_number: Optional[str] = None
    status: str = "SUCCESS"  # PENDING, SUCCESS, FAILED
    description: Optional[str] = None


class TransactionStatusUpdate(BaseModel):
    """Request model untuk update status"""
    status: str  # PENDING, SUCCESS, FAILED


class TransactionResponse(BaseModel):
    """Response model untuk transaction"""
    id: int
    m_customer_id: int
    transaction_type: str
    transaction_amount: float
    from_account_number: Optional[str]
    to_account_number: Optional[str]
    status: str
    description: Optional[str]
    transaction_date: Optional[str]
    created_at: Optional[str]


# ===== API Endpoints =====

@router.post("", response_model=TransactionResponse, status_code=201)
def insert_transaction(transaction: TransactionCreate, db: Session = Depends(get_db)):
    """
    Insert transaction baru
    Dipanggil setelah middleware approve transaksi
    
    Endpoint: POST /service/transaction
    
    Request Body:
    {
        "m_customer_id": 1,
        "transaction_type": "TR",
        "transaction_amount": 100000,
        "from_account_number": "123456",
        "to_account_number": "987654",
        "status": "SUCCESS",
        "description": "Transfer sesama bank"
    }
    
    Returns:
        Transaction object yang baru dibuat
    """
    transaction_data = transaction.dict()
    result = transaction_service.create_transaction(db, transaction_data)
    return result


@router.get("/customer/{customer_id}", response_model=List[TransactionResponse])
def get_transactions_by_customer(customer_id: int, skip: int = 0, limit: int = 100, 
                                 db: Session = Depends(get_db)):
    """
    Get semua transaction milik customer
    Digunakan untuk riwayat transaksi
    
    Endpoint: GET /service/transaction/customer/{customer_id}?skip=0&limit=100
    
    Returns:
        List of transaction objects (sorted by date desc)
    """
    result = transaction_service.get_transactions_by_customer(db, customer_id, skip, limit)
    return result


@router.get("/account/{account_number}", response_model=List[TransactionResponse])
def get_transactions_by_account(account_number: str, skip: int = 0, limit: int = 100,
                                db: Session = Depends(get_db)):
    """
    Get semua transaction dari/ke account tertentu
    Digunakan untuk mutasi rekening
    
    Endpoint: GET /service/transaction/account/{account_number}?skip=0&limit=100
    
    Returns:
        List of transaction objects (sorted by date desc)
    """
    result = transaction_service.get_transactions_by_account(db, account_number, skip, limit)
    return result


@router.get("/{transaction_id}", response_model=TransactionResponse)
def get_transaction_by_id(transaction_id: int, db: Session = Depends(get_db)):
    """
    Get transaction berdasarkan ID
    
    Endpoint: GET /service/transaction/{transaction_id}
    
    Returns:
        Transaction object
    """
    result = transaction_service.get_transaction_by_id(db, transaction_id)
    return result


@router.get("/customer/{customer_id}/by-date")
def get_transactions_by_date_range(customer_id: int, start_date: str, end_date: str,
                                   db: Session = Depends(get_db)):
    """
    Get transactions dalam rentang tanggal
    
    Endpoint: GET /service/transaction/customer/{customer_id}/by-date?start_date=2025-01-01T00:00:00&end_date=2025-01-31T23:59:59
    
    Returns:
        List of transaction objects
    """
    result = transaction_service.get_transactions_by_date_range(db, customer_id, start_date, end_date)
    return result


@router.get("/customer/{customer_id}/by-type/{transaction_type}")
def get_transactions_by_type(customer_id: int, transaction_type: str, db: Session = Depends(get_db)):
    """
    Get transactions berdasarkan tipe
    
    Endpoint: GET /service/transaction/customer/{customer_id}/by-type/{transaction_type}
    
    Returns:
        List of transaction objects
    """
    result = transaction_service.get_transactions_by_type(db, customer_id, transaction_type)
    return result


@router.get("/customer/{customer_id}/by-status/{status}")
def get_transactions_by_status(customer_id: int, status: str, db: Session = Depends(get_db)):
    """
    Get transactions berdasarkan status
    
    Endpoint: GET /service/transaction/customer/{customer_id}/by-status/{status}
    
    Returns:
        List of transaction objects
    """
    result = transaction_service.get_transactions_by_status(db, customer_id, status)
    return result


@router.get("/customer/{customer_id}/recent")
def get_recent_transactions(customer_id: int, days: int = 30, db: Session = Depends(get_db)):
    """
    Get transactions N hari terakhir
    
    Endpoint: GET /service/transaction/customer/{customer_id}/recent?days=30
    
    Returns:
        List of transaction objects
    """
    result = transaction_service.get_recent_transactions(db, customer_id, days)
    return result


@router.put("/{transaction_id}/status", response_model=TransactionResponse)
def update_transaction_status(transaction_id: int, status_update: TransactionStatusUpdate,
                              db: Session = Depends(get_db)):
    """
    Update status transaction
    Digunakan jika transaksi pending perlu diupdate
    
    Endpoint: PUT /service/transaction/{transaction_id}/status
    
    Request Body:
    {
        "status": "SUCCESS"
    }
    
    Returns:
        Transaction object yang telah diupdate
    """
    result = transaction_service.update_transaction_status(db, transaction_id, status_update.status)
    return result
