"""
Customer Controller - REST API Endpoints untuk Customer operations
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from typing import Optional, List
from db.database import get_db
from services.customer_service import CustomerService

router = APIRouter(prefix="/service/customer", tags=["Customer Service"])
customer_service = CustomerService()


# ===== Pydantic Models (Request/Response) =====

class CustomerCreate(BaseModel):
    """Request model untuk create customer"""
    customer_name: str
    customer_username: str
    customer_pin: str  # Harus sudah di-hash dari middleware
    customer_email: EmailStr
    customer_phone: str
    cif_number: str


class CustomerUpdate(BaseModel):
    """Request model untuk update customer"""
    customer_name: Optional[str] = None
    customer_email: Optional[EmailStr] = None
    customer_phone: Optional[str] = None
    failed_login_attempts: Optional[int] = None
    is_locked: Optional[bool] = None
    last_login: Optional[str] = None


class CustomerResponse(BaseModel):
    """Response model untuk customer"""
    id: int
    customer_name: str
    customer_username: str
    customer_email: str
    customer_phone: str
    cif_number: str
    failed_login_attempts: int
    is_locked: bool
    last_login: Optional[str]
    created_at: Optional[str]
    updated_at: Optional[str]


# ===== API Endpoints =====

@router.post("", response_model=CustomerResponse, status_code=201)
def register_customer(customer: CustomerCreate, db: Session = Depends(get_db)):
    """
    Register customer baru
    
    Endpoint: POST /service/customer
    
    Request Body:
    {
        "customer_name": "Budi",
        "customer_username": "budi01",
        "customer_pin": "HASHED_PIN",
        "customer_email": "budi@gmail.com",
        "customer_phone": "08123",
        "cif_number": "9001"
    }
    
    Returns:
        Customer object yang baru dibuat
    """
    print(f"\n{'='*50}")
    print(f"📝 NEW CUSTOMER REGISTRATION REQUEST")
    print(f"   Username: {customer.customer_username}")
    print(f"   Name: {customer.customer_name}")
    print(f"   Email: {customer.customer_email}")
    print(f"   CIF: {customer.cif_number}")
    print(f"{'='*50}\n")
    
    customer_data = customer.dict()
    result = customer_service.create_customer(db, customer_data)
    
    print(f"\n{'='*50}")
    print(f"✅ REGISTRATION SUCCESSFUL")
    print(f"   Customer ID: {result['id']}")
    print(f"   Username: {result['customer_username']}")
    print(f"{'='*50}\n")
    
    return result


@router.get("/username/{username}")
def get_customer_by_username(username: str, db: Session = Depends(get_db)):
    """
    Get customer berdasarkan username
    Digunakan untuk proses login di middleware
    
    Endpoint: GET /service/customer/username/{username}
    
    Returns:
        Customer object (termasuk PIN untuk validasi)
    """
    result = customer_service.get_customer_by_username(db, username)
    return result


@router.get("/{customer_id}", response_model=CustomerResponse)
def get_customer_by_id(customer_id: int, db: Session = Depends(get_db)):
    """
    Get customer berdasarkan ID
    
    Endpoint: GET /service/customer/{customer_id}
    
    Returns:
        Customer object
    """
    result = customer_service.get_customer_by_id(db, customer_id)
    return result


@router.get("", response_model=List[CustomerResponse])
def get_all_customers(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """
    Get semua customer dengan pagination
    
    Endpoint: GET /service/customer?skip=0&limit=100
    
    Returns:
        List of customer objects
    """
    result = customer_service.get_all_customers(db, skip, limit)
    return result


@router.put("/{customer_id}", response_model=CustomerResponse)
def update_customer(customer_id: int, customer: CustomerUpdate, db: Session = Depends(get_db)):
    """
    Update customer data
    Digunakan untuk update failed_login_attempts, is_locked, last_login, dll
    
    Endpoint: PUT /service/customer/{customer_id}
    
    Request Body (semua field optional):
    {
        "failed_login_attempts": 2,
        "last_login": "2025-01-11T10:20:00"
    }
    
    Returns:
        Customer object yang telah diupdate
    """
    # Filter hanya field yang diisi
    update_data = {k: v for k, v in customer.dict().items() if v is not None}
    result = customer_service.update_customer(db, customer_id, update_data)
    return result


@router.post("/{customer_id}/failed-login")
def handle_failed_login(customer_id: int, db: Session = Depends(get_db)):
    """
    Handle failed login attempt
    Increment failed_login_attempts dan lock account jika >= 3
    
    Endpoint: POST /service/customer/{customer_id}/failed-login
    
    Returns:
        {
            "customer_id": 1,
            "failed_login_attempts": 2,
            "is_locked": false
        }
    """
    result = customer_service.handle_failed_login(db, customer_id)
    return result


@router.post("/{customer_id}/successful-login")
def handle_successful_login(customer_id: int, db: Session = Depends(get_db)):
    """
    Handle successful login
    Reset failed_login_attempts dan update last_login
    
    Endpoint: POST /service/customer/{customer_id}/successful-login
    
    Returns:
        Customer object yang telah diupdate
    """
    result = customer_service.handle_successful_login(db, customer_id)
    return result


@router.post("/{customer_id}/unlock")
def unlock_account(customer_id: int, db: Session = Depends(get_db)):
    """
    Unlock account dan reset failed attempts
    
    Endpoint: POST /service/customer/{customer_id}/unlock
    
    Returns:
        Customer object yang telah diupdate
    """
    result = customer_service.unlock_account(db, customer_id)
    return result


@router.get("/{customer_id}/check-locked")
def check_account_locked(customer_id: int, db: Session = Depends(get_db)):
    """
    Check apakah account locked
    
    Endpoint: GET /service/customer/{customer_id}/check-locked
    
    Returns:
        {
            "is_locked": true/false
        }
    """
    is_locked = customer_service.check_account_locked(db, customer_id)
    return {"is_locked": is_locked}
