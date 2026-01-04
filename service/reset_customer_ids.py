"""
Script untuk reset ID customer menjadi berurutan dari 1
"""
import sqlite3

def reset_customer_ids():
    conn = sqlite3.connect('ebanking.db')
    cursor = conn.cursor()
    
    print("\n" + "="*80)
    print("🔄 RESET CUSTOMER IDs")
    print("="*80)
    
    # Get current customers ordered by ID
    cursor.execute("""
        SELECT id, customer_name, customer_username
        FROM m_customer
        ORDER BY id ASC
    """)
    
    customers = cursor.fetchall()
    
    if not customers:
        print("❌ Tidak ada customer di database.\n")
        conn.close()
        return
    
    print(f"\n📋 Customer saat ini:\n")
    for customer in customers:
        print(f"  ID {customer[0]} -> {customer[1]} ({customer[2]})")
    
    # Create mapping of old ID to new ID
    id_mapping = {}
    for idx, customer in enumerate(customers, start=1):
        old_id = customer[0]
        new_id = idx
        id_mapping[old_id] = new_id
    
    print(f"\n🔄 Mapping ID:")
    for old_id, new_id in id_mapping.items():
        print(f"  ID {old_id} -> ID {new_id}")
    
    # Disable foreign key constraints temporarily
    cursor.execute("PRAGMA foreign_keys = OFF")
    
    # Drop temp table if exists
    cursor.execute("DROP TABLE IF EXISTS m_customer_temp")
    
    # Create temporary table
    cursor.execute("""
        CREATE TABLE m_customer_temp AS 
        SELECT * FROM m_customer
    """)
    
    # Clear original table
    cursor.execute("DELETE FROM m_customer")
    
    # Insert with new IDs
    for old_id, new_id in id_mapping.items():
        cursor.execute("""
            INSERT INTO m_customer (
                id, customer_name, customer_username, customer_pin,
                customer_email, customer_phone, cif_number,
                failed_login_attempts, is_locked, last_login,
                created_at, updated_at
            )
            SELECT 
                ?, customer_name, customer_username, customer_pin,
                customer_email, customer_phone, cif_number,
                failed_login_attempts, is_locked, last_login,
                created_at, updated_at
            FROM m_customer_temp
            WHERE id = ?
        """, (new_id, old_id))
    
    # Drop temporary table
    cursor.execute("DROP TABLE m_customer_temp")
    
    # Update foreign keys in m_account if exists
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='m_account'")
    if cursor.fetchone():
        print("\n🔗 Updating m_account foreign keys...")
        for old_id, new_id in id_mapping.items():
            cursor.execute("UPDATE m_account SET customer_id = ? WHERE customer_id = ?", (new_id, old_id))
    
    # Reset autoincrement
    try:
        cursor.execute("SELECT name FROM sqlite_sequence WHERE name='m_customer'")
        if cursor.fetchone():
            cursor.execute("DELETE FROM sqlite_sequence WHERE name='m_customer'")
        cursor.execute(f"INSERT OR REPLACE INTO sqlite_sequence (name, seq) VALUES ('m_customer', {len(customers)})")
    except sqlite3.OperationalError:
        # sqlite_sequence doesn't exist yet, will be created on next insert
        pass
    
    # Re-enable foreign keys
    cursor.execute("PRAGMA foreign_keys = ON")
    
    conn.commit()
    
    print("\n✅ Berhasil reset ID customer!")
    print(f"   Total: {len(customers)} customer")
    print(f"   ID baru: 1 - {len(customers)}")
    print("="*80 + "\n")
    
    conn.close()

if __name__ == "__main__":
    reset_customer_ids()
