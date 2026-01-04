"""
Script untuk melihat semua customer yang terdaftar di database
"""
import sqlite3
from datetime import datetime

def view_customers():
    # Connect to database
    conn = sqlite3.connect('ebanking.db')
    cursor = conn.cursor()
    
    # Query all customers
    cursor.execute("""
        SELECT id, customer_name, customer_username, customer_email, 
               customer_phone, cif_number, failed_login_attempts, 
               is_locked, created_at
        FROM m_customer
        ORDER BY id DESC
    """)
    
    customers = cursor.fetchall()
    
    print("\n" + "="*120)
    print("📋 DAFTAR CUSTOMER TERDAFTAR")
    print("="*120)
    print(f"Total: {len(customers)} customer\n")
    
    if customers:
        for customer in customers:
            id, name, username, email, phone, cif, failed_attempts, locked, created = customer
            
            status = "🔒 LOCKED" if locked else "✅ ACTIVE"
            
            print(f"ID: {id}")
            print(f"  👤 Nama         : {name}")
            print(f"  🔑 Username     : {username}")
            print(f"  📧 Email        : {email}")
            print(f"  📱 Phone        : {phone}")
            print(f"  💳 CIF Number   : {cif}")
            print(f"  🔐 Login Fails  : {failed_attempts}")
            print(f"  📊 Status       : {status}")
            print(f"  📅 Registered   : {created}")
            print("-" * 120)
    else:
        print("Belum ada customer terdaftar.")
    
    print("="*120 + "\n")
    
    conn.close()

if __name__ == "__main__":
    view_customers()
