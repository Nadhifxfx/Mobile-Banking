# 🏗️ ARSITEKTUR MOBILE BANKING SYSTEM

## 📊 3-TIER ARCHITECTURE

Sistem Mobile Banking ini menggunakan arsitektur 3-tier:

```
┌─────────────────────────────────────────────────────────────┐
│                      MOBILE APP LAYER                        │
│            (Flutter + Dart - Port: Mobile Device)            │
│                                                              │
│  - User Interface (Login, Transfer, Cek Saldo, dll)        │
│  - Input Validation                                         │
│  - Session Management & JWT Token Storage                   │
│  - Offline Caching                                          │
│  - Material Design UI & Custom Widgets                      │
└──────────────────────┬──────────────────────────────────────┘
                       │ HTTP/HTTPS
                       │ REST API Calls
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    MIDDLEWARE LAYER ✅                       │
│            (Node.js + Express - Port: 3000) - SUDAH ADA!    │
│                                                              │
│  - Authentication & Authorization (JWT Token)               │
│  - Business Logic & Validation                              │
│  - Transaction Processing                                   │
│  - API Gateway / Routing                                    │
│  - Rate Limiting & Security (Helmet + express-rate-limit)  │
│  - Call Service Layer untuk database operations             │
└──────────────────────┬──────────────────────────────────────┘
                       │ HTTP
                       │ Internal API Calls
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                     SERVICE LAYER ✅                         │
│          (FastAPI/Python - Port: 8001) - SUDAH ADA!         │
│                                                              │
│  - Database Operations (CRUD)                               │
│  - Data Access Layer                                        │
│  - Repository Pattern                                       │
│  - Direct Database Connection                               │
└──────────────────────┬──────────────────────────────────────┘
                       │ SQL
                       │ Database Queries
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    DATABASE LAYER                            │
│              (PostgreSQL/SQLite - Port: 5432)               │
│                                                              │
│  - Data Storage (m_customer, m_portfolio_account, dll)     │
│  - Data Integrity & Constraints                             │
│  - Transactions & ACID                                      │
└─────────────────────────────────────────────────────────────┘
```

---

## ✅ STATUS SAAT INI

### **Yang Sudah Ada:**
- ✅ **SERVICE LAYER** (Port 8001) - **COMPLETE!**
  - Customer Management API
  - Account Management API
  - Transaction Management API
  - Database Models & Connection
  - Repository Pattern
  - Swagger Documentation

- ✅ **MIDDLEWARE LAYER** (Port 3000) - **COMPLETE!**
  - JWT Authentication & Authorization
  - Business Logic & Validation
  - Security (Helmet, Rate Limiting, CORS)
  - Service Layer Integration
  - Express Routes & Middleware

- ✅ **DATABASE** (SQLite)
  - `ebanking.db`
  - Tables: m_customer, m_portfolio_account, t_transaction
  - Auto-created saat service start

- ✅ **MOBILE APP** (Flutter) - **SETUP COMPLETE!**
  - Flutter project initialized
  - Ready untuk development
  - Cross-platform (Android, iOS, Web)

### **Yang Perlu Dikembangkan:**
- 🔧 **MOBILE APP FEATURES** - **IN DEVELOPMENT**
  - Login & Authentication UI
  - Dashboard & Balance Display
  - Transfer & Transaction Features
  - Transaction History
  - Profile Management

---

## 🔗 CARA KERJA INTEGRASI

### **Contoh Flow: User Transfer Uang**

```
1️⃣ USER (Mobile App)
   - User buka aplikasi
   - Login dengan username & PIN
   - Klik menu "Transfer"
   - Input: Rekening Tujuan, Nominal, Deskripsi
   - Klik "Kirim"

   ⬇️ HTTP POST

2️⃣ MOBILE APP → MIDDLEWARE
   POST http://middleware-server:8000/api/v1/transfer
   Headers:
     Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   Body:
     {
       "from_account": "1234567890",
       "to_account": "9876543210",
       "amount": 100000,
       "description": "Transfer ke teman"
     }

   ⬇️

3️⃣ MIDDLEWARE
   a. Decode JWT Token → dapat customer_id
   b. Validasi:
      - Token valid?
      - Customer locked?
      - Account exists?
      - Saldo cukup?
   
   c. Call SERVICE LAYER untuk cek saldo:
      GET http://localhost:8001/service/account/1234567890/balance
   
   d. Jika saldo cukup, lakukan transfer:
      - POST http://localhost:8001/service/account/1234567890/debit?amount=100000
      - POST http://localhost:8001/service/account/9876543210/credit?amount=100000
      - POST http://localhost:8001/service/transaction (record)
   
   e. Return response ke Mobile

   ⬇️

4️⃣ MIDDLEWARE → MOBILE APP
   Response:
     {
       "status": "success",
       "message": "Transfer berhasil",
       "transaction_id": 123,
       "new_balance": 900000
     }

   ⬇️

5️⃣ MOBILE APP
   - Tampilkan notifikasi "Transfer Berhasil!"
   - Update saldo di layar
   - Simpan receipt
```

---

## 🎯 MIDDLEWARE LAYER - YANG PERLU DIBUAT

Middleware adalah **penghubung** antara Mobile App dan Service Layer.

### **Tanggung Jawab Middleware:**

1. **Authentication & Authorization**
   ```javascript
   // Login: Generate JWT Token
   POST /api/v1/auth/login
   - Terima username & PIN dari mobile
   - Call: GET /service/customer/username/{username}
   - Validasi PIN (hash comparison)
   - Generate JWT Token
   - Return token ke mobile
   ```

2. **Business Logic**
   ```javascript
   // Transfer: Orchestrate multiple service calls
   POST /api/v1/transfer
   - Decode token → dapat customer_id
   - Validasi ownership (rekening pengirim milik customer?)
   - Cek saldo → Call service layer
   - Debit pengirim → Call service layer
   - Credit penerima → Call service layer
   - Insert transaction → Call service layer
   - Handle rollback jika ada yang gagal
   ```

3. **Security**
   - Rate limiting (max 10 request/menit)
   - Input sanitization
   - SQL injection prevention
   - CORS configuration

4. **API Gateway**
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
