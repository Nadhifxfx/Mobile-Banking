"""
Customer Repository - Data Access Layer untuk m_customer
"""
from sqlalchemy.orm import Session
from typing import Optional, List
from db.models import Customer
from datetime import datetime


class CustomerRepository:
    """Repository untuk operasi database m_customer"""

    @staticmethod
    def create(db: Session, customer_data: dict) -> Customer:
        """
        Insert customer baru ke database
        
        Args:
            db: Database session
            customer_data: Dict dengan keys: customer_name, customer_username, 
                          customer_pin, customer_email, customer_phone, cif_number
        
        Returns:
            Customer object yang baru dibuat
        """
        new_customer = Customer(**customer_data)
        db.add(new_customer)
        db.commit()
        db.refresh(new_customer)
        return new_customer

    @staticmethod
    def get_by_id(db: Session, customer_id: int) -> Optional[Customer]:
        """
        Get customer berdasarkan ID
        
        Args:
            db: Database session
            customer_id: ID customer
        
        Returns:
            Customer object atau None jika tidak ditemukan
        """
        return db.query(Customer).filter(Customer.id == customer_id).first()

    @staticmethod
    def get_by_username(db: Session, username: str) -> Optional[Customer]:
        """
        Get customer berdasarkan username (untuk login)
        
        Args:
            db: Database session
            username: Username customer
        
        Returns:
            Customer object atau None jika tidak ditemukan
        """
        return db.query(Customer).filter(Customer.customer_username == username).first()

    @staticmethod
    def get_by_email(db: Session, email: str) -> Optional[Customer]:
        """
        Get customer berdasarkan email
        
        Args:
            db: Database session
            email: Email customer
        
        Returns:
            Customer object atau None jika tidak ditemukan
        """
        return db.query(Customer).filter(Customer.customer_email == email).first()

    @staticmethod
    def get_by_cif(db: Session, cif_number: str) -> Optional[Customer]:
        """
        Get customer berdasarkan CIF number
        
        Args:
            db: Database session
            cif_number: CIF number
        
        Returns:
            Customer object atau None jika tidak ditemukan
        """
        return db.query(Customer).filter(Customer.cif_number == cif_number).first()

    @staticmethod
    def get_all(db: Session, skip: int = 0, limit: int = 100) -> List[Customer]:
        """
        Get semua customer dengan pagination
        
        Args:
            db: Database session
            skip: Offset untuk pagination
            limit: Jumlah maksimal data
        
        Returns:
            List of Customer objects
        """
        return db.query(Customer).offset(skip).limit(limit).all()

    @staticmethod
    def update(db: Session, customer_id: int, update_data: dict) -> Optional[Customer]:
        """
        Update customer data
        
        Args:
            db: Database session
            customer_id: ID customer yang akan diupdate
            update_data: Dict berisi field yang akan diupdate
        
        Returns:
            Customer object yang telah diupdate atau None jika tidak ditemukan
        """
        customer = db.query(Customer).filter(Customer.id == customer_id).first()
        if customer:
            for key, value in update_data.items():
                if hasattr(customer, key):
                    setattr(customer, key, value)
            customer.updated_at = datetime.now()
            db.commit()
            db.refresh(customer)
        return customer

    @staticmethod
    def increment_failed_login(db: Session, customer_id: int) -> Optional[Customer]:
        """
        Increment failed login attempts
        
        Args:
            db: Database session
            customer_id: ID customer
        
        Returns:
            Customer object yang telah diupdate
        """
        customer = db.query(Customer).filter(Customer.id == customer_id).first()
        if customer:
            customer.failed_login_attempts += 1
            # Lock account jika sudah 3 kali gagal
            if customer.failed_login_attempts >= 3:
                customer.is_locked = True
            db.commit()
            db.refresh(customer)
        return customer

    @staticmethod
    def reset_failed_login(db: Session, customer_id: int) -> Optional[Customer]:
        """
        Reset failed login attempts (setelah login berhasil)
        
        Args:
            db: Database session
            customer_id: ID customer
        
        Returns:
            Customer object yang telah diupdate
        """
        customer = db.query(Customer).filter(Customer.id == customer_id).first()
        if customer:
            customer.failed_login_attempts = 0
            customer.last_login = datetime.now()
            db.commit()
            db.refresh(customer)
        return customer

    @staticmethod
    def delete(db: Session, customer_id: int) -> bool:
        """
        Delete customer (soft delete bisa diimplementasikan dengan flag)
        
        Args:
            db: Database session
            customer_id: ID customer yang akan dihapus
        
        Returns:
            True jika berhasil, False jika customer tidak ditemukan
        """
        customer = db.query(Customer).filter(Customer.id == customer_id).first()
        if customer:
            db.delete(customer)
            db.commit()
            return True
        return False
