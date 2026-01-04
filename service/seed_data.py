"""
Seed dummy data for testing
Run with: python seed_data.py
"""
import requests
import bcrypt

# Hash PIN: 123456
pin = "123456"
hashed_pin = bcrypt.hashpw(pin.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

# Create customer
customer_data = {
    "customer_name": "John Doe",
    "customer_username": "johndoe",
    "customer_pin": hashed_pin,
    "customer_email": "johndoe@example.com",
    "customer_phone": "081234567890",
    "cif_number": "CIF999"  # Changed to unique CIF
}

print("Creating customer johndoe...")
response = requests.post("http://localhost:8001/service/customer", json=customer_data)
print(f"Status: {response.status_code}")
print(f"Response: {response.json()}")

if response.status_code == 200:
    customer_id = response.json()['id']
    print(f"\n✅ Customer created with ID: {customer_id}")
    
    # Create account
    account_data = {
        "m_customer_id": customer_id,
        "account_number": "1234567890",
        "account_name": "John Doe - Savings",
        "account_type": "SAVINGS",
        "balance": 1000000.00
    }
    
    print("\nCreating account...")
    acc_response = requests.post("http://localhost:8001/service/account", json=account_data)
    print(f"Status: {acc_response.status_code}")
    print(f"Response: {acc_response.json()}")
    
    if acc_response.status_code == 200:
        print("\n✅ Account created successfully!")
        print("\n🎉 Demo data seeded!")
        print("\nLogin credentials:")
        print("  Username: johndoe")
        print("  PIN: 123456")
        print("  Account: 1234567890")
        print("  Balance: Rp 1.000.000")
else:
    print(f"\n❌ Error: {response.json()}")
