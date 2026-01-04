"""
Script untuk menghapus customer berdasarkan ID
"""
import sqlite3

def delete_customers_by_ids(ids):
    # Connect to database
    conn = sqlite3.connect('ebanking.db')
    cursor = conn.cursor()
    
    print("\n" + "="*80)
    print("🗑️  HAPUS CUSTOMER DARI DATABASE")
    print("="*80)
    
    # Get customer info before deleting
    placeholders = ','.join('?' * len(ids))
    cursor.execute(f"""
        SELECT id, customer_name, customer_username, cif_number
        FROM m_customer
        WHERE id IN ({placeholders})
    """, ids)
    
    customers = cursor.fetchall()
    
    if not customers:
        print("❌ Tidak ada customer dengan ID tersebut.\n")
        conn.close()
        return
    
    print(f"\n📋 Customer yang akan dihapus ({len(customers)}):\n")
    for customer in customers:
        print(f"  ID: {customer[0]} | {customer[1]} ({customer[2]}) | CIF: {customer[3]}")
    
    # Delete customers
    cursor.execute(f"""
        DELETE FROM m_customer
        WHERE id IN ({placeholders})
    """, ids)
    
    deleted_count = cursor.rowcount
    conn.commit()
    
    print(f"\n✅ Berhasil menghapus {deleted_count} customer dari database.")
    print("="*80 + "\n")
    
    conn.close()

if __name__ == "__main__":
    # Delete customers with ID 1-4
    ids_to_delete = [1, 2, 3, 4]
    delete_customers_by_ids(ids_to_delete)
