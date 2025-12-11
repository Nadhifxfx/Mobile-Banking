"""
Customer Service - Business Logic Layer untuk Customer operations
"""
from sqlalchemy.orm import Session
from repository.customer_repository import CustomerRepository
from typing import Optional, List
from fastapi import HTTPException


class CustomerService:
    """Service layer untuk business logic customer"""

    def __init__(self):
        self.repository = CustomerRepository()

    def create_customer(self, db: Session, customer_data: dict) -> dict:
        """
        Create customer baru dengan validasi
        
        Args:
            db: Database session
            customer_data: Data customer baru
        
        Returns:
            Dict representasi customer yang dibuat
        
        Raises:
            HTTPException: Jika username/email/cif sudah terdaftar
        """
        # Validasi username belum dipakai
        existing_username = self.repository.get_by_username(db, customer_data["customer_username"])
        if existing_username:
            raise HTTPException(status_code=400, detail="Username sudah terdaftar")
        
        # Validasi email belum dipakai
        existing_email = self.repository.get_by_email(db, customer_data["customer_email"])
        if existing_email:
            raise HTTPException(status_code=400, detail="Email sudah terdaftar")
        
        # Validasi CIF belum dipakai
        existing_cif = self.repository.get_by_cif(db, customer_data["cif_number"])
        if existing_cif:
            raise HTTPException(status_code=400, detail="CIF Number sudah terdaftar")
        
        # Create customer
        customer = self.repository.create(db, customer_data)
        
        return self._customer_to_dict(customer)

    def get_customer_by_id(self, db: Session, customer_id: int) -> dict:
        """
        Get customer berdasarkan ID
        
        Args:
            db: Database session
            customer_id: ID customer
        
        Returns:
            Dict representasi customer
        
        Raises:
            HTTPException: Jika customer tidak ditemukan
        """
        customer = self.repository.get_by_id(db, customer_id)
        if not customer:
            raise HTTPException(status_code=404, detail="Customer tidak ditemukan")
        
        return self._customer_to_dict(customer)

    def get_customer_by_username(self, db: Session, username: str) -> dict:
        """
        Get customer berdasarkan username
        Digunakan untuk proses login di middleware
        
        Args:
            db: Database session
            username: Username customer
        
        Returns:
            Dict representasi customer (termasuk PIN untuk validasi login)
        
        Raises:
            HTTPException: Jika customer tidak ditemukan
        """
        customer = self.repository.get_by_username(db, username)
        if not customer:
            raise HTTPException(status_code=404, detail="Customer tidak ditemukan")
        
        return self._customer_to_dict(customer, include_pin=True)

    def get_all_customers(self, db: Session, skip: int = 0, limit: int = 100) -> List[dict]:
        """
        Get semua customer dengan pagination
        
        Args:
            db: Database session
            skip: Offset
            limit: Limit
        
        Returns:
            List of customer dicts
        """
        customers = self.repository.get_all(db, skip, limit)
        return [self._customer_to_dict(c) for c in customers]

    def update_customer(self, db: Session, customer_id: int, update_data: dict) -> dict:
        """
        Update customer data
        
        Args:
            db: Database session
            customer_id: ID customer
            update_data: Data yang akan diupdate
        
        Returns:
            Dict representasi customer yang telah diupdate
        
        Raises:
            HTTPException: Jika customer tidak ditemukan
        """
        customer = self.repository.update(db, customer_id, update_data)
        if not customer:
            raise HTTPException(status_code=404, detail="Customer tidak ditemukan")
        
        return self._customer_to_dict(customer)

    def handle_failed_login(self, db: Session, customer_id: int) -> dict:
        """
        Handle failed login attempt - increment counter
        
        Args:
            db: Database session
            customer_id: ID customer
        
        Returns:
            Dict dengan info failed attempts dan lock status
        """
        customer = self.repository.increment_failed_login(db, customer_id)
        if not customer:
            raise HTTPException(status_code=404, detail="Customer tidak ditemukan")
        
        return {
            "customer_id": customer.id,
            "failed_login_attempts": customer.failed_login_attempts,
            "is_locked": customer.is_locked
        }

    def handle_successful_login(self, db: Session, customer_id: int) -> dict:
        """
        Handle successful login - reset failed attempts dan update last_login
        
        Args:
            db: Database session
            customer_id: ID customer
        
        Returns:
            Dict representasi customer
        """
        customer = self.repository.reset_failed_login(db, customer_id)
        if not customer:
            raise HTTPException(status_code=404, detail="Customer tidak ditemukan")
        
        return self._customer_to_dict(customer)

    def check_account_locked(self, db: Session, customer_id: int) -> bool:
        """
        Check apakah account locked
        
        Args:
            db: Database session
            customer_id: ID customer
        
        Returns:
            True jika locked, False jika tidak
        """
        customer = self.repository.get_by_id(db, customer_id)
        if not customer:
            return False
        
        return customer.is_locked

    def unlock_account(self, db: Session, customer_id: int) -> dict:
        """
        Unlock account dan reset failed attempts
        
        Args:
            db: Database session
            customer_id: ID customer
        
        Returns:
            Dict representasi customer
        """
        update_data = {
            "is_locked": False,
            "failed_login_attempts": 0
        }
        return self.update_customer(db, customer_id, update_data)

    def _customer_to_dict(self, customer, include_pin: bool = False) -> dict:
        """
        Convert Customer object to dict
        
        Args:
            customer: Customer object
            include_pin: Include PIN dalam response (untuk login validation)
        
        Returns:
            Dict representasi customer
        """
        data = {
            "id": customer.id,
            "customer_name": customer.customer_name,
            "customer_username": customer.customer_username,
            "customer_email": customer.customer_email,
            "customer_phone": customer.customer_phone,
            "cif_number": customer.cif_number,
            "failed_login_attempts": customer.failed_login_attempts,
            "is_locked": customer.is_locked,
            "last_login": customer.last_login.isoformat() if customer.last_login else None,
            "created_at": customer.created_at.isoformat() if customer.created_at else None,
            "updated_at": customer.updated_at.isoformat() if customer.updated_at else None
        }
        
        # Include PIN hanya jika diminta (untuk validasi login)
        if include_pin:
            data["customer_pin"] = customer.customer_pin
        
        return data
