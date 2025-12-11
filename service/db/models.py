"""
SQLAlchemy ORM Models untuk semua tabel database
"""
from sqlalchemy import Column, Integer, String, Numeric, DateTime, Boolean, ForeignKey, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .database import Base


class Customer(Base):
    """Model untuk tabel m_customer"""
    __tablename__ = "m_customer"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    customer_name = Column(String(100), nullable=False)
    customer_username = Column(String(50), unique=True, nullable=False, index=True)
    customer_pin = Column(String(255), nullable=False)
    customer_email = Column(String(100), unique=True, nullable=False)
    customer_phone = Column(String(20), nullable=False)
    cif_number = Column(String(20), unique=True, nullable=False)
    failed_login_attempts = Column(Integer, default=0)
    is_locked = Column(Boolean, default=False)
    last_login = Column(DateTime, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

    # Relationship
    accounts = relationship("PortfolioAccount", back_populates="customer")
    transactions = relationship("Transaction", back_populates="customer")


class PortfolioAccount(Base):
    """Model untuk tabel m_portfolio_account"""
    __tablename__ = "m_portfolio_account"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    m_customer_id = Column(Integer, ForeignKey("m_customer.id"), nullable=False, index=True)
    account_number = Column(String(20), unique=True, nullable=False, index=True)
    account_name = Column(String(100), nullable=False)
    account_type = Column(String(10), nullable=False)  # SAV, CHK, etc.
    currency_code = Column(String(3), default="IDR")
    clear_balance = Column(Numeric(18, 2), default=0.00)
    available_balance = Column(Numeric(18, 2), default=0.00)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

    # Relationship
    customer = relationship("Customer", back_populates="accounts")


class Transaction(Base):
    """Model untuk tabel t_transaction"""
    __tablename__ = "t_transaction"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    m_customer_id = Column(Integer, ForeignKey("m_customer.id"), nullable=False, index=True)
    transaction_type = Column(String(10), nullable=False)  # TR, WD, DP, etc.
    transaction_amount = Column(Numeric(18, 2), nullable=False)
    from_account_number = Column(String(20), nullable=True, index=True)
    to_account_number = Column(String(20), nullable=True, index=True)
    status = Column(String(20), default="PENDING")  # PENDING, SUCCESS, FAILED
    description = Column(Text, nullable=True)
    transaction_date = Column(DateTime, server_default=func.now())
    created_at = Column(DateTime, server_default=func.now())

    # Relationship
    customer = relationship("Customer", back_populates="transactions")
