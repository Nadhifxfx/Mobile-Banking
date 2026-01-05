"""
Script untuk melihat semua rekening dengan detail customer
"""
import sqlite3

def view_all_accounts():
    conn = sqlite3.connect('ebanking.db')
    cursor = conn.cursor()
    
    print("\n" + "="*100)
    print("💳 DAFTAR REKENING - SAE BANK")
    print("="*100)
    
    cursor.execute("""
        SELECT 
            a.id,
            a.account_number,
            a.account_name,
            c.customer_name,
            c.customer_username,
            c.cif_number,
            a.account_type,
            a.available_balance,
            a.is_active
        FROM m_portfolio_account a
        JOIN m_customer c ON a.m_customer_id = c.id
        ORDER BY a.id ASC
    """)
    
    accounts = cursor.fetchall()
    
    print(f"Total: {len(accounts)} rekening\n")
    
    if accounts:
        for acc in accounts:
            acc_id, acc_num, acc_name, cust_name, username, cif, acc_type, balance, active = acc
            
            status = "✅ AKTIF" if active else "❌ NONAKTIF"
            acc_type_name = {
                'SAV': '💰 Tabungan',
                'CHK': '💵 Giro',
                'DEP': '💎 Deposito'
            }.get(acc_type, acc_type)
            
            print(f"📋 ID Rekening: {acc_id}")
            print(f"   💳 Nomor Rekening  : {acc_num}")
            print(f"   📝 Nama Rekening   : {acc_name}")
            print(f"   👤 Pemilik         : {cust_name} (@{username})")
            print(f"   🔖 CIF             : {cif}")
            print(f"   🏦 Jenis           : {acc_type_name}")
            print(f"   💵 Saldo Tersedia  : Rp {balance:,.2f}")
            print(f"   📊 Status          : {status}")
            print("-" * 100)
    else:
        print("Belum ada rekening terdaftar.")
    
    # Summary by customer
    print("\n" + "="*100)
    print("📊 RINGKASAN PER CUSTOMER")
    print("="*100 + "\n")
    
    cursor.execute("""
        SELECT 
            c.id,
            c.customer_name,
            c.cif_number,
            COUNT(a.id) as total_accounts,
            SUM(a.available_balance) as total_balance
        FROM m_customer c
        LEFT JOIN m_portfolio_account a ON c.id = a.m_customer_id
        GROUP BY c.id, c.customer_name, c.cif_number
        ORDER BY c.id ASC
    """)
    
    summary = cursor.fetchall()
    
    for s in summary:
        cust_id, name, cif, acc_count, total_bal = s
        print(f"👤 {name} (ID: {cust_id})")
        print(f"   CIF: {cif}")
        print(f"   Total Rekening: {acc_count}")
        print(f"   Total Saldo: Rp {total_bal:,.2f}")
        print("-" * 100)
    
    print("="*100 + "\n")
    
    conn.close()

if __name__ == "__main__":
    view_all_accounts()
