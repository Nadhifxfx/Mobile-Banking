"""
Script untuk membuat rekening (account) untuk setiap customer
"""
import sqlite3
from datetime import datetime

def create_accounts_for_customers():
    conn = sqlite3.connect('ebanking.db')
    cursor = conn.cursor()
    
    print("\n" + "="*80)
    print("💳 MEMBUAT REKENING UNTUK SETIAP CUSTOMER")
    print("="*80)
    
    # Get all customers
    cursor.execute("""
        SELECT id, customer_name, customer_username, cif_number
        FROM m_customer
        ORDER BY id ASC
    """)
    
    customers = cursor.fetchall()
    
    if not customers:
        print("❌ Tidak ada customer di database.\n")
        conn.close()
        return
    
    print(f"\n📋 Total customer: {len(customers)}\n")
    
    created_count = 0
    
    for customer in customers:
        customer_id, name, username, cif = customer
        
        # Check if customer already has account
        cursor.execute("""
            SELECT COUNT(*) FROM m_portfolio_account 
            WHERE m_customer_id = ?
        """, (customer_id,))
        
        existing_count = cursor.fetchone()[0]
        
        if existing_count > 0:
            print(f"⚠️  ID {customer_id} - {name} sudah punya {existing_count} rekening, skip...")
            continue
        
        # Generate account number from CIF (last 10 digits)
        account_number = cif.replace('CIF', '')[:10].zfill(10)
        
        # Create savings account
        account_name = f"{name} - Tabungan"
        
        cursor.execute("""
            INSERT INTO m_portfolio_account (
                m_customer_id, account_number, account_name, 
                account_type, currency_code, clear_balance, 
                available_balance, is_active, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            customer_id,
            account_number,
            account_name,
            'SAV',  # Savings
            'IDR',
            1000000.00,  # Initial balance 1 juta
            1000000.00,
            True,
            datetime.now(),
            datetime.now()
        ))
        
        print(f"✅ ID {customer_id} - {name}")
        print(f"   📱 Rekening: {account_number}")
        print(f"   💰 Saldo: Rp 1.000.000,00")
        print(f"   📝 Nama: {account_name}")
        
        created_count += 1
    
    conn.commit()
    
    print(f"\n{'='*80}")
    print(f"✅ Berhasil membuat {created_count} rekening baru!")
    print("="*80 + "\n")
    
    # Show summary
    cursor.execute("""
        SELECT 
            c.id, c.customer_name, 
            a.account_number, a.account_name, 
            a.available_balance
        FROM m_customer c
        JOIN m_portfolio_account a ON c.id = a.m_customer_id
        ORDER BY c.id ASC
    """)
    
    accounts = cursor.fetchall()
    
    print("📊 DAFTAR REKENING:")
    print("-" * 80)
    for acc in accounts:
        cust_id, cust_name, acc_num, acc_name, balance = acc
        print(f"ID {cust_id}: {cust_name}")
        print(f"  💳 Rekening: {acc_num}")
        print(f"  💰 Saldo: Rp {balance:,.2f}")
        print("-" * 80)
    
    conn.close()

if __name__ == "__main__":
    create_accounts_for_customers()
