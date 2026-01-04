# 📁 PROJECT STRUCTURE

Struktur folder Mobile Banking System yang terorganisir dan mudah dipahami.

## 🏗️ Arsitektur Lengkap

```
Mobile Banking/
├── 📱 mobile/              # Flutter Mobile App
├── 🔧 middleware/          # Node.js API Gateway
├── ⚙️  service/            # Python FastAPI Service Layer
├── 📄 ARCHITECTURE.md      # Dokumentasi arsitektur
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
│   │   ├── dashboard_screen.dart      # Dashboard utama
│   │   ├── transfer_screen.dart       # Transfer uang
│   │   ├── withdraw_screen.dart       # Tarik tunai
│   │   ├── deposit_screen.dart        # Setor tunai
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
├── android/                           # Android platform
├── ios/                               # iOS platform
├── web/                               # Web platform
├── windows/                           # Windows desktop
├── pubspec.yaml                       # Dependencies Flutter
└── README.md                          # Dokumentasi mobile app
```

### **Key Files:**
- `lib/main.dart` - Entry point, routing
- `lib/services/api_service.dart` - Semua API calls (login, transfer, balance, dll)
- `lib/utils/constants.dart` - API endpoints, colors, transaction types
- `pubspec.yaml` - Dependencies: http, provider, shared_preferences, dll

---

## 🔧 **MIDDLEWARE (Node.js + Express)**

```
middleware/
├── server.js                          # Main server
├── authenticate.js                    # JWT middleware
│
├── 📂 routes/                         # API Routes
│   ├── auth.js                        # POST /auth/login, /auth/register
│   ├── account.js                     # GET /account/balance, /account/details/:accountNumber
│   ├── transaction.js                 # POST /transaction/transfer, /transaction/withdraw, /transaction/deposit
│   │                                  # GET /transaction/history
│   └── customer.js                    # GET /customer/profile, PUT /customer/profile
│
├── 🔌 services/                       # External Services
│   └── serviceLayerClient.js          # HTTP client ke Service Layer
│
├── package.json                       # Dependencies Node.js
├── .env                               # Environment variables
└── README.md                          # Dokumentasi middleware
```

### **Key Files:**
- `server.js` - Express server, CORS, helmet, rate limiting
- `authenticate.js` - Verify JWT token untuk protected routes
- `routes/auth.js` - Login & register dengan bcrypt PIN hashing
- `routes/transaction.js` - Transfer, withdraw, deposit dengan business logic
- `services/serviceLayerClient.js` - Wrapper untuk call Service Layer API

---

## ⚙️ **SERVICE LAYER (Python + FastAPI)**

```
service/
├── main.py                            # FastAPI entry point
│
├── 🎮 controllers/                    # REST API Endpoints
│   ├── __init__.py
│   ├── customer_controller.py         # /service/customer/* endpoints
│   ├── account_controller.py          # /service/account/* endpoints
│   └── transaction_controller.py      # /service/transaction/* endpoints
│
├── 💼 services/                       # Business Logic Layer
│   ├── __init__.py
│   ├── customer_service.py            # Customer business logic
│   ├── account_service.py             # Account operations
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
│   └── ebanking.db                    # SQLite database file
│
├── 📝 tests/                          # Unit tests
│   └── (test files)
│
├── 📋 Postman Collections/
│   ├── Mobile_Banking_Service.postman_collection.json
│   ├── Mobile_Banking_Local.postman_environment.json
│   ├── POSTMAN_GUIDE.md
│   └── POSTMAN_README.md
│
├── requirements.txt                   # Python dependencies
├── .env                               # Environment variables
├── .env.example                       # Environment template
├── README.md                          # Dokumentasi service layer
└── TESTING_GUIDE.md                   # Panduan testing
```

### **Key Files:**
- `main.py` - FastAPI app, CORS, Swagger docs di `/docs`
- `controllers/` - REST API endpoints (thin layer)
- `services/` - Business logic & validations
- `repository/` - Database operations (CRUD)
- `db/models.py` - SQLAlchemy ORM models
- `requirements.txt` - fastapi, uvicorn, sqlalchemy, bcrypt, dll

---

## 🔄 **COMMUNICATION FLOW**

```
┌─────────────┐
│ Mobile App  │ (Flutter - Dart)
└──────┬──────┘
       │ HTTPS
       │ Authorization: Bearer <JWT>
       ↓
┌─────────────┐
│ Middleware  │ (Node.js - Port 8000)
│             │ - JWT Verification
│             │ - Business Logic
│             │ - Rate Limiting
└──────┬──────┘
       │ HTTP
       │ Internal API
       ↓
┌─────────────┐
│ Service     │ (Python - Port 8001)
│ Layer       │ - Database Operations
│             │ - CRUD APIs
└──────┬──────┘
       │ SQL
       ↓
┌─────────────┐
│  SQLite DB  │ (ebanking.db)
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
