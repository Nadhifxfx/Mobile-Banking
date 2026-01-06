# 🏦 Mobile SAE Banking 

**Last Updated:** 6 Januari 2026

Sistem Mobile Banking lengkap dengan 3-tier architecture: **Mobile App (Flutter Web)**, **Middleware (Node.js)**, dan **Service Layer (Python FastAPI)**.

---

## 📋 Table of Contents

- [Features](#-features)
- [Architecture](#️-architecture)
- [Project Structure](#-project-structure)
- [Quick Start](#-quick-start)
- [API Endpoints](#-api-endpoints)
- [Technical Details](#-technical-details)
- [Development](#-development)

---

## 🎯 Features

### ✅ Fully Functional Features
- **Authentication** - Login & Register dengan JWT token
- **Dashboard** - Saldo real-time, Recent Contacts & Transactions
- **Transfer** - Transfer antar rekening (3 steps, no PIN confirmation)
- **Withdraw & Deposit** - Tarik & Setor Tunai (3 steps, no PIN confirmation)
- **Profile Management** - Update PIN & Customer Info
- **Transaction History** - Tersimpan di database & SharedPreferences
- **Security** - JWT, bcrypt PIN hashing, rate limiting, CORS, Helmet

### 🔒 Security Features
- JWT Token Authentication
- Bcrypt PIN Hashing
- Rate Limiting (max requests per minute)
- CORS Protection
- Helmet Security Headers
- Auto-approve transactions (demo mode)  

---

## 🏗️ Architecture

### 3-Tier Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      MOBILE APP LAYER ✅                      │
│              (Flutter Web - Chrome Browser)                  │
│                                                              │
│  - User Interface (Login, Register, Transfer, dll) ✅       │
│  - SharedPreferences untuk Recent Transactions ✅           │
│  - No PIN Confirmation (Auto-approved) ✅                    │
│  - Material Design UI ✅                                     │
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
│  - Rate Limiting & Security (Helmet + CORS) ✅             │
│  - Balance Check: Flexible dict/object access ✅            │
└──────────────────────┬──────────────────────────────────────┘
                       │ HTTP
                       │ Internal API: http://localhost:8001/service/*
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                     SERVICE LAYER ✅                         │
│          (FastAPI/Python - Port: 8001)                      │
│                                                              │
│  - Database Operations (CRUD) ✅                            │
│  - Repository Pattern ✅                                     │
│  - Returns dict via _to_dict() methods ✅                   │
│  - SQLAlchemy ORM Connection ✅                             │
└──────────────────────┬──────────────────────────────────────┘
                       │ SQLAlchemy ORM
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    DATABASE LAYER ✅                         │
│                   (SQLite - ebanking.db)                    │
│                                                              │
│  - m_customer, m_portfolio_account, t_transaction ✅        │
│  - Auto-initialization on startup ✅                        │
└─────────────────────────────────────────────────────────────┘
```

### Communication Flow Example (Transfer)

```
1️⃣ USER → Mobile App
   - Login → Input transfer details
   - Click "Transfer Sekarang" (no PIN!)

2️⃣ Mobile App → Middleware
   POST http://localhost:8000/api/v1/transaction/transfer
   Headers: Authorization: Bearer <JWT>
   Body: {from_account, to_account, amount, pin: "123456"}

3️⃣ Middleware Processing
   - Verify JWT token
   - NO PIN validation (auto-approved)
   - Check balance: balance.available_balance || balance['available_balance']
   - Call Service Layer: debit, credit, record transaction

4️⃣ Service Layer → Database
   - Execute database operations
   - Return dict responses

5️⃣ Response → Mobile App
   - Save to SharedPreferences (contacts & transactions)
   - Show success screen
   - Update dashboard
```

---

## 📁 Project Structure

### Complete Directory Structure

```
Mobile Banking/
├── 📱 mobile/              # Flutter Web App
├── 🔧 middleware/          # Node.js API Gateway (Port 8000)
├── ⚙️  service/            # Python FastAPI Service Layer (Port 8001)
├── 📄 README.md            # Documentation (this file)
└── .gitignore              # Git ignore rules
```

### Mobile App (Flutter)

```
mobile/
├── lib/
│   ├── main.dart                      # Entry point
│   │
│   ├── 📺 screens/                    # UI Screens
│   │   ├── login_screen.dart          # Login with JWT
│   │   ├── register_screen.dart       # Register new user
│   │   ├── dashboard_screen.dart      # Dashboard + Recent Contacts
│   │   ├── transfer_screen.dart       # Transfer (3 steps, no PIN)
│   │   ├── withdraw_screen.dart       # Withdraw & Deposit (3 steps, no PIN)
│   │   └── profile_screen.dart        # Profile & Update PIN
│   │
│   ├── 🔌 services/                   # API Integration
│   │   └── api_service.dart           # HTTP client
│   │
│   ├── 🧩 widgets/                    # Reusable components
│   ├── 📦 models/                     # Data models
│   └── ⚙️  utils/                     # Helpers & Constants
│       └── constants.dart             # API URLs, colors
│
├── web/                               # Web platform (ACTIVE)
│   ├── index.html
│   └── manifest.json
│
├── pubspec.yaml                       # Dependencies
└── README.md                          # Mobile app docs
```

**Key Features:**
- ✅ 3-step transaction flow (no PIN confirmation)
- ✅ SharedPreferences untuk Recent Contacts & Transactions
- ✅ Running di Chrome Browser

### Middleware (Node.js)

```
middleware/
├── server.js                          # Main server (Port 8000)
├── authenticate.js                    # JWT middleware
│
├── 📂 routes/                         # API Routes
│   ├── auth.js                        # POST /api/v1/auth/login, register
│   ├── account.js                     # GET /api/v1/account/balance
│   ├── transaction.js                 # POST /api/v1/transaction/*
│   └── customer.js                    # GET/PUT /api/v1/customer/*
│
├── 🔌 services/                       # External Services
│   └── serviceLayerClient.js          # HTTP client to Service Layer
│
├── package.json                       # Dependencies
└── README.md                          # Middleware docs
```

**Key Features:**
- ✅ JWT Authentication & Authorization
- ✅ Auto-approve transactions (PIN: '123456')
- ✅ Flexible balance access (dict/object)
- ✅ Security: CORS, Helmet, Rate Limiting

### Service Layer (Python)

```
service/
├── main.py                            # FastAPI entry point (Port 8001)
│
├── 🎮 controllers/                    # REST API Endpoints
│   ├── customer_controller.py         # /service/customer/*
│   ├── account_controller.py          # /service/account/* (FIXED)
│   └── transaction_controller.py      # /service/transaction/*
│
├── 💼 services/                       # Business Logic Layer
│   ├── customer_service.py            # Customer logic
│   ├── account_service.py             # Account operations + _account_to_dict()
│   └── transaction_service.py         # Transaction processing
│
├── 📚 repository/                     # Data Access Layer
│   ├── customer_repository.py         # Customer CRUD
│   ├── account_repository.py          # Account CRUD
│   └── transaction_repository.py      # Transaction CRUD
│
├── 🗄️  db/                            # Database
│   ├── database.py                    # SQLAlchemy connection
│   ├── models.py                      # ORM models
│   └── ebanking.db                    # SQLite database
│
├── requirements.txt                   # Python dependencies
└── README.md                          # Service layer docs
```

**Key Features:**
- ✅ RESTful API dengan FastAPI
- ✅ Repository pattern untuk clean architecture
- ✅ Balance endpoint: `account['clear_balance']` (dict access)
- ✅ Swagger docs: http://localhost:8001/docs

---

## 🚀 Quick Start

### Prerequisites
- **Mobile:** Flutter SDK 3.9.2+
- **Middleware:** Node.js 16+, npm
- **Service:** Python 3.9+, pip

### 1. Service Layer (Port 8001)

```bash
cd service
pip install -r requirements.txt
python main.py
```

✅ API Docs: http://localhost:8001/docs

### 2. Middleware (Port 8000)

```bash
cd middleware
npm install
npm start
```

✅ API: http://localhost:8000

### 3. Mobile App

```bash
cd mobile
flutter pub get
flutter run -d chrome      # Browser
flutter run -d windows     # Windows Desktop
flutter run                # Emulator/Device
```

---

## 🧪 Testing

### Demo Credentials
- **Username:** `johndoe`
- **PIN:** `123456`
- **Account:** `9876543210`
- **Balance:** Rp 1.000.000

### Test Flow
1. ✅ Login dengan credentials di atas
2. ✅ Lihat balance di Dashboard
3. ✅ Transfer ke rekening lain
4. ✅ Withdraw/Deposit
5. ✅ Lihat transaction history

### Postman Testing
Import collections dari `service/` folder:
- `Mobile_Banking_Service.postman_collection.json`
- `Mobile_Banking_Local.postman_environment.json`

---

## 📚 API Endpoints

### Middleware API (Port 8000)

**Authentication:**
```
POST   /api/v1/auth/login       # Login with JWT
POST   /api/v1/auth/register    # Register new user
```

**Account:**
```
GET    /api/v1/account/balance  # Get account balance
```

**Transaction:**
```
POST   /api/v1/transaction/transfer   # Transfer between accounts
POST   /api/v1/transaction/withdraw   # Withdraw cash
POST   /api/v1/transaction/deposit    # Deposit cash
GET    /api/v1/transaction/history    # Get transaction history
```

**Customer:**
```
GET    /api/v1/customer/profile       # Get customer profile
PUT    /api/v1/customer/profile       # Update customer profile
PUT    /api/v1/customer/pin           # Update PIN
```

### Service Layer API (Port 8001)

**Swagger Documentation:** http://localhost:8001/docs

**Customer Endpoints:**
```
POST   /service/customer                    # Register customer
GET    /service/customer/{customer_id}      # Get customer by ID
GET    /service/customer/username/{username} # Get by username (for login)
PUT    /service/customer/{customer_id}      # Update customer
```

**Account Endpoints:**
```
POST   /service/account                           # Create account
GET    /service/account/customer/{customer_id}    # Get accounts by customer
GET    /service/account/number/{account_number}   # Get account by number
GET    /service/account/{account_number}/balance  # Get balance (FIXED)
POST   /service/account/{account_number}/debit    # Debit account
POST   /service/account/{account_number}/credit   # Credit account
```

**Transaction Endpoints:**
```
POST   /service/transaction                       # Record transaction
GET    /service/transaction/customer/{customer_id} # Get transactions
GET    /service/transaction/account/{account_number} # Get by account
```

---

## 🔧 Technical Details

### Authentication Flow

```javascript
// Login Process
POST /api/v1/auth/login
Request: { username: "johndoe", pin: "123456" }

Middleware:
1. Call Service Layer: GET /service/customer/username/johndoe
2. Get customer data with hashed PIN
3. Compare PIN using bcrypt.compare(inputPin, hashedPin)
4. If valid, generate JWT token
5. Return: { token: "eyJ...", customer: {...} }
```

### Transaction Processing

```javascript
// Transfer (Auto-Approved)
POST /api/v1/transaction/transfer

Steps:
1. Verify JWT token → extract customer_id
2. NO PIN validation (auto-approved with default PIN)
3. Verify source account ownership
4. Check balance: balance.available_balance || balance['available_balance']
5. Debit source, credit destination
6. Record transaction
7. Return success response
```

### Service Layer Data Handling

```python
# Account Service returns dict
class AccountService:
    def get_account_by_number(self, db, account_number):
        account = self.repository.get_by_account_number(db, account_number)
        return self._account_to_dict(account)  # Returns dict!
    
    def _account_to_dict(self, account):
        return {
            "id": account.id,
            "account_number": account.account_number,
            "clear_balance": float(account.clear_balance),
            "available_balance": float(account.available_balance)
        }

# Controller uses dict access
@router.get("/{account_number}/balance")
def get_account_balance(account_number: str, db: Session = Depends(get_db)):
    account = account_service.get_account_by_number(db, account_number)
    return {
        "clear_balance": account['clear_balance'],  # Dict access!
        "available_balance": account['available_balance']
    }
```

### Mobile App Local Storage

```dart
// Save transactions & contacts to SharedPreferences
Future<void> _saveContactAndTransaction(...) async {
  final prefs = await SharedPreferences.getInstance();
  
  // Save contact for quick transfer
  List<Map<String, String>> contacts = [...];
  contacts.insert(0, {'account': account, 'name': name, 'bank': bank});
  await prefs.setString('saved_contacts', jsonEncode(contacts));
  
  // Save transaction for dashboard
  List<Map<String, dynamic>> transactions = [...];
  transactions.insert(0, {
    'type': 'Transfer',
    'amount': amount,
    'date': DateTime.now().toIso8601String(),
    'status': 'SUCCESS'
  });
  await prefs.setString('recent_transactions', jsonEncode(transactions));
}
```

---

## 🔐 Security

- ✅ **JWT Token** - 24 jam expiry
- ✅ **PIN Hashing** - bcrypt (10 rounds)
- ✅ **Rate Limiting** - 100 req/15 min
- ✅ **CORS** - Configured
- ✅ **Helmet** - Security headers
- ✅ **Input Validation** - express-validator & pydantic

---

## 📦 Technologies

| Layer | Stack |
|-------|-------|
| **Mobile** | Flutter, Dart, Material Design |
| **Middleware** | Node.js, Express, JWT, bcrypt |
| **Service** | Python, FastAPI, SQLAlchemy, Pydantic |
| **Database** | SQLite (dev), PostgreSQL (prod-ready) |

---

## 📚 Additional Information

### Project Status
✅ **Production Ready** - All features implemented and tested
- Mobile App (Flutter Web): Running on Chrome
- Middleware (Node.js): Port 8000
- Service Layer (Python FastAPI): Port 8001
- Database (SQLite): ebanking.db

### Key Achievements
- ✅ Complete 3-tier architecture
- ✅ JWT authentication system
- ✅ Seamless transaction flow (no PIN confirmation)
- ✅ Real-time balance updates
- ✅ Recent contacts & transactions
- ✅ Clean code with repository pattern

### Future Enhancements
- 📱 Mobile app for Android/iOS
- 🔔 Push notifications
- 📊 Analytics dashboard
- 💳 Multiple card support
- 🌍 Multi-language support

---

## 📞 Support

For questions or issues:
- Check Swagger docs: http://localhost:8001/docs
- Review this README
- Check terminal output for errors

---

## 📄 License

This project is for educational purposes.

---

**Last Updated:** 6 Januari 2026

---

## 🛑 Stop Services

**Tekan `Ctrl+C`** di setiap terminal window, atau:

```powershell
# Windows PowerShell
taskkill /F /IM python.exe      # Service Layer
taskkill /F /IM node.exe        # Middleware
# Flutter akan stop otomatis saat close browser/app
```

---

## 🐛 Troubleshooting

### Port Already in Use
```powershell
# Check port
netstat -ano | findstr :8000
netstat -ano | findstr :8001

# Kill process
taskkill /PID <PID> /F
```

### Database Error
```bash
cd service
rm ebanking.db       # Hapus database
python main.py       # Auto-create baru
```

### Flutter Issues
```bash
cd mobile
flutter clean
flutter pub get
```

---

## 📊 Database

**File:** `service/ebanking.db` (SQLite)

**Tables:**
- `m_customer` - Data nasabah
- `m_portfolio_account` - Data rekening
- `t_transaction` - Riwayat transaksi

**Auto-initialize** saat service layer start pertama kali.

---

## 🎯 Development Workflow

1. **Backend Development:** Edit service layer → Test via Swagger/Postman
2. **API Development:** Edit middleware routes → Test via Postman
3. **Frontend Development:** Edit Flutter screens → Hot reload (`r`)
4. **Integration Testing:** Run all layers → Test full flow

---

## 🔄 Build untuk Production

### Mobile App

**Android APK:**
```bash
cd mobile
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

**iOS (Mac only):**
```bash
flutter build ios --release
```

**Windows Desktop:**
```bash
flutter build windows --release
```

**Web:**
```bash
flutter build web --release
```
Output: `build/web/`

### Middleware & Service
```bash
# Docker deployment recommended
docker build -t mobile-banking-middleware ./middleware
docker build -t mobile-banking-service ./service
```

---

## 📝 License

MIT License

---

## 👨‍💻 Support

Untuk pertanyaan atau issue:
1. Check dokumentasi di `ARCHITECTURE.md` dan `PROJECT_STRUCTURE.md`
2. Lihat Postman collection untuk API examples
3. Check `TESTING_GUIDE.md` untuk testing

---

**Happy Banking! 🏦💰**

**Version:** 1.0.0  
**Last Updated:** January 5, 2026

## 🏗️ Arsitektur

```
┌─────────────────┐
│   Mobile App    │  (Flutter - Cross Platform)
│ Port: Device   │  - Material Design UI
└────────┬────────┘  - Native Performance
         │ HTTPS
         ↓
┌─────────────────┐
│   Middleware    │  (Node.js + Express)
│   Port: 3000    │  - JWT Authentication
└────────┬────────┘  - Business Logic
         │ HTTP      - Rate Limiting
         ↓
┌─────────────────┐
│ Service Layer   │  (Python + FastAPI)
│   Port: 8001    │  - Database Operations
└────────┬────────┘  - CRUD APIs
         │
         ↓
    ┌──────────┐
    │ SQLite DB│
    └──────────┘
```

## 📁 Struktur Folder

```
Mobile Banking/
├── service/              # Service Layer (FastAPI)
│   ├── main.py
│   ├── controllers/
│   ├── services/
│   ├── repository/
│   └── db/
├── middleware/           # Middleware (Express)
│   ├── server.js
│   ├── routes/
│   ├── middleware/
│   └── services/
└── mobile/              # Mobile App (Flutter)
    ├── lib/
    │   ├── main.dart
    │   ├── screens/
    │   ├── widgets/
    │   └── services/
    └── pubspec.yaml
```

## 🚀 Quick Start - Jalankan Semua Sekaligus

### Windows PowerShell:
```powershell
.\start-all.ps1
```

### Windows Command Prompt:
```batch
start-all.bat
```

Script akan membuka 3 terminal terpisah:
1. **Service Layer** - Port 8001
2. **Middleware** - Port 3000  
3. **Mobile App** - Flutter (development mode)

## 🔧 Manual Setup (per Layer)

### 1. Service Layer

```bash
cd service
pip install -r requirements.txt
python main.py
```

**Docs:** http://localhost:8001/docs

### 2. Middleware

```bash
cd middleware
npm install
npm start
```

**API:** http://localhost:8000/api

### 3. Mobile App

```bash
cd mobile
flutter pub get
flutter run
```

**Platform Options:**
- `flutter run -d chrome` - Run di web browser
- `flutter run -d windows` - Run di Windows desktop
- `flutter run` - Run di emulator/device yang tersambung

**Build APK:**
```bash
flutter build apk --release
```

## 📱 Fitur Aplikasi

### ✅ Authentication
- Register nasabah baru
- Login dengan username & PIN
- JWT token management
- Logout

### ✅ Account Management
- View semua rekening
- Check balance per rekening
- Total balance dashboard

### ✅ Transactions
- **Transfer** - Antar rekening
- **Withdraw** - Tarik tunai
- **Deposit** - Setor tunai
- **History** - Riwayat transaksi

### ✅ Profile
- View data nasabah
- CIF Number
- Contact information

## 🧪 Testing

### Postman
Import collection dari `service/Mobile_Banking_Service.postman_collection.json`

### Browser
1. Jalankan semua layer
2. Buka browser ke mobile app
3. Register user baru
4. Login dan test fitur

### Testing Flow:
```
1. Register → john_doe, PIN: 123456
2. Login → Dapat token
3. Dashboard → Lihat balance
4. Transfer → Rp 100,000
5. History → Lihat transaksi
6. Logout
```

## 🔐 Security

- **PIN Hashing**: bcrypt (10 rounds)
- **JWT Token**: 24 jam expiry
- **CORS**: Enabled untuk cross-origin
- **Rate Limiting**: 100 req/15 min
- **Input Validation**: Express-validator

## 🌐 Ports

| Layer         | Port | URL                      |
|---------------|------|--------------------------|
| Service       | 8001 | http://localhost:8001    |
| Middleware    | 3000 | http://localhost:3000    |
| Mobile (Dev)  | Auto | Flutter hot reload       |

## 📚 Documentation

- **Service Layer**: [service/README.md](service/README.md)
- **Middleware**: [middleware/README.md](middleware/README.md)
- **Mobile App**: [mobile/README.md](mobile/README.md)
- **Postman Guide**: [service/POSTMAN_GUIDE.md](service/POSTMAN_GUIDE.md)
- **Testing Guide**: [service/TESTING_GUIDE.md](service/TESTING_GUIDE.md)

## 🛑 Stop Services

**PowerShell/CMD**: Tekan `Ctrl+C` di setiap terminal window

atau tutup semua terminal yang dibuka oleh script

## 🐛 Troubleshooting

### Port sudah digunakan
```powershell
# Check port 8001
netstat -ano | findstr :8001

# Check port 8000  
netstat -ano | findstr :8000

# Kill process
taskkill /PID <PID> /F
```

### CORS Error
- Pastikan middleware running
- Check CORS config di middleware/server.js

### Database Error
- Delete `service/ebanking.db`
- Restart service layer (auto-create new DB)

### Token Expired
- Clear browser localStorage
- Login ulang

## 📦 Build Mobile App

### Android APK
```bash
cd mobile
flutter build apk --release
```

APK location: `mobile/build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (untuk Play Store)
```bash
flutter build appbundle --release
```

### iOS (Mac only)
```bash
flutter build ios --release
```

### Windows Desktop
```bash
flutter build windows --release
```

### Web
```bash
flutter build web --release
```

Output: `mobile/build/web/`

## 🔄 Development Workflow

1. **Backend Development**: Edit service layer → Test via Postman
2. **Middleware Development**: Edit routes → Test via Postman/cURL
3. **Frontend Development**: Edit mobile/www → Test di browser
4. **Integration Testing**: Jalankan semua layer → Test full flow

## 📊 Database

**File**: `service/ebanking.db` (SQLite)

**Tables**:
- `customer` - Data nasabah
- `account` - Data rekening
- `transaction` - Riwayat transaksi

**Auto-initialize** saat service layer start pertama kali.

## 🎯 Next Features

- [ ] Push notifications
- [ ] Biometric authentication
- [ ] QR code payment
- [ ] Bill payment
- [ ] Virtual card

## 📝 License

MIT License

## 👨‍💻 Support

Untuk pertanyaan atau issue, check documentation di masing-masing folder.

---

**Happy Banking! 🏦💰**
