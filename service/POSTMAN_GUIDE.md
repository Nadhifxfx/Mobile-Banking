# 📮 PANDUAN IMPORT POSTMAN COLLECTION

## 🚀 File yang Tersedia

1. **Mobile_Banking_Service.postman_collection.json** - Collection lengkap semua endpoint
2. **Mobile_Banking_Local.postman_environment.json** - Environment variables

---

## 📥 CARA IMPORT KE POSTMAN

### **Metode 1: Import Collection & Environment**

1. **Buka Postman**
2. **Import Collection:**
   - Klik tombol **Import** (kiri atas)
   - Klik **Upload Files**
   - Pilih file: `Mobile_Banking_Service.postman_collection.json`
   - Klik **Import**

3. **Import Environment:**
   - Klik tombol **Import** lagi
   - Upload file: `Mobile_Banking_Local.postman_environment.json`
   - Klik **Import**

4. **Aktifkan Environment:**
   - Klik dropdown environment (kanan atas)
   - Pilih **"Mobile Banking - Local"**

✅ **Done!** Anda siap testing!

---

### **Metode 2: Import dari Swagger (Alternative)**

1. Pastikan service running di `http://localhost:8001`
2. Di Postman: **Import** → **Link**
3. Paste URL: `http://localhost:8001/openapi.json`
4. Klik **Continue** → **Import**

---

## 📁 STRUKTUR COLLECTION

```
📦 Mobile Banking Service API
│
├── 📁 0. Health & Info
│   ├── ✅ Health Check
│   └── ✅ Root Info
│
├── 📁 1. Customer Management
│   ├── 1️⃣ Register Customer
│   ├── 2️⃣ Get Customer by Username
│   ├── 3️⃣ Get Customer by ID
│   ├── 4️⃣ Update Customer
│   ├── 5️⃣ Failed Login (x3 = Lock)
│   ├── 6️⃣ Check Locked Status
│   └── 7️⃣ Unlock Account
│
├── 📁 2. Account Management
│   ├── 1️⃣ Create Portfolio Account
│   ├── 2️⃣ Get Accounts by Customer
│   ├── 3️⃣ Get Account by Number
│   ├── 4️⃣ Get Account by ID
│   ├── 5️⃣ Update Account
│   ├── 6️⃣ Debit Account (Kurangi Saldo)
│   ├── 7️⃣ Credit Account (Tambah Saldo)
│   └── 8️⃣ Get Account Balance
│
├── 📁 3. Transaction Management
│   ├── 1️⃣ Insert Transaction
│   ├── 2️⃣ Get Transactions by Customer
│   ├── 3️⃣ Get Transactions by Account
│   ├── 4️⃣ Get Transaction by ID
│   └── 5️⃣ Update Transaction Status
│
└── 📁 🧪 Test Scenarios
    ├── ▶️ Scenario A: Complete Registration Flow
    │   ├── Step 1 - Register Customer
    │   ├── Step 2 - Create Account
    │   └── Step 3 - Check Balance
    │
    ├── ▶️ Scenario B: Transfer Flow
    │   ├── Step 1 - Debit Sender
    │   ├── Step 2 - Credit Receiver
    │   ├── Step 3 - Record Transaction
    │   └── Step 4 - Get Transaction History
    │
    └── ▶️ Scenario C: Security Test
        ├── Step 1 - Failed Login (1st)
        ├── Step 2 - Failed Login (2nd)
        ├── Step 3 - Failed Login (3rd = LOCK)
        ├── Step 4 - Check Locked
        └── Step 5 - Unlock
```

---

## 🎯 CARA MENGGUNAKAN

### **Quick Start - Testing Manual**

1. **Start Service:**
   ```powershell
   cd service
   uvicorn main:app --reload --port 8001
   ```

2. **Test Health Check:**
   - Buka folder: `0. Health & Info`
   - Klik: `Health Check`
   - Klik tombol: **Send**
   - Lihat response: `{ "status": "healthy" }`

3. **Register Customer:**
   - Buka folder: `1. Customer Management`
   - Klik: `1. Register Customer`
   - Body sudah terisi otomatis
   - Klik: **Send**
   - ✅ `customer_id` auto-saved ke environment

4. **Create Account:**
   - Klik: `2. Account Management` → `1. Create Portfolio Account`
   - Body menggunakan `{{customer_id}}` dari step sebelumnya
   - Klik: **Send**
   - ✅ `account_number` auto-saved ke environment

5. **Check Balance:**
   - Klik: `8. Get Account Balance`
   - URL menggunakan `{{account_number}}`
   - Klik: **Send**

---

### **Quick Start - Testing dengan Scenario**

Lebih mudah! Semua step sudah disusun:

1. **Run Scenario A (Registration):**
   - Buka folder: `🧪 Test Scenarios` → `Scenario A`
   - Jalankan dari atas ke bawah:
     - Send: Step 1 (Register)
     - Send: Step 2 (Create Account)
     - Send: Step 3 (Check Balance)

2. **Run Scenario B (Transfer):**
   - Pastikan ada 2 account
   - Jalankan semua step berurutan

3. **Run Scenario C (Security):**
   - Test failed login mechanism
   - Jalankan 3x failed login → auto lock
   - Unlock kembali

---

## 🔧 ENVIRONMENT VARIABLES

Variables yang auto-update setelah request:

| Variable | Description | Auto-Save |
|----------|-------------|-----------|
| `base_url` | Service URL | Manual |
| `customer_id` | ID customer terakhir | ✅ Auto |
| `customer_username` | Username terakhir | ✅ Auto |
| `account_id` | ID account terakhir | ✅ Auto |
| `account_number` | Nomor rekening terakhir | ✅ Auto |
| `account_number_2` | Nomor rekening ke-2 | Manual |
| `transaction_id` | ID transaksi terakhir | ✅ Auto |

**Cara pakai:**
- Di request gunakan: `{{base_url}}`, `{{customer_id}}`, dll
- Variables akan auto-update setelah request berhasil (lihat Tests tab)

---

## 💡 FITUR COLLECTION

### **1. Auto-Save Response**
Setiap request penting punya script untuk auto-save ID:

```javascript
// Tests tab - auto save customer_id
if (pm.response.code === 201) {
    var jsonData = pm.response.json();
    pm.environment.set("customer_id", jsonData.id);
}
```

### **2. Dynamic Data**
Request menggunakan variables untuk data dinamis:

```json
{
  "m_customer_id": {{customer_id}},
  "account_number": "ACC{{$timestamp}}"
}
```

### **3. Descriptions**
Setiap endpoint punya penjelasan lengkap:
- Fungsi endpoint
- Real world use case
- Expected response

---

## 🎨 TIPS & TRICKS

### **1. Testing Sequential**
Jalankan berurutan untuk dapat data lengkap:
```
Health Check → Register → Create Account → Get Balance
```

### **2. Use Scenarios**
Gunakan folder `🧪 Test Scenarios` untuk testing yang lebih terstruktur.

### **3. Check Environment**
Setelah setiap request, cek environment variables apakah sudah update:
- Klik icon **mata** (👁️) di kanan atas
- Lihat current values

### **4. Copy to New Request**
Jika butuh variasi:
- Right-click request → **Duplicate**
- Edit body sesuai kebutuhan

### **5. Generate Random Data**
Gunakan Postman variables:
- `{{$timestamp}}` → Unix timestamp
- `{{$randomInt}}` → Random number
- `{{$guid}}` → UUID

Contoh:
```json
{
  "customer_email": "user_{{$timestamp}}@example.com",
  "cif_number": "CIF_{{$randomInt}}"
}
```

---

## 🧪 TESTING CHECKLIST

Gunakan checklist ini untuk testing lengkap:

### **Customer Management**
- [ ] ✅ Register customer baru
- [ ] ✅ Get customer by username
- [ ] ✅ Get customer by ID
- [ ] ✅ Update customer
- [ ] ✅ Failed login 3x → lock
- [ ] ✅ Check locked status
- [ ] ✅ Unlock account

### **Account Management**
- [ ] ✅ Create account
- [ ] ✅ Get accounts by customer
- [ ] ✅ Get account by number
- [ ] ✅ Update account
- [ ] ✅ Debit account
- [ ] ✅ Credit account
- [ ] ✅ Get balance

### **Transaction Management**
- [ ] ✅ Insert transaction
- [ ] ✅ Get transactions by customer
- [ ] ✅ Get transactions by account
- [ ] ✅ Get transaction by ID
- [ ] ✅ Update transaction status

### **End-to-End Scenarios**
- [ ] ✅ Complete registration flow
- [ ] ✅ Transfer scenario
- [ ] ✅ Security test

---

## ❌ ERROR HANDLING

Expected errors yang harus muncul:

1. **404 Not Found**
   - Get customer dengan ID tidak ada
   - Get account dengan nomor tidak ada

2. **400 Bad Request**
   - Register dengan username yang sudah ada
   - Register dengan email yang sudah ada
   - Debit dengan saldo tidak cukup

3. **422 Validation Error**
   - Body request tidak sesuai schema
   - Email format salah

---

## 🔄 RESET DATABASE

Jika ingin mulai dari awal:

1. Stop service (Ctrl+C)
2. Delete file: `ebanking.db`
3. Start service lagi → database baru otomatis dibuat

---

## 📊 VIEWING DATABASE

Untuk lihat data di database SQLite:

**Option 1: DB Browser for SQLite**
1. Download: https://sqlitebrowser.org/
2. Open file: `ebanking.db`
3. Browse data di tab "Browse Data"

**Option 2: Command Line**
```powershell
sqlite3 ebanking.db
.tables
SELECT * FROM m_customer;
SELECT * FROM m_portfolio_account;
SELECT * FROM t_transaction;
.quit
```

---

## 🎯 NEXT STEPS

Setelah collection ready:

1. ✅ Test semua endpoint manual
2. ✅ Test semua scenarios
3. ✅ Validate error handling
4. ✅ Export collection untuk tim
5. ✅ Setup automated tests (Newman)

---

## 📞 SUPPORT

Jika ada masalah:

1. **Check Service:** `http://localhost:8001/health`
2. **Check Docs:** `http://localhost:8001/docs`
3. **Check Logs:** Lihat terminal tempat service running
4. **Check Database:** Buka `ebanking.db` dengan SQLite browser

---

**Happy Testing! 🚀**
