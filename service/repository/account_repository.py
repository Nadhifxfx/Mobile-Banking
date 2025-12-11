"""
Account Repository - Data Access Layer untuk m_portfolio_account
"""
from sqlalchemy.orm import Session
from typing import Optional, List
from db.models import PortfolioAccount
from decimal import Decimal
from datetime import datetime


class AccountRepository:
    """Repository untuk operasi database m_portfolio_account"""

    @staticmethod
    def create(db: Session, account_data: dict) -> PortfolioAccount:
        """
        Insert account baru ke database
        
        Args:
            db: Database session
            account_data: Dict dengan keys: m_customer_id, account_number, 
                         account_name, account_type, currency_code, 
                         clear_balance, available_balance
        
        Returns:
            PortfolioAccount object yang baru dibuat
        """
        new_account = PortfolioAccount(**account_data)
        db.add(new_account)
        db.commit()
        db.refresh(new_account)
        return new_account

    @staticmethod
    def get_by_id(db: Session, account_id: int) -> Optional[PortfolioAccount]:
        """
        Get account berdasarkan ID
        
        Args:
            db: Database session
            account_id: ID account
        
        Returns:
            PortfolioAccount object atau None
        """
        return db.query(PortfolioAccount).filter(PortfolioAccount.id == account_id).first()

    @staticmethod
    def get_by_account_number(db: Session, account_number: str) -> Optional[PortfolioAccount]:
        """
        Get account berdasarkan account number
        
        Args:
            db: Database session
            account_number: Nomor rekening
        
        Returns:
            PortfolioAccount object atau None
        """
        return db.query(PortfolioAccount).filter(
            PortfolioAccount.account_number == account_number
        ).first()

    @staticmethod
    def get_by_customer_id(db: Session, customer_id: int) -> List[PortfolioAccount]:
        """
        Get semua account milik customer tertentu
        
        Args:
            db: Database session
            customer_id: ID customer
        
        Returns:
            List of PortfolioAccount objects
        """
        return db.query(PortfolioAccount).filter(
            PortfolioAccount.m_customer_id == customer_id
        ).all()

    @staticmethod
    def get_active_accounts_by_customer(db: Session, customer_id: int) -> List[PortfolioAccount]:
        """
        Get semua account aktif milik customer tertentu
        
        Args:
            db: Database session
            customer_id: ID customer
        
        Returns:
            List of active PortfolioAccount objects
        """
        return db.query(PortfolioAccount).filter(
            PortfolioAccount.m_customer_id == customer_id,
            PortfolioAccount.is_active == True
        ).all()

    @staticmethod
    def update_balance(db: Session, account_number: str, 
                      clear_balance: Decimal, available_balance: Decimal) -> Optional[PortfolioAccount]:
        """
        Update balance account (untuk debit/credit)
        
        Args:
            db: Database session
            account_number: Nomor rekening
            clear_balance: Clear balance baru
            available_balance: Available balance baru
        
        Returns:
            PortfolioAccount object yang telah diupdate atau None
        """
        account = db.query(PortfolioAccount).filter(
            PortfolioAccount.account_number == account_number
        ).first()
        
        if account:
            account.clear_balance = clear_balance
            account.available_balance = available_balance
            account.updated_at = datetime.now()
            db.commit()
            db.refresh(account)
        
        return account

    @staticmethod
    def update(db: Session, account_id: int, update_data: dict) -> Optional[PortfolioAccount]:
        """
        Update account data
        
        Args:
            db: Database session
            account_id: ID account
            update_data: Dict berisi field yang akan diupdate
        
        Returns:
            PortfolioAccount object yang telah diupdate atau None
        """
        account = db.query(PortfolioAccount).filter(PortfolioAccount.id == account_id).first()
        
        if account:
            for key, value in update_data.items():
                if hasattr(account, key):
                    setattr(account, key, value)
            account.updated_at = datetime.now()
            db.commit()
            db.refresh(account)
        
        return account

    @staticmethod
    def deactivate_account(db: Session, account_number: str) -> Optional[PortfolioAccount]:
        """
        Deactivate account (soft delete)
        
        Args:
            db: Database session
            account_number: Nomor rekening
        
        Returns:
            PortfolioAccount object yang telah diupdate atau None
        """
        account = db.query(PortfolioAccount).filter(
            PortfolioAccount.account_number == account_number
        ).first()
        
        if account:
            account.is_active = False
            account.updated_at = datetime.now()
            db.commit()
            db.refresh(account)
        
        return account

    @staticmethod
    def delete(db: Session, account_id: int) -> bool:
        """
        Delete account (hard delete)
        
        Args:
            db: Database session
            account_id: ID account
        
        Returns:
            True jika berhasil, False jika tidak ditemukan
        """
        account = db.query(PortfolioAccount).filter(PortfolioAccount.id == account_id).first()
        
        if account:
            db.delete(account)
            db.commit()
            return True
        
        return False
