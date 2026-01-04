"""
Update customer budi01 to johndoe
"""
import requests
import bcrypt

# Hash PIN: 123456
pin = "123456"
hashed_pin = bcrypt.hashpw(pin.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

# Update customer ID 1
customer_data = {
    "customer_name": "John Doe",
    "customer_email": "johndoe@example.com",
    "customer_phone": "081234567890"
}

print("Updating customer ID 1 to johndoe...")
response = requests.put("http://localhost:8001/service/customer/1", json=customer_data)
print(f"Status: {response.status_code}")
print(f"Response: {response.json()}")

# Update username via direct SQL would be better, but let's use what we have
# Since we can't update username via API, let's create account for existing user

print("\nChecking accounts for customer 1...")
acc_response = requests.get("http://localhost:8001/service/account/customer/1")
print(f"Status: {acc_response.status_code}")

if acc_response.status_code == 200:
    accounts = acc_response.json()
    print(f"Found {len(accounts)} accounts")
    if len(accounts) > 0:
        print(f"\n✅ Use these credentials:")
        print(f"  Username: budi01")
        print(f"  PIN: (unknown - check original)")
        print(f"  Account: {accounts[0]['account_number']}")
else:
    print("Creating account...")
    account_data = {
        "m_customer_id": 1,
        "account_number": "1234567890",
        "account_name": "Budi Santoso - Savings",
        "account_type": "SAVINGS",
        "balance": 1000000.00
    }
    acc_create = requests.post("http://localhost:8001/service/account", json=account_data)
    print(f"Account created: {acc_create.json()}")
