"""
Account Controller - REST API Endpoints untuk Account operations
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional, List
from db.database import get_db
from services.account_service import AccountService

router = APIRouter(prefix="/service/account", tags=["Account Service"])
account_service = AccountService()


# ===== Pydantic Models (Request/Response) =====

class AccountCreate(BaseModel):
    """Request model untuk create account"""
    m_customer_id: int
    account_number: str
    account_name: str
    account_type: str  # SAV, CHK, dll
    currency_code: str = "IDR"
    clear_balance: float = 0.0
    available_balance: float = 0.0


class AccountBalanceUpdate(BaseModel):
    """Request model untuk update balance"""
    clear_balance: float
    available_balance: float


class AccountUpdate(BaseModel):
    """Request model untuk update account"""
    account_name: Optional[str] = None
    is_active: Optional[bool] = None


class AccountResponse(BaseModel):
    """Response model untuk account"""
    id: int
    m_customer_id: int
    account_number: str
    account_name: str
    account_type: str
    currency_code: str
    clear_balance: float
    available_balance: float
    is_active: bool
    created_at: Optional[str]
    updated_at: Optional[str]


# ===== API Endpoints =====

@router.post("", response_model=AccountResponse, status_code=201)
def create_portfolio_account(account: AccountCreate, db: Session = Depends(get_db)):
    """
    Create portfolio account baru
    Dipanggil setelah customer register
    
    Endpoint: POST /service/account
    
    Request Body:
    {
        "m_customer_id": 1,
        "account_number": "1234567890",
        "account_name": "Budi",
        "account_type": "SAV",
        "currency_code": "IDR",
        "clear_balance": 1000000,
        "available_balance": 1000000
    }
    
    Returns:
        Account object yang baru dibuat
    """
    account_data = account.dict()
    result = account_service.create_account(db, account_data)
    return result


@router.get("/customer/{customer_id}", response_model=List[AccountResponse])
def get_accounts_by_customer(customer_id: int, active_only: bool = True, db: Session = Depends(get_db)):
    """
    Get semua account milik customer
    Digunakan untuk cek saldo di middleware
    
    Endpoint: GET /service/account/customer/{customer_id}?active_only=true
    
    Returns:
        List of account objects
    """
    result = account_service.get_accounts_by_customer(db, customer_id, active_only)
    return result


@router.get("/number/{account_number}", response_model=AccountResponse)
def get_account_by_number(account_number: str, db: Session = Depends(get_db)):
    """
    Get account berdasarkan account number
    
    Endpoint: GET /service/account/number/{account_number}
    
    Returns:
        Account object
    """
    result = account_service.get_account_by_number(db, account_number)
    return result


@router.get("/{account_id}", response_model=AccountResponse)
def get_account_by_id(account_id: int, db: Session = Depends(get_db)):
    """
    Get account berdasarkan ID
    
    Endpoint: GET /service/account/{account_id}
    
    Returns:
        Account object
    """
    result = account_service.get_account_by_id(db, account_id)
    return result


@router.get("/{account_number}/balance")
def get_account_balance(account_number: str, db: Session = Depends(get_db)):
    """
    Get balance account by account number
    
    Endpoint: GET /service/account/{account_number}/balance
    
    Returns:
    {
        "clear_balance": 1000000,
        "available_balance": 1000000
    }
    """
    account = account_service.get_account_by_number(db, account_number)
    return {
        "clear_balance": account['clear_balance'],
        "available_balance": account['available_balance']
    }


@router.put("/{account_number}/balance", response_model=AccountResponse)
def update_account_balance(account_number: str, balance: AccountBalanceUpdate, db: Session = Depends(get_db)):
    """
    Update balance account
    Dipanggil setelah transaksi berhasil
    Middleware harus memastikan debit/credit valid
    
    Endpoint: PUT /service/account/{account_number}/balance
    
    Request Body:
    {
        "clear_balance": 850000,
        "available_balance": 850000
    }
    
    Returns:
        Account object yang telah diupdate
    """
    result = account_service.update_balance(
        db, account_number, balance.clear_balance, balance.available_balance
    )
    return result


@router.post("/{account_number}/debit")
def debit_account(account_number: str, amount: float, db: Session = Depends(get_db)):
    """
    Debit (kurangi) balance dari account
    
    Endpoint: POST /service/account/{account_number}/debit
    
    Request Body:
    {
        "amount": 100000
    }
    
    Returns:
        Account object yang telah diupdate
    """
    result = account_service.debit_account(db, account_number, amount)
    return result


@router.post("/{account_number}/credit")
def credit_account(account_number: str, amount: float, db: Session = Depends(get_db)):
    """
    Credit (tambah) balance ke account
    
    Endpoint: POST /service/account/{account_number}/credit
    
    Request Body:
    {
        "amount": 100000
    }
    
    Returns:
        Account object yang telah diupdate
    """
    result = account_service.credit_account(db, account_number, amount)
    return result


@router.get("/{account_number}/check-balance")
def check_balance_sufficient(account_number: str, amount: float, db: Session = Depends(get_db)):
    """
    Check apakah balance mencukupi untuk transaksi
    
    Endpoint: GET /service/account/{account_number}/check-balance?amount=100000
    
    Returns:
        {
            "sufficient": true/false
        }
    """
    is_sufficient = account_service.check_balance_sufficient(db, account_number, amount)
    return {"sufficient": is_sufficient}


@router.put("/{account_id}", response_model=AccountResponse)
def update_account(account_id: int, account: AccountUpdate, db: Session = Depends(get_db)):
    """
    Update account data
    
    Endpoint: PUT /service/account/{account_id}
    
    Request Body (semua field optional):
    {
        "account_name": "Budi Santoso",
        "is_active": true
    }
    
    Returns:
        Account object yang telah diupdate
    """
    # Filter hanya field yang diisi
    update_data = {k: v for k, v in account.dict().items() if v is not None}
    result = account_service.update_account(db, account_id, update_data)
    return result


@router.post("/{account_number}/deactivate", response_model=AccountResponse)
def deactivate_account(account_number: str, db: Session = Depends(get_db)):
    """
    Deactivate account (soft delete)
    
    Endpoint: POST /service/account/{account_number}/deactivate
    
    Returns:
        Account object yang telah di-deactivate
    """
    result = account_service.deactivate_account(db, account_number)
    return result
