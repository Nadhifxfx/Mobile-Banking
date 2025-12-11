"""
Transaction Service - Business Logic Layer untuk Transaction operations
"""
from sqlalchemy.orm import Session
from repository.transaction_repository import TransactionRepository
from typing import Optional, List
from datetime import datetime
from fastapi import HTTPException


class TransactionService:
    """Service layer untuk business logic transaction"""

    def __init__(self):
        self.repository = TransactionRepository()

    def create_transaction(self, db: Session, transaction_data: dict) -> dict:
        """
        Create transaction baru
        Dipanggil setelah middleware approve transaksi
        
        Args:
            db: Database session
            transaction_data: Data transaction
        
        Returns:
            Dict representasi transaction yang dibuat
        """
        transaction = self.repository.create(db, transaction_data)
        return self._transaction_to_dict(transaction)

    def get_transaction_by_id(self, db: Session, transaction_id: int) -> dict:
        """
        Get transaction berdasarkan ID
        
        Args:
            db: Database session
            transaction_id: ID transaction
        
        Returns:
            Dict representasi transaction
        
        Raises:
            HTTPException: Jika transaction tidak ditemukan
        """
        transaction = self.repository.get_by_id(db, transaction_id)
        if not transaction:
            raise HTTPException(status_code=404, detail="Transaction tidak ditemukan")
        
        return self._transaction_to_dict(transaction)

    def get_transactions_by_customer(self, db: Session, customer_id: int, 
                                     skip: int = 0, limit: int = 100) -> List[dict]:
        """
        Get semua transaction milik customer
        Digunakan untuk riwayat transaksi
        
        Args:
            db: Database session
            customer_id: ID customer
            skip: Offset pagination
            limit: Limit pagination
        
        Returns:
            List of transaction dicts
        """
        transactions = self.repository.get_by_customer_id(db, customer_id, skip, limit)
        return [self._transaction_to_dict(t) for t in transactions]

    def get_transactions_by_account(self, db: Session, account_number: str, 
                                    skip: int = 0, limit: int = 100) -> List[dict]:
        """
        Get semua transaction dari/ke account tertentu
        Digunakan untuk mutasi rekening
        
        Args:
            db: Database session
            account_number: Nomor rekening
            skip: Offset pagination
            limit: Limit pagination
        
        Returns:
            List of transaction dicts
        """
        transactions = self.repository.get_by_account_number(db, account_number, skip, limit)
        return [self._transaction_to_dict(t) for t in transactions]

    def get_transactions_by_date_range(self, db: Session, customer_id: int,
                                       start_date: str, end_date: str) -> List[dict]:
        """
        Get transactions dalam rentang tanggal
        
        Args:
            db: Database session
            customer_id: ID customer
            start_date: Tanggal mulai (ISO format)
            end_date: Tanggal akhir (ISO format)
        
        Returns:
            List of transaction dicts
        """
        # Parse string ke datetime
        start_dt = datetime.fromisoformat(start_date)
        end_dt = datetime.fromisoformat(end_date)
        
        transactions = self.repository.get_by_date_range(db, customer_id, start_dt, end_dt)
        return [self._transaction_to_dict(t) for t in transactions]

    def get_transactions_by_type(self, db: Session, customer_id: int, 
                                 transaction_type: str) -> List[dict]:
        """
        Get transactions berdasarkan tipe
        
        Args:
            db: Database session
            customer_id: ID customer
            transaction_type: Tipe transaksi (TR, WD, DP, dll)
        
        Returns:
            List of transaction dicts
        """
        transactions = self.repository.get_by_type(db, customer_id, transaction_type)
        return [self._transaction_to_dict(t) for t in transactions]

    def get_transactions_by_status(self, db: Session, customer_id: int, 
                                   status: str) -> List[dict]:
        """
        Get transactions berdasarkan status
        
        Args:
            db: Database session
            customer_id: ID customer
            status: Status transaksi (PENDING, SUCCESS, FAILED)
        
        Returns:
            List of transaction dicts
        """
        transactions = self.repository.get_by_status(db, customer_id, status)
        return [self._transaction_to_dict(t) for t in transactions]

    def get_recent_transactions(self, db: Session, customer_id: int, days: int = 30) -> List[dict]:
        """
        Get transactions N hari terakhir
        
        Args:
            db: Database session
            customer_id: ID customer
            days: Jumlah hari ke belakang
        
        Returns:
            List of transaction dicts
        """
        transactions = self.repository.get_recent_transactions(db, customer_id, days)
        return [self._transaction_to_dict(t) for t in transactions]

    def update_transaction_status(self, db: Session, transaction_id: int, status: str) -> dict:
        """
        Update status transaction
        Digunakan jika transaksi pending perlu diupdate
        
        Args:
            db: Database session
            transaction_id: ID transaction
            status: Status baru (PENDING, SUCCESS, FAILED)
        
        Returns:
            Dict representasi transaction yang telah diupdate
        
        Raises:
            HTTPException: Jika transaction tidak ditemukan
        """
        transaction = self.repository.update_status(db, transaction_id, status)
        if not transaction:
            raise HTTPException(status_code=404, detail="Transaction tidak ditemukan")
        
        return self._transaction_to_dict(transaction)

    def update_transaction(self, db: Session, transaction_id: int, update_data: dict) -> dict:
        """
        Update transaction data
        
        Args:
            db: Database session
            transaction_id: ID transaction
            update_data: Data yang akan diupdate
        
        Returns:
            Dict representasi transaction yang telah diupdate
        
        Raises:
            HTTPException: Jika transaction tidak ditemukan
        """
        transaction = self.repository.update(db, transaction_id, update_data)
        if not transaction:
            raise HTTPException(status_code=404, detail="Transaction tidak ditemukan")
        
        return self._transaction_to_dict(transaction)

    def _transaction_to_dict(self, transaction) -> dict:
        """
        Convert Transaction object to dict
        
        Args:
            transaction: Transaction object
        
        Returns:
            Dict representasi transaction
        """
        return {
            "id": transaction.id,
            "m_customer_id": transaction.m_customer_id,
            "transaction_type": transaction.transaction_type,
            "transaction_amount": float(transaction.transaction_amount),
            "from_account_number": transaction.from_account_number,
            "to_account_number": transaction.to_account_number,
            "status": transaction.status,
            "description": transaction.description,
            "transaction_date": transaction.transaction_date.isoformat() if transaction.transaction_date else None,
            "created_at": transaction.created_at.isoformat() if transaction.created_at else None
        }
