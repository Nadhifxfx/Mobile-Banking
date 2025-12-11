"""
Account Service - Business Logic Layer untuk Account operations
"""
from sqlalchemy.orm import Session
from repository.account_repository import AccountRepository
from typing import Optional, List
from decimal import Decimal
from fastapi import HTTPException


class AccountService:
    """Service layer untuk business logic account"""

    def __init__(self):
        self.repository = AccountRepository()

    def create_account(self, db: Session, account_data: dict) -> dict:
        """
        Create account baru dengan validasi
        
        Args:
            db: Database session
            account_data: Data account baru
        
        Returns:
            Dict representasi account yang dibuat
        
        Raises:
            HTTPException: Jika account number sudah terdaftar
        """
        # Validasi account number belum dipakai
        existing_account = self.repository.get_by_account_number(db, account_data["account_number"])
        if existing_account:
            raise HTTPException(status_code=400, detail="Account number sudah terdaftar")
        
        # Create account
        account = self.repository.create(db, account_data)
        
        return self._account_to_dict(account)

    def get_account_by_id(self, db: Session, account_id: int) -> dict:
        """
        Get account berdasarkan ID
        
        Args:
            db: Database session
            account_id: ID account
        
        Returns:
            Dict representasi account
        
        Raises:
            HTTPException: Jika account tidak ditemukan
        """
        account = self.repository.get_by_id(db, account_id)
        if not account:
            raise HTTPException(status_code=404, detail="Account tidak ditemukan")
        
        return self._account_to_dict(account)

    def get_account_by_number(self, db: Session, account_number: str) -> dict:
        """
        Get account berdasarkan account number
        
        Args:
            db: Database session
            account_number: Nomor rekening
        
        Returns:
            Dict representasi account
        
        Raises:
            HTTPException: Jika account tidak ditemukan
        """
        account = self.repository.get_by_account_number(db, account_number)
        if not account:
            raise HTTPException(status_code=404, detail="Account tidak ditemukan")
        
        return self._account_to_dict(account)

    def get_accounts_by_customer(self, db: Session, customer_id: int, active_only: bool = True) -> List[dict]:
        """
        Get semua account milik customer
        Digunakan untuk cek saldo di middleware
        
        Args:
            db: Database session
            customer_id: ID customer
            active_only: Hanya account aktif
        
        Returns:
            List of account dicts
        """
        if active_only:
            accounts = self.repository.get_active_accounts_by_customer(db, customer_id)
        else:
            accounts = self.repository.get_by_customer_id(db, customer_id)
        
        return [self._account_to_dict(a) for a in accounts]

    def update_balance(self, db: Session, account_number: str, 
                      clear_balance: float, available_balance: float) -> dict:
        """
        Update balance account
        Dipanggil setelah transaksi berhasil
        
        Args:
            db: Database session
            account_number: Nomor rekening
            clear_balance: Clear balance baru
            available_balance: Available balance baru
        
        Returns:
            Dict representasi account yang telah diupdate
        
        Raises:
            HTTPException: Jika account tidak ditemukan
        """
        # Convert to Decimal untuk presisi
        clear_decimal = Decimal(str(clear_balance))
        available_decimal = Decimal(str(available_balance))
        
        account = self.repository.update_balance(db, account_number, clear_decimal, available_decimal)
        if not account:
            raise HTTPException(status_code=404, detail="Account tidak ditemukan")
        
        return self._account_to_dict(account)

    def debit_account(self, db: Session, account_number: str, amount: float) -> dict:
        """
        Debit (kurangi) balance dari account
        
        Args:
            db: Database session
            account_number: Nomor rekening
            amount: Jumlah yang akan didebit
        
        Returns:
            Dict representasi account yang telah diupdate
        
        Raises:
            HTTPException: Jika saldo tidak cukup atau account tidak ditemukan
        """
        account = self.repository.get_by_account_number(db, account_number)
        if not account:
            raise HTTPException(status_code=404, detail="Account tidak ditemukan")
        
        # Validasi saldo cukup
        if account.available_balance < Decimal(str(amount)):
            raise HTTPException(status_code=400, detail="Saldo tidak mencukupi")
        
        # Update balance
        new_clear = account.clear_balance - Decimal(str(amount))
        new_available = account.available_balance - Decimal(str(amount))
        
        return self.update_balance(db, account_number, float(new_clear), float(new_available))

    def credit_account(self, db: Session, account_number: str, amount: float) -> dict:
        """
        Credit (tambah) balance ke account
        
        Args:
            db: Database session
            account_number: Nomor rekening
            amount: Jumlah yang akan dikreditkan
        
        Returns:
            Dict representasi account yang telah diupdate
        
        Raises:
            HTTPException: Jika account tidak ditemukan
        """
        account = self.repository.get_by_account_number(db, account_number)
        if not account:
            raise HTTPException(status_code=404, detail="Account tidak ditemukan")
        
        # Update balance
        new_clear = account.clear_balance + Decimal(str(amount))
        new_available = account.available_balance + Decimal(str(amount))
        
        return self.update_balance(db, account_number, float(new_clear), float(new_available))

    def check_balance_sufficient(self, db: Session, account_number: str, amount: float) -> bool:
        """
        Check apakah balance mencukupi untuk transaksi
        
        Args:
            db: Database session
            account_number: Nomor rekening
            amount: Jumlah yang akan di-check
        
        Returns:
            True jika cukup, False jika tidak
        """
        account = self.repository.get_by_account_number(db, account_number)
        if not account:
            return False
        
        return account.available_balance >= Decimal(str(amount))

    def update_account(self, db: Session, account_id: int, update_data: dict) -> dict:
        """
        Update account data
        
        Args:
            db: Database session
            account_id: ID account
            update_data: Data yang akan diupdate
        
        Returns:
            Dict representasi account yang telah diupdate
        
        Raises:
            HTTPException: Jika account tidak ditemukan
        """
        account = self.repository.update(db, account_id, update_data)
        if not account:
            raise HTTPException(status_code=404, detail="Account tidak ditemukan")
        
        return self._account_to_dict(account)

    def deactivate_account(self, db: Session, account_number: str) -> dict:
        """
        Deactivate account (soft delete)
        
        Args:
            db: Database session
            account_number: Nomor rekening
        
        Returns:
            Dict representasi account yang telah di-deactivate
        
        Raises:
            HTTPException: Jika account tidak ditemukan
        """
        account = self.repository.deactivate_account(db, account_number)
        if not account:
            raise HTTPException(status_code=404, detail="Account tidak ditemukan")
        
        return self._account_to_dict(account)

    def _account_to_dict(self, account) -> dict:
        """
        Convert PortfolioAccount object to dict
        
        Args:
            account: PortfolioAccount object
        
        Returns:
            Dict representasi account
        """
        return {
            "id": account.id,
            "m_customer_id": account.m_customer_id,
            "account_number": account.account_number,
            "account_name": account.account_name,
            "account_type": account.account_type,
            "currency_code": account.currency_code,
            "clear_balance": float(account.clear_balance),
            "available_balance": float(account.available_balance),
            "is_active": account.is_active,
            "created_at": account.created_at.isoformat() if account.created_at else None,
            "updated_at": account.updated_at.isoformat() if account.updated_at else None
        }
