# 🏦 Mobile Banking System

Sistem Mobile Banking lengkap dengan 3-tier architecture: **Mobile App (Flutter)**, **Middleware (Node.js)**, dan **Service Layer (Python FastAPI)**.

> **📁 Untuk struktur file detail, lihat:** [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)  
> **🏗️ Untuk arsitektur sistem, lihat:** [ARCHITECTURE.md](ARCHITECTURE.md)

---

## 🎯 Features

✅ **Authentication** - Login dengan JWT token  
✅ **Dashboard** - Real-time balance & recent transactions  
✅ **Transfer** - Transfer antar rekening dengan validasi  
✅ **Withdraw** - Tarik tunai dengan balance check  
✅ **Deposit** - Setor tunai instant  
✅ **Transaction History** - Riwayat lengkap dengan filter  
✅ **Security** - JWT, bcrypt PIN hashing, rate limiting  

---

## 🏗️ Architecture

```
┌─────────────────┐
│   Mobile App    │  (Flutter - Cross Platform)
│  Port: Device   │  Material Design UI
└────────┬────────┘
         │ HTTPS (JWT Bearer Token)
         ↓
┌─────────────────┐
│   Middleware    │  (Node.js + Express)
│   Port: 8000    │  Authentication & Business Logic
└────────┬────────┘
         │ HTTP (Internal)
         ↓
┌─────────────────┐
│ Service Layer   │  (Python + FastAPI)
│   Port: 8001    │  Database Operations
└────────┬────────┘
         │ SQL
         ↓
    ┌──────────┐
    │ SQLite DB│
    └──────────┘
```

---

## 📁 Project Structure

```
Mobile Banking/
├── mobile/          # 📱 Flutter App
├── middleware/      # 🔧 Node.js API Gateway  
├── service/         # ⚙️  Python FastAPI
├── ARCHITECTURE.md  # 📋 Arsitektur detail
└── PROJECT_STRUCTURE.md  # 📁 Struktur file lengkap
```

**Detail struktur file:** [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)

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

## 🌐 Endpoints

| Service | Port | URL | Docs |
|---------|------|-----|------|
| Service Layer | 8001 | http://localhost:8001 | [Swagger](http://localhost:8001/docs) |
| Middleware | 8000 | http://localhost:8000 | - |
| Mobile (Dev) | - | Flutter DevTools | - |

### API Routes

**Middleware (Port 8000):**
```
POST   /api/v1/auth/login
POST   /api/v1/auth/register
GET    /api/v1/account/balance
POST   /api/v1/transaction/transfer
POST   /api/v1/transaction/withdraw
POST   /api/v1/transaction/deposit
GET    /api/v1/transaction/history
```

**Service Layer (Port 8001):**
- Auto-generated docs: http://localhost:8001/docs

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

## 📚 Documentation

- **📁 Structure:** [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - Struktur file lengkap
- **🏗️ Architecture:** [ARCHITECTURE.md](ARCHITECTURE.md) - Arsitektur sistem
- **📱 Mobile:** [mobile/README.md](mobile/README.md) - Flutter app guide
- **🔧 Middleware:** [middleware/README.md](middleware/README.md) - API Gateway
- **⚙️ Service:** [service/README.md](service/README.md) - Service Layer
- **🧪 Testing:** [service/TESTING_GUIDE.md](service/TESTING_GUIDE.md) - Test guide
- **📮 Postman:** [service/POSTMAN_GUIDE.md](service/POSTMAN_GUIDE.md) - API testing

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
