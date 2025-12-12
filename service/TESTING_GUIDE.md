# 🧪 PANDUAN UJI COBA SERVICE LAYER MOBILE BANKING

## ✅ Service Sudah Running!

Service Layer sedang berjalan di: **http://localhost:8001**

## 📚 Akses Dokumentasi API

Buka di browser:

1. **Swagger UI** (Interactive): http://localhost:8001/docs
2. **ReDoc** (Documentation): http://localhost:8001/redoc
3. **Health Check**: http://localhost:8001/health

---

## 🧪 SKENARIO TESTING LENGKAP

### SKENARIO 1️⃣: Register Customer Baru

**Endpoint:** `POST /service/customer`

1. Buka http://localhost:8001/docs
2. Klik endpoint **POST /service/customer**
3. Klik tombol **Try it out**
4. Masukkan data:

```json
{
  "customer_name": "Budi Santoso",
  "customer_username": "budi01",
  "customer_pin": "123456",
  "customer_email": "budi@example.com",
  "customer_phone": "081234567890",
  "cif_number": "CIF001"
}
```

5. Klik **Execute**
6. Lihat response, seharusnya return customer dengan ID

**Expected Result:**
```json
{
  "id": 1,
  "customer_name": "Budi Santoso",
  "customer_username": "budi01",
  "customer_email": "budi@example.com",
  "customer_phone": "081234567890",
  "cif_number": "CIF001",
  "failed_login_attempts": 0,
  "is_locked": false,
  "last_login": null,
  "created_at": "2025-12-12T...",
  "updated_at": "2025-12-12T..."
}
```

---

### SKENARIO 2️⃣: Create Portfolio Account

**Endpoint:** `POST /service/account`

1. Buka endpoint **POST /service/account**
2. Klik **Try it out**
3. Masukkan data (gunakan customer_id dari hasil register):

```json
{
  "m_customer_id": 1,
  "account_number": "1234567890",
  "account_name": "Budi Santoso",
  "account_type": "SAV",
  "currency_code": "IDR",
  "clear_balance": 1000000,
  "available_balance": 1000000
}
```

4. Klik **Execute**

**Expected Result:**
```json
{
  "id": 1,
  "m_customer_id": 1,
  "account_number": "1234567890",
  "account_name": "Budi Santoso",
  "account_type": "SAV",
  "currency_code": "IDR",
  "clear_balance": 1000000.0,
  "available_balance": 1000000.0,
  "is_active": true,
  "created_at": "2025-12-12T...",
  "updated_at": "2025-12-12T..."
}
```

---

### SKENARIO 3️⃣: Get Customer by Username (untuk Login)

**Endpoint:** `GET /service/customer/username/{username}`

1. Buka endpoint **GET /service/customer/username/{username}**
2. Klik **Try it out**
3. Masukkan username: `budi01`
4. Klik **Execute**

**Expected Result:** Return customer dengan PIN (untuk validasi login)

---

### SKENARIO 4️⃣: Get Accounts by Customer (Cek Saldo)

**Endpoint:** `GET /service/account/customer/{customer_id}`

1. Buka endpoint **GET /service/account/customer/{customer_id}**
2. Klik **Try it out**
3. Masukkan customer_id: `1`
4. Set active_only: `true`
5. Klik **Execute**

**Expected Result:** Return array semua account milik customer

```json
[
  {
    "id": 1,
    "m_customer_id": 1,
    "account_number": "1234567890",
    "account_name": "Budi Santoso",
    "account_type": "SAV",
    "currency_code": "IDR",
    "clear_balance": 1000000.0,
    "available_balance": 1000000.0,
    "is_active": true,
    "created_at": "2025-12-12T...",
    "updated_at": "2025-12-12T..."
  }
]
```

---

### SKENARIO 5️⃣: Transfer - Insert Transaction

**Step 1: Create account tujuan dulu**

Register customer kedua dan buat account:

```json
{
  "customer_name": "Ani Wijaya",
  "customer_username": "ani01",
  "customer_pin": "654321",
  "customer_email": "ani@example.com",
  "customer_phone": "081987654321",
  "cif_number": "CIF002"
}
```

Buat account untuk Ani:
```json
{
  "m_customer_id": 2,
  "account_number": "9876543210",
  "account_name": "Ani Wijaya",
  "account_type": "SAV",
  "currency_code": "IDR",
  "clear_balance": 500000,
  "available_balance": 500000
}
```

**Step 2: Debit Account Budi (pengirim)**

**Endpoint:** `POST /service/account/1234567890/debit`

Parameter query `amount`: `100000`

**Step 3: Credit Account Ani (penerima)**

**Endpoint:** `POST /service/account/9876543210/credit`

Parameter query `amount`: `100000`

**Step 4: Insert Transaction Record**

**Endpoint:** `POST /service/transaction`

```json
{
  "m_customer_id": 1,
  "transaction_type": "TR",
  "transaction_amount": 100000,
  "from_account_number": "1234567890",
  "to_account_number": "9876543210",
  "status": "SUCCESS",
  "description": "Transfer ke Ani"
}
```

**Expected Result:**
```json
{
  "id": 1,
  "m_customer_id": 1,
  "transaction_type": "TR",
  "transaction_amount": 100000.0,
  "from_account_number": "1234567890",
  "to_account_number": "9876543210",
  "status": "SUCCESS",
  "description": "Transfer ke Ani",
  "transaction_date": "2025-12-12T...",
  "created_at": "2025-12-12T..."
}
```

---

### SKENARIO 6️⃣: Get Transaction History

**Endpoint:** `GET /service/transaction/customer/{customer_id}`

1. Buka endpoint **GET /service/transaction/customer/{customer_id}**
2. Masukkan customer_id: `1`
3. Klik **Execute**

**Expected Result:** Return array semua transaksi customer

---

### SKENARIO 7️⃣: Failed Login Test

**Endpoint:** `POST /service/customer/{customer_id}/failed-login`

1. Panggil endpoint ini 3x untuk customer_id: `1`
2. Setelah 3x, customer akan ter-lock

**Check Status:**

**Endpoint:** `GET /service/customer/{customer_id}/check-locked`

Masukkan customer_id: `1`

**Expected Result:**
```json
{
  "is_locked": true
}
```

**Unlock Account:**

**Endpoint:** `POST /service/customer/{customer_id}/unlock`

---

## 🛠 TESTING MENGGUNAKAN CURL (Command Line)

### 1. Register Customer
```powershell
curl -X POST "http://localhost:8001/service/customer" `
  -H "Content-Type: application/json" `
  -d '{
    "customer_name": "Test User",
    "customer_username": "testuser",
    "customer_pin": "123456",
    "customer_email": "test@example.com",
    "customer_phone": "081234567890",
    "cif_number": "CIF999"
  }'
```

### 2. Get Customer by Username
```powershell
curl -X GET "http://localhost:8001/service/customer/username/testuser"
```

### 3. Create Account
```powershell
curl -X POST "http://localhost:8001/service/account" `
  -H "Content-Type: application/json" `
  -d '{
    "m_customer_id": 1,
    "account_number": "1111111111",
    "account_name": "Test User",
    "account_type": "SAV",
    "currency_code": "IDR",
    "clear_balance": 5000000,
    "available_balance": 5000000
  }'
```

### 4. Get Accounts by Customer
```powershell
curl -X GET "http://localhost:8001/service/account/customer/1?active_only=true"
```

### 5. Insert Transaction
```powershell
curl -X POST "http://localhost:8001/service/transaction" `
  -H "Content-Type: application/json" `
  -d '{
    "m_customer_id": 1,
    "transaction_type": "DP",
    "transaction_amount": 200000,
    "to_account_number": "1111111111",
    "status": "SUCCESS",
    "description": "Deposit"
  }'
```

---

## 📊 VALIDASI TESTING

### ✅ Yang Harus Berhasil:

1. ✅ Register customer baru
2. ✅ Tidak bisa register username yang sama (error 400)
3. ✅ Tidak bisa register email yang sama (error 400)
4. ✅ Create account dengan customer_id yang valid
5. ✅ Get customer by username return data + PIN
6. ✅ Get accounts by customer return array accounts
7. ✅ Debit account mengurangi saldo
8. ✅ Credit account menambah saldo
9. ✅ Insert transaction berhasil
10. ✅ Failed login 3x → account locked
11. ✅ Unlock account → is_locked = false

### ❌ Yang Harus Gagal (Error Handling):

1. ❌ Get customer dengan ID tidak ada → 404
2. ❌ Debit dengan saldo tidak cukup → 400
3. ❌ Create account dengan account_number yang sudah ada → 400
4. ❌ Update customer dengan ID tidak ada → 404

---

## 🗄 Cek Database SQLite

Database disimpan di: `ebanking.db`

Buka dengan SQLite Browser atau command:
```powershell
sqlite3 ebanking.db
.tables
SELECT * FROM m_customer;
SELECT * FROM m_portfolio_account;
SELECT * FROM t_transaction;
```

---

## 🔄 Flow Testing End-to-End

**Simulasi: Mobile → Middleware → Service**

### Flow Cek Saldo:

```
1. Mobile → GET /api/v1/balance
   ↓
2. Middleware decode token, dapat customer_id = 1
   ↓
3. Middleware → GET http://localhost:8001/service/account/customer/1
   ↓
4. Service query database
   ↓
5. Service return JSON accounts
   ↓
6. Middleware format response
   ↓
7. Mobile dapat saldo
```

**Testing Manual:**
```powershell
# Simulasi panggilan dari middleware
curl -X GET "http://localhost:8001/service/account/customer/1"
```

---

## 🎯 CHECKLIST TESTING

- [ ] Service running di port 8001
- [ ] Swagger UI terbuka di /docs
- [ ] Health check return status healthy
- [ ] Register customer berhasil
- [ ] Create account berhasil
- [ ] Get customer by username berhasil
- [ ] Get accounts by customer berhasil
- [ ] Debit account berhasil
- [ ] Credit account berhasil
- [ ] Insert transaction berhasil
- [ ] Get transaction history berhasil
- [ ] Failed login mechanism works
- [ ] Account locking works
- [ ] Error handling 404 works
- [ ] Error handling 400 works

---

## 🛑 Stop Service

Untuk stop service, tekan **CTRL+C** di terminal

---

## 🔥 TIPS TESTING

1. **Gunakan Swagger UI** - Paling mudah untuk testing manual
2. **Save Request** - Copy request body yang sudah berhasil
3. **Test Sequential** - Register → Create Account → Transaction
4. **Check Database** - Validasi data tersimpan dengan benar
5. **Test Error Cases** - Pastikan error handling bekerja
6. **Use Postman** - Untuk testing yang lebih advanced

---

**Status:** ✅ Service Layer Ready for Testing!  
**Port:** 8001  
**Database:** SQLite (ebanking.db)  
**Docs:** http://localhost:8001/docs
