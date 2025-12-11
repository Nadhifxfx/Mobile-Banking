"""
Transaction Repository - Data Access Layer untuk t_transaction
"""
from sqlalchemy.orm import Session
from typing import Optional, List
from db.models import Transaction
from datetime import datetime, timedelta


class TransactionRepository:
    """Repository untuk operasi database t_transaction"""

    @staticmethod
    def create(db: Session, transaction_data: dict) -> Transaction:
        """
        Insert transaction baru ke database
        
        Args:
            db: Database session
            transaction_data: Dict dengan keys: m_customer_id, transaction_type,
                             transaction_amount, from_account_number, to_account_number,
                             status, description
        
        Returns:
            Transaction object yang baru dibuat
        """
        new_transaction = Transaction(**transaction_data)
        db.add(new_transaction)
        db.commit()
        db.refresh(new_transaction)
        return new_transaction

    @staticmethod
    def get_by_id(db: Session, transaction_id: int) -> Optional[Transaction]:
        """
        Get transaction berdasarkan ID
        
        Args:
            db: Database session
            transaction_id: ID transaction
        
        Returns:
            Transaction object atau None
        """
        return db.query(Transaction).filter(Transaction.id == transaction_id).first()

    @staticmethod
    def get_by_customer_id(db: Session, customer_id: int, 
                          skip: int = 0, limit: int = 100) -> List[Transaction]:
        """
        Get semua transaction milik customer tertentu
        
        Args:
            db: Database session
            customer_id: ID customer
            skip: Offset untuk pagination
            limit: Jumlah maksimal data
        
        Returns:
            List of Transaction objects
        """
        return db.query(Transaction).filter(
            Transaction.m_customer_id == customer_id
        ).order_by(Transaction.transaction_date.desc()).offset(skip).limit(limit).all()

    @staticmethod
    def get_by_account_number(db: Session, account_number: str, 
                             skip: int = 0, limit: int = 100) -> List[Transaction]:
        """
        Get semua transaction dari/ke account tertentu
        
        Args:
            db: Database session
            account_number: Nomor rekening
            skip: Offset untuk pagination
            limit: Jumlah maksimal data
        
        Returns:
            List of Transaction objects
        """
        return db.query(Transaction).filter(
            (Transaction.from_account_number == account_number) | 
            (Transaction.to_account_number == account_number)
        ).order_by(Transaction.transaction_date.desc()).offset(skip).limit(limit).all()

    @staticmethod
    def get_by_date_range(db: Session, customer_id: int, 
                         start_date: datetime, end_date: datetime) -> List[Transaction]:
        """
        Get transactions dalam rentang tanggal tertentu
        
        Args:
            db: Database session
            customer_id: ID customer
            start_date: Tanggal mulai
            end_date: Tanggal akhir
        
        Returns:
            List of Transaction objects
        """
        return db.query(Transaction).filter(
            Transaction.m_customer_id == customer_id,
            Transaction.transaction_date >= start_date,
            Transaction.transaction_date <= end_date
        ).order_by(Transaction.transaction_date.desc()).all()

    @staticmethod
    def get_by_type(db: Session, customer_id: int, transaction_type: str) -> List[Transaction]:
        """
        Get transactions berdasarkan tipe transaksi
        
        Args:
            db: Database session
            customer_id: ID customer
            transaction_type: Tipe transaksi (TR, WD, DP, dll)
        
        Returns:
            List of Transaction objects
        """
        return db.query(Transaction).filter(
            Transaction.m_customer_id == customer_id,
            Transaction.transaction_type == transaction_type
        ).order_by(Transaction.transaction_date.desc()).all()

    @staticmethod
    def get_by_status(db: Session, customer_id: int, status: str) -> List[Transaction]:
        """
        Get transactions berdasarkan status
        
        Args:
            db: Database session
            customer_id: ID customer
            status: Status transaksi (PENDING, SUCCESS, FAILED)
        
        Returns:
            List of Transaction objects
        """
        return db.query(Transaction).filter(
            Transaction.m_customer_id == customer_id,
            Transaction.status == status
        ).order_by(Transaction.transaction_date.desc()).all()

    @staticmethod
    def get_recent_transactions(db: Session, customer_id: int, days: int = 30) -> List[Transaction]:
        """
        Get transactions dalam N hari terakhir
        
        Args:
            db: Database session
            customer_id: ID customer
            days: Jumlah hari ke belakang
        
        Returns:
            List of Transaction objects
        """
        start_date = datetime.now() - timedelta(days=days)
        return db.query(Transaction).filter(
            Transaction.m_customer_id == customer_id,
            Transaction.transaction_date >= start_date
        ).order_by(Transaction.transaction_date.desc()).all()

    @staticmethod
    def update_status(db: Session, transaction_id: int, status: str) -> Optional[Transaction]:
        """
        Update status transaksi
        
        Args:
            db: Database session
            transaction_id: ID transaction
            status: Status baru (PENDING, SUCCESS, FAILED)
        
        Returns:
            Transaction object yang telah diupdate atau None
        """
        transaction = db.query(Transaction).filter(Transaction.id == transaction_id).first()
        
        if transaction:
            transaction.status = status
            db.commit()
            db.refresh(transaction)
        
        return transaction

    @staticmethod
    def update(db: Session, transaction_id: int, update_data: dict) -> Optional[Transaction]:
        """
        Update transaction data
        
        Args:
            db: Database session
            transaction_id: ID transaction
            update_data: Dict berisi field yang akan diupdate
        
        Returns:
            Transaction object yang telah diupdate atau None
        """
        transaction = db.query(Transaction).filter(Transaction.id == transaction_id).first()
        
        if transaction:
            for key, value in update_data.items():
                if hasattr(transaction, key):
                    setattr(transaction, key, value)
            db.commit()
            db.refresh(transaction)
        
        return transaction
