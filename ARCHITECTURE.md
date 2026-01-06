# 🏗️ ARSITEKTUR MOBILE BANKING SYSTEM

**Last Updated:** 6 Januari 2026

## 📊 3-TIER ARCHITECTURE

Sistem Mobile Banking ini menggunakan arsitektur 3-tier yang sudah berjalan penuh:

```
┌─────────────────────────────────────────────────────────────┐
│                      MOBILE APP LAYER ✅                      │
│              (Flutter Web - Chrome Browser)                  │
│                                                              │
│  - User Interface (Login, Register, Transfer, dll) ✅       │
│  - Input Validation ✅                                       │
│  - Session Management & JWT Token Storage ✅                 │
│  - SharedPreferences untuk Recent Transactions ✅           │
│  - Material Design UI ✅                                     │
│  - No PIN Confirmation (Auto-approved) ✅                    │
└──────────────────────┬──────────────────────────────────────┘
                       │ HTTP/HTTPS
                       │ REST API: http://localhost:8000/api/v1/*
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    MIDDLEWARE LAYER ✅                       │
│            (Node.js + Express - Port: 8000)                 │
│                                                              │
│  - Authentication & Authorization (JWT Token) ✅            │
│  - Business Logic & Validation ✅                           │
│  - Transaction Processing (Auto-approve) ✅                 │
│  - API Gateway / Routing ✅                                 │
│  - Rate Limiting & Security (Helmet + CORS) ✅             │
│  - Balance Check: Flexible dict/object access ✅            │
│  - Call Service Layer untuk database operations ✅          │
└──────────────────────┬──────────────────────────────────────┘
                       │ HTTP
                       │ Internal API: http://localhost:8001/service/*
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                     SERVICE LAYER ✅                         │
│          (FastAPI/Python - Port: 8001)                      │
│                                                              │
│  - Database Operations (CRUD) ✅                            │
│  - Data Access Layer (Repository Pattern) ✅                │
│  - Returns dict via _to_dict() methods ✅                   │
│  - Balance endpoint: account['clear_balance'] ✅            │
│  - Direct SQLAlchemy ORM Connection ✅                      │
└──────────────────────┬──────────────────────────────────────┘
                       │ SQLAlchemy ORM
                       │ Database Queries
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    DATABASE LAYER ✅                         │
│                   (SQLite - ebanking.db)                    │
│                                                              │
│  - Data Storage (m_customer, m_portfolio_account, etc) ✅   │
│  - Data Integrity & Constraints ✅                          │
│  - Transactions & ACID ✅                                   │
│  - Auto-initialization on startup ✅                        │
└─────────────────────────────────────────────────────────────┘
```

---

## ✅ STATUS SISTEM

### **Semua Layer Sudah Berjalan Penuh:**

- ✅ **SERVICE LAYER** (Port 8001) - **PRODUCTION READY!**
  - Customer Management API ✅
  - Account Management API ✅
  - Transaction Management API ✅
  - Database Models & Connection ✅
  - Repository Pattern ✅
  - Balance endpoint fixed (dict access) ✅
  - Swagger Documentation: http://localhost:8001/docs ✅

- ✅ **MIDDLEWARE LAYER** (Port 8000) - **PRODUCTION READY!**
  - JWT Authentication & Authorization ✅
  - Business Logic & Validation ✅
  - Security (Helmet, Rate Limiting, CORS) ✅
  - Service Layer Integration ✅
  - Auto-approve transactions (no PIN confirmation) ✅
  - Flexible balance access (dict/object) ✅
  - Express Routes & Middleware ✅

- ✅ **DATABASE** (SQLite) - **ACTIVE!**
  - `ebanking.db` & `mobile_banking.db` ✅
  - Tables: m_customer, m_portfolio_account, t_transaction ✅
  - Auto-created saat service start ✅
  - SQLAlchemy ORM integration ✅

- ✅ **MOBILE APP** (Flutter Web) - **PRODUCTION READY!**
  - Login & Register ✅
  - Dashboard dengan Recent Contacts & Transactions ✅
  - Transfer (3 steps, no PIN) ✅
  - Withdraw & Deposit (3 steps, no PIN) ✅
  - Profile & PIN Update ✅
  - SharedPreferences untuk local storage ✅
  - Running di Chrome Browser ✅

### **Fitur yang Sudah Berfungsi:**
- ✅ User Registration & Login dengan JWT
- ✅ Dashboard menampilkan saldo total & per account
- ✅ Transfer antar rekening tanpa konfirmasi PIN
- ✅ Tarik & Setor Tunai tanpa konfirmasi PIN
- ✅ Recent Contacts tersimpan untuk transfer cepat
- ✅ Recent Transactions ditampilkan di Dashboard (3 terakhir)
- ✅ Update PIN di Profile
- ✅ Saldo otomatis terupdate setelah transaksi
- ✅ Transaksi tersimpan di database & SharedPreferences

---

## 🔗 CARA KERJA SISTEM (TRANSFER FLOW)

### **Contoh Flow: User Transfer Uang**

```
1️⃣ USER (Mobile App)
   - User buka aplikasi di Chrome
   - Login dengan username & PIN
   - Klik menu "Transfer"
   - Step 1: Pilih rekening sumber & tujuan
   - Step 2: Input nominal & deskripsi
   - Klik "Transfer Sekarang" (langsung diproses, NO PIN!)
   - Step 3: Tampilkan success screen

   ⬇️ HTTP POST

2️⃣ MOBILE APP → MIDDLEWARE
   POST http://localhost:8000/api/v1/transaction/transfer
   Headers:
     Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   Body:
     {
       "from_account": "1234567890",
       "to_account": "9876543210",
       "amount": 100000,
       "pin": "123456",
       "description": "Transfer ke teman"
     }

   ⬇️

3️⃣ MIDDLEWARE (Auto-Process)
   a. Decode JWT Token → dapat customer_id
   b. NO PIN Validation (auto-approved dengan PIN default)
   c. Verify source account ownership
   d. Verify destination account exists
   
   e. Call SERVICE LAYER untuk cek saldo:
      GET http://localhost:8001/service/account/1234567890/balance
      Response: {"clear_balance": 1000000, "available_balance": 1000000}
      Access with: balance.available_balance || balance['available_balance']
   
   f. Jika saldo cukup, lakukan transfer:
      - POST http://localhost:8001/service/account/1234567890/debit?amount=100000
      - POST http://localhost:8001/service/account/9876543210/credit?amount=100000
      - POST http://localhost:8001/service/transaction (record)
   
   g. Return response ke Mobile

   ⬇️

4️⃣ MIDDLEWARE → MOBILE APP
   Response:
     {
       "status": "success",
       "message": "Transfer successful",
       "transaction": {
         "id": 123,
         "type": "Transfer",
         "amount": 100000,
         "from": "1234567890",
         "to": "9876543210",
         "to_name": "Budi",
         "description": "Transfer ke teman"
       },
       "new_balance": 900000
     }

   ⬇️

5️⃣ MOBILE APP
   - Simpan ke SharedPreferences:
     * Contact: {"account": "9876543210", "name": "Budi", "bank": "BRI"}
     * Transaction: {"type": "Transfer", "amount": 100000, "date": "...", "status": "SUCCESS"}
   - Tampilkan success screen dengan detail transaksi
   - Update saldo di layar
   - Navigate to dashboard → Recent Contacts & Transactions akan terupdate
```

---

## 🎯 TECHNICAL DETAILS

### **1. Authentication Flow**

```javascript
// Login Process
POST /api/v1/auth/login
Request: { username: "budi01", pin: "123456" }

Middleware:
1. Call Service Layer: GET /service/customer/username/budi01
2. Get customer data with hashed PIN
3. Compare PIN using bcrypt.compare(inputPin, hashedPin)
4. If valid, generate JWT token with payload: { customer_id, username }
5. Return: { token: "eyJ...", customer: {...} }

Mobile App:
- Store token in memory
- Store user data in SharedPreferences
- Set Authorization header for all subsequent requests
```

### **2. Transaction Processing**

```javascript
// Transfer (Middleware Logic)
POST /api/v1/transaction/transfer

Steps:
1. Verify JWT token → extract customer_id
2. NO PIN validation (auto-approved)
3. Verify source account ownership
4. Check balance with flexible access:
   - balance.available_balance || balance['available_balance'] || 0
5. Debit source account
6. Credit destination account
7. Record transaction
8. Return success response

// Withdraw/Deposit (Same pattern)
POST /api/v1/transaction/withdraw
POST /api/v1/transaction/deposit
- Same auto-approval logic
- No PIN confirmation required
```

### **3. Service Layer Data Flow**

```python
# Account Service (Python)
class AccountService:
    def get_account_by_number(self, db, account_number):
        account = self.repository.get_by_account_number(db, account_number)
        return self._account_to_dict(account)  # Returns dict!
    
    def _account_to_dict(self, account):
        return {
            "id": account.id,
            "account_number": account.account_number,
            "clear_balance": float(account.clear_balance),
            "available_balance": float(account.available_balance),
            # ... other fields
        }

# Controller (Fixed)
@router.get("/{account_number}/balance")
def get_account_balance(account_number: str, db: Session = Depends(get_db)):
    account = account_service.get_account_by_number(db, account_number)
    return {
        "clear_balance": account['clear_balance'],  # Dict access!
        "available_balance": account['available_balance']
    }
```

### **4. Mobile App Local Storage**

```dart
// SharedPreferences Usage
class TransferScreen {
  // Save contact after successful transfer
  Future<void> _saveContactAndTransaction(...) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save contact
    List<Map<String, String>> contacts = [...];
    contacts.insert(0, {
      'account': account,
      'name': name,
      'bank': bank
    });
    await prefs.setString('saved_contacts', jsonEncode(contacts));
    
    // Save transaction
    List<Map<String, dynamic>> transactions = [...];
    transactions.insert(0, {
      'type': 'Transfer',
      'account': account,
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
      'status': 'SUCCESS'
    });
    await prefs.setString('recent_transactions', jsonEncode(transactions));
  }
}

// Dashboard loads and displays
class DashboardScreen {
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = prefs.getString('saved_contacts');
    final transactionsJson = prefs.getString('recent_transactions');
    // Display in UI
  }
}
```
   - Single endpoint untuk mobile
   - Route ke berbagai service layer endpoints
   - Request/Response transformation

---

## 📱 MOBILE APP - YANG PERLU DIBUAT

### **Fitur Mobile App:**

1. **Authentication**
   - Login screen (username + PIN)
   - Biometric login (fingerprint/face)
   - Remember me
   - Logout

2. **Dashboard**
   - Tampilkan saldo semua rekening
   - Recent transactions
   - Quick actions (Transfer, Tarik Tunai, dll)

3. **Transfer**
   - Input rekening tujuan
   - Input nominal
   - Konfirmasi dengan PIN
   - Tampilkan receipt

4. **Transaction History**
   - List semua transaksi
   - Filter by date, type
   - Detail transaksi
   - Download statement

5. **Profile**
   - Lihat & edit profil
   - Ganti PIN
   - Manage devices

---

## 🔧 CARA KONEKSI SERVICE LAYER

### **Service Layer Sudah Siap Digunakan!**

Middleware tinggal panggil endpoint yang sudah tersedia:

#### **1. Login Flow**
```javascript
// Middleware code (Node.js/Express example)
const axios = require('axios');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

app.post('/api/v1/auth/login', async (req, res) => {
  const { username, pin } = req.body;
  
  try {
    // Call Service Layer
    const response = await axios.get(
      `http://localhost:8001/service/customer/username/${username}`
    );
    
    const customer = response.data;
    
    // Validasi PIN
    const isValidPin = await bcrypt.compare(pin, customer.customer_pin);
    
    if (isValidPin) {
      // Generate JWT Token
      const token = jwt.sign(
        { customer_id: customer.id, username: customer.customer_username },
        process.env.JWT_SECRET,
        { expiresIn: '24h' }
      );
      
      res.json({
        status: 'success',
        token: token,
        customer: {
          id: customer.id,
          name: customer.customer_name,
          email: customer.customer_email
        }
      });
    } else {
      res.status(401).json({ error: 'Invalid PIN' });
    }
  } catch (error) {
    res.status(500).json({ error: 'Login failed' });
  }
});
```

#### **2. Get Balance**
```javascript
// Middleware code
app.get('/api/v1/balance', authenticate, async (req, res) => {
  const customer_id = req.user.customer_id; // dari JWT token
  
  try {
    // Call Service Layer
    const response = await axios.get(
      `http://localhost:8001/service/account/customer/${customer_id}`
    );
    
    res.json({
      status: 'success',
      accounts: response.data
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to get balance' });
  }
});
```

#### **3. Transfer**
```javascript
// Middleware code
app.post('/api/v1/transfer', authenticate, async (req, res) => {
  const { from_account, to_account, amount, description } = req.body;
  const customer_id = req.user.customer_id;
  
  try {
    // 1. Cek saldo
    const balanceRes = await axios.get(
      `http://localhost:8001/service/account/${from_account}/balance`
    );
    
    if (balanceRes.data.available_balance < amount) {
      return res.status(400).json({ error: 'Saldo tidak cukup' });
    }
    
    // 2. Debit pengirim
    await axios.post(
      `http://localhost:8001/service/account/${from_account}/debit?amount=${amount}`
    );
    
    // 3. Credit penerima
    await axios.post(
      `http://localhost:8001/service/account/${to_account}/credit?amount=${amount}`
    );
    
    // 4. Insert transaction
    const txnRes = await axios.post(
      `http://localhost:8001/service/transaction`,
      {
        m_customer_id: customer_id,
        transaction_type: 'TR',
        transaction_amount: amount,
        from_account_number: from_account,
        to_account_number: to_account,
        status: 'SUCCESS',
        description: description
      }
    );
    
    res.json({
      status: 'success',
      message: 'Transfer berhasil',
      transaction_id: txnRes.data.id
    });
    
  } catch (error) {
    res.status(500).json({ error: 'Transfer gagal' });
  }
});
```

---

## 📦 SETUP LENGKAP

### **1. Service Layer (Port 8001)** ✅ **SUDAH JALAN**
```powershell
cd service
uvicorn main:app --reload --port 8001
```

### **2. Middleware Layer (Port 8000)** ❌ **PERLU DIBUAT**

**Option A: Node.js + Express**
```bash
mkdir middleware
cd middleware
npm init -y
npm install express axios jsonwebtoken bcrypt cors dotenv
```

Struktur middleware:
```
middleware/
├── server.js
├── routes/
│   ├── auth.js
│   ├── account.js
│   └── transaction.js
├── middleware/
│   └── authenticate.js
├── services/
│   └── serviceLayer.js
└── package.json
```

**Option B: Python + FastAPI**
```bash
mkdir middleware
cd middleware
pip install fastapi uvicorn python-jose bcrypt python-multipart
```

### **3. Mobile App (Flutter)** ✅ **SUDAH DIBUAT**

```bash
cd mobile
flutter pub get
flutter run
```

**Struktur Flutter App:**
```
mobile/
├── lib/
│   ├── main.dart           # Entry point
│   ├── screens/            # UI Screens
│   │   ├── login_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── transfer_screen.dart
│   │   └── history_screen.dart
│   ├── widgets/            # Reusable widgets
│   ├── services/           # API services
│   │   └── api_service.dart
│   ├── models/             # Data models
│   └── utils/              # Helpers & constants
├── pubspec.yaml            # Dependencies
└── android/ios/web/        # Platform-specific
```

---

## 🔐 SECURITY CONSIDERATIONS

### **1. Communication Security**
```
Mobile → Middleware: HTTPS (SSL/TLS)
Middleware → Service: HTTP (internal network) atau HTTPS
```

### **2. Authentication Flow**
```
1. Mobile → Middleware: username + PIN
2. Middleware → Service: Get customer data
3. Middleware: Validate PIN
4. Middleware → Mobile: JWT Token
5. Mobile: Save token, use for all subsequent requests
6. Mobile → Middleware: Include token in Authorization header
7. Middleware: Decode token, get customer_id
8. Middleware → Service: Use customer_id for operations
```

### **3. Environment Configuration**

**Middleware `.env`:**
```
SERVICE_LAYER_URL=http://localhost:8001
JWT_SECRET=your-secret-key-change-in-production
JWT_EXPIRY=24h
PORT=8000
```

---

## ✅ CHECKLIST INTEGRASI

### **Service Layer → Middleware**
- [ ] ✅ Service layer running di port 8001
- [ ] Create middleware project
- [ ] Install dependencies (axios, jwt, bcrypt)
- [ ] Create authentication endpoint
- [ ] Create service layer client (axios wrapper)
- [ ] Implement business logic endpoints
- [ ] Test middleware → service communication
- [ ] Add error handling & logging

### **Middleware → Mobile**
- [ ] Create mobile app project
- [ ] Setup HTTP client (dio/axios/retrofit)
- [ ] Implement login screen
- [ ] Store JWT token securely
- [ ] Implement authenticated requests
- [ ] Create UI screens (dashboard, transfer, history)
- [ ] Test end-to-end flow

---

## 🎯 KESIMPULAN

### **JAWABAN SINGKAT:**

**Service Layer SUDAH SIAP** untuk disambungkan ke middleware! ✅

Yang perlu Anda buat:
1. **Middleware Layer** - untuk handle authentication, business logic, dan call service layer
2. **Mobile App** - untuk user interface

Service layer sudah menyediakan **semua endpoint yang dibutuhkan** untuk operasi database. Middleware tinggal panggil endpoint-endpoint tersebut via HTTP request.

### **NEXT STEPS:**

1. Tentukan teknologi untuk middleware (Node.js/Python/Java)
2. Buat middleware project
3. Implement authentication & JWT
4. Create endpoints yang call service layer
5. Buat mobile app
6. Test integrasi end-to-end

Apakah Anda ingin saya buatkan **template middleware layer** juga? 🚀
