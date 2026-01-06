# 📁 PROJECT STRUCTURE

**Last Updated:** 6 Januari 2026

Struktur folder Mobile Banking System yang terorganisir dan mudah dipahami.

## 🏗️ Arsitektur Lengkap

```
Mobile Banking/
├── 📱 mobile/              # Flutter Web App
├── 🔧 middleware/          # Node.js API Gateway (Port 8000)
├── ⚙️  service/            # Python FastAPI Service Layer (Port 8001)
├── 📄 ARCHITECTURE.md      # Dokumentasi arsitektur
├── 📄 PROJECT_STRUCTURE.md # Struktur project
└── 📖 README.md            # Panduan utama
```

---

## 📱 **MOBILE APP (Flutter)**

```
mobile/
├── lib/
│   ├── main.dart                      # Entry point aplikasi
│   │
│   ├── 📺 screens/                    # UI Screens
│   │   ├── login_screen.dart          # Login dengan JWT
│   │   ├── register_screen.dart       # Registrasi user baru
│   │   ├── dashboard_screen.dart      # Dashboard utama + Recent Contacts
│   │   ├── transfer_screen.dart       # Transfer uang (3 steps, no PIN)
│   │   ├── withdraw_screen.dart       # Tarik & Setor Tunai (3 steps, no PIN)
│   │   ├── profile_screen.dart        # Profile & Update PIN
│   │   └── history_screen.dart        # Riwayat transaksi
│   │
│   ├── 🔌 services/                   # API Integration
│   │   └── api_service.dart           # HTTP client (login, balance, transfer, dll)
│   │
│   ├── 🧩 widgets/                    # Reusable components
│   │   └── (custom widgets)
│   │
│   ├── 📦 models/                     # Data models
│   │   └── (data models)
│   │
│   └── ⚙️  utils/                     # Helpers & Constants
│       └── constants.dart             # API URLs, colors, constants
│
├── web/                               # Web platform (AKTIF)
│   ├── index.html
│   └── manifest.json
│
├── pubspec.yaml                       # Dependencies Flutter
└── README.md                          # Dokumentasi mobile app
```

### **Key Features:**
- ✅ Login & Register dengan JWT Authentication
- ✅ Dashboard dengan Recent Contacts & Transactions
- ✅ Transfer tanpa konfirmasi PIN (langsung diproses)
- ✅ Tarik & Setor Tunai tanpa konfirmasi PIN
- ✅ Transaksi tersimpan di SharedPreferences untuk tampil di Dashboard
- ✅ Update PIN di Profile
- ✅ Running di Chrome Browser (Web Platform)

### **Key Files:**
- `lib/main.dart` - Entry point, routing
- `lib/services/api_service.dart` - Semua API calls (login, transfer, balance, dll)
- `lib/utils/constants.dart` - API endpoints (http://localhost:8000), colors
- `lib/screens/transfer_screen.dart` - 3 steps: Account → Amount → Success
- `lib/screens/withdraw_screen.dart` - 3 steps: Type → Amount → Success
- `pubspec.yaml` - Dependencies: http, shared_preferences

---

## 🔧 **MIDDLEWARE (Node.js + Express)**

```
middleware/
├── server.js                          # Main server (Port 8000)
├── authenticate.js                    # JWT middleware
│
├── 📂 routes/                         # API Routes
│   ├── auth.js                        # POST /api/v1/auth/login, /auth/register
│   ├── account.js                     # GET /api/v1/account/balance
│   ├── transaction.js                 # POST /api/v1/transaction/transfer
│   │                                  # POST /api/v1/transaction/withdraw
│   │                                  # POST /api/v1/transaction/deposit
│   └── customer.js                    # GET /api/v1/customer/profile
│                                      # PUT /api/v1/customer/profile
│                                      # PUT /api/v1/customer/pin
│
├── 🔌 services/                       # External Services
│   └── serviceLayerClient.js          # HTTP client ke Service Layer (Port 8001)
│
├── package.json                       # Dependencies Node.js
└── README.md                          # Dokumentasi middleware
```

### **Key Features:**
- ✅ JWT Authentication & Authorization
- ✅ PIN validation removed (auto-approved dengan PIN default '123456')
- ✅ Transfer, Withdraw, Deposit langsung diproses tanpa konfirmasi PIN
- ✅ Balance check dengan flexible dict/object access
- ✅ Security: CORS, Helmet, Rate Limiting
- ✅ Communicates dengan Service Layer via HTTP

### **Key Files:**
- `server.js` - Express server, CORS, helmet, rate limiting
- `authenticate.js` - Verify JWT token untuk protected routes
- `routes/auth.js` - Login & register (PIN di-hash dengan bcrypt)
- `routes/transaction.js` - Transfer/withdraw/deposit dengan auto-approval
- `services/serviceLayerClient.js` - Axios client untuk call Python service

---

## ⚙️ **SERVICE LAYER (Python + FastAPI)**

```
service/
├── main.py                            # FastAPI entry point (Port 8001)
│
├── 🎮 controllers/                    # REST API Endpoints
│   ├── __init__.py
│   ├── customer_controller.py         # /service/customer/* endpoints
│   ├── account_controller.py          # /service/account/* endpoints (FIXED)
│   └── transaction_controller.py      # /service/transaction/* endpoints
│
├── 💼 services/                       # Business Logic Layer
│   ├── __init__.py
│   ├── customer_service.py            # Customer business logic
│   ├── account_service.py             # Account operations + _account_to_dict()
│   └── transaction_service.py         # Transaction processing
│
├── 📚 repository/                     # Data Access Layer
│   ├── __init__.py
│   ├── customer_repository.py         # Customer CRUD
│   ├── account_repository.py          # Account CRUD
│   └── transaction_repository.py      # Transaction CRUD
│
├── 🗄️  db/                            # Database
│   ├── __init__.py
│   ├── database.py                    # SQLAlchemy connection
│   ├── models.py                      # ORM models (Customer, Account, Transaction)
│   ├── ebanking.db                    # SQLite database file (PRODUCTION)
│   └── mobile_banking.db              # SQLite database file (BACKUP)
│
├── requirements.txt                   # Python dependencies
├── .env.example                       # Environment template
└── README.md                          # Dokumentasi service layer
```

### **Key Features:**
- ✅ RESTful API dengan FastAPI
- ✅ SQLAlchemy ORM untuk database operations
- ✅ Repository pattern untuk clean architecture
- ✅ Balance endpoint fixed: dict access dengan bracket notation
- ✅ Swagger documentation di http://localhost:8001/docs
- ✅ CORS enabled untuk middleware communication
- ✅ SQLite database dengan auto-initialization

### **Key Files:**
- `main.py` - FastAPI app, CORS, Swagger docs di `/docs`
- `controllers/account_controller.py` - Balance endpoint menggunakan `account['clear_balance']`
- `services/account_service.py` - Returns dict via `_account_to_dict()`
- `repository/` - Database operations (CRUD)
- `db/models.py` - SQLAlchemy ORM: Customer, PortfolioAccount, Transaction
- `requirements.txt` - fastapi, uvicorn, sqlalchemy, bcrypt

---

## 🔄 **COMMUNICATION FLOW**

```
┌─────────────┐
│ Mobile App  │ (Flutter Web - Chrome)
│             │ - SharedPreferences untuk transactions
│             │ - No PIN confirmation screens
└──────┬──────┘
       │ HTTPS
       │ Authorization: Bearer <JWT>
       │ http://localhost:8000/api/v1/*
       ↓
┌─────────────┐
│ Middleware  │ (Node.js - Port 8000)
│             │ - JWT Verification
│             │ - Auto-approve transactions (PIN: '123456')
│             │ - Balance check: flexible dict/object access
│             │ - Rate Limiting & Security
└──────┬──────┘
       │ HTTP
       │ Internal API
       │ http://localhost:8001/service/*
       ↓
┌─────────────┐
│ Service     │ (Python FastAPI - Port 8001)
│ Layer       │ - Database Operations (CRUD)
│             │ - Returns dict via _to_dict()
│             │ - Balance: account['clear_balance']
└──────┬──────┘
       │ SQLAlchemy ORM
       ↓
┌─────────────┐
│  SQLite DB  │ (ebanking.db)
│             │ - m_customer
│             │ - m_portfolio_account
│             │ - t_transaction
└─────────────┘
```

---

## 📝 **FILE NAMING CONVENTIONS**

### **Flutter (Dart)**
- `snake_case` untuk files: `login_screen.dart`, `api_service.dart`
- `PascalCase` untuk classes: `LoginScreen`, `ApiService`
- `camelCase` untuk variables: `isLoading`, `totalBalance`

### **Node.js (JavaScript)**
- `camelCase` untuk files: `authenticate.js`, `serviceLayerClient.js`
- `camelCase` untuk functions: `getBalance()`, `handleTransfer()`
- `UPPER_SNAKE_CASE` untuk constants: `JWT_SECRET`, `PORT`

### **Python**
- `snake_case` untuk everything: `customer_service.py`, `get_customer_by_id()`
- `PascalCase` untuk classes: `CustomerService`, `Customer`
- Files dalam folder harus punya `__init__.py`

---

## 🗂️ **CONFIGURATION FILES**

### **Mobile (Flutter)**
- `pubspec.yaml` - Dependencies & assets
- `android/gradle.properties` - Android config
- `ios/Runner/Info.plist` - iOS config

### **Middleware (Node.js)**
- `package.json` - NPM dependencies
- `.env` - Environment variables
- `.gitignore` - Git exclusions

### **Service Layer (Python)**
- `requirements.txt` - Python packages
- `.env` - Database URL, secrets
- `.gitignore` - Ignore venv, __pycache__, *.db

---

## 🚀 **QUICK REFERENCE**

### **Mobile App Files (User Interface)**
| File | Purpose |
|------|---------|
| `login_screen.dart` | Login form dengan JWT |
| `dashboard_screen.dart` | Balance & quick actions |
| `transfer_screen.dart` | Transfer form |
| `history_screen.dart` | Transaction list |
| `api_service.dart` | HTTP client singleton |
| `constants.dart` | API URLs & app constants |

### **Middleware Files (API Gateway)**
| File | Purpose |
|------|---------|
| `server.js` | Express server setup |
| `auth.js` | Login & register routes |
| `transaction.js` | Transfer, withdraw, deposit |
| `account.js` | Balance & account info |
| `authenticate.js` | JWT middleware |

### **Service Layer Files (Database)**
| File | Purpose |
|------|---------|
| `main.py` | FastAPI app |
| `customer_controller.py` | Customer endpoints |
| `account_controller.py` | Account endpoints |
| `transaction_controller.py` | Transaction endpoints |
| `models.py` | Database schema |

---

## 📦 **DEPENDENCIES**

### **Mobile (Flutter)**
```yaml
http: ^1.2.0                    # HTTP client
dio: ^5.4.0                     # Advanced HTTP
provider: ^6.1.0                # State management
shared_preferences: ^2.2.0      # Local storage
flutter_secure_storage: ^9.0.0  # Secure storage
```

### **Middleware (Node.js)**
```json
express: ^4.18.2                # Web framework
axios: ^1.6.0                   # HTTP client
jsonwebtoken: ^9.0.2            # JWT
bcryptjs: ^2.4.3                # Password hashing
helmet: ^7.1.0                  # Security
express-rate-limit: ^7.1.5      # Rate limiting
```

### **Service Layer (Python)**
```
fastapi>=0.100.0                # Web framework
uvicorn[standard]>=0.23.0       # ASGI server
sqlalchemy>=2.0.0               # ORM
pydantic>=2.0.0                 # Data validation
```

---

## 🎯 **KEY FEATURES BY LAYER**

### **Mobile App**
✅ Login & JWT authentication  
✅ Dashboard dengan real balance  
✅ Transfer antar rekening  
✅ Withdraw & Deposit  
✅ Transaction history  
✅ Pull to refresh  
✅ Error handling  

### **Middleware**
✅ JWT authentication & authorization  
✅ PIN hashing dengan bcrypt  
✅ Business logic validation  
✅ Rate limiting (100 req/15min)  
✅ CORS & Helmet security  
✅ Service layer integration  

### **Service Layer**
✅ RESTful API (FastAPI)  
✅ Swagger documentation  
✅ SQLAlchemy ORM  
✅ Repository pattern  
✅ Transaction management  
✅ Database migrations  

---

**Last Updated:** January 5, 2026  
**Version:** 1.0.0
